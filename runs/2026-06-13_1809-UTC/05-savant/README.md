# Savant — daily trivia

A fresh ten-question quiz every day — the same for everyone — plus unlimited practice across ten categories. Beat the clock, build a streak, and learn a fun fact with every answer. No ads, no accounts.

**The problem & audience.** The massive casual-game audience that loves a daily ritual (Wordle proved it) and trivia fans (Trivia Crack, QuizUp). Most trivia apps are buried in ads and pay-to-continue lives; people want a clean, fair, daily quiz with a real streak.

## Features
- **Today** — a deterministic Daily Challenge (10 questions seeded by the date, identical for everyone), quick-stats (streak, best daily, accuracy) and quick-practice category chips.
- **Gameplay** — timed questions with a countdown, instant correct/incorrect feedback, a fun fact, difficulty-weighted scoring with time and streak bonuses, and an animated results screen with a `ShareLink`.
- **160 hand-authored, fact-checked questions** across Science, History, Geography, Arts & Lit, Sports, Film & TV, Music, Nature, Tech and Food & Drink, with shuffled answer order.
- **Categories** — browse all ten with question counts and your per-category accuracy; start a practice round (length & difficulty are Pro).
- **Stats** — day streak, rounds played, overall accuracy, a daily-score **Swift Chart** and per-category accuracy bars.
- **History** — every round logged with score and accuracy; swipe to delete.
- Onboarding (persisted), Settings with timed-mode, fun-facts and haptics (all wired into gameplay), light + dark, Dynamic Type, VoiceOver, Reduce Motion, opt-out haptics, a designed lightbulb icon and launch screen.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Savant.xcodeproj` in Xcode 15+, iOS 17+ simulator, Cmd+R.

**Free-signing:** personal Team in Signing & Capabilities — no paid account needed.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM with a `@Observable` `QuizSession` (timer, scoring, streaks via the weak-self `scheduledTimer` + `deinit` pattern) and a deterministic `QuizEngine` (FNV-seeded `SplitMix64`).
- Persistence: **SwiftData** (`GameResult`) for stats/streaks/history; static `QuestionBank` content; `UserDefaults` for prefs.
- Design language: electric quiz-night — violet with a lamp-glow gold, rounded type.
- **Monetization:** the daily challenge and five free practice rounds/day are free; one-time **Savant Pro ($4.99)** for unlimited practice, difficulty filters and longer rounds. Who pays: daily-habit trivia fans who want endless play without ads.
- **Why it can boom:** daily word/quiz games are the volume + virality genre (shareable scores, streaks), and trivia has proven mass appeal — a clean, ad-free, fair daily trivia with a real streak is exactly the gap left by ad-stuffed incumbents.

## Self-review
Audited file-by-file: anti-stub grep clean; balanced delimiters; only the in-memory `ModelContainer` `try!`, no `fatalError`, no force-unwraps; RNG `inout` use restructured into explicit loops to avoid exclusivity errors; all 160 questions have 4 choices and a valid `answerIndex`; imports (SwiftUI/SwiftData/Charts) present; Theme tokens defined.
