# Apex — Pyramid Solitaire

**Platform:** iOS 17+ · **Stack:** SwiftUI 5, SwiftData, Swift Charts · **Monetization:** One-time Pro IAP ($2.99)

## What it does
Apex is a polished Pyramid Solitaire card game. Remove pairs of cards that sum to 13 from a 7-row pyramid. Clear the pyramid for a 250-point bonus.

## Key Features
- Classic Pyramid Solitaire with a full 52-card deck
- Draw pile with 3-pass limit before game over
- Undo (unlimited, snapshot-based)
- Scoring: Kings=50, low cards=30, others=20 pts; clear pyramid=+250
- Win/loss overlays with stats breakdown
- Seeded RNG for reproducible daily games
- Swift Charts score history chart
- Full dark/light mode, haptics, VoiceOver, dynamic type
- Free: unlimited play · Pro: daily challenges, themes ($2.99 one-time)

## Architecture
- `PyramidGameEngine` — `@Observable`: 7-row pyramid state, draw/waste piles, `pairSumsTo13`, move validation, undo via `SavedPyramidGame` snapshots, `SplitMix64` seeded RNG
- `CardView` — SwiftUI card face rendering with suit colors and selected state animation
- `GameResult` + `AppPreferences` — SwiftData models
- `StatsView` — Swift Charts bar chart colored by win/loss

## Beat
Outperforms existing Pyramid Solitaire apps by offering a native SwiftUI UI, no ads, snapshot undo, and clean accessibility support.
