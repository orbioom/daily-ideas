# Strata

**A calm, premium climbing & bouldering logbook for iOS — by Orbioom.**

Strata is a native SwiftUI app for logging climbing sessions, tracking the climbs
and projects you're working on, and watching yourself progress through a real
relational model and a non-trivial grade-conversion engine.

> Conjured, not just coded.

---

## What it is

Log every session as an ordered list of attempts. Each attempt records an outcome
(flash / onsight / send / repeat / fall) against a climb or an ad-hoc grade. Climbs
carry a discipline, a canonical grade, a gym/crag location, an optional hold color
and set date, notes, and a project flag. Strata then computes a live **send
pyramid**, **flash/onsight rate**, **max grade sent / attempted**, **projects in
progress**, **volume**, and **month-by-month progression** — all from your real
attempts.

## Features

- **Sessions** (tab 1): reverse-chronological list with a summary header; log a new
  session (date, location, duration, notes); empty/first-run state with a call to action.
- **Session detail** (+ add attempt): header stats, ordered attempts, per-attempt
  delete, edit/delete the session, and a focal **Add attempt** flow that lets you
  pick an existing climb (grade inherited) or quick-log an ad-hoc grade by family.
- **Climbs / Projects** (tab 2): browse every climb with All / Projects / Sent
  filters; add/edit climbs (name optional, discipline, grade picker in your preferred
  system, location, hold color, set date, project flag, notes); climb detail shows the
  grade with **cross-system conversion** and full attempt history.
- **Insights** (tab 3): overview totals, a per-family (boulder/route) **send pyramid**,
  **flash/onsight rate**, **max send / max tried**, and a **hardest-send-by-month**
  progression chart (Swift Charts).
- **Settings** (tab 4): persisted preferences (below), **CSV/JSON export** of attempts
  and climbs, data counts, reset-to-sample, and clear-all.
- **Onboarding**: a calm single-screen first run, gated by a persisted flag.
- **Locations**: gyms and crags are managed entities, creatable inline from session
  and climb editors.

## The grade-conversion engine

`Utilities/GradeScale.swift` is a **pure, testable** engine. Every grade is stored
**canonically** as `(family, index)` — a position on a single ordered ladder shared
by both systems in that family — so analytics can sort and aggregate trivially while
display renders in whichever system you prefer:

- **Boulders:** V-scale (V0–V17) ↔ Fontainebleau (4 … 9A), aligned rung-for-rung.
- **Routes:** YDS (5.6–5.15d) ↔ French sport (4c … 9c+), aligned rung-for-rung.

The engine never crashes on bad input: parsing an unknown string returns `nil`,
rendering an out-of-range index returns `nil` (handled gracefully in the UI as "—"),
and `clampedIndex` snaps arbitrary values into bounds. It exposes `convert`,
`compare`, `nearest`, parse, and display. You pick your preferred display system per
family in Settings; stored data is untouched when you switch.

## Persisted preferences (each changes behavior)

- **Appearance** — System / Light / Dark.
- **Boulder grade display** — V-Scale or Font.
- **Route grade display** — YDS or French.
- **Default discipline** — preselected for new climbs.
- **Default location** — preselected for new sessions and climbs.
- **Haptic feedback** — gates all haptics.

## Run steps

1. Open `ios/Strata.xcodeproj` in Xcode 15+ (iOS 17 SDK).
2. Select an iOS 17 simulator (e.g. iPhone 15).
3. Build & run (⌘R).

### Free-signing note

The project builds with a free Apple ID. In **Signing & Capabilities**, pick your
Personal Team; Xcode manages a development signing certificate automatically. The
bundle id is `com.orbioom.strata` — change it if it collides with an existing
profile on your account.

## Tech notes

- **SwiftUI + SwiftData**, MVVM-leaning. `@Model` types: `Location`, `Climb`,
  `Session`, `Attempt`. Sessions cascade-delete their attempts; attempts snapshot a
  canonical grade so a deleted climb never corrupts history.
- **Persistence:** SwiftData for all records; **UserDefaults only** for flags/prefs
  (`SettingsStore`). The model container falls back to in-memory if the on-disk store
  is unavailable, so the app always launches.
- **Analytics** (`Utilities/Analytics.swift`) and the **grade engine** are pure and
  free of SwiftUI/SwiftData — easy to reason about and test.
- **Design:** Orbioom mist backgrounds (never pure white), `.ultraThinMaterial`
  glass, ink-gradient primary buttons, restrained green for sends only, SF Pro with
  monospaced digits for grades/counts. Slow, purposeful motion that honors Reduce
  Motion. Light and dark are both first-class.
- **Accessibility:** Dynamic Type throughout; grades and outcomes are conveyed with
  **text + icon, never color alone**; VoiceOver labels on rows, stats, the pyramid,
  and the progression chart; decorative imagery hidden.
- **Export:** CSV (attempts and climbs) and a complete JSON archive via the system
  file exporter; grades render in your preferred systems.
- **Seed data:** ~6 sessions across ~2.5 months with 20+ attempts, 10 climbs (with
  several projects), and 4 locations — so the pyramid and progression are alive on
  first launch. Reset/clear paths in Settings.

## Self-review

- **Anti-stub grep is clean.** `grep -rniE 'todo|fixme|xxx|placeholder|lorem|coming
  soon|not implemented|// stub' Strata` returns nothing.
- **No unsafe constructs on user paths:** no force-unwrap, `try!`, `as!`, or
  `fatalError` in the codebase. Grade lookups use bounds-checked `indices.contains`
  / `clampedIndex`; rate computations guard against division by zero; the one
  unreachable last-resort container path uses `preconditionFailure` only after two
  successful-by-construction fallbacks.
- **Compile / data-flow review passed:** verified imports (`SwiftUI`, `SwiftData`,
  `Charts`, `UniformTypeIdentifiers`), iOS-17 APIs only, `@Model` relationship
  inverses declared on exactly one side, `@Query`/`modelContainer`/`@Bindable`
  wiring, `NavigationStack` + `navigationDestination` + sheet bindings, and the full
  create → persist → relaunch → read path for sessions, attempts, climbs, and
  locations. `#Preview` blocks use in-memory model containers.
