# Peg — Cribbage for iOS

A beautiful native iOS implementation of the classic card game Cribbage.

## Features
- Full cribbage rules: 15s, pairs, runs, flush, nobs, his heels
- Smart AI opponent with Easy / Medium / Hard difficulty
- Pegging phase with automatic scoring
- Detailed hand breakdown after each round
- Statistics tracking (win rate, streaks, high score)
- Haptic feedback
- Light & dark mode

## Tech Stack
- Swift 5, SwiftUI 5, SwiftData, iOS 17+
- @Observable game state machine
- XcodeGen project generation

## Build
```bash
cd ios
xcodegen generate
open Peg.xcodeproj
```

## Monetization
One-time Pro unlock ($2.99): removes ads, unlocks card themes.
