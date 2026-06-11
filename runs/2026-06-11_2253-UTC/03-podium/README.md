# Podium — on-device speech coach

**What it is.** Podium is a public-speaking coach that listens while you practice and tells you what audiences actually notice: filler words, pace, and word variety — live, on-device, private. For interview preppers, wedding-toast writers, founders pitching, and anyone who hates hearing themselves say "um". Speeko ($29.99/mo) and Orai proved people pay for exactly this; Podium does it natively with Apple's on-device speech recognition and no subscription.

## Full feature list

- **Live practice takes** — AVAudioEngine mic tap → SFSpeechRecognizer continuous transcription (on-device recognition requested whenever supported); live readouts while you talk: words-per-minute (color-coded vs. your target band), filler count, word count, scrolling live transcript; elapsed clock; idle-timer off; cancel-safe.
- **Prompt library** — 21 prompts across 4 categories (Interview, Impromptu, Presentation, Toasts & intros) plus Free Talk; horizontal card shelves.
- **Post-take analysis** — 0–100 delivery score from a documented formula (filler rate −4/fpm capped, pace miss −0.5/wpm capped, vocabulary diversity, substance floor); grade labels; length/wpm/fillers/variety tiles; filler breakdown ("um" ×4, "you know" ×2…); full transcript with **every filler highlighted** (two-word fillers like "you know"/"I mean" matched before singles); save or discard.
- **Sessions** — saved takes with score badge, pace, filler stats; swipe-to-delete; detail view with highlighted transcript (selectable), filler table, pace label vs. your band.
- **Progress** — takes/stage-time/avg/best tiles; score line chart; fillers-per-minute bars with 2/min target rule; pace line chart with shaded target band (last 20 takes).
- **Coach** — 6 technique drills (pause swap, slow-is-smooth, one-idea-per-sentence, cold open, vocabulary stretch, land-the-ending), each with instructions and a matched prompt that launches straight into a take.
- **Settings** — target pace band sliders (live + analysis use it), haptics toggle, appearance picker, 10 sample sessions showing a 2-week improvement arc, delete-all with confirmation, privacy statement.
- Onboarding (3 pages, persisted), empty states, mic/speech permission-denied screens with Open Settings, recognition-failure error state, Dynamic Type, accessibility labels, Reduce Motion respected, dark + light.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Podium.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

*Free signing:* Xcode → Signing & Capabilities → personal team. Live transcription works best on a real device; the simulator supports it with the host Mac's mic. Sample sessions exercise all analytics screens.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM: pure `SpeechAnalyzer` (tokenizer, two-pass filler counter, scoring, `fillerRanges` for AttributedString highlighting — zero UI imports), `@Observable SpeechEngine` (AVAudioEngine + SFSpeechAudioBufferRecognitionRequest), SwiftData `SpeechSession` with `[String: Int]` filler breakdown.
- Design language: dark stage + violet spotlight — charcoal, stage-violet, warm gold for fillers, rounded display type.
- **Monetization:** subscription is proven here (Speeko $29.99/mo, Orai $39.99/yr) — Podium Pro at $4.99/mo or $29.99 lifetime for drills + progress history beyond 7 days; free tier keeps unlimited takes.
- **Why it can boom:** incumbents are pricey, buggy (Orai's own reviews), and cloud-based; Apple's on-device speech recognition makes a faster, private, cheaper coach possible — and "watch your ums get counted live" demos perfectly on TikTok.

## Self-review

Re-read every Swift file: imports (SwiftUI/SwiftData/Charts/Speech/AVFAudio/Observation/UIKit) verified; SFSpeechRecognizer/SFSpeechAudioBufferRecognitionRequest/recognitionTask APIs checked against iOS 17 SDK; AVAudioApplication permission API (iOS 17); audio tap installed with input format and removed in all teardown paths; recognition callbacks hop to main via DispatchQueue; AttributedString.Index conversion guarded with optionals; Chart x-axis types kept homogeneous per chart; no force-unwraps/`try!` on user paths. Anti-stub grep clean. project.yml + Info.plist include NSMicrophoneUsageDescription and NSSpeechRecognitionUsageDescription.
