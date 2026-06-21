# Pebble — Mancala for iOS

A beautiful native iOS Mancala (Kalah rules) game.

## Features
- Full Kalah rules: sow, capture, extra turns, end-game sweep
- Smart AI with Easy / Medium / Hard (minimax + alpha-beta)
- 3, 4, or 6 stones per pit variants
- Statistics tracking
- Haptic feedback, dark/light mode

## Build

Prerequisites: Xcode 15+, [xcodegen](https://github.com/yonaskolb/XcodeGen)

```bash
cd ios && xcodegen generate && open Pebble.xcodeproj
```

## Board Layout

```
[P2 Store] [12][11][10][ 9][ 8][ 7] [P1 Store]
           [ 0][ 1][ 2][ 3][ 4][ 5]
```

- P1 (human) pits: 0–5, store: 6 (right)
- P2 (AI) pits: 7–12, store: 13 (left)
- Opposite of pit i: `12 - i` (used for captures)
