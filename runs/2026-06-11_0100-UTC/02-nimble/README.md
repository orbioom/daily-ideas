# Nimble

**Daily brain training with 5 cognitive mini-games**

## Problem & Audience

Lumosity and Elevate charge $60+/year for brain training. Nimble delivers the same experience — 5 diverse mini-games targeting different cognitive skills — with a transparent, lower-cost IAP. Target: productivity-focused users 20–50 who want a daily 5-minute mental warm-up.

## Features

- **Memory Grid** — Memorize highlighted cells in a grid, reproduce from memory. 3×3 → 5×5 adaptive.
- **Quick Math** — Arithmetic under a 10-second countdown. Adaptive operators and operand ranges.
- **Word Flash** — A word flashes briefly; answer questions about it. Tests reading speed and retention.
- **Pattern Game** — Simon-says color sequence. Grows by one step each round.
- **Reaction Game** — Tap the dot as fast as possible. Green = point, red = penalty.
- **Daily Score** — Aggregated score across all 5 games with a 30-day bar chart (Swift Charts)
- **Per-game breakdown** — Best score, average, level reached per game type
- **Settings** — Haptics, sound, difficulty bias, daily reminder

## Run Steps

```bash
cd runs/2026-06-11_0100-UTC/02-nimble/ios
xcodegen generate
open Nimble.xcodeproj
```

## Tech Notes

- `GameSession` and `DailyResult` persisted via SwiftData
- All games self-contained `View` structs with local `@State`; scores reported via callback
- `Timer.publish` for countdown clock in QuickMath; `DispatchWorkItem` for auto-miss in Reaction
- `TrainingViewModel` (`@Observable`) coordinates today's session

## Monetization

**Free daily limit** (3 games/day) → unlock unlimited + longer sessions for $2.99/month or $14.99/year. In-app purchase with free trial week.

## Why It Can Hit

Brain training is evergreen. The app focuses on quick, satisfying daily loops rather than lengthy sessions. The 5-game variety prevents boredom that kills Wordle-style single-game apps.

## Self-Review Attestation

- [x] All 5 mini-games fully implemented, no stubs
- [x] Daily aggregation and 30-day history chart
- [x] SwiftData models for sessions and results
- [x] 4+ distinct screens (Training hub, each game, Stats, Settings)
- [x] XcodeGen project.yml
- [x] iOS 17 `@Observable`
