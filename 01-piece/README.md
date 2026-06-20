# Piece — Jigsaw Puzzle Game

A polished iOS jigsaw puzzle game with hand-crafted procedural artwork, SRS-style progress tracking, and a dark-amber design language.

## Concept

Piece turns beautiful Canvas-rendered artwork into jigsaw puzzles. Every piece of artwork is drawn procedurally — no asset files — giving crisp, scalable images at every device size. Players tap to select a piece from the tray, then tap its correct board slot to snap it in. Wrong slots shake and reject the piece with haptic feedback.

## Killer Features

- **5 procedural artworks** drawn entirely with SwiftUI Canvas (Mountain Sunset, Ocean Waves, Geometric Grid, Aurora Borealis, Floral Mandala)
- **3 difficulty levels**: Beginner (4×4 = 16 pieces), Intermediate (6×6 = 36), Expert (9×9 = 81)
- **Save & resume** — backing out mid-game auto-saves via SwiftData; resume banner appears on the select screen
- **Personal best tracking** per puzzle × difficulty combination
- **Reference image** — tap the photo icon while playing to see the full artwork
- **Haptics** at every interaction (select, correct placement, wrong slot, puzzle complete)

## Stack

- SwiftUI 5 + SwiftData (iOS 17+)
- `@Observable` macro for the `PuzzleEngine` game state
- `ImageRenderer` to pre-render artwork to `UIImage` once (avoids re-drawing Canvas 81× per frame)
- `TimelineView(.periodic)` for the live elapsed timer
- `LazyVGrid` / `LazyHStack` for board and tray performance
- `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` for haptics

## File Structure

```
01-piece/ios/
├── project.yml                   # XcodeGen spec
└── Piece/
    ├── Info.plist
    ├── PieceApp.swift            # App + ContentView (onboarding gate)
    ├── Assets.xcassets/
    ├── Theme/PieceTheme.swift
    ├── Utilities/HapticsManager.swift
    ├── Models/
    │   ├── PuzzleModels.swift    # Difficulty, ArtStyle, PuzzlePiece, PuzzleSave, PuzzleResult
    │   ├── PuzzleArtwork.swift   # Canvas drawing (all 5 artworks)
    │   └── PuzzleEngine.swift    # @Observable game state + rendering
    └── Views/
        ├── MainTabView.swift
        ├── Onboarding/OnboardingView.swift
        ├── Game/
        │   ├── PuzzleSelectView.swift
        │   ├── PuzzlePlayView.swift
        │   └── PuzzleCompleteView.swift
        ├── Stats/StatsView.swift
        ├── Settings/SettingsView.swift
        └── Components/
            └── PieceTileView.swift   # PieceTileView + BoardSlotView
```

## Build

```bash
cd 01-piece/ios
xcodegen generate
open Piece.xcodeproj
```

Requires Xcode 15+ and iOS 17+ simulator or device.
