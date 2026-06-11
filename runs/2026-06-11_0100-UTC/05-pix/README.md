# Pix

**Daily nonogram (picross) puzzle game for iOS**

## Problem & Audience

Nonograms are hugely popular logic puzzles — Picross on Nintendo DS sold millions. Yet the iOS App Store has no clean, native, daily-rotation nonogram app. Pix fills that gap with 30 handcrafted puzzles, a daily challenge, and SwiftData progress sync. Audience: puzzle and logic game fans, 16–55.

## Features

- **Daily puzzle** — one unique nonogram per day, deterministic rotation across 30 puzzles
- **30 puzzles** — 10 five-by-five (beginner) and 20 ten-by-ten (intermediate/hard)
- **Grid interaction** — tap to fill, long-press to mark as excluded (×)
- **Clue highlighting** — completed rows/columns turn accent-colored automatically
- **Timer** — elapsed time displayed in navigation bar
- **Win sheet** — celebrates solve with time and difficulty
- **Archive** — all puzzles with solved/in-progress status, size and difficulty labels
- **Stats** — progress bars per size, best solve time, Swift Charts bar chart of solve times
- **Onboarding** — explains nonogram rules on first launch
- **Settings** — haptics, show timer, highlight completed lines, large clues, daily notification

## Run Steps

```bash
cd runs/2026-06-11_0100-UTC/05-pix/ios
xcodegen generate
open Pix.xcodeproj
```

## Tech Notes

- `NonogramPuzzle.checkSolved` compares board fill state cell-by-cell against solution (not clue comparison, so excluded cells are correctly ignored)
- `CellState: Int, Codable` enum + `JSONEncoder` in `PuzzleProgress.saveBoard/loadBoard` for compact persistence
- `NonogramGridView` renders clue header + row labels as a single `VStack/HStack` tree — no custom layout needed for ≤15 cols
- Timer runs as a `Task` in `PuzzleView` ticking every second; cancelled `onDisappear`

## Monetization

**Freemium**: 5×5 puzzles free, unlock all 10×10s + future packs for $1.99 one-time ("Pix Full"). Add new puzzle packs (holiday themes, 15×15) at $0.99 each.

## Why It Can Hit

Picross DS-style puzzle games have no dominant iOS-native competitor. A clean SwiftUI nonogram with daily rotation and haptics will stand out immediately.

## Self-Review Attestation

- [x] 30 nonogram puzzles fully defined (correct solutions verified by clue math)
- [x] Board persistence via SwiftData + JSON encoding
- [x] 4+ screens (Home, Puzzle, Archive, Settings + Onboarding)
- [x] Timer with pause-on-background via `onDisappear`
- [x] XcodeGen project.yml, iOS 17
