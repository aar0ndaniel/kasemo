import Foundation

public struct JapaneseReading: Codable, Equatable, Sendable {
    public let surface: String
    public let kanaReading: String
    public let romaji: String
    public let asciiRomaji: String?

    public let hiraganaForm: String?
    public let kanjiForm: String?
    public let katakanaTranscription: String?

    public let spellingGuide: String?
    public let pronunciationNotes: String?

    public init(
        surface: String,
        kanaReading: String,
        romaji: String,
        asciiRomaji: String? = nil,
        hiraganaForm: String? = nil,
        kanjiForm: String? = nil,
        katakanaTranscription: String? = nil,
        spellingGuide: String? = nil,
        pronunciationNotes: String? = nil
    ) {
        self.surface = surface
        self.kanaReading = kanaReading
        self.romaji = romaji
        self.asciiRomaji = asciiRomaji
        self.hiraganaForm = hiraganaForm
        self.kanjiForm = kanjiForm
        self.katakanaTranscription = katakanaTranscription
        self.spellingGuide = spellingGuide
        self.pronunciationNotes = pronunciationNotes
    }

    public init(writing: String, reading: String, romaji: String) {
        self.init(surface: writing, kanaReading: reading, romaji: romaji)
    }

    public var writing: String { surface }
    public var reading: String { kanaReading }

    enum CodingKeys: String, CodingKey {
        case surface, kanaReading, romaji, asciiRomaji
        case hiraganaForm, kanjiForm, katakanaTranscription
        case spellingGuide, pronunciationNotes
        case legacyWriting = "writing"
        case legacyReading = "reading"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let s = try container.decodeIfPresent(String.self, forKey: .surface)
            ?? container.decodeIfPresent(String.self, forKey: .legacyWriting)
            ?? ""
        let r = try container.decodeIfPresent(String.self, forKey: .kanaReading)
            ?? container.decodeIfPresent(String.self, forKey: .legacyReading)
            ?? ""
        self.surface = s
        self.kanaReading = r
        self.romaji = try container.decodeIfPresent(String.self, forKey: .romaji) ?? ""
        self.asciiRomaji = try container.decodeIfPresent(String.self, forKey: .asciiRomaji)
        self.hiraganaForm = try container.decodeIfPresent(String.self, forKey: .hiraganaForm)
        self.kanjiForm = try container.decodeIfPresent(String.self, forKey: .kanjiForm)
        self.katakanaTranscription = try container.decodeIfPresent(String.self, forKey: .katakanaTranscription)
        self.spellingGuide = try container.decodeIfPresent(String.self, forKey: .spellingGuide)
        self.pronunciationNotes = try container.decodeIfPresent(String.self, forKey: .pronunciationNotes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(surface, forKey: .surface)
        try container.encode(kanaReading, forKey: .kanaReading)
        try container.encode(surface, forKey: .legacyWriting)
        try container.encode(kanaReading, forKey: .legacyReading)
        try container.encode(romaji, forKey: .romaji)
        try container.encodeIfPresent(asciiRomaji, forKey: .asciiRomaji)
        try container.encodeIfPresent(hiraganaForm, forKey: .hiraganaForm)
        try container.encodeIfPresent(kanjiForm, forKey: .kanjiForm)
        try container.encodeIfPresent(katakanaTranscription, forKey: .katakanaTranscription)
        try container.encodeIfPresent(spellingGuide, forKey: .spellingGuide)
        try container.encodeIfPresent(pronunciationNotes, forKey: .pronunciationNotes)
    }

    public static let greeting = JapaneseReading(
        surface: "こんにちは！何について話しましょうか？",
        kanaReading: "こんにちは！なにについてはなしましょうか？",
        romaji: "Konnichiwa! Nani ni tsuite hanashimashō ka?",
        asciiRomaji: "Konnichiwa! Nani ni tsuite hanashimashou ka?",
        hiraganaForm: "こんにちは！なにについてはなしましょうか？",
        kanjiForm: nil,
        katakanaTranscription: "コンニチハ！ナニニツイテハナシマショウカ？",
        spellingGuide: "Greetings such as こんにちは are conventionally spelled in Hiragana in modern Japanese. Note that the particle は is pronounced 'wa'.",
        pronunciationNotes: "Read topic particle は as 'wa'. Maintain standard polite rhythm."
    )

    public static let goodMorning = JapaneseReading(
        surface: "おはよう",
        kanaReading: "おはよう",
        romaji: "ohayō",
        asciiRomaji: "ohayou",
        hiraganaForm: "おはよう",
        kanjiForm: "お早う",
        katakanaTranscription: "オハヨウ",
        spellingGuide: "Spelled in native Japanese as おはよう (Hiragana). Katakana オハヨウ is used for phonetic transcription or stylistic emphasis. While お早う / 御早う are attested historical kanji variants, modern everyday Japanese conventionally writes this greeting in Hiragana. English speakers often phonetically misspell it as 'ohiao', but in Japanese it is 4 distinct morae: お・は・よ・う (o-ha-yo-u) with a lengthened 'o' sound (ohayō).",
        pronunciationNotes: "4 morae (o-ha-yo-u). Standard pitch accent: atamadaka (drops after the first mora: o↓hayō) in standard Tokyo Japanese."
    )

    public static let guidance = """
    Japanese reading aid: return a JSON object with natural Japanese writing, contextual kana reading, and romanization, grounded in Japan Foundation Irodori and the JF Standard for Japanese-Language Education.
    Schema keys:
    - surface: Exact supplied natural Japanese writing (e.g. おはよう, 学校, コーヒー).
    - kanaReading: Contextual reading in hiragana (keep katakana only for actual loanwords like コーヒー).
    - romaji: Standard Modified Hepburn romanization with long-vowel macrons (ohayō, gakkō, kōhī).
    - asciiRomaji: Keyboard/wāpuro ASCII input form without macrons (ohayou, gakkou, koohii).
    - hiraganaForm: Pure hiragana rendering if applicable.
    - kanjiForm: Attested kanji variant if natural (e.g. お早う for おはよう, 学校 for がっこう); return null if there is no natural kanji form. Do not fabricate obscure or obsolete kanji.
    - katakanaTranscription: Katakana transcription of the word or phrase; treat this as a phonetic transcription, not everyday native spelling.
    - spellingGuide: Concise explanation of how Japanese spell the word in their language vs. how English speakers write or misspell it (e.g. clarify that 'ohiao' is an English phonetic error, while authentic Japanese spelling is 4 morae o-ha-yo-u / お・は・よ・う, and that everyday greetings are written in hiragana).
    - pronunciationNotes: Concise notes on mora timing (e.g. small っ, long vowel ō/ou, syllabic ん) and particle shifts (は as wa, へ as e, を as o). Include pitch accent only when confident of standard Tokyo accent; do not invent accent patterns.
    """
}
