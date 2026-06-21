# Flop — Texas Hold'em Pre-Flop Trainer

**Category:** Games / Education  
**Platform:** iOS 17+  
**Run:** 2026-06-21_run4 · #353

## What It Does

Flop trains your Texas Hold'em pre-flop decision-making using GTO (Game Theory Optimal) strategy for 6-max no-limit hold'em. Quiz yourself on all 169 starting hand combinations across all 6 positions, study visual hand range charts, calculate pot odds on the fly, and log your real poker sessions.

## Feature Screens

| Screen | Description |
|--------|-------------|
| **Hand Quiz** | Two playing cards + position badge; Raise/Call/Fold buttons with color coding; instant result with GTO explanation; session stats bar (accuracy, hands, streak, best streak) |
| **Pre-flop Charts** | Position picker (UTG→BB) with color coding; 5 hand groups with color legend (Premium/Strong/Playable/Speculative/Position-only); 13×13 color-coded range grid |
| **Pot Odds** | Interactive slider calculator for pot size and call amount; break-even equity display; common hand equity reference table; Rule of 4&2 formula |
| **Session Log** | CRUD poker sessions: game type, date, hands, duration, notes; stats overview (sessions, hands, time, quiz accuracy); swipe-to-delete |
| **Settings** | Show/hide explanations, haptic feedback, daily goal stepper, default position picker, quiz stats with reset |

## Technical Highlights

- **PokerEngine.swift** — Position-aware GTO pre-flop chart: all 169 hand combinations (pairs, suited, offsuit) with correct action per position; explanation generation; pot odds math
- **QuizViewModel** — @Observable; answer(), nextHand(), accuracy, streak tracking
- **CardView** — Full playing card rendering in SwiftUI (rank corners, suit symbol, red/black coloring)
- **HandRangeGrid** — 13×13 Canvas grid color-coded by action (raise=gold, call=green, fold=dim)
- **SwiftData** — FlopQuizRecord, FlopSession, FlopSettings persistence

## Self-Review

- ✅ GTO chart verified against known ranges (UTG folds 77, CO raises 77, BTN raises 77 ✓)
- ✅ All 169 starting hands have defined actions for all 6 positions
- ✅ Pot odds math correct: call/(pot+call) × 100
- ✅ Dark felt-green theme with gold accents
- ✅ No external dependencies
- ✅ XcodeGen project.yml

## Monetization

Pro IAP: range trainer drill mode, equity calculator, session analytics dashboard. Free tier: unlimited quiz + charts + pot odds.
