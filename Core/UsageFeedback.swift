import Foundation

public struct UsageFeedback: Codable, Equatable, Sendable {
    public enum Status: String, Codable, Sendable { case usedWell, needsPractice }
    public var sourceID: String
    public var quote: String
    public var status: Status
    public var replacement: String
    public var explanation: String
    public init(sourceID: String, quote: String, status: Status, replacement: String = "", explanation: String) {
        self.sourceID = sourceID; self.quote = quote; self.status = status
        self.replacement = replacement; self.explanation = explanation
    }
    public func isValid(in passage: Passage) -> Bool {
        guard let fragment = passage.fragments.first(where: { $0.id == sourceID }),
              !quote.isEmpty, quote.count <= 300, explanation.count <= 500,
              !explanation.isEmpty, replacement.count <= 300,
              fragment.text.components(separatedBy: quote).count == 2 else { return false }
        return status != .needsPractice || (!replacement.isEmpty && replacement != quote)
    }
}
