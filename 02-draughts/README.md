# Draughts

A production-ready, ad-free Checkers/Draughts game for iOS, built with SwiftUI and SwiftData.

## Overview

Draughts is a polished native iOS app featuring:

- Full English Draughts rules (8×8, 12 pieces per side, mandatory jumps, multi-jumps, kings)
- Minimax AI with alpha-beta pruning at three difficulty levels
- Dark wood aesthetic with gold accents
- SwiftData persistence for stats, settings, and onboarding state
- Swift Charts integration for win/loss visualisation
- Haptic feedback
- Full accessibility labels on all board elements
- One-time purchase model ($2.99 Pro unlock, StoreKit 2-ready)

## Tech Stack

| Concern | Solution |
|---|---|
| UI | SwiftUI (iOS 17+) |
| State | `@Observable` |
| Persistence | SwiftData (`@Model`) |
| Charts | Swift Charts |
| AI | Minimax + alpha-beta pruning |
| Project generation | XcodeGen (`project.yml`) |
| Min deployment | iOS 17.0 |
| Bundle ID | `com.orbioom.draughts` |

## Building

### Prerequisites

- Xcode 15 or later
- XcodeGen (`brew install xcodegen`)

### Steps

```bash
cd ios
xcodegen generate
open Draughts.xcodeproj
```

Press ⌘R to build and run on a simulator or device.

## Project Structure

```
ios/
  project.yml                   # XcodeGen spec
  Draughts/
    DraughtsApp.swift            # App entry point + modelContainer
    Info.plist
    Models/
      CheckersMove.swift         # Move value type (tuples, manual Equatable)
      CheckersBoard.swift        # Board state, valid-move generation, multi-jump logic
      CheckersAI.swift           # Minimax + alpha-beta, Difficulty enum
      DraughtsGame.swift         # @Observable game controller
    Views/
      ContentView.swift          # TabView + onboarding gate
      Onboarding/
        OnboardingView.swift     # 3-page onboarding, persisted via SwiftData
      Game/
        GameView.swift           # Game screen with status bar, result sheet
        BoardView.swift          # 8×8 board rendered via Canvas + SwiftUI layers
        RulesView.swift          # How-to-play sheet
      Stats/
        StatsView.swift          # Win/loss bar chart (Swift Charts), recent games
      Settings/
        SettingsView.swift       # Difficulty, side selection, haptics, Pro unlock
      Components/
        PieceView.swift          # Radial-gradient piece with crown for kings
    Theme/
      DraughtsTheme.swift        # Centralised colour palette
    Persistence/
      DraughtsStats.swift        # @Model — games played, wins, streaks, history
      DraughtsSettings.swift     # @Model — difficulty, side, haptics, isPro
      DraughtsOnboarding.swift   # @Model — onboarding completion flag
    Assets.xcassets/
      AppIcon.appiconset/
      AccentColor.colorset/
    Preview Content/
      Preview Assets.xcassets/
```

## Game Rules Implemented

1. **Board** — 8×8, pieces on dark squares `(row + col) % 2 == 1`
2. **Setup** — Red on rows 0-2 (moves down), Black on rows 5-7 (moves up)
3. **Simple moves** — Men slide one diagonal square forward; Kings slide any diagonal direction
4. **Mandatory jump** — If any jump is available for any piece, a jump must be made
5. **Multi-jump** — After landing, if the same piece can jump again it must continue
6. **Promotion** — Man reaching row 7 (Red) or row 0 (Black) becomes a King
7. **Win** — Opponent has no legal moves (all captured or blocked)

## AI Design

- Algorithm: Minimax with alpha-beta pruning
- Depths: Easy = 2, Medium = 4, Hard = 6
- Evaluation: piece count + king bonus (2.5×) + position advancement + centre control + edge penalty for kings
- Move ordering: jumps before non-jumps, multi-jumps first (improves pruning)
- Easy mode: 30% random move injection for a human feel
- Runs on a detached `Task` so the main thread stays responsive

## Colour Palette

| Token | Value |
|---|---|
| Background | `#261A0F` |
| Light square | `#D9B88C` |
| Dark square | `#6B4729` |
| Red piece | `#D92619` |
| Black piece | `#141414` |
| Gold accent | `#D4B038` |
