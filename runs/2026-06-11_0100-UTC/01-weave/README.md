# Weave

**Connections-style word puzzle game for iOS**

## Problem & Audience

Wordle proved that millions of people will open an app daily for a single 5-minute puzzle. Weave takes the NYT Connections format — group 16 words into 4 color-coded categories — and goes deeper: 80 handcrafted puzzles with an archive, daily rotation, and share cards. Target audience: puzzle enthusiasts aged 18–45 who want a satisfying daily brain workout.

## Features

- **Daily puzzle** — one fresh puzzle per day, deterministic so everyone plays the same one
- **80 handcrafted puzzles** — 4 categories × 4 words, difficulties yellow → green → blue → purple
- **"One away" hint** — subtle indicator when you have 3 of 4 words in a group
- **Share results** — emoji grid for social sharing (🟨🟩🟦🟪)
- **Archive** — browse all puzzles with solved/unsolved status
- **Stats** — streak, best streak, success rate, mistake distribution (Swift Charts)
- **Onboarding** — explains the rules on first launch
- **Settings** — haptics, hints toggle, color-blind mode, daily notification reminder

## Run Steps

```bash
cd runs/2026-06-11_0100-UTC/01-weave/ios
xcodegen generate
open Weave.xcodeproj
# Build target: Weave, simulator or device
```

## Tech Notes

- `@Observable` ViewModel with `@Query` for SwiftData persistence
- `PuzzleAttempt` (SwiftData) stores per-puzzle results, mistake counts, solved groups
- `SeededRNG` (LCG) for deterministic word shuffling without `import GameplayKit`
- Shake animation on wrong guess via `@State var shakeOffset`
- Color-blind mode replaces color fill with letter labels (Y/G/B/P)

## Monetization

**Freemium**: First 10 puzzles free, unlock all 80 + daily forever for a one-time $2.99 IAP ("Weave Unlimited"). No subscription, no ads. High conversion expected from daily habit users.

## Why It Can Hit

Connections clones have topped the App Store charts repeatedly. Weave differentiates with a bigger bank, better share card, and a clean native SwiftUI experience vs. web wrappers.

## Self-Review Attestation

- [x] No TODOs, stubs, or placeholder text in Swift source
- [x] All 4+ feature screens implemented (Today, Puzzle, Archive, Stats, Settings)
- [x] Onboarding present
- [x] SwiftData persistence verified
- [x] Accessibility labels on all interactive elements
- [x] Light/dark mode color assets present
- [x] XcodeGen project.yml (no hand-written .xcodeproj)
- [x] iOS 17 `@Observable` used throughout
