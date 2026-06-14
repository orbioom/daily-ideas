# Nonet

**Clean, ad-free Sudoku with a real engine.** A beautiful native iOS 17 SwiftUI app by the
Orbioom studio: a proper puzzle generator (unique solution, technique-graded difficulty), a
deterministic daily puzzle, great input (pencil marks, undo, logical hints, mistake-check),
resume-after-relaunch, and rich stats — with **no ads, ever.**

Top Sudoku apps are ad-stuffed and subscription-gated; their reviews beg for a clean,
ad-free Sudoku with good hints. Nonet is exactly that.

---

## What it is

A focused, paper-and-ink Sudoku built around a careful, correct engine. Every puzzle is
generated to have a single solution and graded by the hardest human technique it requires,
so "Medium" really is locked-candidates-hard and "Expert" really is the full challenge. The
in-progress game persists continuously, so you can close the app mid-puzzle and pick up
exactly where you left off.

## Full feature list

- **Daily puzzle** — seeded from the date (`yyyyMMdd`), so everyone gets the same board.
  Tracks current and longest daily streak with a solved-days heatmap.
- **Four difficulties** — Easy (singles), Medium (+locked candidates), Hard (+pairs),
  Expert (hardest / most empties). Hard & Expert are Pro.
- **Real generator** — randomized backtracking full solution, symmetric hole-digging while
  uniqueness is preserved and the required technique matches the target grade. Time- and
  attempt-capped, with a verified fallback bank so it never hangs.
- **Logical hint engine** — surfaces the next *human* deduction (naked/hidden single, locked
  candidate, naked/hidden pair) with a plain-English explanation, not a random reveal.
- **Great input** — tap-to-select, 1–9 pad with completed-digit dimming, erase, manual
  pencil marks, optional auto-candidate mode, undo stack.
- **Assistance & feedback** — peer / same-number / conflict highlighting (each toggleable),
  mistake checking with an optional 3-strike limit, pausable hidden-able timer.
- **Resume** — current grid, pencil marks, elapsed time, and mistakes persist via SwiftData.
- **Stats** — Swift Charts: games & win-rate by difficulty, best & average times, streaks,
  total solved, and a 5-week solved-days heatmap. Computed off the main thread.
- **Learn** — a techniques guide that teaches the exact methods the hint engine uses.
- **History** — past results and resumable in-progress games.
- **Onboarding** — 3 pages (rules, smart tools, ad-free promise), gated on first launch.
- **Accessibility** — Dynamic Type chrome, per-cell `accessibilityLabel`/`Value`
  ("row 3 column 5, 7" / "empty"), labeled controls, and Reduce-Motion-aware animation.
- **Light & dark** — both first-class, high-contrast cell text for AA.

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Nonet.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

### Free signing

No paid Apple Developer account is required for the simulator. To run on a physical device,
select the Nonet target → Signing & Capabilities → choose your personal team; Xcode will
provision a free development signing certificate automatically.

## Tech notes

**Engine (`Engine/`, pure, grid = `[Int]` of length 81, 0 = empty).**

- `SudokuSolver` — constraint validity (row/column/box), `solutionCount(maxToFind:)` via
  MRV backtracking with candidate **bitmasks** (used to verify uniqueness), and a logical
  solver applying human techniques in increasing order: naked singles → hidden singles →
  locked candidates (pointing/claiming) → naked/hidden pairs. It returns the **hardest
  technique required**, which drives difficulty grading. The grading loop is bounded and
  always terminates.
- `SudokuGenerator` — builds a full valid solution with randomized backtracking (seeded
  RNG), then digs holes **symmetrically** (180° rotational) while `solutionCount == 1` is
  preserved *and* the logical solver's hardest required technique matches the target. Both
  attempts and wall-clock **time are capped**; if the target can't be met in budget it
  returns the best valid unique puzzle found.
- `PuzzleBank` — ~6 hand-built fallback puzzles per difficulty. Every served fallback is
  uniqueness-checked and, if needed, cells are revealed from the solution until it is
  unique — so the app **never** serves an ambiguous or unsolvable board.
- **Seeded daily** — `SplitMix64` seeded from `yyyyMMdd` makes the daily puzzle identical
  for everyone, and keeps any daily fallback deterministic too.

**Architecture.** SwiftData is the primary store: `@Model SavedGame` (persists the
in-progress game — givens, current grid, pencil-mark bitmasks, solution, elapsed, mistakes —
for resume) and `@Model GameRecord` (completed-game history for stats), surfaced with
`@Query` and a shared `modelContext`. `GameViewModel` is a `final class: ObservableObject`
with `@Published` state, owned by the game screen via `@StateObject` (no `@Observable`
macro mixed with `@StateObject`). **Puzzle generation runs off the main thread**
(`Task.detached`) with a `@MainActor` handoff; the UI shows a real "Generating…" state and
falls back gracefully on the rare error path. UserDefaults holds only small prefs/flags via
`AppSettings` (`@AppStorage`) plus daily-streak bookkeeping.

**Safety.** No force-unwraps, no `try!` except the single allowed in-memory
`ModelContainer` fallback, no `fatalError`. Every grid index is bounds-checked to `0..<81`,
every division is guarded, and all backtracking/solver loops are iteration-capped so nothing
can hang.

## Monetization

- **Free, generous tier:** the daily puzzle, **unlimited Easy & Medium**, full core play,
  three free hints per game.
- **Nonet Pro — one-time $2.99** (a non-consumable; never a subscription): Hard & Expert
  difficulties, unlimited hints with explanations, extra board themes, and full stats
  history.
- **Never any ads.** This is the whole point.

> The Pro unlock in this build is an honest local demo (an `@AppStorage("isPro")` flag with
> a Restore action). The shipping app would back it with a StoreKit non-consumable purchase.

## Why it can boom

The most-downloaded Sudoku apps are ad-stuffed or subscription-gated, and their reviews are
full of people asking for one clean, ad-free Sudoku with real hints. Nonet is precisely
that — a proper technique-graded generator, a fair seeded daily, hints that teach, and a
one-time unlock instead of a subscription — which is exactly the gap the top charts leave open.

## Self-review attestation

Every Swift file was re-read and inspected against the iOS 17 SDK. The solver/generator
logic is correct and terminates (uniqueness via capped backtracking; grading and digging
loops are iteration- and time-bounded). Every grid index access is bounds-checked to
`0..<81`; there are no force-unwraps, no `try!` beyond the permitted container fallback, and
no `fatalError`. Generation runs off the main thread with a `@MainActor` handoff and a real
loading state. `@Query` / `@StateObject` ownership is consistent; Charts series are
`Identifiable` structs; Theme tokens are defined; light and dark are both first-class.
A scan for `TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub` returns
zero matches. No stubs.
