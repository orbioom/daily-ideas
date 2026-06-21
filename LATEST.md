# Run 2026-06-21 — 6 Production-Ready iOS Apps (Run 2)

## Summary
Shipped 6 complete native iOS apps (entries #340–345 in SHIPPED.md). All apps target iOS 17+, use SwiftUI 5, SwiftData, @Observable, XcodeGen project.yml, 3-page onboarding, 4 tabs, settings with 3+ real preferences, and one-time Pro monetization.

## Apps Shipped

### 01 — Ivory (Reversi/Othello) · com.orbioom.ivory
Full Reversi/Othello vs AI. ReversiEngine with minimax α-β pruning (Beginner=2/Intermediate=4/Advanced=6 depth), position weight matrix (100/-25/10/5 corner bonus pattern), @Observable GameViewModel, async AI via Task.detached + MainActor.run, SwiftData history, hint display for valid moves, ivy green theme.
14 Swift files, 24 total

### 02 — Tricks (Spades) · com.orbioom.tricks
Full partnership Spades card game vs AI. CardEngine (Suit/Rank/Card with beats() trump logic), SpadesEngine (nil/bags/10-bag penalty/partnership scoring), AIEngine (estimateBid, chooseCard, nil-avoidance, partner nil awareness), @Observable GameViewModel with HandPhase state machine, async AI via Task.detached, felt green card table layout.
17 Swift files, 24 total

### 03 — Count (Blackjack Trainer) · com.orbioom.count
Blackjack Basic Strategy Trainer. Full standard multi-deck basic strategy (hard totals, soft totals, pairs), HandScenario with isPair/isSoft detection, session accuracy tracking, haptic feedback, Swift Charts 7-day BarMark, hardest-scenarios list (min 3 attempts sorted by accuracy), casino green theme.
14 Swift files, 21 total

### 04 — Recto (Bullet Journal) · com.orbioom.recto
Digital Bullet Journal. Rapid-logging bullets (task•/event○/note–) with TaskStatus (open/complete/migrated/irrelevant), BulletEntry + Collection SwiftData models, date-navigation daily log, migrate-to-today gesture, Collections with icon+color, monthly calendar IndexView (7-column grid), theme/font settings.
14 Swift files, 21 total

### 05 — Alley (Bowling Scorekeeper) · com.orbioom.alley
Bowling scorekeeper. BowlingEngine with full 10-frame scoring (strike/spare lookahead, 10th-frame 2/3 balls, nil scores until lookahead resolved), up to 6 players, turn rotation, undo stack, PinEntryView with live PinDiagramView, ScoreboardView with running total, personal best + average + strike% stats, Swift Charts.
15 Swift files, 22 total

### 06 — Buck (Euchre) · com.orbioom.buck
Full Euchre card game vs AI. 24-card deck (9→A), right bower (J-trump=15pts) / left bower (J-same-color=14pts), effectiveSuit() for bower routing, AIEngine (shouldOrderUp, callSuit, chooseCard), going alone (partner sits out, 4pts for sweep), HandResult scoring (1/2/4 pts making, 2pts euchred opponents), async AI delays, BiddingView overlay with round 1/2 logic.
18 Swift files, 25 total
