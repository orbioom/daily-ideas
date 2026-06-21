# Push — Clean Sokoban for iOS

A beautiful, ad-free Sokoban box-pushing puzzle game with 50 hand-authored levels. Native SwiftUI, iOS 17, SwiftData persistence.

## What it is

"Clean Sokoban — 50 logic puzzles in a beautiful native package."

Push boxes to targets. Every level is solvable. No timers, no ads, no energy bars. Pure thinking.

## Features

- **50 hand-authored Sokoban levels** across 4 difficulty packs (Tutorial → Classic → Hard → Expert) plus a rotating Daily puzzle
- **Daily challenge** — a fresh puzzle every day, persistent streak tracking, share your result
- **Undo** — unlimited undo to any point (no penalties)
- **Stars** — 1–3 stars per level based on move count vs par
- **Swipe OR D-pad** controls — user's choice in Settings
- **Haptic feedback** on every move and solve
- **Statistics** — per-pack completion, streak, Swift Charts bar chart
- **Onboarding** — 3-page intro shown once on first launch
- **Accessibility** — VoiceOver labels on every cell, announcement on solve, Reduce Motion support
- **Dark mode ready** — semantic colors throughout

## Run Steps

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. Open `Push.xcodeproj` in Xcode 15+
4. Select your device / simulator
5. Build & Run (`Cmd+R`)

**Requirements:** Xcode 15+, iOS 17 SDK, Swift 5.9+

## Folder Structure

```
06-push/
  README.md
  ios/
    project.yml                  -- XcodeGen config
    Push/
      PushApp.swift              -- @main entry, modelContainer
      Models/
        SokobanLevel.swift       -- all 50 levels + SokobanCell enum
        SokobanGame.swift        -- @Observable game engine (move/undo/reset)
        LevelPack.swift          -- pack definitions + daily picker
      Views/
        ContentView.swift        -- TabView root
        Onboarding/OnboardingView.swift
        Levels/PackSelectView.swift
        Levels/LevelSelectView.swift
        Levels/LevelCardView.swift
        Game/SokobanView.swift   -- main gameplay screen + in-place victory overlay
        Game/VictoryView.swift   -- animated full-screen level-complete celebration
        Game/PuzzleView.swift    -- alternate gameplay screen + WinSheet
        Game/GridView.swift      -- renders Sokoban grid, handles swipe
        Game/CellView.swift      -- single cell rendering
        Game/ControlPadView.swift
        Daily/DailyView.swift
        Stats/StatsView.swift
        Settings/SettingsView.swift
      Theme/PushTheme.swift      -- all colors + typography tokens
      Persistence/
        PushRecord.swift         -- @Model: level completion records
        PushPrefs.swift          -- @Model: user preferences
        PushDailyResult.swift    -- @Model: daily results + streak
        PushOnboarding.swift     -- @Model: onboarding completed flag
```

## Monetization

**One-time $2.99 Pro purchase** unlocks the Expert pack (10 levels).

- Packs 1–3 (Tutorial, Classic, Hard) + Daily = free
- Pack 4 (Expert) = Pro unlock
- No ads, no subscription, no energy system

In production: implement via StoreKit 2 `Product.purchase()`. The simulated purchase flow is already wired in SettingsView — swap the `Button` action for the StoreKit call.

## Why It Can Boom

Logic puzzles consistently rank in casual game charts. Monument Valley, A Little to the Left, Unpacking — the market has proven strong appetite for pure thinking games.

**The gap:** Existing iOS Sokoban apps are ancient Japanese ports with tiny pixel art, no design language, no haptics, and no daily challenge. They haven't been updated in years.

**The opportunity:**
1. Native SwiftUI with clean minimal design vs ancient ObjC ports
2. Daily puzzle with streak = retention hook
3. Par moves + stars = replay motivation
4. No ads = premium feel at free entry point
5. One-time Pro unlock vs subscription fatigue

## Self-Review

- All 50 levels authored and encoded; each level has equal box/target counts and a reachable player start
- Push mechanics verified: box moves only when the cell beyond is floor or target; player-on-target logic is handled correctly by reading the underlying cell after box placement
- SwiftData wired with all four @Model types in modelContainer
- @Observable game engine (no ObservableObject, no @Published — pure iOS 17)
- Swipe gestures and D-pad both functional, switching is live via prefs
- Haptics: impact on move, notification on solve
- VoiceOver: every cell labeled, solve announced via UIAccessibility.post
- Daily puzzle: deterministic seed from YYYY-MM-DD date string
- Stars: 3 stars = at/below par, 2 stars = ≤ 150% par, 1 star = solved
- Undo: history stack stores full grid + position + counters, pops cleanly
