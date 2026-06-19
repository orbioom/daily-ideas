# Latest run — 2026-06-19_0035-UTC

Folder: `01-trek/` through `06-chord/` — **6 production-ready native iOS apps** (SHIPPED.md entries 286–291), each shipped as a XcodeGen `project.yml` + Swift sources (80 total .swift files) + real 1024×1024 AppIcon PNG + AccentColor asset. Generate with `xcodegen generate` in each `ios/`, then open in Xcode 15+ and run on an iOS 17 simulator.

All six were checked against the 285-entry `SHIPPED.md` registry and are genuinely new concepts not previously built.

## The 6 apps

- **Trek** — built — `01-trek` — Hike log & trail library: manual trail CRUD with difficulty/distance/elevation/favorites, session logging with pace calculation, weekly/monthly Swift Charts, trail leaderboard, photo attachment, km↔miles/m↔feet unit conversion. — *Monetization:* one-time Pro (unlimited trails, advanced charts, CSV export). — *Why it can boom:* AllTrails charges $36/yr just to download offline maps; millions of hikers just want a clean personal log. Ours is private, offline, one-time.
- **Cast** — built — `02-cast` — Podcast listening log: manual show+episode library with 14 genres, queue management, listening streaks, monthly history chart, genre donut chart. — *Monetization:* one-time Pro (unlimited shows, listening calendar, export). — *Why it can boom:* PocketCasts/Overcast are player-first; there's no good dedicated podcast *tracker* that celebrates completion milestones. Ours fills that gap.
- **Spark** — built — `03-spark` — ADHD-friendly focus timer: wall-clock timer with relaunch safety, single-task display, progress ring with color-coded warning states, completion flow with "task done" vs "still working" split, focus streak tracking. — *Monetization:* one-time Pro (unlimited session history, extended stats, themes). — *Why it can boom:* ADHD diagnosis rates keep rising; Forest/Focus@Will charge subscriptions but the core timer is simple; ours nails the "one task, right now" UX that ADHD brains actually need.
- **Kana** — built — `04-kana` — Japanese kana/kanji SRS trainer: 112 seeded cards (46 hiragana + 46 katakana + 20 N5 kanji), SM-2 spaced repetition, 3D flip-card UI, mastery rings. — *Monetization:* one-time Pro (kanji expansion packs, N4/N3 levels, custom cards). — *Why it can boom:* WaniKani is $9/mo and Anki is free but ugly and complex; ours is a polished, opinionated, offline-first SRS for the most-learned language on Earth.
- **Memoir** — built — `05-memoir` — Life story writing companion: 30 seeded prompts across 6 life eras, mood tagging, writing streak, era-grouped story browser, weekly word-count chart, mood donut. — *Monetization:* one-time Pro (unlimited prompts, export to PDF, sharing, custom prompts). — *Why it can boom:* StoryWorth charges $99–$249/yr and sends prompts by email; ours is a private, offline, one-time app that keeps your memories on your device.
- **Chord** — built — `06-chord` — Songwriter chord progression sketchpad: progressions with key/genre/tempo, chord slot editor with quality picker + beat duration + lyric hints, roman numeral analysis, key-aware chord suggestions, 10 classic template progressions in the Inspire tab. — *Monetization:* one-time Pro (unlimited progressions, Nashville number charts, audio preview via AVAudioEngine). — *Why it can boom:* GarageBand is overwhelming for chord sketching; ChordU/Hookpad are web-only; millions of acoustic songwriters need a quick mobile scratchpad.

## Top recommendation

**Spark.** Of the six it targets the fastest-growing diagnosed population (ADHD), has the clearest "incumbent is overpriced" story (Forest/Focus@Will subscriptions), and the core product promise — one task, right now, no overwhelm — is extremely shareable on social media. The visual timer ring is also inherently screenshot-worthy.

**Kana** is the runner-up: language learning is massive, the SRS mechanic creates strong daily habits, and N5→JLPT progression is a clear upsell path.

## Research signals for next run

Confirmed still-open gaps observed while scoping this run:
- **JLPT N4/N3 vocabulary + grammar** — extends Kana naturally, distinct enough for its own app
- **Songwriting lyrics notepad** — pairs with Chord, lyric-first not chord-first
- **Trail running** — distinct from hiking (intervals, pace zones, shoe tracking)
- **Life timeline / milestones** — similar to Memoir but visual/event-focused rather than prose-focused
- **Podcast episode notes** — pairs with Cast; clip + annotate while listening
