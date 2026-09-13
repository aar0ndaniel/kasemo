import SwiftUI
import MuralCore

struct InputCountView: View {
    let text: String
    let limit: Int
    var body: some View {
        Text(text.count > limit ? "\(text.count) / \(limit) characters. Shorten your text to continue." : "\(text.count) / \(limit) characters")
            .font(.caption).foregroundStyle(text.count > limit ? .red : MuralColor.secondary)
            .accessibilityIdentifier("input-character-count")
    }
}

struct LearnerPassageView: View {
    let passage: Passage
    let assessment: Assessment?
    private var feedback: [UsageFeedback] {
        guard let assessment, assessment.revisionKey == passage.revisionKey, assessment.outcome != .uncertain else { return [] }
        return (assessment.feedback ?? []).filter { $0.isValid(in: passage) }
    }
    private var highlighted: AttributedString {
        var result = AttributedString(), plain = ""
        for fragment in passage.fragments {
            let joined = Transcript.join([plain, fragment.text])
            let addition = String(joined.dropFirst(plain.count))
            var part = AttributedString(addition)
            for item in feedback where item.sourceID == fragment.id {
                if let range = part.range(of: item.quote) {
                    part[range].foregroundColor = item.status == .usedWell ? Color(red: 0.12, green: 0.36, blue: 0.20) : Color(red: 0.62, green: 0.20, blue: 0.10)
                    part[range].underlineStyle = .single
                }
            }
            result.append(part); plain = joined
        }
        return result
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("You", systemImage: "person.crop.circle").font(.caption.weight(.semibold))
            Text(highlighted).font(.body).textSelection(.enabled).accessibilityIdentifier("learner-caption")
            ForEach(Array(feedback.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 3) {
                    Label(item.status == .usedWell ? "Used well: \(item.quote)" : "Try: \(item.quote) → \(item.replacement)",
                          systemImage: item.status == .usedWell ? "checkmark.circle" : "arrow.triangle.2.circlepath")
                        .font(.caption.weight(.medium))
                    Text(item.explanation).font(.caption)
                }
            }
            if !feedback.isEmpty { Text("Usage suggestions, not a pronunciation score. Unmarked words haven’t been assessed.").font(.caption2) }
        }.foregroundStyle(MuralColor.ink).padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(MuralColor.sage.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }
}
