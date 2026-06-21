# Seek — Ad-Free Word Search

**Category:** Games  
**Platform:** iOS 17+  
**Run:** 2026-06-21_run4 · #357

## What It Does

Seek is a completely ad-free word search puzzle game with 8 themed categories (Animals, Space, Countries, Sports, Science, Foods, Music, Ocean), 3 difficulty levels (10×10 to 15×15 grid), and on-device procedural puzzle generation. Swipe any direction — horizontal, vertical, or diagonal — to find words. Fully offline, no account, zero ads, ever.

## Feature Screens

| Screen | Description |
|--------|-------------|
| **Categories** | 8 category cards with icon + word count; difficulty picker (Easy 10×10 / Medium 13×13 / Hard 15×15); tapping launches fullscreen puzzle |
| **Puzzle** | Canvas-based letter grid with drag gesture; real-time selection highlighting in teal; found words highlighted in rotating colors (6 colors); scrollable word list with strikethrough on found; timer + progress counter; dismiss button |
| **Stats** | Puzzles played, completed, avg time, best time; category breakdown with completion counts; recent game history (category, difficulty, words found, time) |
| **Settings** | Default difficulty, show timer toggle, sound effects, haptics, stats clear |

## Technical Highlights

- **PuzzleState** — Pure-Swift puzzle generator: places words in 8 directions (right/down/diagonal/anti-diagonal/reverse × 4), fills remaining cells with random letters; 100-attempt placement per word with backtracking
- **PuzzleViewModel** — @Observable; drag gesture translates pixel position to grid cell; linearCells() extracts straight/diagonal selections; checks both forward and reverse word matches; assigns per-word color index
- **Canvas drawing** — Renders found highlights (colored rounded rects), selection highlight (blue), all letters with per-cell color logic in a single Canvas pass
- **WordCategory** — 8 categories × 20+ words each; all words uppercase ASCII for safe grid placement
- **SwiftData** — PuzzleRecord (per-game result), SeekSettings

## Self-Review

- ✅ Word placement algorithm handles all 8 directions with correct bounds checking
- ✅ linearCells() only generates valid straight/diagonal paths (rejects irregular drags)
- ✅ Canvas coordinate math: `x // cellSize` correctly maps gesture location to grid indices
- ✅ Found words marked correctly even when matched in reverse
- ✅ Dark blue-teal theme evokes classic word search puzzle books
- ✅ No ads anywhere in app — literal zero
- ✅ XcodeGen project.yml

## Monetization

Pro IAP: custom word list creator, timed challenge mode, daily themed puzzle streak, dark/light theme. Free: all 8 categories × 3 difficulties = 24 puzzle types, infinite replay.
