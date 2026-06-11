# Latest run — 2026-06-11_0100-UTC

Six production-ready native iOS apps, all built (slots 01–06), in `runs/2026-06-11_0100-UTC/`. Each ships a XcodeGen `project.yml` (`xcodegen generate` in its `ios/` folder), a real designed 1024×1024 AppIcon, light/dark color assets, accessibility labels, and SwiftData persistence. Anti-stub grep clean; every Swift file reviewed against iOS 17 SDK.

## The six

- **Weave** — built — `01-weave` — Connections-style word-grouping puzzle: 80 handcrafted puzzles (4 groups × 4 words, color-coded difficulties), daily rotation via LCG seeding, one-away hint, emoji share card, archive with attempt history, streak + mistake Charts, color-blind mode. — Monetization: first 10 puzzles free; $2.99 one-time "Weave Unlimited." — Why it can boom: Connections clones top App Store charts repeatedly; a clean native SwiftUI entry with 80 puzzles beats web wrappers.

- **Nimble** — built — `02-nimble` — Daily cognitive brain training: 5 mini-games (MemoryGrid, QuickMath, WordFlash, PatternGame, ReactionGame), adaptive difficulty, daily aggregate score with 30-day bar chart, per-game breakdown (SwiftData). — Monetization: 3 games/day free; Pro $2.99/month for unlimited. — Why it can boom: brain training is evergreen; 5-game variety beats single-game Wordle-fatigue.

- **Loft** — built — `03-loft` — Vision board & goal tracker: boards by life category, PhotosPicker image collage with captions, per-board affirmations, Goals with cascade Milestones + progress bars, FileManager JPEG store, completion stats Charts. — Monetization: 3 boards free; Loft Pro $3.99/month. — Why it can boom: vision board apps top Lifestyle charts; a fast native app beats slow web tools.

- **Skim** — built — `04-skim` — RSVP speed reader 100–1000 WPM: DispatchQueue-recursive word-tick engine, 1–3 word chunks, focus guide lines, 4 color themes, font-size stepper, article library, reading session history (WPM/duration/completion), Charts stats. — Monetization: 3 articles + 300 WPM free; Skim Pro $2.99/month. — Why it can boom: RSVP apps have dated SwiftUI; a polished native one wins ratings.

- **Pix** — built — `05-pix` — Daily nonogram (picross) puzzle game: 30 hand-crafted puzzles (10 5×5 + 20 10×10), tap-to-fill/long-press-to-exclude, completed-clue highlighting, pause-safe timer, win sheet, archive with solve-time Charts, daily rotation, SwiftData board persistence (JSON-encoded CellState). — Monetization: 5×5 free; $1.99 one-time for 10×10s + packs. — Why it can boom: no dominant native iOS nonogram app; Picross is proven globally.

- **Murmur** — built — `06-murmur` — Private voice journal with on-device transcription: AVAudioRecorder state machine, power-meter waveform (60-sample window), SFSpeechRecognizer on-device transcription, 5-mood tagging, FlowLayout tag chips, mood donut chart, month calendar with mood dots, full-text search with AttributedString highlights, all audio stored locally. — Monetization: 10 entries/month free; Pro $2.99/month. — Why it can boom: Day One charges $35/year and syncs to cloud; an honest on-device voice journal is the version people wish existed.

## Top recommendation

**Murmur** has the highest long-term ceiling. Voice journaling is underserved natively on iOS, the on-device privacy angle is a genuine differentiator, and daily habit loops keep users retained. **Weave** is the fastest monetization path: puzzle habits are well-proven, $2.99 one-time converts easily, and the audience is large and active.

## Research signals worth following next run

- AI dream journal — niche but passionate; no quality native iOS app yet
- Symptom/menstrual tracker for privacy-first audience — Flo backlash angle
- Pomodoro + deep-work analytics with real session history
- Contacts deduplication (extends Sweep privacy thesis to contacts)
- Language micro-drills with on-device spaced repetition (Duolingo-adjacent, ad-free)
