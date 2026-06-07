# Links — Golf handicap & round logbook

**A World Handicap System calculator and scorecard logbook that lives entirely on your phone.** For amateur golfers who want an honest, up-to-date Handicap Index without a club account or a subscription.

Design language: **Orbioom** (Liquid Glass, ink-gradient buttons, SF Pro + JetBrains Mono for figures, green as a rare live/counting accent).

## The problem
Casual golfers either guess their handicap or pay a federation/app to track it. Links computes a real WHS Handicap Index from your own scorecards — best 8 of your last 20 — with the proper Net Double Bogey adjustment, all offline.

## Features
- **Handicap** home screen — big Handicap Index, Low Index, counting-rounds count, a differential trend chart, and the full score-differential table with the 8 counting scores highlighted (live green dot).
- **WHS engine** (verifiable in `Utilities/HandicapEngine.swift`): Score Differential `(113/Slope)×(AGS−Rating)`, best-N-of-20 with the short-record table & soft adjustments, Course Handicap, Net Double Bogey hole capping (par+5 before an Index is established), processed **chronologically** so each round's cap uses the Index established before it. Plus Stableford points and score-name helpers.
- **Rounds** — full logbook with per-round score, to-par, FIR/GIR badges; tap for a hole-by-hole scorecard (front/back nine grids, colour-coded scores, putts/fairways/greens stats).
- **Scorecard editor** — choose course & tee, enter every hole with score steppers, putts, fairway-hit (par 4/5), and green-in-regulation; live running total.
- **Courses** — full CRUD: per-hole par & stroke index (9 or 18 holes), and multiple tees each with Course Rating / Slope / yardage.
- **Insights** — scoring average, average to par, best round, fairway %, GIR %, putts/round, a scoring distribution (eagle→double), and average-vs-par by par-3/4/5.
- **Settings** — haptics, appearance (System/Light/Dark), confirm-before-delete, plus library stats and a guarded erase-all.
- Onboarding gated by a persisted flag; empty/loading/error/success states throughout; full Dynamic Type, VoiceOver labels, Reduce Motion, light & dark, designed app icon.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Links.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** no paid account needed — select your personal team under Signing & Capabilities; the bundle id is `com.orbioom.links`. No network, accounts, or API keys.

## Tech
iOS 17+, SwiftUI 5, MVVM-ish with a pure value-type engine, SwiftData persistence (`Course`/`Tee`/`Round`, rounds store a self-contained snapshot so handicap math is stable across course edits), `UserDefaults` only for small prefs. Charts drawn with `Canvas`. No third-party dependencies.

## Self-review
Re-read every Swift file by hand (no Xcode in the build sandbox): imports, iOS 17 SDK symbols, SwiftData `@Model`/`@Relationship`/`@Query` wiring, `Picker` tag types, `.onChange` two-parameter form, and the `project.yml`. Anti-stub grep (TODO/FIXME/placeholder/lorem/coming soon/not implemented/stub) is clean. No force-unwraps, `try!` (except the in-memory container fallback), or unguarded division on user paths. An automated by-hand compile review pass was also run. Believed to compile cleanly under Xcode 15+ after `xcodegen generate`.
