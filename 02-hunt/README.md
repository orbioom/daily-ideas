# Hunt — Boggle-Style Word Finder

## App Concept
Hunt is a fast-paced word game where you find words in a 4×4 letter grid before time runs out. Swipe to connect adjacent letters and build words — the longer the word, the higher the score.

## Why It Can Boom
- Word Hunt is the #1 most played game in iMessage Game Pigeon with millions of daily players
- Most existing Boggle apps are ad-heavy, dated, and cluttered
- Hunt is clean, offline-capable, one-time purchase with zero subscriptions

## Monetization
- Free tier: 2-minute games, daily challenge, core stats
- One-time $2.99 Pro unlock:
  - 3-minute extended mode
  - 4-letter minimum (harder challenge)
  - Board themes (dark, light, forest, ocean)
  - Unlimited daily challenge history

## Features
- 4×4 letter grid with adjacency-based word finding (including diagonals)
- 2-minute timed games with score system
- Daily challenge with streak tracking
- 3000+ word dictionary embedded (no internet required)
- Score tracking and 14-day chart via Swift Charts
- Haptic feedback on word discovery
- SwiftData persistence

## Tech Stack
- iOS 17+, SwiftUI 5, MVVM
- @Observable for reactive state
- SwiftData for persistence
- Swift Charts for stats visualization
- XcodeGen project.yml for reproducible builds

## Scoring
- 3 letters: 1 point
- 4 letters: 2 points
- 5 letters: 4 points
- 6 letters: 7 points
- 7 letters: 11 points
- 8+ letters: 16 points

## Build
1. Install XcodeGen: `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. Open `Hunt.xcodeproj` in Xcode
4. Run on device or simulator
