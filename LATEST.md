# Run 2026-06-21 — 6 Production-Ready iOS Apps

## Summary
Shipped 6 complete native iOS apps (entries #334–339 in SHIPPED.md). All apps target iOS 17+, use SwiftUI 5, SwiftData, @Observable, XcodeGen project.yml, onboarding, 3+ tabs, settings with 3+ real preferences, and one-time Pro monetization.

## Apps Shipped

### 01 — Peg (Cribbage) · com.orbioom.peg
Full cribbage vs AI. CribbageScorer handles 15s (combinations), pairs, runs (rankCounts + multiplier), flush (4/5-card), nobs, his-heels. CribbageAI uses EV-based discard selection (expectedHandValue sampling) and pegging heuristics (15/31/pair/run). @Observable CribbageGame state machine: dealing→discarding→cutting→pegging→showHand→showCrib→gameOver with dealer rotation.
14 Swift files, 21 total

### 02 — Draughts (Checkers) · com.orbioom.draughts
Full checkers vs AI. Mandatory jump, multi-jump with origin tracking, king promotion, forward-only men. Minimax α-β depth 2/4/6, evaluation: piece+king(2.5×)+advancement+center+edge. Move ordering: multi-jumps→single→simple.
17 Swift files, 24 total

### 03 — Slide (15-Puzzle) · com.orbioom.slide
Sliding tile puzzle. Parity-correct solvability check. SplitMix64 PRNG. FNV-1a date hash for daily seed. 5 Canvas themes (2 Pro). Spring tile animation. Swift Charts history. Daily streak.
15 Swift files, 22 total

### 04 — Pebble (Mancala/Kalah) · com.orbioom.pebble
Full Kalah vs AI: counter-clockwise sow, skip opponent store, extra turn on own store, capture on landing in empty pit, end-of-game sweep. Minimax α-β depth 2/4/6, store differential evaluation. PitView with stone-dot grid up to 16 stones.
17 Swift files, 24 total

### 05 — Atom (Periodic Table) · com.orbioom.atom
All 118 elements (H–Og) with real data. Pinch-to-zoom ZStack periodic table (0.5×–2.5×). 4 quiz modes. Swift Charts accuracy tracking. 5 tabs: Table/Search/Quiz/Stats/Settings.
19 Swift files, 26 total

### 06 — Push (Sokoban) · com.orbioom.push
50 hand-authored levels in 5 packs. Full Sokoban rules, undo stack, 3-star rating vs par. CellView with wall bevel/target ring/wood-grain box/checkmark/face-dot player. D-pad + swipe controls. Daily puzzle with streak.
21 Swift files, 28 total
