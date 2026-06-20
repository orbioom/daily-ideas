# Hoop

Live basketball scorekeeper for pickup games and youth leagues.

## Features
- Track teams, players, and scoring (2pt / 3pt / free throws)
- Quarter-by-quarter score tracking with live game clock
- Per-player stats: points, fouls, free throw %
- Team fouls and timeout management
- Undo last action
- Full game history with player stat breakdown
- Dark hardwood/orange theme

## Stack
- SwiftUI 5
- SwiftData (persistent game history)
- `@Observable` GameEngine (no ObservableObject)
- iOS 17+ target

## Build
```
cd ios
xcodegen generate
open Hoop.xcodeproj
```
Run on simulator or device (iOS 17+).
