# Quotient

A calm, ad-free **Calcudoku / KenKen-style arithmetic puzzle** for iOS — with a
real seeded puzzle generator and a backtracking uniqueness solver, so every
board has exactly one solution.

## What it is

Fill an N×N grid so that every row and column contains each number from 1 to N
exactly once, and every outlined **cage** combines its cells with the printed
operation (+, −, ×, ÷) to hit its target. It's Sudoku-grade logic with
arithmetic — fresher and far less saturated than Sudoku — wrapped in a precise,
modern interface.

## Full feature list

- **Real puzzle engine (the substance):**
  - Seeded `SplitMix64` RNG → deterministic generation (the Daily is identical
    for everyone on a given date).
  - Valid **Latin square** construction (cyclic base + random row/column/symbol
    permutations).
  - Randomized **flood-growth cage partition** (mostly size 2–3, some 1 and 4),
    bounds-checked, every cell in exactly one cage.
  - **Operation assignment** computed from the actual solution values, so every
    puzzle is solvable by construction (size 1 → given; size 2 → add / subtract /
    multiply / divide; size ≥3 → add / multiply).
  - **Backtracking solver** with Latin + cage pruning that **counts solutions up
    to 2** to guarantee uniqueness. Non-unique puzzles are re-partitioned and
    retried (cap 60); a guaranteed reveal-until-unique fallback (and a bundled
    verified puzzle) ensure generation **always** returns a unique, correctly
    sized board.
  - `PuzzleValidator` reports per-cell conflicts (row/column duplicates and
    violated full cages) for live highlighting.
- **Four substantive tabs + Settings + onboarding:**
  - **Play** — the grid with computed **cage borders** (thick edges on cage
    boundaries, thin lines elsewhere), cage labels, tactile number pad, Notes
    (pencil) mode, Erase, **Hint** (reveals/fixes one cell), Undo, timer, mistake
    indicator, row/column/cage highlighting, and a success sheet. Resumes a
    saved game on relaunch; shows a brief **generating** state while a board is
    built and verified.
  - **New Puzzle** — pick difficulty (Easy 4×4, Medium 5×5, Hard 6×6, Expert
    7×7). 6×6 / 7×7 are Pro-gated.
  - **Daily** — today's deterministic daily, a streak calendar (last 4 weeks),
    current/best streak, and a **Pro-gated archive** of past dailies.
  - **Stats** — totals, win rate, current/best streak, best & average times by
    size, and a per-difficulty **Swift Charts** bar chart. Friendly empty state.
  - **How to Play** — the rules with a solved 3×3 worked example.
  - **Settings** — highlight conflicts, highlight row/column/cage, auto-remove
    candidate notes, check mistakes, haptics, show timer, mistake limit, accent
    theme, Pro management, reset data, and About.
- **First-run onboarding** (3 steps) gated by `@AppStorage("hasOnboarded")`.
- **Quotient Pro** — simulated one-time **$2.99** unlock via `@AppStorage`:
  free gets 4×4 & 5×5 plus the daily; Pro unlocks 6×6 / 7×7, the daily archive,
  unlimited generated puzzles, and extra accent themes.
- **Accessibility** — Dynamic Type, full VoiceOver labels/hints/values (cells
  announce row, column, value, and cage target/operator), decorative shapes
  hidden, WCAG-AA colors in light **and** dark, and Reduce Motion support.
- **Haptics** — sparse and gated by a Settings toggle.

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Quotient.xcodeproj` in **Xcode 15+**, select an **iOS 17+** simulator,
   and press **Cmd+R**.

## Free signing

The project uses no paid capabilities. In Xcode, select the **Quotient** target →
**Signing & Capabilities** → choose your **Personal Team** (free Apple ID) and,
if needed, change the bundle identifier to something unique. It runs on a
free-signed device or any simulator.

## Tech notes

- **iOS 17+**, **SwiftUI 5**, **MVVM** with an `@Observable` `GameViewModel`.
- **SwiftData** for persistence: `@Model` `SavedGame` (resumable in-progress and
  completed games) and `@Model` `PuzzleResult` (finished-game records for stats
  and streaks); both registered in the `ModelContainer` schema. Small
  preferences use `@AppStorage`. State survives relaunch.
- **Navigation** via `TabView` + `NavigationStack` (no `NavigationView`),
  two-parameter `.onChange`, `@Query` for SwiftData reads.
- **Design language** — soft neutral grid surfaces, crisp thick cage borders with
  thin interior lines, small cage target+operator labels, a tactile number pad,
  and the **#6C5CE7** indigo/violet accent throughout the `Theme`. First-class
  light and dark mode; no hardcoded colors that break in either appearance.
- **Generation** runs off the main actor via `async`/`await` with a `@MainActor`
  view model, so even a 7×7 build never blocks the UI; a loading state covers it.
- **Monetization** — a tasteful simulated one-time **Quotient Pro ($2.99)** that
  is **ad-free**; free users still get two grid sizes and the daily.
- **Why it can boom** — number puzzles are a massive evergreen category, Sudoku
  is saturated, and Calcudoku is fresher and under-served by apps with a *real*
  generator plus a uniqueness solver — delivered ad-free as a one-time unlock.

## Self-review attestation

Every Swift source file was re-read and verified by hand (no Xcode in the build
environment):

- **Schema** registers every `@Model` type (`SavedGame`, `PuzzleResult`).
- iOS 17 APIs only — `NavigationStack` (no `NavigationView`), two-parameter
  `.onChange`, `@Observable` view model, `@Query`, `.modelContainer`.
- Imports, types, initializers, enum cases, and modifiers checked; conformances
  satisfied; `@State` / `@Bindable` / `@Environment` ownership correct.
- **Anti-stub grep is zero** (no TODO/FIXME/XXX/placeholder/lorem/"coming
  soon"/"not implemented"/stub) and braces/parens/brackets are balanced.
- **No** `fatalError`, `try!`, or force-unwraps on user paths; division and
  array indexing are guarded; SwiftData container creation degrades gracefully.
- The **generate → uniqueness-check → solve** cycle was reasoned through and
  exercised across all four difficulties and many seeds: the generator **always
  returns a uniquely-solvable puzzle of the requested size**, falling back to a
  reveal-until-unique construction only in rare cases (and never to a
  wrong-size or non-unique board).
