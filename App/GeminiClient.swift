import Foundation
import Security
import MuralCore

enum GeminiCredentialStore {
    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "no.william.mural.gemini",
         kSecAttrAccount as String: "owner", kSecAttrSynchronizable as String: false]
    }
    static var hasKey: Bool { read() != nil }
    static func read() -> String? {
        var query = query; query[kSecReturnData as String] = true; query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func save(_ key: String) throws {
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key.count >= 20, key.count <= 500, !key.contains(where: \.isWhitespace) else { throw GeminiError.invalidKey }
        let data = Data(key.utf8)
        let result = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if result == errSecItemNotFound {
            var query = query; query[kSecValueData as String] = data; query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else { throw GeminiError.keychain }
        } else if result != errSecSuccess { throw GeminiError.keychain }
    }
    static func delete() throws {
        let result = SecItemDelete(query as CFDictionary)
        guard result == errSecSuccess || result == errSecItemNotFound else { throw GeminiError.keychain }
    }
}

enum GeminiError: LocalizedError {
    case invalidKey, missingKey, keychain, incomplete, http(Int), connection, audio, timeout, server(String)
    var errorDescription: String? {
        switch self {
        case .invalidKey: "Enter a valid Gemini API key."
        case .missingKey: "Add a Gemini API key and enable fallback in Advanced settings."
        case .keychain: "The Gemini key couldn’t be updated in this iPhone’s Keychain."
        case .incomplete: "Gemini didn’t return a complete response. Please try again."
        case .http(429): "Gemini’s project quota or rate limit was reached. Check Google AI Studio for your current limits."
        case .http(400), .http(401), .http(403): "Gemini rejected the request. Check the key, model access and project settings."
        case .http(let status): "Gemini couldn’t complete the request (HTTP \(status))."
        case .connection: "The Gemini voice connection ended. Your conversation is saved."
        case .audio: "Gemini audio couldn’t start on this audio route. Check the microphone and try again."
        case .timeout: "Gemini took too long to connect. Please try again."
        case .server(let message): "Gemini: \(message)"
        }
    }
}

@MainActor final class GeminiClient {
    static let textModel = GeminiWire.textModel
    static let liveModel = GeminiWire.liveModel
    private let session: URLSession
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 45; config.timeoutIntervalForResource = 60
        config.httpCookieStorage = nil; config.urlCache = nil
        session = URLSession(configuration: config, delegate: NoRedirect(), delegateQueue: nil)
    }
    func respond(instructions: String, input: String, schema: [String: Any]?, search: Bool) async throws -> APIResult {
        guard let key = GeminiCredentialStore.read() else { throw GeminiError.missingKey }
        var generation: [String: Any] = ["maxOutputTokens": schema == nil ? 2048 : 4096]
        if let schema { generation["responseMimeType"] = "application/json"; generation["responseJsonSchema"] = schema }
        var body: [String: Any] = ["systemInstruction": ["parts": [["text": instructions]]],
            "contents": [["role": "user", "parts": [["text": input]]]], "generationConfig": generation]
        if search { body["tools"] = [["googleSearch": [:] as [String: String]]] }
        var request = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(Self.textModel):generateContent")!)
        request.httpMethod = "POST"; request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        var result = try await session.data(for: request)
        var retry = 0
        while let http = result.1 as? HTTPURLResponse,
              let model = GeminiWire.retryModel(status: http.statusCode, attempt: retry) {
            try await Task.sleep(for: .seconds(1 << retry))
            try Task.checkCancellation()
            request.url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!
            result = try await session.data(for: request)
            retry += 1
        }
        let (data, response) = result
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse else { throw GeminiError.incomplete }
        guard (200..<300).contains(http.statusCode) else {
            let detail = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? [String: Any]
            let message = detail?["message"] as? String
            if let message { throw GeminiError.server("HTTP \(http.statusCode): \(String(message.prefix(400)))") }
            throw GeminiError.http(http.statusCode)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidate = (json["candidates"] as? [[String: Any]])?.first,
              candidate["finishReason"] as? String == "STOP",
              let content = candidate["content"] as? [String: Any] else { throw GeminiError.incomplete }
        let text = (content["parts"] as? [[String: Any]] ?? []).filter { $0["thought"] as? Bool != true }.compactMap { $0["text"] as? String }.joined()
        guard !text.isEmpty else { throw GeminiError.incomplete }
        var sources: [SourceLink] = []
        if let grounding = candidate["groundingMetadata"] as? [String: Any] {
            for chunk in grounding["groundingChunks"] as? [[String: Any]] ?? [] {
                guard let web = chunk["web"] as? [String: Any], let uri = web["uri"] as? String else { continue }
                let source = SourceLink(title: web["title"] as? String ?? "Source", url: uri)
                if source.safeURL != nil, !sources.contains(where: { $0.url == uri }) { sources.append(source) }
            }
        }
        let usage = json["usageMetadata"] as? [String: Any] ?? [:]
        return APIResult(text: text, sources: sources, usage: APIUsage(input: usage["promptTokenCount"] as? Int ?? 0,
            output: usage["candidatesTokenCount"] as? Int ?? 0, searches: sources.isEmpty ? 0 : 1))
    }
}
