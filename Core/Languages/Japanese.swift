import Foundation

extension LanguageModule {
    public static let japanese = LanguageModule(
        id: "ja", name: "Japanese", nativeName: "日本語", variety: "Japan", locale: "ja-JP",
        greeting: "こんにちは！何について話しましょうか？", greetingWord: "こんにちは",
        speechGuidance: "Use clear, natural standard Japanese, initially polite です/ます. Preserve mora timing, long vowels, small っ consonant length and ん; model natural pitch accent without claiming there is one accent for every region. Read particles は/へ/を as wa/e/o where appropriate. Accept regional forms respectfully. Do not pronounce rōmaji as English or read visual annotations aloud. Avoid exaggerated anime voices; assess pronunciation only with suitable audio evidence, never a transcript alone.",
        writingGuidance: "Use natural Japanese kanji with hiragana inflections and katakana loanwords. Keep greetings such as おはよう and こんにちは in their usual kana form; do not force kanji or katakana equivalents. Spoken output remains natural Japanese. Reading aids separately show contextual kana and Hepburn rōmaji, not an English translation. Explain kanji readings in context rather than assigning one fixed reading to a character.",
        lemmaGuidance: "Use Japanese dictionary forms: Godan verbs such as 書く and Ichidan verbs such as 食べる; handle irregular する/来る separately. Use い-adjective dictionary forms and な-adjective stems, explaining な/だ in context. Normalize inflection only with contextual evidence. Preserve the distinction between homophones and separate kanji senses. Reuse canonical kana/kanji lemmas for the same lexeme when verified, but do not mechanically replace kana with kanji or merge names and ambiguous readings. Keep compounds and useful chunks intact; do not split unspaced text at arbitrary characters.",
        teachingFocus: [
            "N5-oriented entry: greetings, kana awareness, useful chunks, です/ます politeness and は/が/を/に in short concrete exchanges.",
            "N5 consolidation: basic verb groups, present/past and negative polite forms, numbers, time, location and everyday requests; introduce common kanji with kana readings.",
            "N4-oriented entry: dictionary and て forms, てください/てもいい, giving reasons and connecting daily actions; contrast い/な adjectives in context.",
            "N4 consolidation: plain forms, comparisons, experience with たことがある, plans, ability and short stories. Shift register only when socially appropriate.",
            "N3-oriented entry: everyday opinions, relative clauses, conditionals, giving/receiving and explaining intentions with natural connectors.",
            "N3-oriented nuance: follow connected everyday discussion, distinguish casual and polite speech, soften requests and express uncertainty naturally. JLPT reading/listening bands guide content; this is not a JLPT certificate or a speaking score."
        ],
        topicPlaceholder: "食べ物、旅行、音楽、日本での日常…",
        lookupUnavailableReply: "申し訳ありません。その情報は今調べられませんでした。",
        themeOverrides: ConversationTheme.culturalOverrides([
            "coffee": ("喫茶店で", "Order coffee in an imagined Japanese kissaten, practise hot/iced choices and natural polite requests."),
            "weekend": ("週末はどうでしたか", "Talk about a weekend in Japan or the learner's home: a park, shopping or resting. Invite a short past-tense story."),
            "walk": ("散歩しましょう", "Imagine a walk in a Japanese neighbourhood or park. Discuss seasons and surroundings without inventing current blossoms."),
            "dinner": ("晩ごはんは何にする", "Plan a meal, discuss ingredients and preferences, and model culturally appropriate but non-compulsory mealtime expressions."),
            "introductions": ("はじめまして", "Meet a new Japanese-speaking acquaintance. Practise names and はじめまして/よろしくお願いします with context and modest politeness."),
            "groceries": ("コンビニで", "Visit an imagined konbini: ask about an onigiri, a bag, heating food and payment. Explain common phrases without assuming every shop has identical rules."),
            "travel": ("東京で電車に乗る", "Navigate an imagined Tokyo train journey, ask about platforms and transfers, and read station names in context. Never invent live schedules or fares."),
            "home": ("どんな部屋ですか", "Describe rooms and a possible move in Japan, asking about space and everyday habits without legal claims about rentals."),
            "friends": ("一緒に行きませんか", "Invite a Japanese-speaking friend to a café or activity. Model accepting and gently declining an invitation."),
            "work": ("職場でひとこと", "Practise a greeting, clarification and simple work request with suitable politeness. Explain お疲れさまです in context, avoiding rigid stereotypes."),
            "weather": ("今日はどんな天気", "Discuss imagined weather and seasonal clothing, including 梅雨 vocabulary. Verify any actual forecast first."),
            "cabin": ("温泉へ行きたい", "Plan an imagined ryokan or hot-spring trip, ask about food and facilities, and discuss checking local bathing rules."),
            "music": ("好きな音楽", "Chat about Japanese or other music the learner likes. Practise preferences without inventing lyrics or current concert information."),
            "film": ("映画とアニメ", "Discuss films, animation or series according to the learner's interests. Distinguish stylized dialogue from everyday Japanese and avoid spoilers."),
            "books": ("本屋さんで", "Browse an imagined Japanese bookshop. Discuss manga, novels or short reading material with appropriate kana and kanji support."),
            "design": ("好きなデザイン", "Describe everyday Japanese objects or architecture. Invite precise preferences without treating one aesthetic as all of Japanese culture."),
            "technology": ("便利な道具", "Discuss useful technology and apps in Japanese. Delegate current product claims for verification."),
            "travelstories": ("旅の思い出", "Share travel memories in Japanese, using concrete descriptions and past-tense sequences. Do not assume the learner has visited Japan."),
            "restaurant": ("居酒屋で注文", "Role-play ordering food and optional drinks at an izakaya. Practise すみません and requests, allergies and checking the bill; do not pressure anyone to drink alcohol."),
            "neighbours": ("近所の人と", "Greet a neighbour, ask for a small favour or discuss the neighbourhood using considerate Japanese."),
            "traditions": ("季節のあいさつ", "Discuss seasonal greetings, New Year or local festivals. Explain situational phrasing and regional variation without presenting customs as universal rules."),
            "opinions": ("どう思いますか", "Discuss a simple everyday dilemma with reasons, uncertainty and gentle disagreement in Japanese."),
            "future": ("これからの予定", "Talk about next week's plans and longer hopes, distinguishing intentions from confirmed arrangements."),
            "today": ("最近の話題", "Ask what current topic interests the learner; use source-backed lookup before discussing facts in Japanese.")
        ])
    )
}
