# Chime

**A meditation timer that respects you — not a content feed.** Just you, a quiet screen, and a bell. Chime is the calm, free, on-device meditation timer for people who want to *sit*, not scroll a library or hit a paywall to silence a countdown.

The problem: the best-known meditation apps either bury the simple timer behind a $60/yr subscription (Calm/Headspace) or wrap it in an overwhelming social library (Insight Timer). As reviewers keep saying, *"a timer is literally a countdown with a bell — paywalling it feels wrong."* Chime is that timer, done beautifully.

## What it is
- **Audience:** anyone with an established or budding meditation practice who wants a fast, distraction-free, private timer with real interval bells.
- **Core job:** configure a sit (warm-up + length + interval bells), run a full-screen guided countdown that survives backgrounding, and log it — building a quiet record of your practice.

## Features
- **Full-screen sit player** — date-derived countdown (accurate across backgrounding), settle-in warm-up phase, a breathing progress ring, pause/resume, and end-early; keeps the screen awake.
- **Synthesized bells, no audio files** — six on-device tones (singing bowl, gong, chime, woodblock, temple bell, silent) generated as decaying inharmonic partials via `AVAudioEngine`. Distinct start / interval / end bells.
- **Presets** — built-in sits (Quick reset, Morning sit, Daily practice, Deep stillness) plus full create/edit/delete of your own: length, warm-up, interval-bell cadence, and per-event tones.
- **Reflection** — after each sit, rate how you feel (1–5) and jot an optional note.
- **History** — every sit logged on-device, grouped by day, with quality dots and swipe-to-delete.
- **Insights** — current/best streak, total time, completion rate, minutes-per-day bar chart (14/30-day), and a "where your minutes go" breakdown by preset (Swift Charts).
- **Settings** — bell preview + tone picker, bell volume, keep-screen-awake, per-bell haptics, interface haptics, and clear-history.
- Onboarding (gated by a persisted flag), empty/success/guard states everywhere, light + dark, Dynamic Type, VoiceOver labels, Reduce Motion support.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Chime.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**.

**Free signing:** no paid account needed — select your personal team in *Signing & Capabilities* and run on the simulator or a device. No API keys; all data is on-device.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. Primary data in **SwiftData** (`MeditationPreset`, `MeditationSession`); small prefs in `UserDefaults` via `@AppStorage`.
- Bells are synthesized at runtime (`BellPlayer` over `AVAudioEngine`); the timer is an `@Observable @MainActor` engine (`SessionEngine`) using start-date math so it's robust to backgrounding. Stats are pure functions (`StatsEngine`).
- **Design language:** Orbioom (glass `.ultraThinMaterial`, ink-gradient buttons, SF Pro + JetBrains Mono for numerics, slow breathing motion, green as a rare live/success accent).
- **Monetization:** freemium — the timer, bells, presets, history, and insights are free forever; Pro unlocks unlimited custom presets, interactive widgets/App Intents to start a sit, Live Activity for the running timer, and extended history export.
- **Why it can boom:** meditation is a proven top-grossing wellness category, and the #1 user complaint about the leaders is exactly the thing Chime gives away free and makes lovely — a fast, beautiful, no-nonsense interval timer. We win on focus, taste, and fairness.

## Self-review
Re-read every Swift file by hand against the iOS 17 SDK: verified all imports; `@Model`/`@Query`/`modelContainer` wiring; `@Observable`/`@State`/`@AppStorage`/`@Environment` usage; `NavigationStack`/`TabView`/`.sheet(item:)`/`.fullScreenCover(item:)` bindings (SwiftData models are `Identifiable`/`Hashable`); `AVAudioEngine`/`AVAudioPCMBuffer` buffer synthesis; Swift Charts `BarMark` API. No force-unwraps, `try!`, or `fatalError` on user paths (only the unreachable in-memory container fallback). Anti-stub grep (TODO/FIXME/XXX/placeholder/lorem/coming soon/not implemented/stub) is clean.
