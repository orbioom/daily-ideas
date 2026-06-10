# Cortex — Brain-training mini-games & daily workout

Five focused brain games — one per cognitive domain — plus a daily three-game workout, with generous free play and procedurally generated content that never repeats. A direct answer to Elevate/Lumosity/Peak, whose users love the games but resent the 3-games-a-day free cap, the year-two price hikes, and the small libraries that go stale in weeks.

## What it is
- **One-line:** A clean, free-to-play brain trainer with five games and a daily workout.
- **Problem + audience:** Brain-training is a huge proven market, but every leader caps free play at ~3 games/day, repeats content within weeks, and quietly auto-renews at $59–$119 in year two. Cortex serves the same self-improvement audience with no cap and freshly generated questions.

## Full feature list
- **Five games, each a real engine:**
  - **Quick Math** (numeracy): timed arithmetic with distractor answers and a streak bonus.
  - **Color Focus** (attention): a Stroop test — tap the *ink* color, not the word.
  - **Next in Line** (reasoning): arithmetic/geometric/square/Fibonacci sequences, pick the next term.
  - **Memory Grid** (working memory): a flashed tile pattern you tap back; levels grow and shrink with success.
  - **Word Scramble** (language): rebuild a scrambled word by tapping letter tiles, with undo/skip.
- **Daily Workout:** three deterministic games for the day, run back-to-back with interstitials and a combined "brain score" summary; "done today" detection.
- **Difficulty** (easy/medium/hard) widens ranges and multiplies score; **round length** (30/45/60/90s) is configurable.
- **Progress:** day streak, games played, total points, a 14-day daily-best line chart, per-game best/average/accuracy, and a recent-plays list (workout plays flagged).
- **Settings:** difficulty, round length, appearance (light/dark/system), haptics, reset all scores, honest "no cap / no price hike" about copy.
- Onboarding gated by a persisted flag; empty/loading/result states; correct/wrong feedback with haptics.

## Run steps
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Cortex.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

## Free-signing note
No paid account needed: select your personal team under Signing & Capabilities and run on a simulator or your own device.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. Pure engines: `QuestionGen` (math/Stroop/sequence/scramble generators with proper distractors), `StatsEngine` (summaries, streak, daily-best, deterministic daily-workout picker).
- Persistence: **SwiftData** (`GameResult`, grouped by `workoutID`); `UserDefaults`/`@AppStorage` for prefs. Swift Charts for trends.
- Design language: **Orbioom**, per-game tints.
- **Monetization:** freemium — all five games free with no daily cap; a one-time/low-sub "Cortex Pro" (extra game variants, detailed analytics, custom workouts) is the upsell, deliberately not gating the core loop.
- **Why it can boom:** brain-training is a validated top-grossing category whose incumbents are widely criticized for stingy free tiers, repetitive content, and year-two price hikes; Cortex's no-cap, never-repeats, no-trap positioning is exactly the version frustrated reviewers ask for.

## Self-review
Re-read every Swift file: imports verified; all SwiftUI/SwiftData/Charts symbols exist in iOS 17; timer-driven game loops, `@Observable`/`@State`/`@Query`/`@AppStorage` and `modelContainer` wiring type-check; no force-unwraps/`try!`/`fatalError` on user paths (container falls back to in-memory); `Array[safe:]` defined once; anti-stub grep clean. Dynamic Type, accessibility, Reduce Motion (gates feedback animation), and light/dark handled.
