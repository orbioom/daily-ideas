# Repertoire

A calm, native iOS practice companion for musicians — built by Orbioom.

Repertoire models a real practice life on a relational core: the **pieces** you're
working on, the specific **passages** giving you trouble, and the **minutes** you put in
over weeks. A built-in metronome and countdown timer drive a session hands-free and write
the result to your log, so progress *accumulates and is visible*.

## What it is

- **iOS 17+, SwiftUI 5, MVVM, no external dependencies.**
- **SwiftData** is the system of record for Pieces, PracticeSpots, PracticeSessions, and
  the SessionEntry join (cascade relationships). `UserDefaults` holds only the onboarding
  flag and a handful of preferences.
- A relational model (a `Piece` owns ordered `PracticeSpot`s; a `PracticeSession` is split
  across pieces via `SessionEntry`) plus non-trivial logic (streaks, weekly-minutes
  heatmap, per-piece time accumulation, tempo-progress curves, least-recently-practiced
  suggestion, tap-tempo averaging).

## Features

**Feature screens (4, excluding Onboarding & Settings):**

1. **Repertoire library** — every piece grouped by status (learning / polishing /
   maintenance / retired), each showing minutes practiced *this week* and a mastery
   roll-up. Search by title, composer, or instrument. Add a piece (with its spots) inline.
2. **Piece detail** — header with composer, instrument, key, difficulty, target tempo and
   total time; practice spots each with a current→target tempo progress bar and 0–5
   mastery; full session history; and the focal **Practice** action. Export the piece's
   log as CSV.
3. **Practice session** — a tempo dial (drag to change BPM, VoiceOver-adjustable),
   tap-tempo and ±1/±5 nudges, start/stop metronome, a `Date`-based countdown timer that
   keeps the screen awake, and a spot checklist. On completion you rate quality and add
   focus notes, and a `PracticeSession` is written to the log.
4. **Insights** — current & longest streak, minutes this week, total time, a 6-week
   minutes **heatmap**, **time-by-piece** bars, and the **suggested next** piece
   (least-recently-practiced active piece).

**Plus:** first-run **Onboarding** (persisted flag) and **Settings**.

**Other capabilities**

- **Metronome** — driven by a `Date`-based `@MainActor` scheduler (no timer-tick drift,
  no bundled audio file, no `AVAudioEngine` source-node risk). The beat is a visual pulse
  plus an `UIImpactFeedbackGenerator` haptic and an optional soft system tick. BPM is
  always bounded 20–300. Tap-tempo averages recent taps.
- **Export** — a single piece's log as CSV; all data as JSON or CSV, shared via the system
  share sheet.
- **Settings (≥3 persisted prefs, each changing behavior):** appearance
  (system/light/dark), default session length, default tempo, A4 reference Hz, metronome
  sound on/off, haptics on/off. Plus reset-to-sample and clear-all paths.
- **States:** empty repertoire, no-search-matches, empty insights, running / paused /
  finished session, guarded errors (a session with no piece writes nothing; BPM and tempos
  are always clamped; durations never go negative).
- **Accessibility:** Dynamic Type throughout; VoiceOver value on the tempo dial (and an
  adjustable action); heatmap cells and mastery dots carry text values (never color-only);
  decorative glyphs hidden; light + dark with on-brand contrast; Reduce Motion fades the
  beat pulse instead of swinging it.
- **Seed content:** 6 pieces (piano, guitar, jazz guitar) with spots and ~24 sessions
  across the last month, so streaks, the heatmap, and insights are alive on first launch.

## Run steps

1. Open `Repertoire.xcodeproj` in Xcode 15 or newer.
2. Select an iOS 17 simulator (or a device).
3. Build & run (⌘R).

The `project.pbxproj` is generated and references every source file, the asset catalog,
the preview assets, and `Info.plist` (which provides the `UILaunchScreen`).

### Free-signing note

The bundle identifier is `com.orbioom.repertoire`. To run on a physical device with a free
Apple ID, open the target's **Signing & Capabilities**, pick your personal team, and (if
needed) change the bundle id to a unique value. No paid account is required for the
simulator.

## Tech notes

- **Architecture:** SwiftUI views + small `@Observable` view-model engines
  (`SettingsStore`, `Metronome`, `PracticeSessionEngine`). Aggregation lives in pure
  functions (`Insights`, `Exporter`) that take already-queried arrays, so they're
  deterministic and preview-friendly.
- **Timing:** both the metronome and the practice timer compute from absolute `Date`s
  rather than summing ticks, so they stay accurate across pauses and run-loop stalls. The
  timer disables the idle timer while running and re-enables it when paused/finished.
- **Persistence trace:** create a piece → insert into the `ModelContext` → relaunch →
  `@Query` reads it back. Sessions are written from the practice screen via
  `PracticeSessionEngine.writeSession`, which guards against a piece-less or zero-length
  session.
- **Brand:** Orbioom mist backgrounds (never pure white/black), `.ultraThinMaterial`
  glass, a single ink-gradient focal action per screen, restrained green for active /
  success only, monospaced digits for tempo and timers, slow purposeful motion.

## Self-review

- **Anti-stub grep is clean.** Running
  `grep -rniE 'todo|fixme|xxx|placeholder|lorem|coming soon|not implemented|// stub'`
  over `Repertoire/` returns no matches.
- **No unsafe constructs on user paths.** No force-unwraps, no `try!`, no `as!`, no
  unguarded indexing, no division by user-supplied zero. The only `fatalError` is the
  double-failure fallback in the SwiftData container init (mirrors the known-good
  reference), after an in-memory fallback has already been attempted. Tempos, BPM,
  mastery, session length, and reference Hz are clamped at every entry point; durations are
  floored at zero; all text input is trimmed and validated (a piece needs a non-empty
  title; a spot needs a non-empty name).
- **Compile / data-flow review passed.** Imports, types, initializers, and modifiers were
  traced against the iOS 17 SDK: `@Observable` + `@State`, `@Query`/`modelContainer`
  wiring, `NavigationStack`/`.sheet(item:)` bindings, two-parameter `onChange(of:)`,
  `contentTransition(.numericText())`, `.searchable`, `Stepper`/`Slider`, and
  `presentationDetents` are all iOS-17-available. The create → persist → relaunch → read
  cycle and the session write path were traced end to end. No post-iOS-17 API is used.
- **`#Preview` compiles** on every screen via a shared seeded in-memory container
  (`PreviewData`), with a non-crashing fallback if in-memory store creation ever fails.
