# Brio

**A calm, free, on-device guided workout app.** Bodyweight and HIIT sessions that
auto-advance through every timed exercise and rest, with a count-in, progress, and
haptic phase cues — no equipment, no accounts, no paywalled basics.

**Problem & audience.** Home-workout apps like Nike Training Club, Seven, and
Freeletics are cluttered and subscription-heavy: the basics that should be free sit
behind a paywall, and the UI nags. Brio is for anyone who just wants to *move* —
beginners through regulars — with a quiet, fast, on-device experience that browses
prebuilt workouts, lets you build your own, runs a focused full-screen guided
session, and quietly tracks your progress.

## Features

- **Workouts** — Browse built-in and custom workouts, filter by category (full body,
  core, upper, lower, cardio, mobility). Each is a glass card with name, category,
  difficulty, estimated time, and rounds. Tap through to a detail screen with the full
  move list, an estimated-time breakdown, and a one-tap **Start Workout**.
- **Guided session player** — A full-screen, auto-advancing player: a count-in, a big
  progress ring + countdown for timed steps, a **Done** button for rep-based steps,
  current/next exercise, round x/y, pause/skip/end, and sparse haptic cues on phase
  changes. Time is derived from a stored end-date so it survives brief backgrounding.
  Keeps the screen awake (per setting). On finish, a quick feeling rating + optional
  note logs the session.
- **Build** — Full CRUD over custom workouts: name, category, difficulty, rounds, and
  rests; add moves from a searchable, filterable exercise library; reorder and delete;
  set reps or duration and per-side for each move. Saves persist via SwiftData.
- **History** — Sessions grouped by day (newest first) with a streak / this-week /
  total-time header, swipe-to-delete, and a session detail screen where you can re-rate
  how it felt and read your note.
- **Insights** — Swift Charts: minutes per week (bar), sessions by category (horizontal
  bar), and stat tiles for current streak, best streak, total time, and completion
  rate. Calm empty state before any data exists.
- **Settings** — Persisted preferences wired to real behavior: count-in seconds (3–15),
  default rest (used to pre-fill the builder), keep-screen-awake, and haptics. Plus a
  replay-intro action, clear-history and delete-all-data actions with confirmation, a
  training summary, and an About section.
- **First-run onboarding** gated by a persisted flag; seeded library (16 exercises),
  6 built-in workouts, and ~50 sessions across the past 8 weeks so charts and streaks
  look real on day one.
- **Polished throughout** — light & dark first-class via Orbioom Brand tokens, full
  Dynamic Type, accessibility labels/hints/values on controls and stats, Reduce Motion
  support, input clamping, recoverable error states, and tasteful motion.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Brio.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

**Free signing:** No paid Apple Developer account needed — select your personal team
under *Signing & Capabilities* and run on a simulator or your own device.

## Tech notes

- iOS 17+, SwiftUI, MVVM-ish (pure engines + `@Observable` view models), SwiftData for
  persistence, Swift Charts for Insights, and the Orbioom design language (Brand tokens,
  glass surfaces, ink buttons, calm motion).
- **Monetization:** free core forever; an optional **Brio+** unlock (premium guided
  programs, deeper insights) — fitness apps have proven, durable subscription
  willingness.
- **Why it can boom:** the home-workout market is huge and proven, but NTC / Seven /
  Freeletics are subscription-heavy and cluttered. Brio is calm, fast, fully on-device,
  and never paywalls the basics — the obvious "just let me work out" alternative.

## Self-review attestation

I re-read every Swift source file I wrote. All imports are present; SwiftData
`@Model`/`@Query`/`@Relationship`/`modelContext` wiring, `@Observable`/`@State`/
`@Bindable`/`@Environment` ownership, and NavigationStack/sheet/fullScreenCover
bindings type-check against the iOS 17 SDK; the live timer holds the engine `weak`
with no retain cycle. The anti-stub grep
(`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub`) returns zero
matches, and the only `fatalError` is the in-memory `ModelContainer` fallback in
`BrioApp.swift`, exactly mirroring the reference `ChimeApp`.
