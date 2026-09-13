import Foundation

public struct DailyStreak: Equatable, Sendable {
    public let languageID: String
    public let currentStreak: Int
    public let longestStreak: Int
    public let lastActiveDate: Date?

    /// A projection of persisted evidence, so edits, deletion and imports cannot leave stale counters.
    public static func project(_ sessions: [SessionRecord], languageID: String, now: Date = .now,
                               calendar: Calendar = .current) -> DailyStreak {
        var days = Set<Date>()
        for session in sessions where session.languageID == languageID {
            for raw in session.assessments {
                guard let assessment = LearningEngine.validate(raw, session: session),
                      assessment.completed == true, assessment.outcome != .uncertain,
                      let passage = session.passages.first(where: { $0.id == assessment.passageID }),
                      !passage.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let spokenAt = passage.fragments.map(\.receivedAt).max(), spokenAt <= now else { continue }
                days.insert(calendar.startOfDay(for: spokenAt))
            }
        }
        let sorted = days.sorted()
        var run = 0, longest = 0, previous: Date?
        for day in sorted {
            run = previous.flatMap { calendar.dateComponents([.day], from: $0, to: day).day } == 1 ? run + 1 : 1
            longest = max(longest, run); previous = day
        }
        let today = calendar.startOfDay(for: now)
        let age = previous.flatMap { calendar.dateComponents([.day], from: $0, to: today).day }
        return DailyStreak(languageID: languageID, currentStreak: age == 0 || age == 1 ? run : 0,
                           longestStreak: longest, lastActiveDate: previous)
    }
}
