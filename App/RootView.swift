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
    @AppStorage("talk_companion_mode") private var companionMode = true
    @GestureState private var touchingMascot = false
    @State private var holdingMascot = false
    @State private var microphoneLocked = false
    @State private var showingStreakCelebration = false
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
                            Button {
                                showingStreakCelebration = true
                            } label: {
                                Label {
                                    Text("\(streak.currentStreak) \(streak.currentStreak == 1 ? "day" : "days")")
                                } icon: {
                                    StreakIcon(size: 14)
                                }
                                .font(.caption).foregroundStyle(MuralColor.ink).padding(.horizontal, 12).padding(.vertical, 6)
                                .modifier(SoftGlass(tint: MuralColor.butter.opacity(0.5))).padding(.top, 8)
                            }
                            .accessibilityLabel("\(coordinator.language.name) streak: \(streak.currentStreak) days. Longest: \(streak.longestStreak) days.")
                            .accessibilityIdentifier("daily-streak")
                            .sheet(isPresented: $showingStreakCelebration) {
                                StreakCelebrationSheet(streak: streak, languageName: coordinator.language.name)
                            }
                        }
                    }
                    Text(coordinator.status).font(.system(.caption, design: .rounded)).foregroundStyle(MuralColor.secondary)
                        .contentTransition(.numericText()).padding(.top, 6).padding(.bottom, 16).accessibilityAddTraits(.updatesFrequently)
                        .accessibilityIdentifier("conversation-status")
                    captionArea
                    let energy = max(coordinator.outputLevel, coordinator.inputLevel * 0.45)
                    ZStack {
                        if companionMode {
                            let pose: GhostPose = {
                                if coordinator.state == .connecting {
                                    return .tiltRight
                                } else if coordinator.state == .active {
                                    if coordinator.outputLevel > 0.02 {
                                        return .happy
                                    } else if coordinator.inputLevel > 0.02 {
                                        return .tiltLeft
                                    } else {
                                        return .neutral
                                    }
                                } else if coordinator.state == .closing {
                                    return .sleepy
                                } else {
                                    return coordinator.session == nil ? .wave : .neutral
                                }
                            }()
                            GhostMascotView(pose: pose, size: typeSize.isAccessibilitySize ? 140 : 150, animated: true, energy: energy)
                                .frame(width: typeSize.isAccessibilitySize ? 170 : 220, height: typeSize.isAccessibilitySize ? 180 : 185)
                                .contentShape(Rectangle())
                                .accessibilityIdentifier("ghost-companion")
                        } else {
                            MuralOrb(energy: energy, listening: coordinator.state == .active && !coordinator.isMuted, active: coordinator.state != .closing)
                                .frame(width: typeSize.isAccessibilitySize ? 170 : 220, height: typeSize.isAccessibilitySize ? 180 : 185)
                                .contentShape(Circle())

                        }
                    }
                    .scaleEffect(holdingMascot && !reduceMotion ? 1.05 : 1)
                    .shadow(color: MuralColor.iris.opacity(holdingMascot || microphoneLocked ? 0.35 : 0), radius: 16)
                    .contentShape(Rectangle())
                    .gesture(mascotGesture)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Hold to talk")
                    .accessibilityHint("Hold and slide right to lock the microphone on.")
                    .accessibilityIdentifier("start-conversation")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction {
                        if microphoneLocked { unlockMicrophone() }
                        else { coordinator.beginPushToTalk(); microphoneLocked = coordinator.isRunning }
                    }
                    .overlay(alignment: .trailing) {
                        if holdingMascot || microphoneLocked {
                            Button { unlockMicrophone() } label: {
                                Image(systemName: microphoneLocked ? "lock.fill" : "lock.open")
                                    .frame(width: 48, height: 48).modifier(SoftGlass())
                            }
                            .accessibilityLabel("Unlock and mute microphone")
                            .accessibilityIdentifier("microphone-lock")
                        }
                    }
                    .padding(.vertical, 6)
                    Text(microphoneLocked ? "Microphone locked on · tap the padlock to mute" : "Hold to talk · slide right to lock")
                        .font(.caption).foregroundStyle(MuralColor.secondary)
                        .multilineTextAlignment(.center).padding(.bottom, 8)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            companionMode.toggle()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: companionMode ? "circle.hexagongrid.circle" : "sparkles")
                            Text(companionMode ? "Orb view" : "Companion mode")
                        }
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(MuralColor.secondary)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(MuralColor.peach.opacity(0.4), in: Capsule())
                    }
                    .accessibilityIdentifier("toggle-companion-mode")
                    .padding(.bottom, 2)
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
        .onChange(of: touchingMascot) { _, touching in
            if !touching { finishMascotHold() }
        }
        .onChange(of: coordinator.state) { _, state in
            if state != .active && state != .connecting { microphoneLocked = false; holdingMascot = false }
        }
        .onDisappear { unlockMicrophone() }
        .sheet(isPresented: $typing) { TypedReplyView(coordinator: coordinator) }
        .overlay(alignment: .top) {
            if let toast = coordinator.providerToast {
                Text(toast).font(.subheadline.weight(.medium))
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .modifier(SoftGlass()).padding(.top, 8)
                    .accessibilityIdentifier("provider-toast")
                    .accessibilityAddTraits(.updatesFrequently)
                    .allowsHitTesting(false)
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: coordinator.state)
        .task(id: coordinator.readingRequestID) { await coordinator.updateReadingAid() }
        .sheet(item: $transcript) { session in
            TranscriptView(session: session, meaningLanguage: coordinator.store.preferences.meaningLanguage)
        }
        .sheet(item: $lookup) { item in LookupView(item: item, coordinator: coordinator) }
    }
    private var mascotGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($touchingMascot) { _, active, _ in active = true }
            .onChanged { value in
                guard coordinator.state != .closing else { return }
                if !holdingMascot {
                    holdingMascot = true
                    coordinator.beginPushToTalk()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                if value.translation.width >= 72 && !microphoneLocked && coordinator.isRunning {
                    microphoneLocked = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
            .onEnded { _ in finishMascotHold() }
    }
    private func finishMascotHold() {
        holdingMascot = false
        if !microphoneLocked { coordinator.releasePushToTalk() }
    }
    private func unlockMicrophone() {
        microphoneLocked = false; holdingMascot = false
        coordinator.releasePushToTalk()
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
            if let user = coordinator.userPassage {
                LearnerPassageView(passage: user, assessment: coordinator.session?.assessments.first { $0.passageID == user.id })
                    .padding(.top, 6)
            }
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
            Text(linkedCaption).font(.system(coordinator.assistantPassage == nil ? .largeTitle : .title2, design: .rounded, weight: .medium))
                .tracking(-0.5).multilineTextAlignment(.center).tint(MuralColor.ink)
                .environment(\.openURL, OpenURLAction { url in
                    guard url.scheme == "mural-word", let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let word = components.queryItems?.first?.value else { return .discarded }
                    lookup = WordLookup(word: word, sentence: coordinator.caption); return .handled
                }).accessibilityIdentifier("target-caption")
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
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 14) {
                    GhostMascotView(pose: .writing, size: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Say it your way.").font(.system(.title2, design: .rounded, weight: .semibold))
                        Text("Type in \(coordinator.language.name) or your native tongue.").font(.caption).foregroundStyle(MuralColor.secondary)
                    }
                }
                TextField("Reply in \(coordinator.language.name) or another language", text: $text, axis: .vertical).lineLimit(3...6).focused($focused).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 22))
                    .accessibilityIdentifier("typed-reply-field")
                InputCountView(text: text, limit: InputLimits.typedReply)
                if let sendError { Text(sendError).font(.footnote).foregroundStyle(.red) }
                Button { sending = true; Task {
                    let accepted = await coordinator.sendTyped(text); sending = false
                    if accepted { dismiss() } else { sendError = coordinator.error }
                } } label: {
                    HStack { Text(sending ? "Sending…" : "Send reply"); Spacer(); Image(systemName: "arrow.up") }.padding(18).background(MuralColor.iris, in: Capsule())
                }.disabled(sending || InputLimits.problem(text, limit: InputLimits.typedReply) != nil).accessibilityIdentifier("send-typed-reply")
                Spacer()
            }.padding(26).foregroundStyle(MuralColor.ink).background(MuralColor.cream)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }.presentationDetents([.medium, .large]).onAppear { focused = true }
    }
}

struct StreakCelebrationSheet: View {
    let streak: DailyStreak
    let languageName: String
    @Environment(\.dismiss) private var dismiss
    
    private var nextMilestone: Int {
        let targets = [3, 7, 14, 30, 60, 100, 365]
        return targets.first { $0 > streak.currentStreak } ?? (streak.currentStreak + 10)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                GhostMascotView(
                    pose: streak.currentStreak >= 7 ? .flying : .flame,
                    size: 110,
                    animated: true
                )
                
                VStack(spacing: 8) {
                    Text("\(streak.currentStreak) Day Streak!")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(MuralColor.ink)
                    
                    Text("You're speaking \(languageName) every day. Consistent daily practice forms natural conversational fluency.")
                        .font(.subheadline)
                        .foregroundStyle(MuralColor.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                HStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Text("\(streak.currentStreak)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(MuralColor.iris)
                        Text("Current")
                            .font(.caption2)
                            .foregroundStyle(MuralColor.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
                    
                    VStack(spacing: 6) {
                        Text("\(streak.longestStreak)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(MuralColor.ink)
                        Text("Best")
                            .font(.caption2)
                            .foregroundStyle(MuralColor.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
                    
                    VStack(spacing: 6) {
                        Text("\(nextMilestone) d")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(MuralColor.butter)
                        Text("Next Goal")
                            .font(.caption2)
                            .foregroundStyle(MuralColor.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 8)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Keep it going!")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(MuralColor.iris, in: Capsule())
                }
                .accessibilityIdentifier("dismiss-streak-celebration")
            }
            .padding(26)
            .background(MuralColor.cream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

