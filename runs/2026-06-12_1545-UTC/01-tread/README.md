# Tread — a calm, honest step tracker

**One-liner:** Turn your iPhone's built-in motion sensor into a beautiful step tracker with streaks and milestone badges — no account, no ads, no subscription to see your own numbers.

**The problem & audience:** Step counting is one of the largest, most durable health categories on the App Store (Pedometer++, StepsApp, Pacer all sit high in the health charts), but the popular free apps are ad-laden, nag for subscriptions, or feel dated. Tread is for the huge mainstream audience that just wants a clean daily ring, a streak to protect, and a few satisfying milestones — done with taste and respect for privacy.

## Full feature list

- **Today** — a hero progress ring (live steps vs goal) backed by CoreMotion `CMPedometer`, with distance, estimated calories, flights climbed, and a "steps to go" tile. Encouragement copy adapts to your progress; the streak flame sits in the nav bar.
- **History** — a 7-day bar chart with your goal line, plus a scrollable list of every cached day showing a per-day completion ring, distance and flights.
- **Insights** — total steps, daily average, best day and longest streak; a 30-day trend area chart and a "weekly rhythm" average-by-weekday chart.
- **Badges** — ten milestone achievements (single-day step targets, goal streaks, lifetime totals) with progress bars for the locked ones and an unlock toast when you earn one.
- **Onboarding** — three panes plus an inline daily-goal picker; starting triggers the Motion & Fitness permission prompt.
- **Settings** — daily goal stepper, metric/imperial units, body weight (drives calorie math), haptics toggle, a **Demo data** switch (fills 30 realistic days so iPad/Simulator users can explore), and an erase-history action.
- Empty, loading, permission-denied, and no-sensor states everywhere; full Dynamic Type, VoiceOver labels, Reduce Motion support, and light/dark designs.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Tread.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

> CoreMotion returns no data on the Simulator — enable **Settings ▸ Demo data** to explore every screen, or run on a real device for live steps.

**Free-signing note:** Personal Apple ID signing works — no paid account needed. Set your team under Signing & Capabilities; the app uses only on-device CoreMotion (no entitlements).

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-ish with a pure `StepEngine` (streaks, averages, weekday rhythm, badge logic) and an `@Observable @MainActor PedometerService` wrapping `CMPedometer`.
- Persistence in **SwiftData** (`DayLog`, `Badge`). Because CoreMotion only retains ~7 days, Tread caches each observed day so longer-range insights survive the sensor's window. Small prefs in `UserDefaults`.
- Design language: "fresh trail" — vivid emerald on deep forest charcoal / airy mist, with the goal ring as the hero on every screen.
- **Monetization:** Free core (today's ring + 7-day history); one-time **Pro** unlock for full insights, all badges and unlimited history. Mainstream health buyers already pay here (Pacer charges $50/yr).
- **Why it can boom:** A massive, proven, evergreen category whose free leaders are mediocre and ad-heavy — Tread is the tasteful, private, fair-priced version of a job hundreds of millions of people already do daily.

## Self-review

Re-read every Swift file: imports verified; all SwiftUI/SwiftData/Charts/CoreMotion APIs exist in the iOS 17 SDK; no tuple key-paths (engine results are `Identifiable` structs); no `try!`/`fatalError`/force-unwraps on user paths (the two guarded `s!` accesses are short-circuited); actor isolation hardened with `@MainActor` on data-sync helpers. Anti-stub grep clean. `project.yml` is valid YAML naming the `Tread` sources and `Info.plist`; icon is a real 1024×1024 RGBA PNG.
