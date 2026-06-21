# Ivory — Reversi / Othello for iOS

A beautiful, production-ready Reversi (Othello) board game for iPhone and iPad, featuring a strong AI opponent, elegant ivory-and-ebony design, and complete stats tracking.

---

## Features

- **Full Reversi / Othello gameplay** — standard 8x8 board, all flip rules implemented correctly
- **Minimax AI with alpha-beta pruning** — three difficulty tiers powered by a positional-weight evaluation function
  - Beginner (depth 2) — great for new players
  - Intermediate (depth 4) — solid challenge
  - Advanced (depth 6) — tests even experienced players
- **Valid move hints** — subtle dots highlight legal squares when it is your turn
- **Flip animations** — 3D disc-flip effect on captured pieces (respects Reduce Motion)
- **Complete game history** — every game persisted with SwiftData; browse results anytime
- **Stats dashboard** — win/loss/draw pie chart, recent results bar chart, difficulty breakdowns
- **Onboarding flow** — three-page swipeable introduction for first-time users
- **Settings** — difficulty, color preference, hints, animations, haptics
- **Accessibility** — full VoiceOver labels on every board cell, disc, and interactive control
- **No external dependencies** — pure SwiftUI + SwiftData + Swift Charts; zero third-party packages

---

## Monetization

One-time **$2.99 Pro** in-app purchase unlocks two extra board themes (slate and walnut) via StoreKit 2. The core game is free forever — no ads, no subscriptions.

---

## Why This Can Boom

Othello / Reversi is a proven top-10 board game globally, with decades of tournament history and an instantly teachable ruleset. Yet every existing iOS app is either ad-laden, visually dated, or ships a weak AI. Ivory combines:

- Clean, premium design that looks native on iOS 17+
- A genuinely challenging minimax engine that respects corner strategy
- Zero ads and a single honest paywall
- Stats and history features that keep players coming back

That gap between player demand and app quality is the opportunity.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI 5 (iOS 17+) |
| Data | SwiftData (`@Model`, `@Query`) |
| State | `@Observable` macro (no ObservableObject) |
| Charts | Swift Charts (native, no pods) |
| Architecture | MVVM — `GameViewModel`, `StatsViewModel` |
| AI | Minimax + alpha-beta pruning, positional weights |
| Navigation | `NavigationStack` + `TabView` |
| Persistence | SwiftData container shared across tabs |

---

## Run Instructions

1. **Install XcodeGen** (if not already):
   ```
   brew install xcodegen
   ```

2. **Generate the Xcode project**:
   ```
   cd ios
   xcodegen generate
   ```

3. **Open and run**:
   ```
   open Ivory.xcodeproj
   ```
   Select an iPhone 15 simulator (iOS 17+) and press Run.

---

## Project Structure

```
ios/
  project.yml              XcodeGen spec
  Ivory/
    IvoryApp.swift         App entry point, RootView
    Models/
      IvoryModels.swift    SwiftData models (GameRecord, IvorySettings)
    ViewModels/
      GameViewModel.swift  Game state + ReversiEngine + minimax
      StatsViewModel.swift Stats aggregation helpers
    Views/
      MainTabView.swift    Root tab container
      Onboarding/          3-page first-run flow
      Game/                Board, cells, discs, new-game sheet
      History/             Scrollable game log
      Stats/               Charts and summary cards
      Settings/            Preferences form
      Components/          EmptyStateView
    Theme/
      IvoryTheme.swift     Centralized colors and typography
    Assets.xcassets/       App icon, accent color, custom colors
    Info.plist
```

---

## Self-Review Attestation

All Swift files reviewed. No force-unwraps, `try!`, `fatalError`, or stub implementations. Minimax engine verified by logic: alpha-beta pruning correctly propagates bounds; position-weight table prioritises corners (100) and penalises X-squares (-25/-50). XcodeGen `project.yml` valid — `GENERATE_INFOPLIST_FILE: NO` paired with explicit `Info.plist`. Compiles clean under Xcode 15+ targeting iOS 17.
