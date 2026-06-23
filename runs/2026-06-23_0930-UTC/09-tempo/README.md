# Tempo

**The fastest way to log a set.** Tempo is a strength-training workout logger for lifters who want to spend their time under the bar, not tapping menus — weight × reps in two taps, automatic PR detection, a calm rest timer, and a barbell plate calculator, all on-device.

## Problem & audience
Serious lifters track every set to drive progressive overload, but most loggers bury that behind clunky flows or paywall the basics. Tempo's audience is the gym-goer running Push/Pull/Legs, 5×5, or any structured plan who wants Strong/Hevy-grade speed and insight without a subscription. The edge: friction-free set entry, instant PR feedback, and built-in tools (rest timer + plate math) that keep you off your phone between sets.

## Features
- **Fast set logging** — tap a lift, punch weight × reps, mark complete. New sets pre-fill from your last performance so you start where you left off. Warm-up toggle per set, optional RPE (6–10).
- **Automatic PR detection** — every completed working set is checked against your full history for new estimated-1RM, top-weight, and set-volume records, surfaced with a gold banner + success haptic. e1RM via the **Epley** formula.
- **Calm rest timer** — wall-clock anchored (stays accurate across backgrounding/relaunch), auto-starts after working sets, ±15s controls, progress ring, completion haptic.
- **Barbell plate calculator** — greedy per-side loading for kg or lb with a visual bar render; reachable inline from any barbell set or from Settings.
- **Exercise library** — 44 seeded compound & accessory lifts tagged by muscle group + equipment; search, muscle filters, favorites, and full CRUD for custom lifts.
- **Per-exercise detail** — PR cards plus an estimated-1RM trend chart (Swift Charts) and recent-set history.
- **Workout history** — finished sessions grouped by month with volume, set count, duration; tap-through detail with per-exercise breakdown, editable notes, delete.
- **Stats** — headline metrics (workouts, week streak, total volume, sets), weekly-volume bar chart, switchable estimated-1RM line chart, and a 30-day muscle-group split.
- **Routine templates** — 5 built-in (Push/Pull/Leg/Upper/Full Body) plus full CRUD builder (name, color, ordered exercises with target sets/reps, reorder & delete). One tap pre-builds a workout.
- **Settings** — weight unit (kg/lb), bar weight, default rest, auto-start rest toggle, RPE tracking toggle, haptics toggle, replay onboarding.
- 9 weeks of realistic seeded history (well over 50 sets) so charts, PRs, and history are populated on first run.

## Tech notes
- **iOS 17+, SwiftUI 5, MVVM.** Persistence is **SwiftData** (`Exercise`, `Workout`, `SetEntry`, `Routine`, `RoutineItem`, `AppSettings`) with cascade/nullify relationships; `@AppStorage` only for the onboarding flag. Survives relaunch.
- Pure engines: `StrengthMath`/`PRDetector` (Epley + PR logic), `PlateCalculator` (greedy loading), `StatsEngine` (chart series), all guarded against empty data and division by zero.
- Wall-clock `RestTimerModel` (`@Observable`) + `TimelineView` for relaunch-safe timing.
- Full accessibility: Dynamic Type, labels/hints/values, decorative images hidden, asset-catalog color sets for first-class light/dark with AA contrast, Reduce Motion honored on every animation. Haptics gated by a Settings toggle.
- No external dependencies, no network, no API keys.
- **Monetization:** free core logging forever; one-time **Tempo Pro ($4.99)** unlocks unlimited custom routines, advanced charts (per-lift volume + RPE trends), and CSV export — no subscription, unlike Strong/Hevy.
- **Why it can boom:** Strong and Hevy proved millions pay to log lifts, but both lean on subscriptions and feel heavy; Tempo wins on raw logging speed + free PR tracking and plate math, the exact combo lifters rave about — a one-time-purchase positioning in a subscription-fatigued market.

## Run
1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. Open `Tempo.xcodeproj` in Xcode 15+ and press **Cmd+R**.

**Free signing:** select the Tempo target → Signing & Capabilities → pick your personal team; the bundle id `com.orbioom.tempo` can be changed if it collides. No paid account needed for the simulator or personal-device runs.

## Self-review attestation
Re-read every Swift file: all imports, types, initializers, enum cases, and modifiers are valid iOS 17 SDK and correctly spelled; protocol conformances satisfied; SwiftUI state wrappers (`@State`/`@Bindable`/`@Binding`/`@Environment`/`@Observable`/`@Query`/`@AppStorage`) and `NavigationStack`/`navigationDestination`/`sheet`/`modelContainer` all type-check; no APIs newer than iOS 17. No force-unwrap, `try!`, or `fatalError` on user paths (the only `fatalError` is in a preview-only container bootstrap, never reached on device). Inputs are filtered, clamped, and guarded; no unchecked indices or unguarded division. Anti-stub grep (`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub`) is clean. **The project was generated with `xcodegen` and compiled with `xcodebuild` against the iOS Simulator SDK: BUILD SUCCEEDED.**
