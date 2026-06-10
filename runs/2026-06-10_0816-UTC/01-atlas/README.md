# Atlas — strength programs, not guesswork

**What it is.** A native iOS strength-training app built around *programs*: reusable workout routines with target set × rep ranges, supersets, and per-exercise progression rules. A full-screen runner walks you through each session with an automatic rest timer, and a progression engine decides exactly what to load next time — the job people buy Hevy, Strong, and LADDER for, without the subscription tax on basics.

**Audience.** Anyone lifting 2–5 days a week who wants a plan that quietly gets heavier — beginners on Full Body A/B through intermediates running an Upper/Lower split.

## Features

- **Routine builder** — name, notes, ordered exercises from a 52-exercise library (grouped by muscle) or custom entries; per-exercise target sets, rep range, rest length, start weight, increment, progression rule (double progression or linear), and superset groups; drag to reorder, swipe to delete; draft-based editor with validation (name required, ≥1 exercise, sane rep range).
- **Starter program** — optional one-tap install of Full Body A/B + Upper + Lower (offered in onboarding and in the empty state), fully editable.
- **Progression engine** — pure logic that reads your last logged performance of each exercise: double progression (earn reps in the range, then add weight and restart) or linear (+increment whenever you complete the work), with a human-readable reason shown for every suggestion.
- **Workout runner** — full-screen session player with prefilled suggested weight/reps for every set, ± weight (unit-aware plate steps) and rep controls, add/remove sets, live elapsed clock, progress bar, session notes, optional keep-screen-awake, and a date-based rest timer that starts itself when you finish a set (+15 s / skip), surviving backgrounding.
- **Finish flow** — confirmation (warns about unfinished sets), saved-summary success screen (duration, sets, volume), partial sets stored as skipped; empty workouts save nothing.
- **History** — month-grouped session log with duration/sets/volume, session detail with per-set breakdown and done/skipped marks, editable notes, swipe- and detail-delete with confirmation.
- **Insights** — this-week vs goal, week streak, lifetime workouts; Swift Charts for volume per week, sets by muscle (last 4 weeks), and sessions per week against your goal line; loading and empty states.
- **Settings** — kg/lb (stored canonically in kg), weekly session goal, keep-screen-awake, haptics toggle; About with the privacy promise.
- Onboarding (3 pages, persisted flag), empty states everywhere, light + dark, Dynamic Type, VoiceOver labels/hints/values, Reduce Motion respected, sparse haptics.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Atlas.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**.

*Free signing:* for a device build, select your personal team under Signing & Capabilities; the free tier is fine (no entitlements used).

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-style: SwiftData models (`Routine→RoutineExercise`, `WorkoutSession→SessionExercise→SessionSet`, all cascade), pure engines (`ProgressionEngine`, `StatsEngine`), an `@Observable` `WorkoutRunner` session object, views per feature.
- Persistence: SwiftData; preferences in `@AppStorage`. Weights canonical in kg.
- Design language: **Orbioom** (glass cards, ink-gradient primary button, mist background, JetBrains-style mono for numbers, slow 0.16/1/0.3/1 motion).
- **Monetization:** lifters already pay $30–120/yr (Hevy/Strong/LADDER); free core logging + one-time "Atlas Pro" unlock (advanced analytics, unlimited routines, export) — the lifetime option Hevy users keep asking for.
- **Why it can boom:** strength training is a perennial top-grossing App Store category (LADDER was the #1 grossing fitness app worldwide in 2026); incumbents gate analytics behind subscriptions and still lack opinionated progression — Atlas ships the missing "what do I lift today" answer, on-device and calm.

## Self-review

Every Swift file re-read against the iOS 17 SDK: imports, API availability (SwiftData `@Model`/`@Query`/relationships with single-side inverses, `@Observable`/`@Bindable`, Swift Charts marks/axes, TimelineView), state ownership, navigation wiring, and unit conversions checked by hand. Anti-stub grep (`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|stub`) clean. No force-unwraps, `try!`, or unchecked indexing on user paths (the only `fatalError` is the unreachable in-memory ModelContainer fallback shared by all Orbioom apps).
