import Foundation

public enum InputLimits {
    public static let typedReply = 2_000
    public static let correction = 10_000
    public static func problem(_ text: String, limit: Int) -> String? {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Enter some text first." }
        if text.count > limit { return "\(text.count) / \(limit) characters. Shorten your text before continuing." }
        return nil
    }
}
