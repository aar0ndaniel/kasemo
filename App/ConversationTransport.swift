import Foundation
import MuralCore

public enum TransportState: String, Sendable {
    case idle
    case openAIActive
    case transitioning
    case geminiActive
}

@MainActor final class ConversationTransport {
    var onEvent: (([String: Any]) -> Void)?
    var onLevels: ((Double, Double) -> Void)?
    var onFailure: ((String) -> Void)?
    private let openAI = LiveTransport()
    private let gemini = GeminiLiveTransport()
    private(set) var provider: AIProvider = .openAI
    private(set) var state: TransportState = .idle
    private var attempt = UUID()
    private var recoveryTask: Task<Void, Never>?
    private var closing = true
    private var connecting = false
    private var initialFailure: String?
    private var muted = false
    private var api: APIClient?
    private var instructions = ""
    private var history: [[String: Any]] = []

    func connect(api: APIClient, instructions: String, history: [[String: Any]]) async throws {
        disconnect()
        self.api = api; self.instructions = instructions; self.history = history
        let generation = UUID(); attempt = generation; closing = false; connecting = true; muted = false
        initialFailure = nil
        provider = api.router.shouldUseGemini(.voice) ? .gemini : .openAI
        bind(generation)
        defer { if attempt == generation { connecting = false } }
        if provider == .gemini {
            state = .geminiActive
            api.router.activeVoice = .gemini
            try await gemini.connect(instructions: instructions)
            return
        }
        let recoveryGeneration = api.router.voice.failureGeneration
        do {
            state = .openAIActive
            api.router.activeVoice = .openAI
            try await openAI.connect(api: api, instructions: instructions, history: history)
            guard attempt == generation, !Task.isCancelled else { throw CancellationError() }
            api.router.succeeded(.voice, generation: recoveryGeneration)
        } catch {
            guard attempt == generation, !Task.isCancelled, ProviderRouter.eligible(error) || initialFailure != nil else {
                state = .idle
                throw error
            }
            state = .transitioning
            api.router.failed(.voice, error: error); openAI.disconnect()
            guard api.router.geminiAvailable else { state = .idle; throw error }
            provider = .gemini; api.router.activeVoice = .gemini
            onEvent?(["type": "mural.provider.switching"])
            try await gemini.connect(instructions: instructions)
            state = .geminiActive
        }
    }
    private func bind(_ generation: UUID) {
        openAI.onEvent = { [weak self] event in
            guard let self, self.attempt == generation, self.provider == .openAI, !self.closing || event["type"] as? String == "session.closed" else { return }
            if event["type"] as? String == "rate_limits.updated", let limits = event["rate_limits"] as? [[String: Any]] {
                self.api?.router.observe(realtimeRateLimits: limits)
            }
            self.onEvent?(event)
        }
        gemini.onEvent = { [weak self] event in
            guard let self, self.attempt == generation, self.provider == .gemini, !self.closing || event["type"] as? String == "session.closed" else { return }
            self.onEvent?(event)
        }
        openAI.onLevels = { [weak self] input, output in
            guard let self, self.attempt == generation, self.provider == .openAI else { return }; self.onLevels?(input, output)
        }
        gemini.onLevels = { [weak self] input, output in
            guard let self, self.attempt == generation, self.provider == .gemini else { return }; self.onLevels?(input, output)
        }
        openAI.onFailure = { [weak self] message in
            guard let self, self.attempt == generation, !self.closing, self.provider == .openAI else { return }
            if self.connecting { self.initialFailure = message; self.openAI.disconnect(); return }
            self.recover(generation, message: message)
        }
        gemini.onFailure = { [weak self] message in
            guard let self, self.attempt == generation, !self.closing, self.provider == .gemini else { return }
            self.onFailure?(message)
        }
    }
    private func recover(_ generation: UUID, message: String) {
        guard recoveryTask == nil, let api else { return }
        state = .transitioning
        api.router.failed(.voice)
        guard api.router.geminiAvailable else { state = .idle; onFailure?(message); return }
        openAI.disconnect(); provider = .gemini; api.router.activeVoice = .gemini
        onEvent?(["type": "mural.provider.switching"])
        recoveryTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.gemini.connect(instructions: self.instructions, initiallyMuted: self.muted)
                guard self.attempt == generation, !Task.isCancelled else { return }
                self.state = .geminiActive
                self.recoveryTask = nil
            } catch {
                guard self.attempt == generation, !Task.isCancelled else { return }
                self.state = .idle
                self.recoveryTask = nil; self.onFailure?(error.localizedDescription)
            }
        }
    }
    @discardableResult func send(_ event: [String: Any]) -> Bool { provider == .openAI ? openAI.send(event) : gemini.send(event) }
    @discardableResult func sendTyped(_ text: String) -> Bool { provider == .gemini && gemini.sendTyped(text) }
    func mute(_ value: Bool) { muted = value; if provider == .openAI { openAI.mute(value) } else { gemini.mute(value) } }
    func close() {
        closing = true; recoveryTask?.cancel(); recoveryTask = nil
        if provider == .openAI { openAI.close() } else { gemini.close() }
    }
    func disconnect() {
        attempt = UUID(); closing = true; connecting = false
        recoveryTask?.cancel(); recoveryTask = nil
        openAI.disconnect(); gemini.disconnect(); api?.router.activeVoice = nil
        onLevels?(0, 0)
    }
}
