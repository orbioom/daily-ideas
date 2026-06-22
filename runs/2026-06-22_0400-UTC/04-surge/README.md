# Surge — Marathon & Half-Marathon Training

A production-ready native iOS app for structured marathon and half-marathon training.

## Overview

Surge gives you a **complete, structured multi-week training plan** with specific daily workouts, pacing guidance, and progression logic. It beats legacy training apps (Hal Higdon, MyRunCoach) with a modern dark athletic UI, SwiftData persistence, and smart pace calculations.

**Race types:**
- Marathon — 16-week plan, peaks at ~70km/week
- Half Marathon — 12-week plan, peaks at ~56km/week

## Tech Stack

- Swift 5 / SwiftUI
- SwiftData (iOS 17+)
- Swift Charts
- XcodeGen for project generation

## Project Structure

```
ios/
  project.yml              # XcodeGen spec
  Surge/
    SurgeApp.swift         # App entry point + ContentView + MainTabView
    Models/
      RunnerProfile.swift  # Athlete profile + RaceType enum
      PlannedRun.swift     # Plan record + RunType enum
      RunLog.swift         # Logged run entry
      SurgeSettings.swift  # App preferences
    Utilities/
      PaceEngine.swift     # Pace/distance/duration math + formatting
      PlanEngine.swift     # Generates full training plans
    Views/
      Onboarding/          # 3-step setup (race → goal time → start date)
      Today/               # Today's workout + week overview
      Plan/                # Full plan calendar + week drill-down
      Log/                 # Log a run + run history
      Insights/            # Charts: mileage, pace trend, long run progression
      Settings/            # Units, haptics, notifications, reset
      Components/          # RunTypeBadge, PaceDisplay, WeeklyGrid
    Theme/
      SurgeTheme.swift     # Colors, fonts, modifiers
```

## Getting Started

### Prerequisites
- Xcode 15+
- iOS 17+ simulator or device
- XcodeGen: `brew install xcodegen`

### Build

```bash
cd ios
xcodegen generate
open Surge.xcodeproj
```

Then press ⌘R to run.

## Features

### 5-Tab Navigation
1. **Today** — Current workout highlighted, week grid, days-to-race countdown
2. **Plan** — Scrollable 16-week calendar with week drill-down sheets
3. **Week** — Day-by-day current week view with mark-done / log actions
4. **Log** — Run history with distance/pace/effort, add runs manually
5. **Insights** — Weekly mileage bars, pace trend line, long run progression, readiness gauge

### Plan Engine
Generates Higdon-inspired progressive overload plans:
- Base building → strength → peak → taper phases
- 7 run types: Easy, Long, Tempo, Intervals, Race Pace, Cross-Train, Rest
- Recovery weeks every 4th week

### Pace Engine
- Computes all training paces from a single goal finish time
- Easy: +75 sec/km above goal pace
- Long: +60 sec/km above goal pace
- Tempo: at goal pace
- Intervals: -25 sec/km below goal pace
- Full km/mi conversion support

## Design

| Token | Hex |
|-------|-----|
| Background | `#0A0A0F` |
| Accent (blue) | `#4A90D9` |
| Highlight (orange) | `#F5821F` |
| Text | `#C8C8D0` |
| Surface | `#1A1A2E` |

## Bundle ID

`com.orbioom.surge`

## License

Private — all rights reserved.
