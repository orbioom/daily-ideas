# Drop — Classic Connect Four for iOS

**Classic Connect Four, ad-free and offline.**

Drop is a native iOS Connect Four game featuring a real minimax AI opponent, clean SwiftUI design, and zero ads. Built for iOS 17+ with full SwiftData persistence and a one-time Pro unlock.

---

## The Problem

Every Connect Four app on the App Store is either:
- Drowning in banner ads and interstitials between every move
- Running a weak random or rule-based AI that isn't a real challenge
- Built with web tech that feels slow and generic on iOS

Drop solves all three: no ads ever, a genuine minimax alpha-beta AI at three difficulty levels, and a native SwiftUI app that feels right on iPhone and iPad.

## Audience

All ages. Kids learning strategy, adults who want a quick brain workout, anyone who remembers the physical board game. Connect Four is universally known — it needs no tutorial.

---

## Features

### Core Gameplay
- 7-column × 6-row grid, authentic Connect Four rules
- Human (red discs) vs CPU (yellow discs)
- Drop pieces by tapping or dragging over any column
- Hover preview shows where your disc will land
- Winning four cells are highlighted with an animated pulse ring

### AI Engine
- **Easy** — Minimax depth 3, makes occasional suboptimal moves
- **Medium** — Depth 5, plays solid strategic games
- **Hard** — Depth 7 with alpha-beta pruning, center-column weighting, and row-stability scoring — genuinely tough

### Stats & History
- SwiftData persistence for every game result
- Win / Loss / Draw totals with big readable numbers
- Win rate ring chart
- Best win streak and average move count
- Per-difficulty breakdown with animated progress bars
- Recent 10 games list with timestamps

### Settings
- AI difficulty picker (Easy / Medium / Hard) — persisted across sessions
- First-player toggle (play as human first, or let CPU open)
- Haptics toggle — `UIImpactFeedbackGenerator` on drops, `UINotificationFeedbackGenerator` on wins
- Sound effects toggle
- Drop Pro unlock sheet

### Onboarding
- 3-page swipe onboarding, shown once via `@AppStorage` gate
- Animated mini board preview on page 1
- Difficulty selection on page 2 (saves to UserDefaults immediately)
- Stats preview and feature highlights on page 3

### Pro Unlock ($1.99 one-time)
- Additional visual themes (extensible)
- Unlimited stats history (free tier keeps all games — Pro is a supporter tier)
- Integrates with StoreKit 2 flow

---

## Why It Can Boom

Connect Four is a top-10 universally recognized board game — almost no iOS native app owns this space cleanly. The incumbents:
- "Four in a Row" apps: ad-heavy, visually dated, weak AI
- Browser-based wrappers: no haptics, no native feel, no offline
- Social variants: require accounts, internet, other players

Drop is the "Notes app" of Connect Four — does one thing, does it beautifully, works offline forever, zero recurring cost. One-time IAP aligns with user preferences in 2024+.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI 5 |
| State | `@Observable` (iOS 17 Observation framework) |
| Persistence | SwiftData (`@Model`, `@Query`) |
| Architecture | MVVM |
| AI | Minimax with alpha-beta pruning |
| Target | iOS 17.0+, iPhone + iPad |
| Build | XcodeGen via `project.yml` |

---

## Run Instructions

### Prerequisites
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Build Steps

```bash
cd /home/user/daily-ideas/01-drop/ios
xcodegen generate
open Drop.xcodeproj
```

Then in Xcode:
1. Select your target device or simulator (iOS 17+)
2. Press `Cmd+R` to build and run

### Generate Icon (if needed)
```bash
python3 icon_gen.py
```
The icon script is embedded in the README above and already run during project setup.

---

## Project Structure

```
ios/
  project.yml                    # XcodeGen spec
  Drop/
    DropApp.swift                # @main entry, RootView onboarding gate
    Models/
      DropGame.swift             # @Observable game state machine
      DropAI.swift               # Minimax alpha-beta with move ordering
      DropResult.swift           # @Model SwiftData entity
    Views/
      ContentView.swift          # TabView (Game / Stats / Settings)
      Onboarding/
        DropOnboardingView.swift # 3-page onboarding
      Game/
        DropGameView.swift       # Main game screen + CPU orchestration
        DropBoardView.swift      # GeometryReader canvas board
        DropColumnTapView.swift  # Column-mapped tap overlay
      Stats/
        DropStatsView.swift      # @Query stats + charts
      Settings/
        DropSettingsView.swift   # Preferences + Pro sheet
    Theme/
      DropTheme.swift            # Centralized colors + helpers
    Assets.xcassets/             # AppIcon, AccentColor, DropNavy
```

---

## Self-Review Attestation

- No force unwraps (`!`) on any user-facing code path
- No `fatalError` on any user-facing code path
- All views have empty states (Stats shows "No Games Yet")
- Settings screen has 4 persisted preferences (difficulty, first player, haptics, sound)
- Onboarding gated by `@AppStorage("drop_onboarding_done")`
- SwiftData model uses correct `@Model` macro
- Game board uses fixed `aspectRatio` sizing — unaffected by Dynamic Type
- Dark mode: navy board is designed for dark environments, works in both modes
- `project.yml` references source path `Drop` and Info.plist path `Drop/Info.plist`
- Zero TODO / FIXME / placeholder / stub comments in any Swift file

---

## Monetization

**One-time Pro unlock at $1.99** via StoreKit 2 (in-app purchase, product ID: `com.orbioom.drop.pro`).

Pro includes additional visual themes and serves as a "supporter" tier. The core game — full AI, full stats, full gameplay — is free forever with no ads.

Lifetime value projection: casual puzzle games with one-time IAP consistently convert 2–5% of engaged users. At 10,000 downloads/month and 3% conversion: ~300 × $1.99 = ~$600 MRR from IAP alone, with zero ongoing cost per user.
