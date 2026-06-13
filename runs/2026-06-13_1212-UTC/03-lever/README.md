# Lever — calisthenics progression coach

**One-liner:** A focused, subscription-free bodyweight coach: test your max, get placed on an honest skill ladder for the core movements, then train with a guided session player that counts your sets, runs your rest, and promotes you when you've earned the next level.

**Problem & audience:** Millions of people want to get strong with nothing but their bodyweight, but the popular apps are cluttered video-course subscriptions that bury the one thing that matters — a clear progression from where you are to where you want to be — behind paywalls and endless clips. Lever does the high-leverage thing beautifully and offline: a real progression tree for push-ups, squats, pull-ups, dips and core holds, a placement test, and a distraction-free guided session player — for one honest price.

## Features

- **Train (Today)** — a card per movement showing your current level and its next target. Tap into a full-screen guided session player: step through every set with a big rep counter or a live hold timer, an automatic Timer-driven rest countdown between sets (with a haptic when rest ends), log each set, then a summary that saves the workout and tells you — and promotes you — when you've earned the next rung.
- **Skills** — the full progression ladder per movement as a vertical skill tree. Each rung shows its cleared / current / upcoming / locked state, and expands to reveal the description, sets and reps, a technique tip, and exactly what advances you.
- **Test** — a max-rep or max-hold placement flow. Pick a movement, do one all-out set, enter the number, and the pure ProgressionEngine places you on the rung you can actually train, records your best, and dates the test.
- **Progress** — day streak, total sessions, total reps, levels climbed and longest streak; Swift Charts of volume-over-time (per movement) and sessions-per-week; per-movement level and best tiles; and a recent-sessions list.
- **Settings** — default rest length, keep-screen-awake-during-sessions toggle, haptics, voice/sound cues, Pro unlock/restore, and a reset-history action. First-run onboarding gated by a persisted flag.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Lever.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

**Free signing:** Select your personal team under Signing & Capabilities; the bundle id is `com.orbioom.lever`. No paid account or code-signing assets required to run on a simulator or a personal device.

## Tech notes

iOS 17+, SwiftUI 5, MVVM. Primary data (per-exercise progress + workout logs) in **SwiftData**; small preferences in `UserDefaults` via `@AppStorage`. A pure, fully-guarded `ProgressionEngine` handles placement, session planning, and the two-session advance rule so it can never crash. The guided session player and rest countdown use a `Timer.scheduledTimer` + `[weak self]` + `deinit`-invalidate view model. Charts with Swift Charts; the keep-awake toggle drives `UIApplication.shared.isIdleTimerDisabled` only while the player is on screen. Light + dark first-class via dynamic asset colors; Dynamic Type, VoiceOver labels, Reduce Motion gating, and opt-out haptics throughout. Design language: a gritty training-floor palette (concrete grey, chalk white, vivid orange) with bold rounded type.

- **Monetization:** Free core (every base ladder + placement test + guided player + progress). One-time **Lever Pro ($8.99)** unlocks the advanced skill ladders (planche, front lever, muscle-up, archer/one-arm and pistol mastery rungs) and custom routines — no subscription, no ads.
- **Why it can boom:** Calisthenics is a large and fast-growing fitness niche, and the proven "0→100 push-ups / 0→pull-up" apps show the appetite for structured bodyweight progression — yet the incumbents are cluttered video subscriptions; a focused progression-tree coach with a guided session player and one honest one-time price is the wished-for version of that category.

## Self-review

Hand-reviewed file by file (no Xcode in the build sandbox). Verified: all imports resolve (`SwiftUI`, `SwiftData`, `Charts`, `UIKit`); every type, modifier, and SwiftData/`@Query`/`@Observable`/`@Environment` usage is iOS-17-valid; `@main` is `LeverApp` with the standard in-memory `ModelContainer` fallback; `NavigationStack`/`navigationDestination`/`sheet`/`fullScreenCover(item:)` wiring type-checks; timers follow the `scheduledTimer` + `[weak self]` + `deinit invalidate` pattern with no `@MainActor` on the view models; no force-unwrap, `try!`, `fatalError`, unchecked index, or unguarded division on user paths (the only `try!` is the in-memory container fallback); `@Model` arrays in `ForEach` use `Array(...enumerated()), id: \.offset`; anti-stub grep clean (no TODO/FIXME/placeholder/etc.). Onboarding gated by a persisted flag; empty/loading/success/error states present; Pro gating real (locked levels route to the paywall); light + dark, Dynamic Type, VoiceOver, Reduce Motion, and opt-out haptics wired.
