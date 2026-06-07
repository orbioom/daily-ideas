# Static

**Freediving apnea trainer that builds CO₂ and O₂ tables around your own breath-hold.** Enter your max hold, get a proper table, and follow a calm full-screen timer through breathe-up, holds and recovery — every session logged so you can watch your personal best climb.

For freedivers and spearos who want correct tables and a quiet, guided session rather than a noisy stopwatch.

## Features

- **Table generator** — pick CO₂ (fixed holds, shrinking rests — carbon-dioxide tolerance) or O₂ (fixed rests, growing holds toward your max — oxygen efficiency), set your max breath-hold and round count, and see the per-round schedule update live before saving.
- **Guided session** — a full-screen breathing ring walks each phase with a countdown, round counter, phase-tinted background, and total progress. Time accrues only while running, so pause is exact; skip a phase, and get a phase-change haptic cue. Finishing logs rounds completed and longest hold with optional notes.
- **Log** — every session with table, type, rounds done/planned, longest hold and notes; swipe-free context delete.
- **Progress** — personal-best hold trend (running best + per-session points), time gained, session count, and a CO₂/O₂ training mix with total rounds trained.
- **Settings** — cue phase changes, keep screen awake during a session, confirm-before-delete, haptics, appearance, erase-all. A safety note (train dry and seated; never in water alone).

Onboarding gate (with a safety line), empty/loading/success states, light & dark, Dynamic Type, VoiceOver, Reduce Motion, designed app icon.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Static.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**.

**Free signing:** pick your personal team under Signing & Capabilities; bundle id `com.orbioom.static`. No paid account needed.

## Tech notes

iOS 17+, SwiftUI 5, pure `TableEngine` that derives schedules and a flattened phase timeline from parameters (tables stay small and reproducible). Live timer uses a `Timer.publish` tick accumulating real elapsed against a phase timeline with cumulative offsets; `UIApplication.isIdleTimerDisabled` gated by a setting. Persistence in **SwiftData** (`ApneaTable`, `ApneaSession`); prefs in `@AppStorage`. **Swift Charts** for the PB trend. Orbioom design language. No third-party dependencies; starter tables and a few weeks of sessions seeded on first launch.

## Self-review

Anti-stub grep clean (only the in-memory `ModelContainer` fallback uses `try!`). By-hand compile pass: timer/phase math, `onChange` two-parameter form on a computed phase index, `contentTransition(.numericText())`, `UIKit` import for idle-timer control, and Swift Charts usage verified against the iOS 17 SDK. Correctness is by inspection (no Xcode in the sandbox).
