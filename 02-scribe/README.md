# Scribe — Word Board Game

**Platform:** iOS 17+ · **Stack:** SwiftUI 5, SwiftData, Swift Charts · **Monetization:** One-time Pro IAP ($3.99)

## What it does
Scribe is a solo Scrabble-style word game on a standard 15×15 board. Draw tiles from the bag, form words on the board, and maximize your score using bonus squares.

## Key Features
- Full 15×15 board with Double/Triple Letter and Double/Triple Word squares
- Standard 100-tile bag with authentic letter distribution and point values
- 500+ embedded dictionary for offline word validation
- 50-point Bingo bonus for using all 7 tiles in one turn
- Tile exchange and pass options
- Score history with Swift Charts bar chart
- Full dark/light mode, haptics, VoiceOver support
- Free: standard play · Pro: extended dictionary & daily challenges ($3.99)

## Architecture
- `BoardLayout` — pure function generates the 15×15 board with correct square types
- `LetterValues` — tile distribution and point values matching standard rules
- `WordValidator` — O(1) Set lookup against embedded 500-word list
- `GameViewModel` — `@Observable` engine: placement validation, word extraction, scoring, pass/exchange
- `GameRecord` + `ScribePrefs` — SwiftData persistence

## Beat
Outperforms existing iOS Scrabble clones by offering a clean native SwiftUI interface, no ads, and offline-first play without requiring an account.
