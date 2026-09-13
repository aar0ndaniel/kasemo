import Foundation

/// Gemini's wire format stays separate from OpenAI's data-channel events.
public enum GeminiWire {
    public static func setup(model: String, instructions: String) -> [String: Any] {
        let modelIdentifier = model.hasPrefix("models/") ? model : "models/" + model
        return ["setup": ["model": modelIdentifier,
            "generationConfig": ["responseModalities": ["AUDIO"]],
            "systemInstruction": ["parts": [["text": instructions]]],
            "inputAudioTranscription": [:] as [String: String], "outputAudioTranscription": [:] as [String: String],
            "realtimeInputConfig": ["automaticActivityDetection": ["silenceDurationMs": 800]],
            "tools": [["functionDeclarations": [["name": "mural_lookup",
                "description": "Ask the application for current verified facts or detailed language help before answering.",
                "parameters": ["type": "OBJECT", "properties": ["query": ["type": "STRING"]], "required": ["query"]]]]]]]
    }
    public static func text(_ text: String, complete: Bool = true) -> [String: Any] {
        ["clientContent": ["turns": [["role": "user", "parts": [["text": text]]]], "turnComplete": complete]]
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
              !mime.contains("rate=") || mime.contains("rate=24000"),
              let encoded = inline["data"] as? String, encoded.count <= 4_000_000,
              let data = Data(base64Encoded: encoded), !data.isEmpty, data.count.isMultiple(of: 2) else { return nil }
        return data
    }
}
