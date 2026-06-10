# Lattice — Sudoku, done right

**One line:** Clean, fast, ad-free Sudoku with an on-device unique-solution generator, four difficulties, a daily challenge, and real stats.

**Problem & audience:** Sudoku is evergreen and enormously lucrative — Sudoku.com grosses heavily on ads and hints. But the popular apps are buried in banner ads, interstitials between puzzles, and energy/hint paywalls. Lattice is for the huge audience of daily Sudoku players who just want a beautiful, distraction-free board.

## Features

- **Play** — Continue your in-progress game, or start a new one in Easy / Medium / Hard / Expert. Each puzzle is generated fresh on-device with a **guaranteed single solution**.
- **Board** — 9×9 grid with selection, peer + matching-number highlighting, conflict marking, pencil **notes** (with auto-removal), erase, **hint**, **undo**, a mistake counter (optional 3-strike mode), a running timer, pause, and a win/lose flow.
- **Daily** — a deterministic daily challenge (identical for everyone that day) on a real month calendar with completion marks and a daily streak.
- **Stats** — overall solved/played/win-rate, a solved-by-difficulty chart, and per-difficulty best & average times.
- **Settings** — highlight conflicts, highlight matching numbers, auto-remove notes, show remaining counts, 3-mistake limit, theme, haptics.
- Onboarding gated by a flag; loading state while a puzzle is crafted; empty states; full Dynamic Type, VoiceOver cell labels, Reduce-Motion-aware animation.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Lattice.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

Free-signing: set your Team in Signing & Capabilities; bundle id `com.orbioom.lattice`.

## Tech notes

- iOS 17+, SwiftUI 5, pure `SudokuEngine`: randomized backtracking full-grid fill, MRV solver, **uniqueness-preserving** cell removal (`countSolutions` capped at 2), seeded daily puzzles via SplitMix64, conflict/peer math. Generation runs off-main with a loading overlay.
- Persistence: **SwiftData** (`SavedGame` with 81-cell arrays + note bitmasks, per-difficulty `GameStats`, unique `DailyResult`). Survives relaunch mid-game.
- Design language: **Orbioom**.
- **Monetization:** freemium — free unlimited play; an optional one-time "Lattice Plus" removes the (tasteful, optional) hint cap and adds themes/stat exports. No forced ads ever.
- **Why it can boom:** a proven, evergreen money-maker whose leaders are ad-choked and hated; a clean, fair, beautiful Sudoku with a real generator is the version players wish existed.

## Self-review

Read every file against the iOS 17 SDK: the engine is force-unwrap-free; `NavigationStack(path:)`/`navigationDestination(for: SavedGame.self)`, `@Bindable`, `Timer.publish`, `@Query`, and Charts type-check. No stubs/TODOs; no `try!`/`fatalError` on user paths beyond the in-memory container fallback. `project.yml` is valid and names the real `Lattice` sources and `Info.plist`.
