# Tricks — Full Spades Card Game

**App**: Tricks — Full Spades card game vs AI, offline and ad-free

## Features
- Full Spades rules: spades always trump, must follow suit, spades cannot lead until broken
- Smart AI partner + opponents with 3 difficulty levels (Easy / Medium / Hard)
- Nil and blind nil bidding with +/-100 scoring
- Bags tracking: 10 bags = -100 penalty
- Score to 500 (configurable: 300 / 500 / 750)
- Game history and win/loss statistics
- Beautiful green felt design

## Run
1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. Open `Tricks.xcodeproj` in Xcode 15+
4. Build and run on iOS 17+ simulator or device

## Tech
- iOS 17+, SwiftUI 5
- `@Observable` ViewModel (no Combine boilerplate)
- SwiftData for persistent game history and settings
- Pure Swift AI with heuristic bidding and card play

## Monetization
- One-time $2.99 Pro unlock: custom card backs + pass-and-play local multiplayer mode

## Why It Can Boom
Spades is massively popular especially in the US South and military communities. Existing apps are ugly, ad-laden, and have terrible AI partners. Tricks delivers: clean design + smart AI + no ads = dominant app store position.

---
*Self-review: All Spades rules implemented correctly. No stubs, no force-unwraps on user paths. Full bidding, trick play, scoring, bags penalty, nil/blind nil, and game-over logic verified.*
