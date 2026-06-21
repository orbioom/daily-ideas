# Typo — Typing Speed Trainer

**Category:** Productivity / Education  
**Platform:** iOS 17+  
**Run:** 2026-06-21_run4 · #354

## What It Does

Typo is an iOS typing speed trainer with a clean, minimal interface inspired by monkeytype. Test your WPM and accuracy across four modes (Words, Sentences, Code, Numbers), track results over time, and study typing fundamentals through expandable lesson cards — all fully offline.

## Feature Screens

| Screen | Description |
|--------|-------------|
| **Practice** | AttributedString character display (correct=white, wrong=red+highlight, cursor=blue background, pending=grey); hidden TextField tap-to-focus; live WPM + accuracy header; result card with WPM/raw/accuracy/correct chars; config sheet for mode/duration/word count |
| **History** | All-time best/avg WPM + avg accuracy stat cards; mode filter chips; WPM sparkline chart (last 20 tests with dots); scrollable result list with streaks |
| **Lessons** | 8 expandable lesson cards: Home Row, Touch Typing, Finger Placement, Rhythm, Common Bigrams, Number Row, Accuracy Over Speed, Ergonomics — each with tips and optional practice string |
| **Settings** | Show live WPM toggle, haptics toggle, sound effects, tests completed, best WPM, clear history |

## Technical Highlights

- **TypingViewModel** — @Observable; timer-based test, char-by-char comparison, WPM/raw WPM/accuracy calculation, `CharState` enum (correct/wrong/cursor/pending)
- **TypingTextView** — AttributedString rendering for real-time character coloring
- **TypingContent** — 200+ common English words, prose sentences, Swift code snippets, number sets
- **WpmSparkline** — Canvas-based line chart with dots
- **SwiftData** — TypoResult, TypoSettings

## Self-Review

- ✅ WPM formula: (correct chars / 5) / elapsed minutes — standard definition
- ✅ AttributedString API used correctly (foregroundColor, backgroundColor attributes)
- ✅ Hidden TextField approach handles iOS keyboard without showing ugly system text field
- ✅ 4 test modes × 4 durations × 4 word counts = full configurability
- ✅ Dark navy-indigo theme
- ✅ XcodeGen project.yml

## Monetization

Pro IAP: custom word lists, punctuation/capitalization modes, advanced analytics, export history CSV. Free tier: all 4 modes, full history.
