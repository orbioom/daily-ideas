# Gammon — Classic Backgammon for iOS

A production-quality native iOS backgammon game with smart AI, beautiful canvas-rendered board, and full rule compliance.

## App Concept

**Gammon** is a full-featured backgammon game for iOS 17+ with:
- Complete backgammon rules (bar, bearing off, doubles, hitting blots, gammon/backgammon detection)
- 3 AI difficulty levels (Easy, Medium, Hard) with heuristic evaluation
- Pass-and-play 2-player mode
- Canvas-rendered board with 4 color schemes
- SwiftData stats persistence
- Onboarding flow
- Pro unlock ($2.99 one-time)

## Why It Can Boom

Backgammon has tens of millions of active players globally. The top iOS apps in the category are either:
- **Ad-riddled freemium apps** with aggressive monetization
- **Backgammon Galaxy** ($6.99/month subscription) with constant dice-rigging complaints from the community
- **Aging apps** not updated for modern iOS

A clean, native, fair-dice iOS app with beautiful design and a one-time price has a wide-open market. Backgammon is uniquely positioned as a "smart person's game" with strong appeal across ages 25-65 — a demographic with disposable income and App Store purchase history.

**Market size**: Backgammon has ~100M players worldwide. Even 0.1% conversion = 100,000 users.

## Monetization

**One-time $2.99 Pro unlock** includes:
- 2-Player pass-and-play mode
- 3 premium board color schemes (Emerald, Midnight, Burgundy)
- Full game history and advanced statistics
- All future features

This pricing is deliberately frictionless — no subscription anxiety, no IAP fatigue. The free tier is fully functional (vs AI, Classic board, recent stats), making the conversion pitch natural.

**Estimated revenue potential** at 10,000 downloads with 15% conversion: ~$4,500 in first month.

## Technical Stack

- **iOS 17+**, **SwiftUI 5**, **Swift 5.9**
- **@Observable** (Observation framework, not ObservableObject)
- **SwiftData** for game result persistence
- **Canvas** API for board rendering (no UIKit drawing)
- **MVVM** architecture
- **XcodeGen** project file (`project.yml`)

## Project Structure

```
ios/
  project.yml              # XcodeGen config
  Gammon/
    GammonApp.swift        # App entry, SwiftData container
    Models/
      BackgammonGame.swift # @Observable game engine + full rules
      BackgammonAI.swift   # Heuristic AI (3 difficulty levels)
      GammonResult.swift   # @Model for SwiftData persistence
    Views/
      ContentView.swift    # TabView root
      Onboarding/
        GammonOnboardingView.swift
      Game/
        GammonGameView.swift        # Main game screen
        BackgammonBoardView.swift   # Canvas board
        DiceView.swift              # Pip dice + roll button
        MoveHintView.swift          # Selection tooltip
      Rules/
        GammonRulesView.swift
      Stats/
        GammonStatsView.swift
      Settings/
        GammonSettingsView.swift    # Includes ProUnlockSheet
    Theme/
      GammonTheme.swift    # Colors, fonts, modifiers
    Assets.xcassets/       # App icon + color assets
```

## Building

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. Open `Gammon.xcodeproj` in Xcode 15+
4. Select a simulator or device and run

## Board Layout

Points are numbered 1–24 in standard backgammon convention:
- **White** moves from point 24 → point 1 (array index 23 → 0)
- **Black** moves from point 1 → point 24 (array index 0 → 23)
- **White home board**: points 1–6 (indices 0–5)
- **Black home board**: points 19–24 (indices 18–23)

Visual layout (portrait):
```
  13 14 15 16 17 18 | BAR | 19 20 21 22 23 24
  ┌─────────────────┼─────┼──────────────────┐
  │  ▼  ▼  ▼  ▼  ▼  ▼ │  │  ▼  ▼  ▼  ▼  ▼  ▼ │
  │                  │  │                   │
  │  ▲  ▲  ▲  ▲  ▲  ▲ │  │  ▲  ▲  ▲  ▲  ▲  ▲ │
  └─────────────────┼─────┼──────────────────┘
  12 11 10  9  8  7 | BAR |  6  5  4  3  2  1
```

## Self-Review Attestation

I have reviewed this codebase and attest:

- [ ] All backgammon rules are implemented correctly (movement, bar, bearing off, doubles, blot hitting, gammon/backgammon detection)
- [ ] No force unwraps (`!`) used on optionals that could be nil at runtime
- [ ] No placeholder or TODO code — every screen is fully functional
- [ ] @Observable is used correctly (not @ObservableObject)
- [ ] SwiftData schema is correct (`@Model`, proper initialization)
- [ ] AI moves happen with realistic delay (0.8s roll + 0.6s move)
- [ ] Haptics respect user toggle setting
- [ ] Stats are saved on game completion
- [ ] Pro unlock gates 2-player mode and premium themes
- [ ] Canvas rendering handles stacked pieces correctly
- [ ] Board tap detection correctly maps to point indices
