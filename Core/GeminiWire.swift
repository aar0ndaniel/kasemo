import Foundation

/// Gemini's wire format stays separate from OpenAI's data-channel events.
public enum GeminiWire {
    public static let textModel = "gemini-2.5-flash"
    public static let liveModel = "gemini-3.1-flash-live-preview"

    /// Never log this URL: Google's WebSocket gateway authenticates via its query.
    public static func liveURL(key: String) -> URL? {
        var components = URLComponents(string: "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent")
        components?.queryItems = [URLQueryItem(name: "key", value: key)]
        return components?.url
    }

    /// Retry transient unavailability and project/model access 404s with a small
    /// list of current models. Authentication and quota errors are not retried.
    public static func retryModel(status: Int, attempt: Int) -> String? {
        guard status == 404 || status == 503 else { return nil }
        switch attempt {
        case 0: return "gemini-3.5-flash"
        case 1: return "gemini-3.1-flash-lite"
        default: return nil
        }
    }
    public static func setup(model: String, instructions: String) -> [String: Any] {
        let modelIdentifier = model.hasPrefix("models/") ? model : "models/" + model
        return [
            "setup": [
                "model": modelIdentifier,
                "responseModalities": ["AUDIO"],
                "systemInstruction": ["parts": [["text": instructions]]],
                "inputAudioTranscription": [:] as [String: String],
                "outputAudioTranscription": [:] as [String: String],
                "realtimeInputConfig": ["automaticActivityDetection": ["silenceDurationMs": 800]],
                "tools": [
                    [
                        "functionDeclarations": [
                            [
                                "name": "mural_lookup",
                                "description": "Ask the application for current verified facts or detailed language help before answering.",
                                "parameters": [
                                    "type": "OBJECT",
                                    "properties": [
                                        "query": ["type": "STRING"]
                                    ],
                                    "required": ["query"]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    }
    public static func text(_ text: String, complete: Bool = true) -> [String: Any] {
        ["clientContent": ["turns": [["role": "user", "parts": [["text": text]]]], "turnComplete": complete]]
    }
    /// User text during an open Live session uses realtimeInput, as opposed to
    /// application guidance/history which uses clientContent.
    public static func realtimeText(_ text: String) -> [String: Any] {
        ["realtimeInput": ["text": text]]
    }
    public static func audio(_ bytes: Data) -> [String: Any] {
        ["realtimeInput": ["audio": ["mimeType": "audio/pcm;rate=16000", "data": bytes.base64EncodedString()]]]
    }
    public static func toolResponse(id: String, text: String) -> [String: Any] {
        ["toolResponse": ["functionResponses": [["id": id, "name": "mural_lookup", "response": ["result": text]]]]]
    }
    public static func pcm(_ part: [String: Any]) -> Data? {
        guard let inline = part["inlineData"] as? [String: Any],
              let mime = inline["mimeType"] as? String, mime.hasPrefix("audio/pcm"),
              let encoded = inline["data"] as? String, encoded.count <= 4_000_000,
              let data = Data(base64Encoded: encoded), !data.isEmpty, data.count.isMultiple(of: 2) else { return nil }
        return data
    }
}
