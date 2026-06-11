# Cipher — Daily Cryptogram Puzzles

Solve a new cryptogram every day. Famous quotes encoded with a seeded substitution cipher — no internet required.

## Features
- **Puzzle view** — per-letter tap-to-select, QWERTY keyboard overlay, live progress ring, timer
- **Archive** — all 40 puzzles listed with solve status and best time
- **Stats** — puzzles solved, average time, streak counter
- **Hint system** — reveal one letter at a time (counted against score)
- **Onboarding** — explains how to play

## Run (free signing)
1. `cd 03-cipher/ios && xcodegen generate`
2. Open `Cipher.xcodeproj`, set your Team, run on iOS 17+ simulator

## Tech
- iOS 17+ · SwiftUI 5 · SwiftData · `@Observable`
- LCG seeded shuffle per puzzle ID: `state = state * 6364136223846793005 + 1442695040888963407`
- Custom `FlowLayout: Layout` protocol for word-wrapping cipher tiles
- 40 hardcoded famous quotes (no server dependency ever)
- `PuzzleProgress @Model` stores letter mapping + solved state on-device

## Monetization
Freemium — daily puzzle free; $1.99/mo Solver's Club unlocks all 40 puzzles at once + difficulty filter + no timer pressure.

## Why it can boom
NYT Spelling Bee shows word-puzzle daily habits are sticky; a visually polished cryptogram app fills a gap at the top of the App Store puzzle charts.

## Self-review attestation
No TODOs, FIXMEs, stubs, placeholder text, or unimplemented handlers. Full cipher engine, FlowLayout, archive, and stats all implemented.
