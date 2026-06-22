# Scrawl — Pass-the-Phone Pictionary Party Game

The offline Pictionary game — draw secret words, pass the phone, and guess what your team drew. No Wi-Fi, no accounts, just fun.

## Features

- **5 Word Packs** — Animals, Movies & TV, Food & Cooking, Sports & Activities, Everyday Life (40 words each)
- **Custom Word Lists** — Create your own lists with inside jokes, local references, anything
- **2–8 Teams** — Play with friends, family, or coworkers
- **Flexible Timer** — 30, 60, or 90 seconds per drawing
- **PencilKit Canvas** — Smooth drawing with finger or Apple Pencil
- **Haptic Feedback** — Success/failure pulses, timer warnings
- **Dark Mode** — Full light and dark mode support
- **Offline First** — Zero Wi-Fi required, zero accounts needed
- **SwiftData Persistence** — Game history, stats, custom lists all saved locally

## Tech Stack

- **SwiftUI** — All views
- **PencilKit** — Drawing canvas
- **SwiftData** — Local persistence
- **@Observable** — Game engine state management
- Minimum iOS 17.0

## Project Structure

```
ios/
  project.yml              # XcodeGen config
  Scrawl/
    ScrawlApp.swift         # App entry + tab navigation
    Models/                 # SwiftData models
    Utilities/              # Game engine + word packs
    Views/
      Onboarding/           # 3-step onboarding
      Home/                 # Home screen
      Game/                 # Full game flow (setup → draw → guess → result)
      Packs/                # Word pack browser
      Custom/               # Custom word list editor
      Stats/                # Game history & stats
      Settings/             # App settings
      Components/           # Reusable UI components
    Theme/                  # Design system (colors, fonts, modifiers)
    Assets.xcassets/        # App icon, colors
```

## Getting Started

1. Install XcodeGen: `brew install xcodegen`
2. From the `ios/` directory: `xcodegen generate`
3. Open `Scrawl.xcodeproj`
4. Build and run on iOS 17+ device or simulator

## Game Flow

1. **Setup** — Enter team names, pick a word pack, set timer and rounds
2. **Word Reveal** — Artist sees secret word privately (others look away)
3. **Drawing** — Artist draws on full-screen canvas with countdown timer
4. **Guessing** — Pass phone to guessers; they see the drawing and type or say their answer
5. **Result** — Correct/wrong revealed, score updated, next turn
6. **Game Over** — Winner announced, final scores shown, option to play again

## Monetization

- **Free**: Animals + Everyday Life packs, Sports pack, 1 custom list, 2–4 teams
- **Pro ($2.99 one-time)**: All 5 packs, unlimited custom lists, up to 8 teams, all future packs

## Design

- **Background**: Warm cream `#FFFEF5`
- **Text**: Charcoal `#1C1C1E`
- **Primary**: Sky blue `#4A90D9`
- **Accent**: Coral `#FF6B6B`
- **Typography**: SF Pro Rounded (system rounded)
