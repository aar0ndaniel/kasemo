# Gemini and mascot interaction validation

Scope: the September 13 request to repair Gemini text/live audio, move learning aids above the spoken caption, use the mascot for push-to-talk, and shorten provider notices.

## Model and connection decisions

The text default is `gemini-2.5-flash`. HTTP 503 retries that model once after one second, then tries `gemini-3.5-flash` after two seconds. Other status codes are not retried. Cancellation stops the delay/request. This caps each request at three attempts.

The live model remains `gemini-3.1-flash-live-preview`. The requested `gemini-1.5-flash` fallback and `gemini-2.0-flash-exp` live model were superseded; replacing working protocol support with retired models would not repair the reported outage. Google's current [deprecation table](https://ai.google.dev/gemini-api/docs/deprecations) lists supported replacements, and its [WebSocket guide](https://ai.google.dev/gemini-api/docs/live-api/get-started-websocket) uses the 3.1 live model and API-key query authentication. A 503 indicates unavailability, not proof that a model identifier is fictitious.

`GeminiWire.liveURL` builds the query with URLComponents. URLs containing the credential are never printed or included in learning exports. Server error payloads now reach the connection error UI, with the saved key redacted and message length bounded. Saving a Gemini key enables fallback and records the requested consent preference.

## Interaction invariants

- Ordinary conversation starts, including topic entry, create a muted transport. Only explicit debug audio verification starts unmuted.
- Holding the mascot requests microphone on. Releasing without a lock requests mute, including while the connection is still being established.
- Dragging at least 72 points right locks the microphone on; the padlock button mutes and unlocks it. Gesture cancellation releases an unlocked hold. Leaving Talk releases the microphone.
- `session.started` reapplies the coordinator's latest desired mute state. OpenAI initially disables its audio track; Gemini processes microphone delivery on the main actor after the start callback.
- Reading aids, meaning, and the previous learner transcript precede the interactive target caption. The mascot and display-mode toggle follow it.
- The provider toast appears once for Gemini per conversation, or on returning from Gemini to OpenAI. It clears after four seconds, a transcript event, or an accepted typed reply.

## Evidence and remaining checks

- `ProviderAvailabilityTests` checks encoded WebSocket query authentication, supported model identifiers, the bounded 503 policy, and no authentication/quota retries.
- `MuralUITests.testMascotHoldReleaseAndDragLock` checks native ordering, hold/release mute, drag lock, and padlock mute using an offline conversation fixture. It saves a screenshot. This fixture does not claim to test provider audio or hardware capture.
- Code review identified unmuted topic entry in `504bed0`; `1731774` fixes it. Follow-up review verified the default and both setup/release code paths.
- Native CI run `34772377002` validates commit `1731774`. Its final outcome and screenshots must be inspected before claiming the native validation gate passed.
- CI packages an unsigned arm64 `.ipa`. Installation requires appropriate signing. A package/build test alone does not prove live audio works with a particular user's Gemini key and audio route.
