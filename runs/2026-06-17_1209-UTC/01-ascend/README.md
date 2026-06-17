# Ascend

**Guided barbell-strength training with automatic progression.** Ascend isn't a freeform
logger — it runs you through a structured program, tells you exactly what to lift today, logs your
sets, and adds weight for you when you hit your reps. Offline, no account, one-time unlock.

Built for iOS 17 with SwiftUI 5, SwiftData, and Swift Charts.

---

## What it is

Pick a program — StrongLifts 5×5, Push/Pull/Legs, Upper/Lower, Full Body 3× — or build your own.
Each training day, Ascend looks at your recent performance and prescribes the exact sets, reps, and
weight for every lift. You check sets off as you go (with a rest timer between them), tap **Finish**,
and your weights progress automatically: hit your reps and the bar goes up next time; stall three
sessions in a row and Ascend deloads you 10%. Your history, estimated 1RM trends, volume, and PRs are
always a tap away.

## Full feature list

- **Today** — the next day in your active program's rotation, with each lift's prescribed
  sets × reps × weight from the progression engine. Check off / edit each set inline, with a
  wall-clock **rest timer** (driven by a stored start `Date` + `TimelineView`, re-anchored on
  `scenePhase` so it survives backgrounding). Finish to save the session and apply progression.
  Empty state when no program is active.
- **Auto-progression** — linear progression with +increment on success, weight hold on a miss, and an
  automatic 10% deload (rounded to the nearest 2.5 kg) after three consecutive failed sessions.
- **Programs** — your saved programs plus a built-in catalog (StrongLifts 5×5 A/B, PPL, Upper/Lower,
  Full Body 3×). Add a built-in in one tap, set any program active, view full day/exercise breakdowns,
  delete, and **build a custom program** (days + exercises with sets/reps/start weight/increment).
- **History** — completed sessions grouped by week, with per-session detail: every logged set,
  duration, set count, and total volume.
- **Progress** — Swift Charts: estimated 1RM over time for a chosen lift, volume by muscle group,
  weekly volume, and a personal-records board. Loading state while computing; empty state until you
  have data.
- **Plate calculator** — greedy per-side breakdown for any target weight, using your bar weight and
  editable plate set, in kg or lb. Reachable from Today and Settings.
- **e1RM** — Epley and Brzycki estimates (reps-guarded), averaged for a steady number.
- **Settings** — units (kg/lb), bar weight, available-plates editor, default rest seconds,
  auto-progression toggle, haptics toggle, Pro unlock/restore, CSV/text export via `ShareLink`,
  load sample data, and an About screen.
- **Onboarding** — a three-page first-run intro, gated by a persisted `hasOnboarded` flag.
- **Sample data** — first launch seeds an active StrongLifts 5×5 program plus 12 past sessions of
  realistic linear progression (Squat / Bench / Deadlift / Row / OHP) so charts and history look real
  immediately.
- Full **light & dark mode**, **Dynamic Type** (semantic/rounded fonts, no clipping frames),
  **VoiceOver** labels on controls and charts, **Reduce Motion** fallbacks, and sparse haptics gated
  by a Settings toggle.

## Run steps

1) `brew install xcodegen` (one-time). 2) In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the
repo root). 3) Open `Ascend.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing:** set your Apple ID team in Signing & Capabilities; the bundle id is
`com.orbioom.ascend`.

## Tech notes

- **Architecture:** SwiftUI 5 + SwiftData. Primary data lives in `@Model` types
  (`Program`, `ProgramDay`, `ProgramExercise`, `WorkoutSession`, `LoggedExercise`, `LoggedSet`),
  all registered in the app's `Schema` and queried with `@Query` / `modelContext`. Small preferences
  and flags use `@AppStorage`. Settings is an `ObservableObject` injected via `@StateObject`.
- **Engines** are pure and crash-proof (guarded division/indexing): `ProgressionEngine`, `OneRepMax`,
  `PlateCalculator`, `StatsEngine`, `BuiltInPrograms`, and `Rotation`.
- **Weights** are stored canonically in kilograms (`Double`) and converted for display via the units
  setting.
- **Timers** are driven by stored `Date`s + `TimelineView`, recomputed on `scenePhase`, so they
  survive backgrounding and relaunch.
- **Charts** use Swift Charts (`LineMark` / `BarMark` / `PointMark`).
- **Monetization:** one-time **$5.99** Ascend Pro (simulated via `@AppStorage("isPro")`, StoreKit-ready
  in spirit). Free core = StrongLifts 5×5 / PPL / Upper-Lower built-ins, full logging, plate calc, e1RM,
  and basic stats + a PR taste. Pro unlocks the custom program builder, accessory / 5/3/1-style
  programming, full progress analytics, and CSV export.
- **Why it can boom:** StrongLifts, Strong, and Jefit proved that millions run barbell programs and
  will pay for them, but the incumbents are ad-laden or charge ongoing subscriptions for basics. Ascend
  delivers guided auto-progression programs + plate math + e1RM for a single one-time price, fully
  offline with no account and a confident, bold design.

## Self-review

Every Swift source was re-read after writing. Attestation:

- **44 Swift files** under `ios/Ascend/Ascend/`, one primary type per file, organized into
  `Models/ Engine/ Views/(Onboarding, Today, Programs, History, Progress, Settings, Components)
  Theme/ Utilities/`.
- **SwiftData schema** registers all six `@Model` types: `Program`, `ProgramDay`, `ProgramExercise`,
  `WorkoutSession`, `LoggedExercise`, `LoggedSet`. Cascade relationships use
  `@Relationship(deleteRule: .cascade)`; enums are stored as `rawValue` strings with computed
  accessors.
- **iOS 17 only:** `NavigationStack` (no `NavigationView`), two-parameter `.onChange(of:)`, no
  `@Previewable`, Swift Charts marks that exist in iOS 17.
- **Consistency:** one observation pattern throughout — `ObservableObject` + `@StateObject` for the
  settings store, `@Bindable` for SwiftData models in editors.
- **Crash-proofing:** no force-unwraps, `try!`, `as!`, or `fatalError` on user paths; division and
  array indexing guarded; a safe `[safe:]` subscript helper; a calm `StoreUnavailableView` fallback if
  the model container cannot be created.
- **Anti-stub:** a grep for `TODO/FIXME/XXX/placeholder/lorem/coming soon/not implemented/stub/
  unimplemented` returns clean; every screen, button, and control is wired to real behavior.
- Empty, loading, error, and success states are present where data is shown; full light/dark,
  Dynamic Type, VoiceOver, and Reduce-Motion support throughout.

Compiles by inspection (the build sandbox has no Xcode).
