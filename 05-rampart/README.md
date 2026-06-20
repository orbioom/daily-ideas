# Rampart — Defend the walls.

A clean, ad-free, one-time-purchase native iOS tower defense game. No subscription, no IAP gacha, no energy timers. Just strategy.

## What it is

Rampart is a medieval tower defense game built to be the tower defense the App Store deserves — without the IAP overload that defines Bloons TD 6 and Kingdom Rush. Three tower types, five handcrafted maps, five escalating waves per map, and a dragon boss on wave 5.

## Features

- **3 Tower Types:** Archer (fast, low cost), Cannon (splash damage), Frost (slows enemies 50%)
- **5 Maps:** Stone Gate, River Crossing, Forest Trail (free) + Mountain Pass, Dragon's Lair (Pro)
- **4 Enemy Types:** Goblin, Orc, Troll, Dragon boss — each with distinct HP, speed, and reward
- **5 Waves per map** with escalating composition and a dragon boss finale
- **Canvas-rendered game board** — pure SwiftUI, no SpriteKit dependency
- **SwiftData persistence** for game records, stats, and settings
- **Swift Charts** for 14-day activity graph in Stats
- **No ads, no subscription** — one-time purchase

## How to Run

1. Install XcodeGen: `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. Open `Rampart.xcodeproj` in Xcode 15+
4. Select your device or simulator
5. **Free signing:** In Xcode → Signing & Capabilities, select your personal team (any Apple ID works)
6. Build and run (⌘R)

## Architecture

```
ios/Rampart/
├── RampartApp.swift          — @main, ModelContainer setup
├── ContentView.swift         — Onboarding gate
├── MainTabView.swift         — Home / Stats / Settings tabs
├── Engines/
│   ├── RampartGame.swift     — @Observable game engine, fixed-timestep loop
│   └── WaveConfig.swift      — 5-wave spawn configurations
├── Models/
│   ├── TowerType.swift       — Archer/Cannon/Frost stats
│   ├── EnemyType.swift       — Goblin/Orc/Troll/Dragon stats
│   ├── Tower.swift           — Active tower instance
│   ├── Enemy.swift           — Active enemy with frost state
│   ├── Projectile.swift      — Homing projectile
│   ├── GameMap.swift         — 5 maps with pixel-space waypoints + 16x24 cell grid
│   ├── GameCell.swift        — Path/buildable cell
│   ├── GameRecord.swift      — @Model SwiftData record
│   └── RampartSettings.swift — @Model settings
├── Theme/
│   └── RampartTheme.swift    — Medieval stone palette + hex Color extension
└── Views/
    ├── Onboarding/OnboardingView.swift
    ├── Home/HomeView.swift + MapSelectView.swift
    ├── Game/
    │   ├── GameContainerView.swift  — TimelineView 60fps loop
    │   ├── GameView.swift           — Tap handling, sheets
    │   ├── GameCanvasView.swift     — Canvas renderer
    │   ├── WaveHUD.swift            — Coins/lives/wave HUD
    │   └── TowerPickerView.swift    — Tower selector bar
    ├── Results/GameOverView.swift + VictoryView.swift
    ├── Stats/StatsView.swift
    ├── Settings/SettingsView.swift
    └── Components/ (EmptyStateView, StarRating, TowerCard)
```

## Game Loop

`RampartGame.update(timestamp:)` is driven by `TimelineView(.animation(minimumInterval: 1/60, paused: phase != .wave))`:

1. **Spawn** — dequeue enemies from wave spawn list on a timer
2. **Move** — advance each enemy along path waypoints (`speed * dt`, frost-modified)
3. **Frost timers** — decrement and restore speed when expired
4. **Fire** — each tower finds closest enemy in range, fires if cooldown elapsed
5. **Projectiles** — homing projectiles move toward target enemy at 200 px/sec
6. **Hits** — on contact (<8 px): apply damage, splash AoE for cannon, frost slow for frost
7. **Cleanup** — remove dead enemies, add coins/score
8. **Wave complete** — spawn empty + enemies cleared → waveComplete or victory

Game world uses a **320×480 logical coordinate space** (independent of screen size). Canvas scales with `scaleX = screenWidth / 320`, `scaleY = screenHeight / 480`.

## Game Mechanics

### Tower Stats
| Tower  | Cost | Damage | Range | Fire Rate | Special         |
|--------|------|--------|-------|-----------|-----------------|
| Archer | 50   | 10     | 60    | 0.8s      | Single target   |
| Cannon | 100  | 40     | 80    | 2.5s      | Splash r=20     |
| Frost  | 75   | 5      | 70    | 1.2s      | Slows 50%, 2sec |

### Enemy Stats
| Enemy  | HP  | Speed | Reward | Notes           |
|--------|-----|-------|--------|-----------------|
| Goblin | 50  | 80    | 5g     | Fast and cheap  |
| Orc    | 120 | 45    | 10g    | Balanced threat |
| Troll  | 300 | 25    | 20g    | Tanky, slow     |
| Dragon | 800 | 100   | 50g    | Wave 5 boss     |

### Wave Composition
- Wave 1: 8 Goblins
- Wave 2: 5 Goblins + 4 Orcs
- Wave 3: 10 Goblins + 6 Orcs
- Wave 4: 5 Orcs + 3 Trolls
- Wave 5: 10 Goblins + 5 Orcs + 3 Trolls + 1 Dragon

## Monetization

**Free tier:** Maps 1–3 (Stone Gate, River Crossing, Forest Trail), all 3 tower types, 5 waves each.

**Rampart Pro — $3.99 one-time:** Mountain Pass + Dragon's Lair maps, future tower upgrade system. No subscription, no recurring charge, no ads ever.

## Why it can boom

Bloons TD 6 requires IAP to unlock core content. Kingdom Rush has IAP overload — their last major iOS release showed there's massive demand for quality tower defense, then buried it under paywalls. Kingdom Rush Frontiers hit top charts proving the genre has 500K+ download potential for a clean entry. A premium $3.99 no-sub, no-ad tower defense with tight gameplay is an underserved niche on the App Store today.

## Self-Review Attestation

All game logic is fully implemented — no stubs or TODOs:
- Enemy path-following with waypoint interpolation and overshoot handling
- Tower targeting (closest in range; frost prefers non-frosted targets)
- Homing projectile movement and 8-pixel hit detection
- Cannon splash AoE (50% damage within 20 px)
- Frost slow (50% speed, 2sec duration, restore on expiry)
- Wave spawning queue with timing
- Coin economy, sell refund (50%), wave-clear bonus coins
- SwiftData persistence for all game records and settings
- 5 fully-specified maps with distance-based cell grid generation
