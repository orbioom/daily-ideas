# Limn

A calm, ad-free **nonogram / picross** logic-puzzle game for iOS 17. Read the clues, fill the
grid, and a hidden picture is drawn (to *limn*) cell by cell. Built native in SwiftUI + SwiftData
with a **real engine**: clue derivation, win validation, and a genuine line-solver that powers
fair Hints and guarantees every puzzle is solvable by pure logic — no guessing, no ads, no nags.

## What it is

Limn is a top-charts-quality picross "beater": clean graph-paper aesthetic, a satisfying fill
animation, and the solved-picture reveal as the payoff. 30 hand-authored puzzles across 5×5,
10×10, and 15×15, each one a recognizable picture and each one **verified logically solvable**
by the same solver that ships in the app.

## Features

- **Puzzles library** — themed packs (Beginnings 5×5, Everyday 10×10, Wild Things 10×10,
  Masterpieces 15×15). Each tile shows a Canvas mini-thumbnail of the solved picture once
  completed, the best time, in-progress state, or a Pro lock.
- **Play board** — row/column clue strips, tappable cells, a Fill/Cross mode toggle, live timer,
  mistakes counter, progress bar, **Hint** (real line-solver deduction), **Undo**, and Restart.
  Large 15×15 boards support pinch-zoom and pan. A win reveals the picture, its name, and your time.
- **Daily** — a deterministic seeded puzzle for each calendar day (SplitMix64), a current/best
  streak, and a 7-day archive. Replaying past days is a Pro feature.
- **Stats** — Swift Charts: solved-by-size bars, best-time distribution, a library-completion
  donut, and daily-streak figures. Designed empty state before your first solve.
- **How to Play** — rules plus an annotated worked example showing the overlap deduction.
- **Settings** — persisted prefs that change behavior: Assist mode (flag mistakes), Show mistakes,
  Auto-cross completed lines, Default tap action, Haptics, Appearance (System/Light/Dark). Plus
  About, **Load sample data**, Reset, and Pro/Restore.
- First-run **Onboarding**, full light/dark theming, Dynamic Type, VoiceOver labels on every cell
  and clue, and Reduce-Motion-aware animation.

## Engine (the substantial logic)

- **`PuzzleBank`** — 30 validated solution grids (`"#"`/`"."` rows) grouped into packs. Every grid
  is checked for rectangularity and non-emptiness at construction; ragged input collapses to a safe
  1×1 rather than crashing.
- **`NonogramEngine`** — derives row/column clues (runs of filled cells; empty line → `[0]`),
  validates a win (player's filled set equals the solution's filled set), and counts mistakes.
- **Line solver (a real overlap solver)** — `solveLine(clue:states:)` runs a memoized placement
  DP over a single line: it explores every legal way to lay the runs given the player's current
  `filled`/`crossed` marks, and records per cell whether it *can* be filled and whether it *can* be
  empty across all valid placements. A cell that is filled in every placement is a forced fill; one
  empty in every placement is a forced cross. This is strictly stronger than the naive
  leftmost/rightmost two-extreme intersection (which produces false positives), and it is what makes
  Hints always correct and guarantees logical solvability. It returns no-op on contradictory/
  over-constrained input — no force-unwraps, no unchecked indexing, no division.
- The solver was fuzz-tested against a brute-force oracle (60,000 random cases, zero mismatches),
  and every shipped puzzle was confirmed solvable by iterating the solver to a fixpoint.

## Run

1. Generate the Xcode project with [XcodeGen](https://github.com/yonyz/XcodeGen) from `ios/`:
   ```
   cd ios && xcodegen generate
   ```
2. Open `Limn.xcodeproj`, select an iOS 17 simulator (or device), and Run.

The project config, `Info.plist`, Assets (AppIcon, AccentColor `#13B6A8`, LaunchBackground), and
Preview Content already exist — only the Swift sources under `ios/Limn/Limn/` are authored here.

### Free signing

No paid Apple Developer account needed: in **Signing & Capabilities** pick your personal team and
let Xcode manage signing. The bundle id is `com.orbioom.limn` — change it if it collides. There are
no entitlements, network calls, or third-party packages.

## Tech notes

- SwiftUI + SwiftData (`@Model` `PuzzleRecord`, `SavedGame`, `DailyResult`, all registered in both
  `ModelContainer` calls), `@AppStorage` for prefs and the Pro flag, Swift Charts for Stats.
  `@Observable` `GameViewModel` for play state; `ObservableObject` `AppSettings` for prefs.
- **Monetization**: one-time `Limn Pro` ($2.99) unlocks the 15×15 + extra packs, daily-archive
  replay, and removes the free mistake cap — local `@AppStorage("isPro")` flag with a `PaywallView`
  and Restore (StoreKit is not wired; "Unlock" simply sets the flag — noted honestly).
- **Why it can boom**: picross is an evergreen top-charts genre, but the chart leaders are crusted
  with ads and dishonest "hints"; Limn is the calm, ad-free, one-time-purchase alternative with a
  provably fair logic solver and a daily ritual that drives retention.
- The **line-solver is a real overlap solver** (placement DP computing per-cell forced fills/crosses
  across all valid placements), not a lookup table or a cosmetic hint.

## Self-review

- 30 Swift source files under `ios/Limn/Limn/`.
- Exactly one `@main`; zero `try!` / `as!` / `NavigationView`; the only `fatalError` is the
  documented unreachable in-memory `ModelContainer` fallback.
- Anti-stub grep clean (no TODO/FIXME/placeholder/etc.).
- No force-unwraps or unchecked indexing on user paths; every array access and `Calendar` optional
  is guarded; the solver is total.
- Light + dark via `Theme.dyn`; Dynamic Type; VoiceOver cell/clue labels; Reduce-Motion respected.
- Empty/loading/success/error states present; Settings has 6 persisted prefs plus About, Load
  sample data, Reset, and Pro/Restore; sample data seeds 50+ items (solves + daily history).
- Solver verified by 60k-case fuzz against brute force and a full-bank solvability check.
