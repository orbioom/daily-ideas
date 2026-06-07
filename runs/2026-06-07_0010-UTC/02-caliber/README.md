# Caliber

**Know your mechanical watch to the second.**

Caliber is an accuracy log and collection tracker for mechanical watch
enthusiasts. You log how many seconds fast or slow each watch reads against a
reference; Caliber fits a least-squares line through your readings and reports the
true daily rate — a timegrapher built from how you actually wear the watch. It also
tracks service intervals and which position runs fastest. On-device, no account.

## Features

- **Collection** — every watch with its current rate and a COSC-style grade
  (chronometer / excellent / good / fair / needs regulation), favorites, and a
  per-watch strap-dot color. Full CRUD.
- **Watch detail** — daily rate, projected drift over your chosen horizon, the most
  recent two-point rate, an offset-over-time chart (Swift Charts), a per-position
  breakdown, and the full reading history with swipe-to-delete.
- **Measure** — a guided capture: pick a watch, dial in how many seconds fast or
  slow it reads, choose the position, and save. Works as a tab or a sheet from a
  watch's detail.
- **Service** — watches sorted by next-service-due (overdue first) from each one's
  last-service date and interval, with a one-tap "mark serviced".
- **Insights** — most accurate watch, average absolute rate, a grade-spread chart,
  and a "most position-sensitive" leaderboard.
- **Settings** — default measuring position, default service interval, drift
  horizon (day/week/month), and haptics; replay intro; clear all data.

## The engine

`RateEngine` is pure value-type math. The headline number is the **least-squares
slope** of offset-seconds versus elapsed-days — a proper regression, not a guess
from two points. It also computes per-position rates from consecutive same-position
readings (the at-home analogue of a regulation report), the positional spread, and
projected drift. `AccuracyGrade` classifies the rate against COSC-style bands.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Caliber.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team under Signing & Capabilities; no paid account
required for the simulator or your own device.

## Tech notes

iOS 17+, SwiftUI 5, SwiftData (`Watch` → `WatchMeasurement`), pure regression
engine off the view layer. Orbioom design language: glass surfaces, ink-gradient
primary action, monospaced figures for all the numbers, light + dark first-class,
Dynamic Type, VoiceOver (rates are spoken as "x seconds per day fast/slow"), Reduce
Motion, and gated haptics.

## Self-review

Hand-checked every file: imports resolve; all SwiftUI/SwiftData/Charts types and SF
Symbols exist in iOS 17; the `WatchPosition` Codable enum persists correctly;
`@Query`/`@Bindable`/sheet wiring type-checks; no force-unwraps on user paths; the
only `try!` is the in-memory container fallback in `CaliberApp`. Anti-stub grep
clean.
