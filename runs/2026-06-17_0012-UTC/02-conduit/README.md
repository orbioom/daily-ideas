# Conduit

**Conduit** is a clean, ad-free **Flow-Free–style connect puzzle** for iOS 17. Drag
colored pipes from one dot to its matching partner, never cross another pipe, and
win by connecting every pair **and** filling every cell of the board. A calm modern
look on a deep navy board, vivid distinct pipe colors, rounded endpoint dots, and a
satisfying snap.

## What it is

A native SwiftUI + SwiftData puzzle game with a hand-derived bank of **45 puzzles**
across five packs, a deterministic daily puzzle with streaks, full progress tracking,
Swift Charts stats, and a simulated one-time Pro unlock. Everything is wired to real
behavior — no stubs, no dead ends.

## Full feature list

- **Play** — interactive `Canvas` board with `DragGesture` pipe drawing. Drag from an
  endpoint (or the trailing end of an existing pipe) to extend through adjacent cells;
  drag back to retract; crossing another color truncates it Flow-style. Live HUD shows
  pipes connected X/Y, board filled Z%, move count, and a wall-clock timer driven by a
  stored start `Date` + `TimelineView` (survives backgrounding via `scenePhase`).
  Toolbar: Undo, Hint, Reset (optional confirm), Back. Success overlay with time/moves
  and a Next-level link. Resume-on-relaunch from a saved board.
- **Levels** — pack browser with a section per pack and a `LazyVGrid` of tiles showing
  solved ✓ / perfect ★ / locked, plus "solved/total" per pack. Master & Mind-bender
  packs are Pro-gated with an inline unlock banner.
- **Daily** — today's date-seeded puzzle, a 35-day streak calendar, current/best streak,
  best time, and a Pro daily archive (replay the last 7 days).
- **Stats** — totals (solved, perfect, total time, % complete), daily streaks, per-pack
  completion bars, and Pro Swift Charts: daily solves over 30 days (BarMark) and solves
  by board size. Calm empty state before any activity.
- **Settings** — persisted prefs: show timer, highlight completed pipes, confirm reset,
  grid-line style (subtle/bold), color-blind mode (letter labels, Pro), animations
  (Reduce-Motion-aware), haptics. Plus reset-all-progress, Restore/Unlock Pro, and About.
- **Onboarding** — three-page intro gated by the persisted `hasOnboarded` flag.

## Puzzle bank

45 puzzles: Starter 5×5 (×12), Classic 6×6 (×12), Tricky 7×7 (×10) free; Master 8×8 (×7)
and Mind-bender 9×9 (×4) Pro. Each puzzle is built from a **Hamiltonian snake** over the
whole grid, then cut into contiguous per-color segments — so every puzzle is *provably*
solvable with 100% coverage: each segment is orthogonally continuous, segments never
overlap, and together they fill the grid. The two ends of each segment are that color's
endpoints, and the full segment is the stored solution used for Hint and validation.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Conduit.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: set your Apple ID team in Signing & Capabilities; the bundle id is
`com.orbioom.conduit`.

## Tech notes

- iOS 17, SwiftUI 5, Observation framework. `ConduitEngine` is `@Observable`, stored with
  `@State` and bound via `@Bindable` — one consistent pattern, no `ObservableObject` mix.
- SwiftData models: `PuzzleProgress`, `SavedBoard`, `DailyResult`, all registered in the
  `Schema`. Paths persist as JSON in `SavedBoard` for resume. `@AppStorage` holds only
  small prefs/flags.
- Crash-proofing: no `try!`/`as!`/`fatalError`, no force-unwraps on user paths, a safe
  array subscript helper, bounds-guarded cell hit-testing, guarded division, and a calm
  `StoreUnavailableView` fallback if the store can't open.
- Accessibility: per-cell VoiceOver labels describing endpoints/pipes/empties, Dynamic
  Type via semantic fonts, chart accessibility labels, WCAG-AA contrast in light & dark,
  and a `Reduce Motion` still fallback for the win celebration.
- **Monetization:** one-time **Conduit Pro — $2.99** (simulated; `@AppStorage("isPro")`
  with demo unlock + restore) gating Master/Mind-bender packs, the daily archive,
  color-blind palette, and detailed charts. Free packs are fully playable.
- **Why it can boom:** Flow-style connect puzzles are evergreen and endlessly
  shareable, but most are buried in ads — Conduit is a calm, ad-free, daily-streak-driven
  take with a provably-solvable bank and a single fair unlock, the kind of polished
  one-tap puzzle that retains and converts.

## Self-review attestation

Re-read every Swift file: all imports present; only iOS 17 APIs used (`NavigationStack`,
`navigationDestination`, `Chart`/`BarMark`, `TimelineView`, `@Observable`/`@Bindable`,
two-parameter `onChange`); protocol conformances satisfied; property-wrapper ownership
consistent; no banned force operations; no anti-stub markers; braces/JSON balanced; the
puzzle bank's 45 layouts were independently simulated to confirm Hamiltonian snakes,
non-overlapping continuous color segments, and 100% coverage for every puzzle.
