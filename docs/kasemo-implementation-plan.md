# Kasemo language and conversation expansion

## Scope and design

Preserve the native SwiftUI app, local SwiftData archive, stable language IDs, cream/orange orb identity and existing OpenAI transport. Implement the full requested scope in this checkout:

- German and Japanese compiled `LanguageModule` values using the existing API (the brief's class/property names are conceptual, not the repository's actual types). Six teaching stages each; all 24 theme IDs receive cultural situations. German progresses from A1 to B2 topics; Japanese from N5-oriented foundations to N3-oriented everyday nuance, without certification claims.
- Japanese supports natural kanji/kana writing, hiragana reading and Hepburn rōmaji in an optional reading aid and word lookup. Keep natural spelling (おはよう, not forced obscure kanji); explain katakana where appropriate. Handle unspaced word selection. Display aids never contaminate spoken audio or count as unaided recall.
- Warm, playful banter, natural tangents, support-language explanations, optional polite-request/immersion games, preferred learner/bot names and evidence-grounded vocabulary callbacks. Respect opt-outs; never invent earlier mistakes. Update the old strict-language redirection rule consistently.
- Derive per-language daily streaks from validated completed user evidence in the persisted archive, avoiding a second mutable counter that drifts after corrections/deletion/import. Local calendar days, duplicate-day deduplication, yesterday continuity, gap reset, longest history, midnight refresh.
- Fix issues 8 (visible shared length limits and rejection with draft preservation), 7 (stable vocabulary identity with legacy evidence consolidation), 6 (safe fragment boundaries), 5 (fixed controls with independently scrolling content), and 3 (distinct learner speech and evidence-based word feedback; uncertain words remain neutral).
- Optional Gemini API key, explicit provider consent and fallback toggle; native WebSocket/PCM live transport plus text/structured-output adapter. Stay on Gemini after an eligible OpenAI availability/rate-limit failure. Do not replay uncertain user speech. Confirm OpenAI recovery with a real request before restoring it, and switch voice only between sessions. Surface observed rate-limit headers/retry times with freshness, never fabricate a remaining balance or a guaranteed reset.

## Research before implementation (13 September 2026)

- Japan Foundation Irodori Starter includes kana, scripts, daily-life lessons and native audio: https://www.irodori.jpf.go.jp/en/starter/pdf.html . Kana charts: https://www.irodori.jpf.go.jp/assets/data/Kana_all.pdf . Use long vowels, small っ and particles は/へ/を correctly; rōmaji is a reading scaffold, not English translation or a complete pronunciation model.
- JLPT official level summaries: https://www.jlpt.jp/e/about/levelsummary.html . JLPT does not test conversation/composition: https://www.jlpt.jp/e/faq/ . Six app stages are a pedagogic progression, not six JLPT levels.
- Google Live capabilities: https://ai.google.dev/gemini-api/docs/live-api/capabilities . Verified raw PCM16 little-endian audio, 16 kHz input / 24 kHz output, input/output transcriptions, current documented `gemini-3.1-flash-live-preview`. WebSocket contract: https://ai.google.dev/api/live . Recheck model availability during integration.
- Gemini quota: https://ai.google.dev/gemini-api/docs/rate-limits . Project quotas vary; daily limits reset at midnight Pacific. This does not imply all 429s clear then or free usage is guaranteed.
- OpenAI headers: https://developers.openai.com/api/docs/guides/rate-limits . Existing source uses `live/sessions` / `gpt-live-1`, not the older realtime endpoint in the pasted architectural example. Preserve the working transport contract.
- Read all five linked upstream issue bodies through GitHub CLI; only the native Swift client exists in this repository. No Android/PWA port is part of this implementation.

## Build guidance and constraints

Searched repository and user `.agent` / `.agents`; no repository AGENTS.md or standalone macOS build rules were present. Native instructions found in `.agents/skills/anti-ui-slop/reference/ios.md`: use real Simulator screenshots, safe areas, Dynamic Type, 44 pt controls, and system materials. Repository build authority: `docs/build-and-test.md`, `scripts/generate_project.py`, Xcode project and pinned WebRTC package.

This host is Windows and has no Swift/Xcode command. Use macOS CI for `swift test`, iOS Simulator build/tests, unsigned generic arm64 device build, and Simulator captures. Device audio and fluent-speaker review require real hardware/humans; do not claim them from unit tests or builds.

## Execution and completion evidence

1. Add regression tests for languages, script aids, streak day arithmetic, identity migration, fragment boundaries, feedback and input limits. Run failing tests where a Swift runtime is available.
2. Implement Core changes, preserving version 1/2 archive compatibility and language isolation. Run core suite.
3. Integrate native reading/feedback/streak UI, stable controls, names/style settings and draft-preserving limits. Add native tests for new flows and large text.
4. Implement and test provider failure/cooldown policy, adapters, Keychain isolation, consent, runtime recovery and status. No keys in exports/logs.
5. Regenerate project using `python scripts/generate_project.py` from this repository root. Run macOS `swift test`, Simulator UI tests, arm64 Simulator and device builds. Verify screenshots from actual Simulator.
6. Request independent code review, fix substantive findings, rerun affected checks. Document exact results and pending hardware checks in verification. Keep the goal open until all required evidence is available.

## UI contract

Talk remains an uncluttered conversation screen: topic/streak, orb, readable conversation, persistent bottom controls. Caption, kana/rōmaji, meaning and learner feedback scroll together above the controls. Use the existing system rounded typography and SoftGlass; no dashboard or new design system. Small screens and accessibility sizes can scroll the orb/content but always retain mute/end/help. Speaker labels and feedback text accompany colors. Draft validation appears beside its field. Gemini controls live in Advanced settings, and provider changes have plain status text.
