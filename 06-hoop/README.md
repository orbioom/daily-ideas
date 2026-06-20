# Hoop

Live basketball game scorekeeper and stat tracker for pickup games, youth leagues, and coaching use.

## Features

- Track teams, players, scoring (2pt/3pt/FT), quarter scores, fouls, and timeouts in real time
- Support for 2-quarter (halves) or 4-quarter game formats
- Configurable quarter length (8, 10, or 12 minutes)
- Per-player stat tracking: field goals, free throws, fouls
- Built-in countdown timer with start/pause/end quarter controls
- Undo last action
- Full game history with box scores
- Dark hardwood-floor + basketball orange theme

## Tech Stack

- SwiftUI 5
- SwiftData (persistence)
- @Observable (GameEngine live state)
- iOS 17+ deployment target
- XcodeGen (project.yml → Xcode project)

## Setup

```bash
cd ios
xcodegen generate
open Hoop.xcodeproj
```

## Structure

```
ios/
├── project.yml
└── Hoop/
    ├── HoopApp.swift
    ├── Theme/HoopTheme.swift
    ├── Models/
    │   ├── HoopModels.swift
    │   └── GameEngine.swift
    └── Views/
        ├── MainTabView.swift
        ├── Onboarding/
        ├── Game/
        ├── History/
        └── Settings/
```
