# Chains

**Disc-golf scorecard with a real round-rating engine.** Keep your courses, score rounds hole by hole, and get a PDGA-style rating estimate the moment you finish — then watch your trend climb and find the holes that cost you strokes.

For disc-golf players who want more than a notepad: a clean live scorecard plus the kind of rating math casual apps skip.

## Features

- **Courses** — build each layout once: per-hole par and distance, 1–36 holes, optional location. Course detail shows par, total distance, and the full layout.
- **Rounds** — start a round from any course, then tap through a focused live scorecard: big stroke counter with birdie/par/bogey labelling, putts and penalties per hole, prev/next navigation, and a full-card grid view. Resume an in-progress round any time.
- **Round rating** — a transparent estimator: a round equal to the course's Scratch Scoring Average rates ~1000, and every throw over costs a fixed, course-tunable number of points. Each round snapshots its baseline so old ratings stay stable. Tier labels (Recreational → Pro).
- **Stats** — rating trend line, average rating over a configurable window, best round, scoring average to par, a per-hole "trouble holes" bar chart for your most-played course, and a scoring mix (eagle/birdie/par/bogey/double+).
- **Round detail** — full breakdown: rating, totals, score distribution, hole-by-hole.
- **Settings** — distance units (feet/meters), rating window size, show/hide rating estimates, confirm-before-delete, haptics, appearance, plus a destructive erase-all.

Onboarding gate, empty/loading/success states, light & dark, Dynamic Type, VoiceOver labels, Reduce Motion, designed app icon.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Chains.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, press **Cmd+R**.

**Free signing:** select your personal team under Signing & Capabilities; the bundle id is `com.orbioom.chains`. No paid account needed for the simulator or a personal device.

## Tech notes

iOS 17+, SwiftUI 5, MVVM-ish with a pure `RatingEngine`. Persistence in **SwiftData** (`DiscCourse → Hole`, `Round → HoleScore`); small prefs in `UserDefaults` via `@AppStorage`. Charts via Apple's **Swift Charts**. Orbioom design language (liquid glass, ink-gradient buttons, JetBrains Mono for numbers). No third-party dependencies; sample courses and a back-catalogue of rounds are seeded on first launch.

## Self-review

Anti-stub grep clean (only the standard in-memory `ModelContainer` fallback uses `try!`). By-hand compile pass: SwiftData relationships and `@Query` wiring, `NavigationStack`/`navigationDestination`, Swift Charts marks over `Identifiable` data (no tuple key-path ids), two-parameter `onChange`, and division/`.infinity` guards in the rating math all verified against the iOS 17 SDK. No Xcode in the build sandbox, so correctness is by inspection.
