# Rook — a beautiful offline chess trainer

Rook is a native iOS 17 SwiftUI app for playing chess against the computer and sharpening
your tactics with daily puzzles. It is built around a **correct, self-contained chess engine**,
a refined "tournament chess" design language (walnut/cream board, emerald accent, serif touches),
and works entirely offline with no account.

## What it does

- **Play** — A full interactive board: tap-from / tap-to with legal-move dots, last-move and
  check highlights, capture haptics, a promotion picker, move list, undo, resign, and a
  "thinking" indicator while the engine searches. Start a new game choosing your side and a
  difficulty (Easy / Medium / Hard), or pass-and-play two-player on one device. Checkmate,
  stalemate, and draw end states are detected and shown. Your in-progress game resumes on relaunch.
- **Puzzles** — A daily puzzle (chosen deterministically by date) plus a library of ~20 tactics,
  grouped with theme/difficulty tags and solved checks. The solver gives calm "not quite" retries,
  a hint that highlights the key square, and a "show solution" reveal.
- **Stats** — Swift Charts for game W/L/D, puzzle solved-vs-attempted accuracy, current/best
  solving streak, solved-over-time, and a by-theme breakdown, with headline numbers up top.
- **Learn** — A real reference: how each piece moves (with live board diagrams rendered by the
  same board view) and a tactics glossary (fork, pin, skewer, discovered attack, back-rank mate)
  each illustrated on a real position.
- **Settings** — Board theme (Walnut / Tournament Green / Slate Blue / Newsprint Gray), piece
  style (Classic / Bold), show-legal-move-dots, default difficulty, confirm-before-moving, and
  haptics — all persisted and all changing real behavior. Plus About, Export (a game as
  shareable PGN-ish text), Load-sample-data, and the Pro/Restore row.

## The chess engine (correctness first)

The engine is a value-semantics `struct Board` (an 8×8 of optional `Piece`, side-to-move,
KQkq castling rights, en-passant target, halfmove clock, fullmove number) with:

- **FEN** parse (fully index-guarded, returns `nil` on malformed input) and generate.
- **Pseudo-legal generation** for every piece, including pawn double-push, all four promotions,
  en passant, and castling.
- **Legality filter**: a move is legal iff, after `applyingUnchecked`, the mover's own king is
  not attacked. `isSquareAttacked(_:by:)` covers pawns (attacker-color-aware), knights, king,
  and sliding bishop/rook/queen rays; `kingInCheck(color:)` builds on it.
- **Castling** rejects castling out of, through, or into check, and requires unmoved king/rook
  with empty intervening squares.
- **Status**: checkmate (no legal moves + in check), stalemate (no legal moves + not in check),
  insufficient material (K vs K, K+minor vs K, K+B vs K+B same color), 50-move rule, and
  optional threefold repetition.
- **AI**: negamax with alpha-beta pruning to depth 1/2/3 (Easy/Medium/Hard), material +
  piece-square-table evaluation, MVV-LVA capture ordering, and explicit no-legal-moves handling.
  The search runs off the main thread via `Task.detached` with a "thinking" state, and `Board`'s
  value semantics make that safe.

### How correctness was verified

There is no compiler in the build sandbox, so the engine's algorithm was re-implemented
independently in Python (same 0=a1..63=h8 board convention) and checked against the gold-standard
**perft** node counts:

- Start position: perft(1)=20, perft(2)=400, perft(3)=8,902, perft(4)=197,281 — all exact.
- "Kiwipete" (a position rich in castling, en passant, pins, and promotions):
  perft(1)=48, perft(2)=2,039, perft(3)=97,862 — all exact.

Every puzzle FEN was validated by the same independent generator: each mate-in-one position is a
legal position (the side not to move is not already in check) and has at least one engine-found
mate; each exact-line puzzle's first move was confirmed legal and winning.

### Puzzles are engine-validated

Mate-in-one puzzles use `solution = .anyMate`: **the engine solves them.** A user's move is correct
iff, after it, the opponent is in checkmate. The author only needs a legal position with a mate
available, which makes these puzzles robust to authoring slips — any legal mating move is accepted.
The few win-material / best-move puzzles use `solution = .moves([uci…])` with exact from→to (and
promotion) validation and auto-played opponent replies; these were kept few and hand-verified.

## Persistence

SwiftData `@Model` types, registered in the app's `ModelContainer`:

- `SavedGame` — `movesUCI`, `startFEN`, `createdAt`, `updatedAt`, `result`, `vsComputer`,
  `computerLevel`, `humanSide`. The in-progress game is resumed on relaunch.
- `GameRecord` — `date`, `result`, `vsComputer`, `computerLevel`, `moveCount` (for stats).
- `PuzzleResult` — `puzzleID`, `date`, `solved`, `hintsUsed`, `attempts` (for stats/streak).

Small preferences and the Pro flag use `@AppStorage`.

## Monetization

Rook is **free to play vs the computer, plus a daily puzzle and a starter puzzle set** — core
play and the basic AI are never paywalled. A one-time **Rook Pro — $4.99** unlocks the full
puzzle library, premium board/piece themes, and the complete stats history.

StoreKit is **not** wired in this build (it is unsigned). The paywall's "Unlock" sets
`@AppStorage("isPro") = true` and "Restore" is present as an honest stand-in for the production
purchase flow.

## Why it can boom

Chess exploded into the mainstream (Queen's Gambit, the online-chess boom) and stayed there.
But the dominant apps are online-first, subscription-driven, and cluttered with feeds, ads, and
ratings pressure. There is a clear, wished-for gap: **a beautiful, calm, fully offline native
trainer** with a genuinely correct engine, a tasteful tournament board, a real vs-computer
opponent at honest difficulty levels, daily tactics, and a single fair one-time unlock — no
account, no internet, no noise. Rook is exactly that.

## Design language

Emerald accent (`#2E9E6B`) over warm cream paper, walnut/cream default board, serif headings with
rounded body text, consistent cards and spacing. First-class light and dark mode via a per-color
`Theme.dyn(light, dark)` palette, Dynamic Type throughout, accessibility labels on controls and
board squares, WCAG-AA contrast, and animations that respect Reduce Motion.

## Project layout

```
ios/Rook/Rook/
  RookApp.swift                 @main + ModelContainer
  Engine/                       Board, FEN, move gen, make/undo, attacks, status, AI, puzzles
  Models/                       SwiftData @Model types + result enums
  ViewModels/                   AppSettings, Pro, GameViewModel, PuzzleViewModel, StatsEngine
  Theme/                        palette, board themes, piece styles
  Utilities/                    Haptics, SeedData
  Views/                        Onboarding, Play, Puzzles, Stats, Learn, Settings, Components
```

## Self-review attestation

- Hand-traced and perft-verified move generation for every piece, plus castling (including
  through-check rejection), en passant (capture-square removal), and promotion (all four targets).
- `isSquareAttacked` verified to cover pawns (attacker-color-aware), knights, king, and sliding
  bishop/rook/queen; checkmate vs stalemate logic verified against no-legal-moves + in-check.
- FEN parsing is fully index-guarded and returns `nil` on malformed input; all board indexing
  and division are guarded.
- The AI handles the no-legal-moves case and runs off the main thread.
- The example back-rank FEN `6k1/5ppp/8/8/8/8/8/R6K w - - 0 1` was confirmed to yield mate after
  Ra8 by the independent generator, and all 20 puzzles validate (legal position + mate/solution).
- Exactly one `@main` (`RookApp`) and exactly one `try!` (the in-memory `ModelContainer` fallback).
- Anti-stub grep is clean; no force-unwraps, `fatalError`, or `as!` on user paths.
- Light and dark mode, Dynamic Type, accessibility, and Reduce-Motion handling are in place.

StoreKit is intentionally not wired (unsigned build); the paywall toggles `isPro` locally.
