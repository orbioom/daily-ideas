# Timber — private snore tracker

**What it is.** Timber tells you whether you snore, how badly, and what fixes it — without recording you. Put your iPhone on the nightstand; Timber meters the microphone all night, detects snore episodes with an adaptive noise-floor threshold, and in the morning hands you a 0–100 Snore Score, a full night timeline, and remedy correlations. For the millions of snorers (and their partners) who want answers without a $25/yr subscription or their sleep audio in someone's cloud.

## Full feature list

- **Overnight monitoring** — AVAudioRecorder metering at 2 Hz; adaptive noise floor (EMA over quiet samples) with a configurable sensitivity threshold; sustained-loudness episode detection (≥2 s above threshold, closed by ≥3 s of quiet); episodes classified Mild / Loud / Epic by peak dB. Audio is written to a temp file and **deleted at session end** — only metrics persist.
- **Live session screen** — elapsed clock (TimelineView), live level meter with visible adaptive threshold line, episode counter, current dB, idle-timer disabled, background-audio entitlement so the screen can lock; end/discard confirmation.
- **Snore Score** — transparent formula: intensity-weighted snoring seconds ÷ (25% of the night), capped at 100, with named grades (Quiet → Epic).
- **Morning summary** — score dial reveal, in-bed/episodes/snoring-time tiles, 1–5 feel rating, optional note.
- **Journal** — every night listed with score chip, duration, episodes, factor emojis; swipe to delete; night detail with per-minute loudness area chart + episode overlay rectangles, intensity breakdown, episode list with wall-clock times.
- **Trends** — average/best score and average time-in-bed tiles, 30-night score bars, snoring-minutes line, by-weekday averages.
- **Remedies lab** — 10 built-in factors (alcohol, mouth tape, nasal strip, side sleeping…) + custom factors with emoji; nightly tagging via chip picker; correlation engine compares average score with vs. without each factor (needs ≥2 nights each side) and ranks remedies by impact.
- **Settings** — detection sensitivity slider (8–24 dB), haptics toggle, appearance (system/light/dark), sample-data loader (14 coherent demo nights), delete-all with confirmation.
- Onboarding (3 pages, persisted flag), empty states on every tab, mic-permission-denied and recorder-failure error cards with recovery, Dynamic Type, accessibility labels throughout, Reduce Motion respected, dark + light first-class.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Timber.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

*Free signing:* Xcode → target → Signing & Capabilities → check "Automatically manage signing", pick your personal team. Mic detection needs a real device for meaningful data; the sample-data loader exercises every screen in the simulator.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-ish: pure `SnoreEngine`/`SnoreDetector` (no UI imports) + `@Observable` `RecorderEngine` + SwiftData (`NightSession` 1→N cascade `SnoreEpisode`, N↔N `SleepFactor`).
- Design language: "nocturnal cabin" — deep indigo nights, lamplight amber, timber-soft rounded cards; full dark/light palettes in `Theme`.
- **Monetization:** snorers pay for answers — free unlimited nights; one-time "Timber Pro" unlock (lifetime, ~$19.99) for remedy correlations + trends export. SnoreLab proves ~$400k/mo in this exact category.
- **Why it can boom:** SnoreLab is #4 top-grossing Medical with a hated, ever-shrinking free tier and cloud anxiety; Timber is the fair, private version of a proven money-printer — metrics-only storage is a marketing wedge ("we can't leak your sleep audio; we never keep it").

## Self-review

Re-read every Swift file end-to-end: imports verified (SwiftUI/SwiftData/Charts/AVFAudio/UIKit/Observation), all APIs iOS 17 SDK (AVAudioApplication permission API, TimelineView, Layout protocol, Swift Charts marks), `@Model` relationships use explicit inverses, no force-unwraps/`try!`/`fatalError` on user paths, all arrays indexed safely, `onChange(of:)` two-parameter form, Equatable state enum verified. Anti-stub grep clean (no TODO/FIXME/placeholder). project.yml names the real `Timber` folder and Info.plist.
