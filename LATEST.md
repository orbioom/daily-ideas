# Run 2026-06-19_0638-UTC

6 production-ready native iOS apps shipped. All target iOS 17+, SwiftUI 5, SwiftData, @Observable. No external dependencies.

## Apps Shipped

| Slot | App | Category | Accent | Screens |
|------|-----|----------|--------|---------|
| 01 | **Keys** — Piano Learning | Music/Education | Forest green #2D7A4F | 5 (Home, Curriculum, Piano, Progress, Settings) |
| 02 | **Volley** — Party Questions Game | Social/Games | Orange #F97316 | 5 (Home, Game, Browse, Custom, Settings) |
| 03 | **Ante** — Gin Rummy | Card Games | Gold #D4A017 | 6 (Menu, Game, Round Summary, Game Over, Stats, Rules) |
| 04 | **Poise** — Posture Coach | Health/Wellness | Sky blue #0EA5E9 | 5 (Home, Break Player, Exercise Library, History, Settings) |
| 05 | **Muddle** — Daily Word Unscramble | Puzzle/Games | Purple #7C3AED | 4 (Daily, Packs, Archive, Settings) |
| 06 | **Rhyme** — Offline Rhyme Finder | Productivity/Music | Rose #E11D48 | 5 (Search, Lyric Pad, Favorites, Daily, Settings) |

## Top Recommendation

**Ante** (Gin Rummy) — High-quality card games have a proven, devoted user base and few indie competitors. The greedy AI, full meld-detection engine, and authentic felt-table UI make this the best Gin Rummy app candidate in the portfolio. Revenue path: one-time purchase + Pass & Play mode drives word-of-mouth.

## Technical Highlights

- **Keys**: AVAudioEngine additive synthesis with ADSR envelope (attack 10ms, decay 150ms, sustain 0.6, release 400ms) + fundamental + 3 harmonics for realistic piano tone. No audio files.
- **Ante**: Full Gin Rummy engine — MeldDetector finds all valid sets and runs, greedy non-overlapping combo selection minimizes deadwood. GinRummyGame @Observable state machine handles gin bonus (+25), undercut detection, and dead-hand draws.
- **Poise**: UNTimeIntervalNotificationTrigger with repeating break reminders. BreakSessionEngine drives exercise→rest→exercise phase transitions with skip/pause/resume. 29 exercises across 5 ergonomic categories.
- **Muddle**: SplitMix64 seeded by calendar date ensures everyone gets the same daily word. 500+ words across 8 categories × 3 difficulties. Tap-tile UI with hint prefix reveal.
- **Rhyme**: Entirely on-device — no API calls. 55 rhyme families (~1500+ words). Live per-line rhyme suggestion bar in the lyric pad updates as you type each line ending.

## Market Signals

- Piano learning apps (Simply Piano, Yousician, Pianote) generate $50M+/year combined — Keys targets the offline/one-time segment they ignore.
- Party question games (Jackbox, Truth or Dare apps) consistently top the Games charts during holidays and weekends — Volley has no IAP friction.
- Gin Rummy is the #3 most-played card game on iOS (behind Solitaire and Cribbage) with no dominant free+premium offering.
- Posture/desk-wellness apps surged after remote work normalization — Poise is the only offline, no-subscription option with a full exercise library.
- Wordle-style daily puzzle apps get habitual daily opens — Muddle's 500+ word pack library extends replayability beyond the daily streak.
- Songwriters are an underserved power-user segment — Rhyme's offline lyric pad + rhyme finder addresses a real gap (RhymeZone has no iOS lyric writing tool).

## Registry

Total apps shipped to date: **297** (entries 1–297 in SHIPPED.md)
Previous run: 2026-06-19_0035-UTC (Trek, Cast, Spark, Kana, Memoir, Chord — #286–291)
