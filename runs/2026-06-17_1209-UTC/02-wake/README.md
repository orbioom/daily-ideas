# Wake

**Plan, swim, and log structured pool workouts — with a guided in-pool interval clock.**

Wake is a focused, offline iOS pool swimming tracker. Build a workout of sets
(e.g. `4 × 100 freestyle @ 1:45`), let the interval timer guide you length by length,
tap to record each rep's split, then save a session and watch your pace per 100,
SWOLF, distance-by-stroke, and weekly volume trend over time. No account, no feed,
no Apple Watch required — everything lives on your device.

---

## What it is

A native SwiftUI + SwiftData app for iOS 17. Five tabs:

- **Swim** — the guided runner. Start from a workout template or a free swim. A big
  interval clock (anchored to a real wall-clock time so it survives lock, backgrounding,
  and relaunch) counts your current rep; tap to record each split; rest counts down and
  auto-advances to the next rep; finish and save a session with RPE and notes.
- **Workouts** — your library of templates: four built-ins plus a full custom builder
  (repeats × distance × stroke × send-off/rest × effort, reorderable). Full CRUD.
- **Log** — every completed swim, grouped by week, with a detail screen showing per-set
  splits, pace per 100, SWOLF, and totals.
- **Stats** — Swift Charts: weekly distance (bars), distance by stroke (donut /
  `SectorMark`), pace-per-100 trend (line), lifetime totals, week streak, and a fun
  milestone ("X lengths of an Olympic pool").
- **Settings** — pool length, units, default rest & stroke, interval cue & haptics
  toggles, body weight (for calorie estimates), export, load sample data, reset, About,
  and Pro unlock/restore.

## Full feature list

- First-run onboarding gated by a persisted `hasOnboarded` flag.
- SwiftData persistence for all primary data (workouts, sets, sessions, completed sets);
  survives relaunch. `@AppStorage` only for small prefs/flags.
- Guided interval runner with a relaunch-safe wall-clock timer (`TimelineView` + stored
  start `Date`, re-anchored on `scenePhase`), per-rep split recording, send-off and fixed
  rest handling, automatic rest countdown + advance, and a save flow.
- Free-swim mode: open clock for an unstructured swim with a target distance.
- Built-in workouts: Endurance 2000m, Sprint 1500m, Technique 1200m, Mixed IM 1800m.
- Custom workout builder with reorder/delete, send-off **or** fixed-rest per set, effort,
  per-set notes, and live total distance.
- Pure, guarded engines: `SwimMath` (pace/100, SWOLF, calories, splits), `WorkoutMath`
  (totals, estimated duration), `StatsEngine` (period totals, distribution, trend, streak,
  milestones). Every division and array index is guarded.
- Distances are canonical in **meters** and converted to yards for display via a setting.
- Empty, loading, success, and recoverable error states throughout (including a calm
  `StoreUnavailableView` if the data store can't open — never a crash).
- Full accessibility: Dynamic Type via semantic fonts, `accessibilityLabel`/`Value`/`Hidden`
  on controls and charts, Reduce Motion fallbacks, WCAG-AA contrast in light **and** dark.
- Sparse haptics gated by a Settings toggle; interval cue toggle.
- Cohesive aquatic theme (pool-teal accent, lane-line motifs, crisp cards) applied across
  every screen, first-class in light and dark mode.
- Idempotent seed: 4 built-in workouts + 15 realistic past sessions (50+ completed sets)
  so stats and trends populate immediately.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Wake.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free signing:** set your Apple ID team in *Signing & Capabilities*; the bundle id is
`com.orbioom.wake`.

## Tech notes

- SwiftUI 5 / iOS 17 SDK only. `NavigationStack` throughout (no `NavigationView`).
- Primary data in **SwiftData**: `@Model` types `SwimWorkout`, `SwimSet`, `SwimSession`,
  `CompletedSet`, all registered in the app `Schema`, with `@Relationship(deleteRule: .cascade)`
  ordered children. Enums persist as their `rawValue` String and expose computed enum
  accessors.
- One observation pattern: the live runner is an `@Observable` `SwimRunner` held with
  `@State`/`@Bindable`; everything else uses `@Query` and `@AppStorage`. No
  `ObservableObject`/`@StateObject` mixing.
- Wall-clock timer pattern: elapsed and rest values derive from stored `Date` anchors and a
  `TimelineView`, reconciled on `scenePhase == .active`, so locking the phone or relaunching
  never loses the swim's place. `.onChange(of:)` uses the iOS 17 two-parameter form.
- Charts via `import Charts` (`BarMark`, `SectorMark`, `LineMark`, `PointMark`).
- Crash-proofing: no force-unwrap on user paths, no `try!`/`as!`/`fatalError`; a safe
  `Collection[safe:]` subscript; all math guards divide-by-zero and empty inputs.
- **Monetization:** one-time **$4.99** Wake Pro (simulated via `@AppStorage("isPro")`,
  StoreKit-ready in spirit) — unlocks the custom workout builder, pace-per-100 trends and
  SWOLF analysis, and unlimited saved workouts. The core app (built-in workouts, free-swim
  logging, distance/stroke stats) is fully usable for free.
- **Why it can boom:** swimmers are a passionate paying audience, and the incumbent
  (MySwimPro, ~$80/yr, Apple-Watch-centric) over-serves casual lap swimmers. Wake is a
  focused phone-first pool tracker — workout builder + interval timer + pace/SWOLF + trends
  — for one offline payment, no account, no watch.

## Self-review attestation

All **40** Swift files were re-read after writing. Verified:

- Every `@Model` (`SwimWorkout`, `SwimSet`, `SwimSession`, `CompletedSet`) is registered in
  the `Schema([...])` in `WakeApp.swift`.
- iOS-17-only APIs; `NavigationStack` everywhere (no `NavigationView`); no `@Previewable`.
- A single observation pattern (`@Observable` + `@State`/`@Bindable` for the runner;
  `@Query`/`@AppStorage` elsewhere) — no `ObservableObject`/`@StateObject` mixing.
- Both `.onChange(of:)` call sites use the two-parameter iOS 17 form.
- No `TODO`/`FIXME`/`placeholder`/`stub`/"coming soon"/"not implemented" anti-stub strings;
  no force-unwrap, `try!`, `as!`, or `fatalError` on user paths.
- All required imports present (`SwiftUI`, `SwiftData`, `Charts`, `Observation`, `UIKit`);
  braces balanced in every file; guarded math and a safe-index helper.
- Empty / loading / success / recoverable-error states present; full accessibility and
  light/dark theming applied across all screens.
