import Foundation
import Observation
import MuralCore

@MainActor @Observable final class ProviderRouter {
    private(set) var text = ProviderAvailability()
    private(set) var voice = ProviderAvailability()
    var activeVoice: AIProvider?
    private let store: LearningStore
    private let preview: Bool
    private var retryHints: [ProviderCapability: Date] = [:]
    init(store: LearningStore) {
        self.store = store
        preview = ProcessInfo.processInfo.arguments.contains("--preview")
        if !preview, let data = UserDefaults.standard.data(forKey: "mural.provider-availability.v1"),
           let saved = try? JSONDecoder().decode([String: ProviderAvailability].self, from: data) {
            text = saved["text"] ?? .init(); voice = saved["voice"] ?? .init()
        }
    }
    var geminiAvailable: Bool {
        !preview && store.preferences.geminiFallbackEnabled == true && store.preferences.geminiConsentVersion == 1 && GeminiCredentialStore.hasKey
    }
    func status(_ capability: ProviderCapability) -> ProviderAvailability { capability == .text ? text : voice }
    func shouldUseGemini(_ capability: ProviderCapability) -> Bool {
        geminiAvailable && (capability == .text && activeVoice == .gemini || !CredentialStore.hasKey || !status(capability).mayAttemptOpenAI())
    }
    func observe(_ response: HTTPURLResponse, capability: ProviderCapability, errorData: Data? = nil) {
        let headers = response.allHeaderFields.reduce(into: [String: String]()) { result, item in
            if let key = item.key as? String { result[key.lowercased()] = String(describing: item.value) }
        }
        var errorCode: String? = nil
        if let errorData, let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
           let err = json["error"] as? [String: Any],
           let code = err["code"] as? String {
            errorCode = code
        }
        var value = status(capability)
        let observation = ProviderObservation(headers: headers, now: .now, httpStatus: response.statusCode, errorCode: errorCode)
        value.observe(observation)
        retryHints[capability] = response.statusCode == 429 ? ProviderObservation.retryDate(headers["retry-after"])
            ?? [observation.remainingRequests == 0 ? observation.requestsResetAt : nil,
                observation.remainingTokens == 0 ? observation.tokensResetAt : nil].compactMap { $0 }.max() : nil
        set(value, capability)
    }
    func observe(realtimeRateLimits: [[String: Any]]) {
        var value = status(.voice)
        let observation = ProviderObservation(realtimeRateLimits: realtimeRateLimits)
        value.observe(observation)
        if observation.remainingRequests == 0 || observation.remainingTokens == 0 {
            retryHints[.voice] = [observation.requestsResetAt, observation.tokensResetAt].compactMap { $0 }.max()
        }
        set(value, .voice)
    }
    func failed(_ capability: ProviderCapability, error: Error? = nil) {
        var value = status(capability)
        let statusToSet: AvailabilityStatus
        if let apiError = error as? APIClient.APIError {
            switch apiError {
            case .http(429):
                let retry = retryHints[capability] ?? Date().addingTimeInterval(60)
                statusToSet = .temporaryRateLimit(retryAt: retry)
            case .http(500...599):
                statusToSet = .serviceUnavailable(retryAt: retryHints[capability])
            default:
                statusToSet = .networkUnavailable
            }
        } else if error is URLError {
            statusToSet = .networkUnavailable
        } else if let retry = retryHints[capability] {
            statusToSet = .temporaryRateLimit(retryAt: retry)
        } else {
            statusToSet = .serviceUnavailable(retryAt: nil)
        }
        value.fail(status: statusToSet)
        set(value, capability)
    }
    func succeeded(_ capability: ProviderCapability, generation: UUID) {
        var value = status(capability); value.succeeded(generation: generation); set(value, capability)
    }
    func invalidate() {
        // Explicit credential/consent changes invalidate all in-flight recovery generations.
        var newText = ProviderAvailability(), newVoice = ProviderAvailability()
        if text.usingFallback { newText.fail() }; if voice.usingFallback { newVoice.fail() }
        text = newText; voice = newVoice; retryHints = [:]; persist()
    }
    static func eligible(_ error: Error) -> Bool {
        if error is CancellationError { return false }
        if let error = error as? APIClient.APIError {
            switch error {
            case .http(429), .http(500...599), .missingKey, .incomplete, .invalidResponse: return true
            default: return false
            }
        }
        if let error = error as? URLError {
            return [.timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet, .dnsLookupFailed].contains(error.code)
        }
        if let error = error as? LiveTransport.TransportError {
            switch error { case .connection, .timeout: return true; case .microphone: return false }
        }
        return false
    }
    private func set(_ value: ProviderAvailability, _ capability: ProviderCapability) {
        if capability == .text { text = value } else { voice = value }; persist()
    }
    private func persist() {
        guard !preview, let data = try? JSONEncoder().encode(["text": text, "voice": voice]) else { return }
        UserDefaults.standard.set(data, forKey: "mural.provider-availability.v1")
    }
}
