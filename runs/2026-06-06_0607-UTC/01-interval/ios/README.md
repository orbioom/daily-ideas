# Interval

An interval-timer **builder** for HIIT, mobility, and circuit workouts, by Orbioom.
Build a routine once — warm-up, rounds of work and rest, cooldown — and run it
hands-free with a calm, full-screen countdown.

## What it is

Interval models a real routine, not just a single countdown. A **Routine** owns an
ordered list of **Segments** (each a *prepare / work / rest / cooldown* kind, a duration,
an optional label, and optional repeat-group membership). A repeat group wraps consecutive
segments so they run as a unit — "8× (work 40s / rest 20s)". Running a routine drives a
**WorkoutEngine** that flattens the routine into a precise timeline and counts it down with
a large monospaced display, a progress ring, a next-up preview, haptic + sound cues, and a
screen that stays awake. Each completed (or ended) run is written to a **Session** log that
powers the History & Insights screen.

## Features

- **Routine Library** — every saved routine as a glass card with total time, work time,
  and step count. Empty-state designed for first use. Create, run, edit, or delete from a
  context menu.
- **Routine Builder** — reorderable segments (drag handles in edit mode), swipe-to-delete,
  per-segment editor (kind, label, duration with minute/second steppers and quick presets),
  and one-tap **repeat groups** with a shared repeat count. Live summary of total/work time
  and expanded step count. Glyph picker. Cancel discards cleanly (value-type drafts).
- **Run / Timer** — full-screen engine with optional count-in lead-in, big mono countdown,
  per-kind colour, progress ring, current + next segment, round indicator, and controls for
  **pause/resume, skip segment, and add 15s**. Auto-pauses on backgrounding. Keeps the
  screen awake (per setting). Writes a Session on completion or early stop.
- **Run summary** — active time, work time, and steps completed, with a completed/ended state.
- **History & Insights** — all-time runs, active/work totals, finish rate, runs this week,
  a current-day streak, and a reverse-chronological list of runs drilling into per-run detail.
- **Onboarding** — a calm one-screen intro shown once, gated by a persisted `hasLaunchedBefore`
  flag.
- **Settings** — count-in length (0–10s), keep-screen-awake, haptics, sound cues, and
  appearance (System/Light/Dark) — all persisted and each changing real behavior — plus a
  routine/run count read-out, reset-sample-routines, and delete-all-data paths.
- **Sample data** — six plausible starter routines seeded on first launch (Classic HIIT,
  Tabata, Morning Mobility, EMOM 10, Core Finisher, Seven Minute), resettable from Settings.

## Run steps

1. Open `Interval.xcodeproj` in **Xcode 15+**.
2. Pick an **iOS 17** simulator (or a device).
3. Press **Cmd+R**.

**Free signing:** the project builds with no paid Apple Developer account. If targeting a
physical device, select your personal team under *Signing & Capabilities* and Xcode will
manage a free provisioning profile. The bundle id is `com.orbioom.interval`.

## Tech notes

- **iOS 17+, SwiftUI 5, MVVM, no external dependencies.**
- **SwiftData** is the primary store for `Routine` / `Segment` / `Session` with cascade
  relationships (deleting a routine removes its segments and run history). `UserDefaults`
  holds only the onboarding flag and the settings preferences.
- **Timer engine:** a single `@MainActor @Observable WorkoutEngine` driven by an
  **absolute-`Date` scheduler** — each interval is given a wall-clock end date and progress
  is derived from `Date.now` rather than tick accumulation, so the countdown stays accurate
  across display stutter or brief backgrounding. The routine's repeat groups are pre-flattened
  into a `[TimelineStep]` timeline (pure value types — see `Utilities/Timeline.swift`).
  Pause/resume recompute remaining time from a fresh "now". `UIApplication.isIdleTimerDisabled`
  is set during a run when keep-awake is on.
- **Feedback:** purposeful haptics (`UINotificationFeedbackGenerator` / `UIImpactFeedbackGenerator`)
  and optional **system sounds** via `AudioServicesPlaySystemSound` — no bundled audio files,
  so nothing can be missing at runtime; sound respects the silent switch. All feedback is gated
  by the Settings toggles.
- **Orbioom design:** mist backgrounds (never pure white), `.ultraThinMaterial` glass surfaces,
  ink-gradient primary buttons, restrained green reserved for live/active/success, monospaced
  digits for countdowns, and slow `cubic-bezier(0.16, 1, 0.3, 1)` easing. Light and dark are
  both first-class; colours resolve per scheme in `Theme/Brand.swift`.
- **Accessibility:** Dynamic Type throughout; `accessibilityLabel`/`Hint`/`Value` on controls
  and rows; decorative images hidden; kind is conveyed by text + symbol, not colour alone;
  **Reduce Motion** fades the countdown ring instead of sweeping it.

## Self-review

- **Anti-stub grep is clean.** `grep -rniE 'todo|fixme|xxx|placeholder|lorem|coming soon|not
  implemented|// stub' Interval` returns no matches. Every control is wired to real behavior.
- **No unsafe user-path code.** No force-unwraps, `try!`, unguarded indices, or user-path
  division. The single `fatalError` is the documented last-resort SwiftData container guard in
  `IntervalApp.swift` (both persistent and in-memory stores failing is an unrecoverable
  environment fault), mirroring the reference app's proven pattern.
- **Compile + data-flow review passed.** Every file was re-read: imports verified; all types,
  initialisers, and modifiers exist in the iOS 17 SDK; `@State`/`@Bindable`/`@Environment`/
  `@Query`/`modelContainer` wiring type-checks; `NavigationStack` value-based navigation and
  `sheet`/`fullScreenCover` bindings are correct; no API newer than iOS 17 is used. The
  create → persist → relaunch → read path was traced by hand: a built routine and its runs are
  stored in SwiftData and reappear after relaunch; onboarding shows once; settings persist via
  `UserDefaults`.
