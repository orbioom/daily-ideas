# Glyph — Clean Sudoku

Every-board-is-fair Sudoku: an on-device generator with a guaranteed-unique solution, four difficulties, pencil notes that auto-clean, conflict highlighting, and hints that teach the technique instead of just handing you the answer. The antidote to ad-buried Sudoku clones with sloppy generation and useless hints.

## What it is
- **One-line:** A calm, ad-free Sudoku with a real generator, smart hints, and a daily puzzle.
- **Problem + audience:** Sudoku is a perennial top puzzle category, but most apps bury players in ads, ship sloppily-generated (sometimes non-unique) boards, and give hints that teach nothing. Glyph targets the same massive audience with a guaranteed-unique generator and teaching hints (the qualities reviewers praise in premium picks like "Good Sudoku").

## Full feature list
- **Generator + solver:** randomized backtracking solution, clue removal that re-verifies uniqueness (solution count capped at 2) for every removed cell, MRV-ordered solving for speed. Four difficulties by target clue count (Easy 40 → Expert 24). Generation runs off the main thread with a loading state.
- **Play:** 9×9 board with selection, peer/row/column/box highlighting, same-value highlighting, and red conflict flagging; a number pad showing remaining count per digit; **pencil notes** with auto-removal from peers when you place a value; undo stack; erase; **logical hint** (finds a naked/hidden single and reveals it); auto-notes fill.
- **Timer & state:** live timer with pause (board blurs), mistake counter, remaining-cells count; the full game (grid, notes, timer, mistakes) persists and resumes after relaunch; win overlay with time/mistakes/hints and a flawless badge.
- **Daily:** one deterministic puzzle per day (difficulty rotates by weekday), continue/review, and a recent-dailies list.
- **Stats:** solved count, day streak, best/average time and win rate per difficulty.
- **Settings:** highlight-conflicts and auto-remove-notes toggles (both actually change gameplay), appearance, haptics, clear-finished-puzzles.
- Onboarding gated by a persisted flag; empty/loading/win states throughout.

## Run steps
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Glyph.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

## Free-signing note
No paid account needed: select your personal team under Signing & Capabilities and run on a simulator or your own device.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM with a pure `SudokuEngine` (uniqueness-checked generation, backtracking solve, human-technique hint finder, candidate computation) and a seeded RNG for reproducible daily puzzles. `GameSession` is an `@Observable` controller.
- Persistence: **SwiftData** (`SudokuGame`, grids encoded as 81-char strings, notes as bitmask CSV) survives relaunch; `@AppStorage` for prefs.
- Design language: **Orbioom**, per-difficulty tints.
- **Monetization:** freemium — unlimited play, daily, and stats free; a one-time "Glyph Plus" (advanced solving techniques in hints, extra-hard/16×16 packs, themes) is the upsell. No ads in the free tier — the whole point.
- **Why it can boom:** Sudoku is a proven, evergreen top-charts category; incumbents are despised for ad overload and sloppy generation, while the loved ones are paid-only. A clean, free, teaches-you-hints generator hits the sweet spot.

## Self-review
Re-read every Swift file: imports verified; all SwiftUI/SwiftData symbols exist in iOS 17; generator/solver are pure and terminate (uniqueness cap, MRV); `@Observable`/`@State`/`@Query`/`navigationDestination(item:)`/`modelContainer` wiring type-checks; no force-unwraps/`try!`/`fatalError` on user paths (container falls back to in-memory); `Array[safe:]` defined once. Anti-stub grep clean. Dynamic Type, per-cell accessibility, Reduce Motion, light/dark handled.
