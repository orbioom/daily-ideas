# Domino — Classic Draw Dominoes for iOS

A beautifully crafted Draw Dominoes game with no ads, ever. Built with SwiftUI, SwiftData, and the `@Observable` macro for iOS 17+.

## Design

- **Background**: Rich mahogany (#4A2C17)
- **Tiles**: Ivory (#F5F0E0) with black pips
- **Accent**: Gold (#C8A96E)
- Classic elegance — the feel of a high-quality physical domino set

## Features

- Full Draw Dominoes rules (double-six set, 28 tiles)
- VS AI with 3 difficulty levels: Easy, Medium, Hard
- 2-player pass-and-play mode
- Match play to 100 points (configurable: 50/100/150)
- Full pip canvas drawing (authentic domino look)
- Round-over and match-over result screens
- AI thinking delay for realism
- Haptic feedback
- Game history with win/loss records
- Stats: win rate, streaks, charts by month
- Accordion rules screen with illustrated examples
- Onboarding (3 steps)
- Settings: difficulty, match points, tile style, haptics
- SwiftData persistence for game records and settings
- Light + dark mode support
- Accessibility labels throughout
- No force-unwraps

## Tech Stack

- **iOS 17+** (SwiftUI, SwiftData, `@Observable`)
- **Xcode 15+**
- **XcodeGen** (`project.yml`) for project generation

## Build

```bash
cd ios
xcodegen generate
open Domino.xcodeproj
```

Then build and run on simulator or device (iOS 17+).

## Game Rules Summary

1. **Double-Six set**: 28 tiles [0|0] through [6|6]
2. **Setup**: Each player draws 7 tiles; remainder is the boneyard
3. **First move**: Highest double goes first; else highest tile
4. **Play**: Match either open end of the chain; draw from boneyard if stuck
5. **Doubles**: Placed perpendicular (visually distinct)
6. **Blocked**: Both players pass → lower pip count wins
7. **Scoring**: Empty hand → opponent's remaining pips; Blocked → pip difference
8. **Match**: First to 100 points wins

## Monetization

- Free to download
- One-time $2.99 Pro purchase removes... wait, there are no ads. This app is premium by default.
- Beats every ad-heavy domino app on the App Store.

## Project Structure

```
ios/
  project.yml              # XcodeGen config
  Domino/
    DominoApp.swift        # App entry point, SwiftData container
    Models/                # DominoTile, GameRecord, DominoSettings
    Utilities/             # DominoEngine (@Observable), DominoAI
    Views/
      Onboarding/          # 3-step onboarding
      Game/                # Main game UI (board, hand, tiles, pips)
      History/             # Game history list
      Stats/               # Win rate, streaks, charts
      Rules/               # Accordion rules with diagrams
      Settings/            # App preferences
      Components/          # ScoreHeader, TurnIndicator
    Theme/                 # DominoTheme colors and fonts
    Assets.xcassets/       # AppIcon, AccentColor
```
