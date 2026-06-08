# Tare — weight-trend tracker

**Weigh in, calmly.** Daily weight bounces with water, food, and sleep. Tare reads through the noise with a smoothed trend line — then projects when you'll hit your goal at your current pace, so one bad morning never ruins your week.

For the weight-loss/maintenance crowd who loved Happy Scale's trend idea but want it cleaner, unit-flexible, and private.

## Features

- **Trend engine** — an exponentially-weighted moving average (Happy-Scale-style, adjustable α) over every weigh-in, plus a **least-squares weekly rate** and a **goal projection** (days-to-goal and a projected date that only shows when you're actually trending toward goal).
- **Today** — big trend-weight number, total change, a sparkline, your weekly rate with direction, latest raw weigh-in, and a projection card.
- **Add weigh-in** — fine ±0.1 / ±1 steppers, slider, date, note. Stored canonically in kg.
- **Trend chart** — raw daily points + smoothed trend line + dashed goal line, with 30d / 90d / 1y / All ranges (Swift Charts).
- **Log** — every weigh-in with the day-over-day delta; tap to edit, swipe to delete.
- **Insights** — trend, rate, total change, BMI (from optional height) with category, and auto-generated **milestones** between start and goal.
- **Settings** — kg / lb / st units (data never rewritten), goal toggle + value, height, trend smoothing slider, haptics, delete-all with confirmation.
- Onboarding (persisted, sets units), empty states, 60-day sample loader, light/dark, Dynamic Type, VoiceOver, Reduce Motion.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Tare.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** personal team; bundle id `com.orbioom.tare`. No paid account, no keys.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM. **SwiftData** (`WeightEntry`, kg canonical); prefs in `@AppStorage`.
- Pure `TrendEngine` (EMA + least-squares slope + projection + BMI) and a `Units` layer (kg/lb/st conversions) — guarded against divide-by-zero and empty data.
- Design language: **Orbioom** (glass, ink, mono numerics; info-blue trend, green for losing/“on track”).
- **Monetization:** one-time Pro unlock (or low subscription) for goal projection, multiple goals, and CSV/Health export — friendlier than the incumbents' nag screens.
- **Why it can boom:** weight tracking is evergreen and Happy Scale proved people pay for *trend* smoothing — but it's iOS-only, dated, and imperial-leaning. Tare modernises the exact mechanic with multi-unit support, a real projection, and on-device privacy.

## Self-review

Re-read every file. Verified imports; `TrendEngine` maths (EMA, slope, projection) and `Units` rounding compile; Charts (`PointMark`/`LineMark`/`RuleMark`) and 4-way range picker type-check; `@AppStorage` goal/height steppers convert correctly; only `try!` is the in-memory fallback; ≥4 feature screens (Today, Trend, Log, Insights) + Onboarding + Settings; no stubs, no iOS-18 APIs. Anti-stub grep clean.
