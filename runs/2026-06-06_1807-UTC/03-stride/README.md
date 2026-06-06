# Stride — running paces, race predictions & training log

**One line:** A calm, offline running companion that logs your runs and turns one recent result into race predictions, training paces, and a race-day split plan.

**Problem & audience:** Runners juggle a pile of separate calculators — a Riegel predictor here, a VDOT pace chart there, a pace/split table somewhere else — none of which know about each other. Stride unifies them around a single benchmark performance and a real training log, entirely on-device. For anyone training for a 5K to a marathon.

## Features

- **Runs** — full CRUD log: name, date, distance, duration, type (easy/long/tempo/interval/race), RPE, notes. Computes pace and VDOT per run. Header shows last-7-day mileage, weekly-goal progress, a 14-day bar chart (Swift Charts), and a type filter.
- **Predict** — from a benchmark (set manually or imported from a logged race), a full table of predicted times **and paces** for 12 standard distances using Riegel's `T₂ = T₁·(D₂/D₁)^k`. Your benchmark distance is highlighted.
- **Training Paces** — computes **VDOT** (Jack Daniels' model) from the benchmark and derives Easy / Marathon / Threshold / Interval / Repetition paces, each with a one-line "how to use it".
- **Race Plan** — pick a goal distance + time and get a per-km/mi split table with cumulative elapsed time, plus an even ↔ negative-split slider that redistributes effort while keeping the average on target.
- **Shared benchmark** — Predict and Paces read the same benchmark, so changing it once updates both. The benchmark can be pulled from any logged race.
- **Real sports-science math** — `PaceMath` implements Riegel, the Daniels VO₂/%VO₂max/VDOT equations (and inverts the VO₂–velocity quadratic for paces), and a renormalized split generator.
- **Settings** — units (km/mi), Riegel exponent, weekly goal, haptics; reload sample runs; delete all.
- First-run onboarding (persisted), empty/loading/success/error states, light & dark, Dynamic Type, VoiceOver, Reduce Motion, sparse haptics.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Stride.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team under Signing & Capabilities; no paid account needed.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-lite (pure `PaceMath` engine, SwiftData `Run` model, thin views).
- Persistence: **SwiftData** for runs; the shared benchmark and prefs live in `UserDefaults` via `@AppStorage`.
- Design language: **Orbioom** (glass, ink-gradient action, mono figures, green as a rare accent for pace highlights).
- No external dependencies; Swift Charts is a system framework.

## Self-review

Re-read every Swift file against the iOS 17 SDK: imports (`SwiftUI`, `SwiftData`, `Charts`) resolve; `@Model`, `@Query`, `@Bindable`, `@AppStorage`, `@Binding` (DurationField/BenchmarkCard), `NavigationStack`/`navigationDestination(for: Run.self)`, sheet bindings, and `Picker` tags typed as `Double` all type-check. No force-unwraps, `try!` (except the in-memory `ModelContainer` bootstrap in `StrideApp`), unchecked indices, or unguarded division — `PaceMath` guards every divisor (distance/time/velocity) and returns 0 on bad input; `clock`/`paceClock` guard non-finite values. Anti-stub grep clean. Seeds 10 runs spanning three weeks.
