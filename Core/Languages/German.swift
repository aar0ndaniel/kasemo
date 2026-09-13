import Foundation

extension LanguageModule {
    public static let german = LanguageModule(
        id: "de", name: "German", nativeName: "Deutsch", variety: "Germany", locale: "de-DE",
        greeting: "Hallo! Worüber möchtest du heute sprechen?", greetingWord: "hallo",
        speechGuidance: "Use clear contemporary Standard German as spoken in Germany. Model vowel length, ä/ö/ü, ich/ach sounds and word stress naturally. Accept valid Austrian, Swiss and regional German without caricature or treating variation as an error. Explain du/Sie choices in context; do not assign pronunciation scores from a transcript.",
        writingGuidance: "Use standard German spelling, noun capitalization, umlauts and ß. Accept Swiss ss as a valid regional convention. Show natural complete phrases and their grammatical context.",
        lemmaGuidance: "Use singular nouns with their dictionary gender article (der, die, das) and verbs in the infinitive. Rejoin separable verbs: steht auf → aufstehen; keep reflexive verbs distinct. Keep compounds as whole dictionary lemmas; explain meaningful components separately without crediting unheard words. Preserve umlauts and ß: never collapse schon/schön or wurde/würde. Accept ae/oe/ue keyboard spellings contextually, restoring an umlaut only when the lexeme is unambiguous. Reuse existing lexical sense IDs; distinguish homographs such as der See/die See.",
        teachingFocus: [
            "A1-oriented entry: greetings, names, present-tense sein/haben, simple verb-second statements, nominative subjects and short polite requests.",
            "A1 consolidation: present tense, W-questions, negation nicht/kein, accusative objects, articles, separable verbs and everyday shopping.",
            "A2 entry: dative recipients, common prepositions, modal verbs, Perfekt with haben/sein and practical travel conversations.",
            "A2 consolidation: two-way prepositions in context, connected past stories, weil/dass clauses with final verbs and comparative choices.",
            "B1-oriented discussion: reasons, relative clauses, Konjunktiv II for polite or hypothetical requests and appropriate du/Sie register.",
            "B2-oriented nuance: nested subordinate clauses, passive voice, concessive connectors and precise argumentation. These are practice targets, not a CEFR certificate."
        ],
        topicPlaceholder: "Essen, Reisen, Musik, Alltag in Deutschland…",
        lookupUnavailableReply: "Entschuldigung, diese Information konnte ich gerade nicht abrufen.",
        themeOverrides: ConversationTheme.culturalOverrides([
            "coffee": ("In der Bäckerei", "Order a Brötchen and coffee in a German bakery; ask about ingredients and whether to eat in or take away."),
            "weekend": ("Dein Wochenende", "Chat about a weekend in a German town: a Flohmarkt, a park or staying home. Follow the learner's actual interests."),
            "walk": ("Ein Spaziergang", "Imagine a walk through a Stadtpark or forest. Discuss paths and clothing without suggesting all Germans share one outdoor habit."),
            "dinner": ("Was kochen wir?", "Plan an evening meal together in Germany, accommodating dietary preferences and regional ingredients."),
            "introductions": ("Hallo, ich bin…", "Meet a new acquaintance in Germany. Practise introductions and negotiate du or Sie naturally."),
            "groceries": ("Auf dem Wochenmarkt", "Shop at a German Wochenmarkt: quantities, weights, prices and returning a Pfand bottle at a supermarket."),
            "travel": ("Mit der Bahn", "Role-play a Deutsche Bahn journey and a possible delay. Ask about platforms and connections; never invent live timetables or guarantees of punctuality."),
            "home": ("Ein neues Zuhause", "Discuss a German apartment listing, shared living, rooms and a viewing. Explain Warmmiete/Kaltmiete as vocabulary, not legal advice."),
            "friends": ("Hast du Zeit?", "Invite a friend to a café, board-game evening or sports activity in a German-speaking community."),
            "work": ("Nach dem Meeting", "Chat with German-speaking colleagues about a meeting, a clarification and how to phrase a polite request."),
            "weather": ("Sonne oder Regen?", "Choose clothing and imagined plans for changeable weather in Germany. Verify any claim about today's weather."),
            "cabin": ("Ein Kurzurlaub", "Plan an imagined short break in the Harz, at a lake or in a city. Discuss accommodation and preferences without invented availability."),
            "music": ("Deine Playlist", "Discuss German-language music or any music the learner enjoys. Explore taste without inventing lyrics or current tour dates."),
            "film": ("Kino oder Sofa?", "Choose between a cinema visit and a series at home; discuss dubbing, subtitles and opinions without spoilers."),
            "books": ("Ein gutes Buch", "Browse an imagined German bookshop. Ask about genres, reading habits and a story the learner remembers."),
            "design": ("Gut gestaltet", "Compare everyday objects, Bauhaus influences or architecture in German-speaking cities without assuming aesthetic preferences."),
            "technology": ("Digitaler Alltag", "Discuss technology in German daily life, tools and practical trade-offs. Delegate current factual claims for verification."),
            "travelstories": ("Unterwegs gewesen", "Tell a travel story about a German-speaking place or elsewhere; invite past-tense details and comparisons."),
            "restaurant": ("Einen Tisch, bitte", "Order in a German restaurant, ask about allergies and practise separate or shared payment politely."),
            "neighbours": ("Nebenan", "Talk with a neighbour in an apartment building about a parcel, a small favour or shared spaces."),
            "traditions": ("Endlich Feierabend", "Discuss Feierabend routines, regional festivities and the learner's own customs without stereotypes."),
            "opinions": ("Wie siehst du das?", "Discuss an everyday dilemma in German: public transport, shared chores or screen time. Invite respectful disagreement."),
            "future": ("Nächstes Jahr", "Discuss plans for study, work or a trip in German. Explore hopes and realistic next steps."),
            "today": ("Was gibt es Neues?", "Ask which current topic the learner wants to discuss in German; obtain sources before making current factual claims.")
        ])
    )
}
