import XCTest
@testable import MuralCore

final class ConversationExpansionTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "America/New_York")!
        return value
    }
    private func date(_ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour))!
    }
    private func evidence(_ day: Int, language: String = "de", meaning: String = "version", lemma: String = "die Version") -> SessionRecord {
        var session = SessionRecord(languageID: language)
        session.startedAt = date(day)
        session.append(Fragment(speaker: .user, text: "Version", startMS: 0, endMS: 1000, receivedAt: date(day)))
        let passage = session.passages[0]
        session.assessments = [Assessment(passageID: passage.id, revisionKey: passage.revisionKey, outcome: .success,
            suggestedLevel: 1, nextGoal: "Weiter", capability: "Names an object",
            words: [WordProposal(lemma: lemma, meaning: meaning, form: "Version", kind: .independent,
                confidence: 0.95, sourceIDs: passage.fragments.map(\.id), quote: "Version", language: language)], createdAt: date(day))]
        return session
    }
    func testGermanAndJapaneseAreRegisteredAndIsolated() throws {
        for id in ["de", "ja"] {
            let module = try XCTUnwrap(LanguageRegistry.module(for: id))
            XCTAssertEqual(module.teachingFocus.count, 6)
            XCTAssertEqual(module.themeOverrides.count, 24)
            var archive = Archive(); archive.preferences.learningLanguageID = id; archive.sessions = [evidence(8, language: id)]
            let restored = try Archive.decode(archive.encoded())
            XCTAssertEqual(LearningEngine.project(restored.sessions, languageID: id).words.count, 1)
            XCTAssertTrue(LearningEngine.project(restored.sessions, languageID: "es").words.isEmpty)
            XCTAssertTrue(TeachingPolicy.assessment(language: module).contains("Use language \(id)"))
        }
    }
    func testSeparateAssistantResponsesHaveAWordBoundary() {
        let fragments = [Fragment(speaker: .assistant, text: "It is easy.", startMS: 0, endMS: 1000),
                         Fragment(speaker: .assistant, text: "Now you?", startMS: 1100, endMS: 2000)]
        XCTAssertEqual(Transcript.passages(fragments)[0].text, "It is easy. Now you?")
    }
    func testJapaneseAndPunctuationDoNotAcquireArtificialSpaces() {
        let fragments = [Fragment(speaker: .assistant, text: "おは", startMS: 0, endMS: 100),
                         Fragment(speaker: .assistant, text: "よう", startMS: 100, endMS: 200),
                         Fragment(speaker: .assistant, text: "！", startMS: 200, endMS: 300)]
        XCTAssertEqual(Transcript.passages(fragments)[0].text, "おはよう！")
    }
    func testVocabularyParaphrasesAndArticlesConsolidateWithoutLosingEvidence() {
        let sessions = [evidence(7, language: "en", meaning: "a particular release", lemma: "a version"),
                        evidence(8, language: "en", meaning: "a form of software", lemma: "version")]
        let words = LearningEngine.project(sessions, languageID: "en", now: date(8)).words
        XCTAssertEqual(words.count, 1)
        XCTAssertEqual(words.first?.independentCount, 2)
        XCTAssertEqual(words.first?.bars, 2)
        let legacyID = "en|a version|a particular release"
        XCTAssertTrue(LearningEngine.project(sessions, languageID: "en", hiddenWords: [legacyID]).words.isEmpty)
    }
    func testStreakDeduplicatesDaysAndSurvivesDST() {
        let sessions = [evidence(7), evidence(8), evidence(8), evidence(9)]
        let streak = DailyStreak.project(sessions, languageID: "de", now: date(9), calendar: calendar)
        XCTAssertEqual(streak.currentStreak, 3)
        XCTAssertEqual(streak.longestStreak, 3)
        XCTAssertEqual(DailyStreak.project(sessions, languageID: "de", now: date(10), calendar: calendar).currentStreak, 3)
        XCTAssertEqual(DailyStreak.project(sessions, languageID: "de", now: date(11), calendar: calendar).currentStreak, 0)
        XCTAssertEqual(DailyStreak.project(sessions + [evidence(12)], languageID: "de", now: date(12), calendar: calendar).currentStreak, 1)
        XCTAssertEqual(DailyStreak.project(sessions, languageID: "ja", now: date(9), calendar: calendar).currentStreak, 0)
    }
    func testUncertainStaleAndFutureEvidenceCannotEarnStreak() {
        var uncertain = evidence(7); uncertain.assessments[0].outcome = .uncertain
        var stale = evidence(8); stale.correctFragment(id: stale.fragments[0].id, text: "changed")
        XCTAssertEqual(DailyStreak.project([uncertain, stale, evidence(10)], languageID: "de", now: date(9), calendar: calendar).longestStreak, 0)
    }
    func testVisibleLimitsRejectWithoutTruncatingUnicode() {
        let exact = String(repeating: "あ", count: InputLimits.typedReply)
        XCTAssertNil(InputLimits.problem(exact, limit: InputLimits.typedReply))
        XCTAssertNotNil(InputLimits.problem(exact + "い", limit: InputLimits.typedReply))
        XCTAssertNotNil(InputLimits.problem(" \n", limit: InputLimits.correction))
    }
    func testJapaneseReadingAidSeparatesWritingReadingAndRomanization() {
        let greeting = JapaneseReading.greeting
        XCTAssertEqual(greeting.reading, "こんにちは！なにについてはなしましょうか？")
        XCTAssertTrue(greeting.romaji.contains("Konnichiwa"))
        XCTAssertTrue(TeachingPolicy.lookup(language: .japanese, meaningLanguage: "English").contains("rōmaji"))
        XCTAssertEqual(JapaneseReading.goodMorning.reading, "おはよう")
        XCTAssertEqual(JapaneseReading.goodMorning.romaji, "ohayō")
    }
}
