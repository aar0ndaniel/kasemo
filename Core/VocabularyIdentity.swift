import Foundation

public enum VocabularyIdentity {
    public static func lemma(_ raw: String, language: String) -> String {
        var value = raw.precomposedStringWithCanonicalMapping.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        value = value.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        // English articles vary in generated lemmas. German articles carry gender and stay intact.
        if language == "en" {
            for article in ["a ", "an ", "the "] where value.hasPrefix(article) {
                value.removeFirst(article.count); break
            }
        }
        // Never strip accents/umlauts, guess Japanese readings, or split German compounds here.
        return value
    }
    public static func key(language: String, lemma: String, senseID: String?) -> String {
        language + "|" + self.lemma(lemma, language: language) + "|sense:" + (senseID?.isEmpty == false ? senseID! : "general")
    }
    public static func hidden(_ hidden: String, matches word: WordProposal) -> Bool {
        if hidden == word.key { return true }
        let parts = hidden.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3, parts[0] == word.language, !parts[2].hasPrefix("sense:") else { return false }
        // Old hidden IDs referred to a mutable glossary phrase. Preserve the user's hidden lexical item.
        return lemma(parts[1], language: parts[0]) == lemma(word.lemma, language: word.language)
    }
}
