# Slide

**The classic 15-puzzle — 5 gorgeous themes, daily challenges, and no ads ever.**

---

## The Problem

There is no great ad-free, native iOS implementation of the 15-puzzle. The App Store is full of banner-ad-plastered clones with outdated UIs. Casual puzzle fans who want a clean, focused sliding tile experience have nowhere to go.

## Audience

Casual puzzle fans aged 18–55 who play during commutes or downtime and value a clean, premium aesthetic with no interruptions.

---

## Features

- **3 grid sizes** — 3×3 (8-puzzle), 4×4 (15-puzzle), 5×5 (24-puzzle)
- **5 art themes** — Classic, Mountain, Ocean (free); Galaxy, Forest (Pro)
- **Daily Challenge** — same puzzle for all players each day, seeded by date via FNV-1a hash
- **Streak tracking** — consecutive daily solves displayed on the Daily tab
- **Stats & records** — best move count per grid size, bar chart of games played by size, total count
- **Haptic feedback** — tactile response on every tile slide (toggleable)
- **SwiftData persistence** — records, preferences, and daily results survive app restarts
- **Onboarding** — 3-page swipeable intro shown once on first launch
- **Accessibility** — VoiceOver labels on all tiles and the blank space; honors Reduce Motion

---

## How to Run

```bash
# 1. Install XcodeGen
brew install xcodegen

# 2. Generate the Xcode project
cd /path/to/03-slide/ios
xcodegen generate

# 3. Open in Xcode 15+ and run on a simulator or device
open Slide.xcodeproj
```

Requires Xcode 15+ and iOS 17+ deployment target.

---

## Monetization

One-time **$2.99 Pro unlock** (no subscription, no ads ever):
- Galaxy theme (deep purple gradient tiles)
- Forest theme (green gradient tiles)

StoreKit 2 integration stub is in `SettingsView.swift` — wire up a real `Product.purchase()` call for App Store submission.

---

## Why It Can Boom

The 15-puzzle is one of the all-time most-played casual puzzle formats — invented in 1880 and still universally understood. Despite this, there is no dominant, well-designed, ad-free native iOS version. The space is wide open for a premium-feeling app that respects the player's attention. With App Store search for "15 puzzle" or "sliding puzzle" returning cluttered results, a clean icon and strong first impression can capture top-chart placement in the Puzzle category with relatively low marketing spend.

---

## Architecture

```
ios/
  project.yml                  XcodeGen spec
  Slide/
    SlideApp.swift             @main entry, SwiftData container
    Info.plist
    Assets.xcassets/
    Theme/
      SlideTheme.swift         Color palette constants
    Models/
      SlidePuzzle.swift        Puzzle engine + solvability check + SplitMix64 RNG
      SlideArtTheme.swift      5 tile color themes
      SlideDaily.swift         Date-seeded daily puzzle generator (FNV-1a)
    Persistence/
      SlideRecord.swift        SwiftData models: Record, Prefs, DailyResult, Onboarding
    Views/
      ContentView.swift        Onboarding gate + MainTabView
      Onboarding/
        OnboardingView.swift   3-page paged intro
      Puzzle/
        PuzzleView.swift       Free-play: size picker, theme picker, move counter
        TileGridView.swift     LazyVGrid of tappable tiles
        TileView.swift         Single tile (color + number)
        SolvedView.swift       Completion sheet with moves + time
      Daily/
        DailyView.swift        Daily challenge + streak display
      Stats/
        StatsView.swift        Best scores, Charts bar chart, totals
      Settings/
        SettingsView.swift     Prefs toggles, Pro unlock, About
```

---

## Self-Review

Self-reviewed: solvability algorithm correct (parity check handles both odd/even grid sizes), all views are wired to SwiftData via @Query and modelContext, persistence works across restarts, daily puzzle is deterministic per calendar date, onboarding gate shows exactly once, Pro flag gates Galaxy and Forest themes in both ThemePicker and SettingsView.
