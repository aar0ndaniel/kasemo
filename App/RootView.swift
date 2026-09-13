import SwiftUI
import MuralCore
import NaturalLanguage

struct RootView: View {
    @State private var coordinator: ConversationCoordinator
    @State private var tab = 0
    @State private var onboarding = false
    @Environment(\.scenePhase) private var scenePhase
    init(store: LearningStore) {
        let coordinator = ConversationCoordinator(store: store)
        #if DEBUG && targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--preview"), ProcessInfo.processInfo.arguments.contains("--preview-existing-user") {
            store.updatePreferences { $0.hasOnboarded = true }
        }
        if let screen = ScreenshotPreview.screen { coordinator.prepareScreenshot(screen) }
        _tab = State(initialValue: ScreenshotPreview.tab)
        #endif
        _coordinator = State(initialValue: coordinator)
    }
    var body: some View {
        @Bindable var coordinator = coordinator
        TabView(selection: $tab) {
            Tab("Talk", systemImage: "waveform", value: 0) { shell { TalkView(coordinator: coordinator) } }
            Tab("Themes", systemImage: "square.grid.2x2", value: 1) {
                shell { ThemesView(coordinator: coordinator) { theme in coordinator.chooseTheme(theme); tab = 0 } }
            }
            Tab("Words", systemImage: "book", value: 2) { shell { WordsView(coordinator: coordinator) } }
        }
        .tint(MuralColor.ink)
        .sheet(isPresented: $coordinator.showSettings) { SettingsView(coordinator: coordinator) }
        .sheet(isPresented: $coordinator.showAIConsent, onDismiss: { coordinator.resumeAfterAIConsent() }) {
            AIConsentView(agree: { coordinator.acceptAIConsent() }, decline: { coordinator.declineAIConsent() })
        }
        .fullScreenCover(isPresented: $onboarding) { OnboardingView(coordinator: coordinator) { coordinator.store.updatePreferences { $0.hasOnboarded = true }; onboarding = false } }
        .alert("A little interruption", isPresented: Binding(get: { coordinator.error != nil || coordinator.store.error != nil }, set: { if !$0 { coordinator.error = nil; coordinator.store.error = nil } })) {
            Button("OK", role: .cancel) { coordinator.error = nil; coordinator.store.error = nil }
        } message: { Text(coordinator.error ?? coordinator.store.error ?? "") }
        .onAppear {
            let arguments = ProcessInfo.processInfo.arguments
            #if DEBUG && targetEnvironment(simulator)
            if arguments.contains("--preview") && arguments.contains("--preview-onboarding") {
                onboarding = !coordinator.store.preferences.hasOnboarded
                return
            }
            #endif
            onboarding = !coordinator.store.preferences.hasOnboarded && !arguments.contains("--preview") && !AudioVerification.requested
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { coordinator.background() }
            else if phase == .active { coordinator.resume() }
        }
        #if DEBUG
        .task {
            if AudioVerification.requested { await AudioVerification.run(coordinator) }
            else if ProcessInfo.processInfo.arguments.contains("--ended-conversation") { coordinator.prepareEndedPreview() }
        }
        #endif
    }
    private func shell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content().background(MuralColor.cream).toolbar {
                ToolbarItem(placement: .topBarLeading) { Brand().fixedSize() }.sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .topBarTrailing) {
                    Button { coordinator.showSettings = true } label: { Image(systemName: "slider.horizontal.3") }
                        .accessibilityLabel("Settings")
                }
            }.toolbarBackground(MuralColor.cream, for: .navigationBar)
        }
    }
}

struct TalkView: View {
    @Bindable var coordinator: ConversationCoordinator
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var typing = false
    @State private var transcript: SessionRecord?
    @State private var lookup: WordLookup?
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Text(coordinator.selectedTheme?.title ?? coordinator.language.talkTitle)
                        .font(.system(.caption, design: .rounded, weight: .medium)).foregroundStyle(MuralColor.secondary)
                        .padding(.horizontal, 14).padding(.vertical, 9).background(MuralColor.butter.opacity(0.58), in: Capsule()).padding(.top, 12)
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        let streak = DailyStreak.project(coordinator.store.sessions, languageID: coordinator.language.id, now: context.date)
                        if streak.currentStreak > 0 {
                            Label("\(streak.currentStreak) \(streak.currentStreak == 1 ? "day" : "days")", systemImage: "flame.fill")
                                .font(.caption).foregroundStyle(MuralColor.ink).padding(.horizontal, 12).padding(.vertical, 6)
                                .modifier(SoftGlass(tint: MuralColor.butter.opacity(0.5))).padding(.top, 8)
                                .accessibilityLabel("\(coordinator.language.name) streak: \(streak.currentStreak) days. Longest: \(streak.longestStreak) days.")
                                .accessibilityIdentifier("daily-streak")
                        }
                    }
                    MuralOrb(energy: max(coordinator.outputLevel, coordinator.inputLevel * 0.45), listening: coordinator.state == .active && !coordinator.isMuted, active: coordinator.state != .closing)
                        .frame(width: typeSize.isAccessibilitySize ? 170 : 220, height: typeSize.isAccessibilitySize ? 180 : 222).padding(.vertical, 8)
                    Text(coordinator.status).font(.system(.caption, design: .rounded)).foregroundStyle(MuralColor.secondary)
                        .contentTransition(.numericText()).padding(.top, 6).padding(.bottom, 16).accessibilityAddTraits(.updatesFrequently)
                        .accessibilityIdentifier("conversation-status")
                    captionArea
                    if let notice = coordinator.notice {
                        Text(notice).font(.footnote).foregroundStyle(MuralColor.secondary).multilineTextAlignment(.center).padding(.vertical, 12)
                    }
                }.padding(.horizontal, 26).padding(.bottom, 16).frame(maxWidth: .infinity)
            }.scrollIndicators(.hidden).frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 0) {
                    controls
                    Text(coordinator.microphoneLabel).font(.caption2).foregroundStyle(MuralColor.secondary).padding(.top, 10)
                        .accessibilityIdentifier("microphone-status")
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 20) { secondaryControls }
                        VStack(spacing: 0) { secondaryControls }
                    }.font(.caption).padding(.top, 4).padding(.bottom, 6)
            }.padding(.horizontal, 20).padding(.top, 10).frame(maxWidth: .infinity).background(MuralColor.cream)
        }
        .sheet(isPresented: $typing) { TypedReplyView(coordinator: coordinator) }
        .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: coordinator.state)
        .task(id: coordinator.readingRequestID) { await coordinator.updateReadingAid() }
        .sheet(item: $transcript) { session in
            TranscriptView(session: session, meaningLanguage: coordinator.store.preferences.meaningLanguage)
        }
        .sheet(item: $lookup) { item in LookupView(item: item, coordinator: coordinator) }
    }
    @ViewBuilder private var secondaryControls: some View {
                        if coordinator.state == .active {
                            Button("Type instead", systemImage: "keyboard") { typing = true }.frame(minHeight: 44)
                            Button("A little help", systemImage: "sparkles") { coordinator.help() }.frame(minHeight: 44)
                        } else if coordinator.session == nil {
                            Text("Reply in whichever language comes to you.").foregroundStyle(MuralColor.secondary)
                        } else if !coordinator.isRunning {
                            Button("New conversation", systemImage: "arrow.counterclockwise") { coordinator.resetConversation() }
                                .accessibilityIdentifier("new-conversation")
                        }
    }
    private var captionArea: some View {
        VStack(spacing: 12) {
            Text(linkedCaption).font(.system(coordinator.assistantPassage == nil ? .largeTitle : .title2, design: .rounded, weight: .medium))
                .tracking(-0.5).multilineTextAlignment(.center).tint(MuralColor.ink)
                .environment(\.openURL, OpenURLAction { url in
                    guard url.scheme == "mural-word", let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let word = components.queryItems?.first?.value else { return .discarded }
                    lookup = WordLookup(word: word, sentence: coordinator.caption); return .handled
                }).accessibilityIdentifier("target-caption")
            if coordinator.readingEnabled {
                if let reading = coordinator.reading {
                    VStack(spacing: 5) {
                        Text(reading.reading).font(.body).accessibilityIdentifier("japanese-kana")
                        Text(reading.romaji).font(.subheadline).accessibilityIdentifier("japanese-romaji")
                    }.foregroundStyle(MuralColor.secondary).multilineTextAlignment(.center).textSelection(.enabled)
                } else if let error = coordinator.readingError {
                    Text(error).font(.caption).foregroundStyle(MuralColor.secondary)
                } else {
                    Text("Finding the reading…").font(.caption).foregroundStyle(MuralColor.secondary)
                }
            }
            if coordinator.store.preferences.meaningVisible {
                Text(coordinator.assistantPassage == nil ? MeaningLanguages.greeting(in: coordinator.store.preferences.meaningLanguage) : !coordinator.meaning.isEmpty ? coordinator.meaning : coordinator.translating ? "Finding the meaning…" : "")
                    .font(.subheadline).foregroundStyle(MuralColor.secondary).multilineTextAlignment(.center)
                    .accessibilityIdentifier("meaning-caption")
                if let error = coordinator.meaningError {
                    VStack(spacing: 6) {
                        Text(error).foregroundStyle(MuralColor.secondary)
                        Button("Try meaning again") { coordinator.retryMeaning() }
                    }.font(.caption).multilineTextAlignment(.center)
                }
            }
            if let user = coordinator.userPassage {
                LearnerPassageView(passage: user, assessment: coordinator.session?.assessments.first { $0.passageID == user.id })
                    .padding(.top, 6)
            }
            if coordinator.working { ProgressView("Checking that for you…").font(.caption).tint(MuralColor.secondary) }
            if let sources = coordinator.session?.topics.last?.sources, !sources.isEmpty {
                Button("Sources", systemImage: "link") { transcript = coordinator.session }.font(.caption)
            }
        }.frame(minHeight: typeSize.isAccessibilitySize ? 100 : 105).frame(maxWidth: .infinity)
    }
    private var linkedCaption: AttributedString {
        let text = coordinator.caption
        var result = AttributedString(text)
        let tokenizer = NLTokenizer(unit: .word); tokenizer.string = text
        tokenizer.setLanguage(NLLanguage(rawValue: coordinator.language.id))
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let word = String(text[range])
            var components = URLComponents(); components.scheme = "mural-word"; components.host = "lookup"
            components.queryItems = [URLQueryItem(name: "word", value: word)]
            if let attributedRange = Range(range, in: result), coordinator.assistantPassage != nil { result[attributedRange].link = components.url }
            return true
        }
        result.foregroundColor = MuralColor.ink
        return result
    }
    private var controls: some View {
        HStack(alignment: .center, spacing: 27) {
            Button { coordinator.toggleMeaning() } label: {
                VStack(spacing: 6) {
                    Image(systemName: coordinator.store.preferences.meaningVisible ? "captions.bubble.fill" : "captions.bubble")
                        .frame(width: 48, height: 48).modifier(SoftGlass(tint: coordinator.store.preferences.meaningVisible ? MuralColor.butter.opacity(0.7) : .white.opacity(0.4)))
                    Text("Meaning").font(.caption2)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
                .accessibilityLabel(coordinator.store.preferences.meaningVisible ? "Hide meaning subtitles" : "Show meaning subtitles")
                .accessibilityValue(coordinator.store.preferences.meaningVisible ? "On" : "Off")
            Button {
                if coordinator.state == .active { coordinator.toggleMute() }
                else if !coordinator.isRunning { coordinator.start() }
            } label: {
                ZStack {
                    Circle().fill(LinearGradient(colors: [Color(red: 1, green: 0.73, blue: 0.48), MuralColor.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    if coordinator.state == .connecting || coordinator.state == .closing { ProgressView().tint(MuralColor.ink) }
                    else { Image(systemName: coordinator.isMuted && coordinator.state == .active ? "mic.slash" : "mic").font(.system(size: 28, weight: .regular)).contentTransition(.symbolEffect(.replace)) }
                }.frame(width: 76, height: 76).shadow(color: MuralColor.orange.opacity(0.25), radius: 10, y: 6)
            }.buttonStyle(.plain).padding(.bottom, 18)
                .disabled(coordinator.state == .connecting || coordinator.state == .closing)
                .accessibilityLabel(coordinator.state == .active ? (coordinator.isMuted ? "Unmute microphone" : "Mute microphone") : "Start conversation")
                .accessibilityIdentifier("start-conversation")
            Button { if coordinator.isRunning { coordinator.end() } else { transcript = coordinator.session } } label: {
                VStack(spacing: 6) {
                    Image(systemName: coordinator.isRunning ? "phone.down" : "text.bubble").frame(width: 48, height: 48).modifier(SoftGlass())
                    Text(coordinator.isRunning ? "End" : "Transcript").font(.caption2)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityLabel(coordinator.isRunning ? "End conversation" : "Conversation transcript")
                .disabled(coordinator.session == nil)
        }.foregroundStyle(MuralColor.ink)
    }
}

struct WordLookup: Identifiable { var id = UUID(); var word: String; var sentence: String }
struct LookupView: View {
    let item: WordLookup
    let coordinator: ConversationCoordinator
    @State private var explanation: String?
    @State private var reading: JapaneseReading?
    @State private var error: String?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(item.word).font(.system(.largeTitle, design: .rounded, weight: .medium))
                    Text(item.sentence).font(.title3).foregroundStyle(MuralColor.secondary)
                    if let reading {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Scripts & Pronunciation").font(.subheadline.weight(.semibold)).foregroundStyle(MuralColor.ink)
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 8) { badges(for: reading) }
                                VStack(alignment: .leading, spacing: 6) { badges(for: reading) }
                            }
                            if let guide = reading.spellingGuide {
                                Text(guide).font(.footnote).foregroundStyle(MuralColor.secondary)
                            }
                            if let notes = reading.pronunciationNotes {
                                Text(notes).font(.caption).foregroundStyle(MuralColor.secondary)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(MuralColor.peach, in: RoundedRectangle(cornerRadius: 18))
                    }
                    if let explanation { Text(explanation).font(.body).textSelection(.enabled) }
                    else if let error { Text(error).foregroundStyle(MuralColor.secondary) }
                    else { ProgressView("Finding the meaning…") }
                    Spacer()
                }.padding(28).frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(MuralColor.cream)
            .navigationTitle("A little meaning").navigationBarTitleDisplayMode(.inline)
        }.presentationDetents([.medium, .large])
            .task {
                if coordinator.language.id == "ja" {
                    Task { reading = await coordinator.lookupReading(word: item.word) }
                }
                do { explanation = try await coordinator.lookup(word: item.word, sentence: item.sentence) }
                catch { self.error = error.localizedDescription }
            }
    }
    @ViewBuilder private func badges(for reading: JapaneseReading) -> some View {
        scriptBadge(label: "Kana", value: reading.kanaReading)
        if let kanji = reading.kanjiForm, !kanji.isEmpty {
            scriptBadge(label: "Kanji variant", value: kanji)
        }
        if let katakana = reading.katakanaTranscription, !katakana.isEmpty {
            scriptBadge(label: "Katakana", value: katakana)
        }
        scriptBadge(label: "Hepburn", value: reading.romaji)
        if let ascii = reading.asciiRomaji, !ascii.isEmpty {
            scriptBadge(label: "Input", value: ascii)
        }
    }
    @ViewBuilder private func scriptBadge(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(MuralColor.secondary)
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(MuralColor.ink)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct TypedReplyView: View {
    let coordinator: ConversationCoordinator
    @State private var text = ""
    @State private var sending = false
    @State private var sendError: String?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Say it your way.").font(.system(.title, design: .rounded, weight: .semibold))
                TextField("Reply in \(coordinator.language.name) or another language", text: $text, axis: .vertical).lineLimit(3...6).focused($focused).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 22))
                    .accessibilityIdentifier("typed-reply-field")
                InputCountView(text: text, limit: InputLimits.typedReply)
                if let sendError { Text(sendError).font(.footnote).foregroundStyle(.red) }
                Button { sending = true; Task {
                    let accepted = await coordinator.sendTyped(text); sending = false
                    if accepted { dismiss() } else { sendError = coordinator.error }
                } } label: {
                    HStack { Text(sending ? "Sending…" : "Send reply"); Spacer(); Image(systemName: "arrow.up") }.padding(18).background(MuralColor.orange, in: Capsule())
                }.disabled(sending || InputLimits.problem(text, limit: InputLimits.typedReply) != nil).accessibilityIdentifier("send-typed-reply")
                Spacer()
            }.padding(26).foregroundStyle(MuralColor.ink).background(MuralColor.cream)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }.presentationDetents([.medium, .large]).onAppear { focused = true }
    }
}
