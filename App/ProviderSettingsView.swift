import SwiftUI
import MuralCore

struct ProviderSettingsView: View {
    let coordinator: ConversationCoordinator
    @State private var key = ""
    @State private var hasKey = ProcessInfo.processInfo.arguments.contains("--preview") ? false : GeminiCredentialStore.hasKey
    @State private var message: String?
    @State private var confirming = false
    @State private var expanded = false
    private var store: LearningStore { coordinator.store }
    var body: some View {
        Section {
            DisclosureGroup("Gemini fallback", isExpanded: $expanded) {
                Text("If OpenAI is unavailable, Mural can send audio, selected conversation text and learning context to Google Gemini using your own Gemini API key. The conversation stays on Gemini until it ends. Google’s data terms and your project’s limits apply.")
                    .font(.footnote).foregroundStyle(MuralColor.secondary)
                SecureField(hasKey ? "Replace Gemini key" : "Gemini API key", text: $key)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().privacySensitive().accessibilityIdentifier("gemini-api-key")
                Button(hasKey ? "Save replacement Gemini key" : "Save Gemini key") {
                    do {
                        try GeminiCredentialStore.save(key); key = ""; hasKey = true
                        store.updatePreferences { $0.geminiFallbackEnabled = true; $0.geminiConsentVersion = 1 }
                        coordinator.providerRouter.invalidate(); message = "Saved in this iPhone’s Keychain. Gemini fallback is enabled."
                    } catch { message = error.localizedDescription }
                }.disabled(key.isEmpty || coordinator.isRunning)
                if hasKey {
                    Label("Gemini key saved on this iPhone", systemImage: "checkmark.shield").font(.footnote)
                    Button("Remove Gemini key", role: .destructive) {
                        do {
                            try GeminiCredentialStore.delete(); hasKey = false
                            store.updatePreferences { $0.geminiFallbackEnabled = false; $0.geminiConsentVersion = nil }
                            coordinator.providerRouter.invalidate(); message = "Gemini key removed."
                        } catch { message = error.localizedDescription }
                    }.disabled(coordinator.isRunning)
                }
                Toggle("Use Gemini when OpenAI is unavailable", isOn: Binding(get: {
                    store.preferences.geminiFallbackEnabled == true && store.preferences.geminiConsentVersion == 1
                }, set: { value in
                    if value { confirming = true }
                    else { store.updatePreferences { $0.geminiFallbackEnabled = false }; coordinator.providerRouter.invalidate() }
                })).disabled(!hasKey || coordinator.isRunning).accessibilityIdentifier("gemini-fallback-toggle")
                Link("Get a Gemini API key", destination: URL(string: "https://aistudio.google.com/apikey")!)
                Link("Google Gemini data terms", destination: URL(string: "https://ai.google.dev/gemini-api/terms")!)
                if let message { Text(message).font(.footnote).foregroundStyle(MuralColor.secondary) }
            }.accessibilityIdentifier("gemini-settings")
        } header: { Text("Backup provider") }
        Section {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                availability("OpenAI voice", state: coordinator.providerRouter.voice, now: context.date)
                availability("OpenAI text", state: coordinator.providerRouter.text, now: context.date)
            }
            if coordinator.isRunning { LabeledContent("Current voice provider", value: coordinator.voiceProvider == .gemini ? "Gemini" : "OpenAI") }
            Link("OpenAI usage and limits", destination: URL(string: "https://platform.openai.com/usage")!)
            Link("Gemini usage and limits", destination: URL(string: "https://aistudio.google.com/usage")!)
        } header: { Text("Provider availability") } footer: {
            Text("Remaining requests and tokens are the last values reported by OpenAI, not your account balance. A retry time permits another attempt; only a successful request confirms recovery. Voice is checked when starting a conversation. Gemini quotas are shared by project; check AI Studio for remaining quota.")
        }
        .confirmationDialog("Enable Gemini fallback?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Agree and enable Gemini") {
                store.updatePreferences { $0.geminiConsentVersion = 1; $0.geminiFallbackEnabled = true }
                coordinator.providerRouter.invalidate()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("When fallback is used, Google receives your audio and selected text. Your key is sent only to Google and is excluded from learning backups. API usage may cost money. You can disable fallback in Settings after ending a conversation.")
        }
    }
    @ViewBuilder private func availability(_ title: String, state: ProviderAvailability, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.subheadline.weight(.medium))
            if state.usingFallback {
                switch state.status {
                case .quotaExhausted:
                    Text("Prepaid credits depleted or project limit reached on OpenAI").font(.footnote).foregroundStyle(.red)
                    Text("Check billing and credits at platform.openai.com.").font(.caption)
                case .billingBlocked:
                    Text("OpenAI payment or billing blocked").font(.footnote).foregroundStyle(.red)
                    Text("Check your payment method at platform.openai.com.").font(.caption)
                default:
                    Text("Unavailable at the last attempt").font(.footnote)
                    if let retry = state.retryAt, retry > now {
                        HStack { Text("Retry eligible in"); Text(retry, style: .timer).monospacedDigit() }.font(.caption)
                    } else { Text("Ready to check again on the next request").font(.caption) }
                }
            } else if let code = state.observation?.httpStatus { Text("Last response: HTTP \(code)").font(.footnote) }
            else { Text("Not checked yet").font(.footnote) }
            if let observation = state.observation {
                if let remaining = observation.remainingRequests { Text("Reported requests remaining: \(remaining)").font(.caption) }
                if let remaining = observation.remainingTokens { Text("Reported tokens remaining: \(remaining)").font(.caption) }
                Text("Observed \(observation.observedAt.formatted(date: .abbreviated, time: .shortened))").font(.caption2)
            }
        }.foregroundStyle(MuralColor.secondary).padding(.vertical, 3)
    }
}
