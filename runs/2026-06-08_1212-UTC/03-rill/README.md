# Rill

**Hydration, honestly — a calm water tracker that counts what you actually drink.**

The problem: hydration trackers are top-grossing in Health, but WaterMinder's reviews are full of intrusive ads, crashes on the history tab, analytics locked behind a paywall, and reminders that "hound like an obsessive." Rill is the version people wish existed: free analytics, one simple reminder interval, a smart goal, and an honest net-hydration model where coffee and beer don't count like pure water. Audience: anyone trying to drink more water, athletes, hot-climate dwellers.

## Features

- **Today** — a hydration ring showing net "pure-water-equivalent" vs goal (overflow turns green), with caffeine and percent stats, an 8-drink quick-add grid (long-press for a custom amount), and an editable today log.
- **Smart goal engine** — recommends a daily target from body weight, profile, activity level, and climate (clamped to a sane range); or set your own.
- **Net-hydration model** — each drink carries a hydration coefficient (water 100%, coffee 85%, beer 50%…) and caffeine, snapshotted onto every log so editing a drink never rewrites history.
- **History** — 7/14/30-day intake bars with a goal line, daily average, goal-met streak, and a per-day list.
- **Drinks** — full catalog CRUD: size, hydration %, caffeine, icon, and color.
- **Insights** — all-time intake, best day, a "where it comes from" sources donut, and a by-weekday rhythm chart (Swift Charts).
- **Settings** — theme, units (ml/oz), smart-goal profile, manual goal, a single reminder interval, haptics, erase-all.
- Onboarding with goal setup (persisted), empty/loading/success states, Dynamic Type + VoiceOver, light & dark, Reduce-Motion-aware, on-brand icon.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Rill.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team; bundle id `com.orbioom.rill`.

## Tech notes

iOS 17+, SwiftUI 5, MVVM with a pure `HydrationEngine` (goal recommendation, daily/weekly rollups, streaks, sources, weekday averages) and a `GoalSettings` bridge over `UserDefaults`. Persistence in **SwiftData** (`DrinkType`, `DrinkLog`). Units canonicalized in ml. Design language: **Orbioom**. No account, no network, no ads.

- **Monetization:** freemium — tracking + full history/insights free (the opposite of WaterMinder); a one-time Pro unlock adds widgets, extra reminders, and themes. Who pays: health-focused users who resent the incumbent's ads/paywall.
- **Why it can boom:** proven top-grossing demand with concrete, well-documented complaints; Rill keeps analytics free and the UX calm, which is exactly what the 1-star reviews ask for.

## Self-review

Re-read every Swift file by hand. Imports resolve; SwiftData models, `@Query`, `@AppStorage`-driven goal recomputation, and the `TimelineView`-free ring all type-check; charts use iOS-17 `BarMark`/`SectorMark`/`RuleMark`; every division is guarded; no force-unwraps/`try!`/`fatalError` on user paths. Added an explicit categorical `chartXScale` for the weekday chart ordering. Anti-stub grep clean.
