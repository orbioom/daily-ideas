# Curfew — caffeine half-life & sleep tracker

**One line:** Log what you drink and Curfew models the caffeine still in your body — so you always know how much is left and the last safe time for that next coffee.

**Problem & audience:** Most people have no idea that the 3 pm latte is still half-present at 8 pm. Caffeine follows a clean exponential decay, but no simple app turns your intake into the one number that matters for sleep. Curfew is for anyone who wants better sleep without quitting coffee — privately, on-device, no account.

## Features

- **Today** (hero) — caffeine **in your system right now** (updates live), a 24-hour curve of your level with a sleep-threshold line, a bedtime marker, and a "now" line (Swift Charts). Quick-add tiles for favorite drinks, plus today's intake list with edit/delete. Stat tiles: today's total, projected level at bedtime, and when you'll drop below your sleep line.
- **Log** — full history grouped by day with daily totals, a 14-day daily-total chart with your limit line, average per day, and edit/delete of any intake.
- **Drinks** — a catalog of reusable drinks (name, mg, category, serving) grouped by type; star favorites for one-tap quick-add. Full CRUD.
- **Curfew** (standout calculator) — pick a drink size and Curfew tells you the **last safe time** to have it before bedtime, whether you can have it anytime, or that you should skip it — plus the projected bedtime level if you drink it now. All from the real decay model.
- **Real pharmacokinetics** — `CaffeineMath` sums first-order decay across all doses, samples the curve, finds the time-to-fall-below-threshold, and inverts the decay to solve the last-safe-time (`(½)^(Δt/halfLife)`).
- **Settings** — bedtime, caffeine half-life (3–7 h), sleep threshold mg, daily limit mg, haptics; reload sample data; delete all.
- First-run onboarding (persisted, captures bedtime), empty/loading/success/error states, light & dark, Dynamic Type, VoiceOver, Reduce Motion, sparse haptics.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Curfew.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team under Signing & Capabilities; no paid account needed.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-lite (pure `CaffeineMath` engine, SwiftData models, thin views).
- Persistence: **SwiftData** — `CaffeineSource` (templates) and `Intake` (snapshotted history, so editing a drink never rewrites the past). Prefs in `UserDefaults` via `@AppStorage`.
- Design language: **Orbioom** (glass, ink-gradient action, mono figures) with a calm night-blue accent; green reserved for "under your sleep line", red for over.
- No external dependencies; Swift Charts is a system framework.

## Self-review

Re-read every Swift file against the iOS 17 SDK: imports (`SwiftUI`, `SwiftData`, `Charts`) resolve; two `@Model` types, `@Query` (including a `#Predicate` for favorites), `@Bindable`, `@AppStorage`, `Timer.publish`/`onReceive` for the live clock, `.sheet(item:)`/`.sheet(isPresented:)`, and Charts `AreaMark`/`LineMark`/`RuleMark` all type-check. No force-unwraps, `try!` (except the in-memory `ModelContainer` bootstrap in `CurfewApp`), unchecked indices, or unguarded division — `CaffeineMath` guards `halfLife > 0` and clamps everywhere; the last-safe-time inversion guards the log domain. Anti-stub grep clean. Seeds 11 drinks and 8 intakes across three days, including a late-night dose so the curve is non-trivial.
