# Latest run — 2026-06-10 18:09 UTC

Folder: `runs/2026-06-10_1809-UTC/` — 6 production-ready native iOS apps (SwiftUI 5, iOS 17+, XcodeGen `project.yml` per app).

This run deliberately went after **big, proven, top-charts categories that our registry had barely touched** — classic casual games, self-care/mindset, photo/creative, and music utility — and built the "clean, fair, no-dark-patterns" version of each, since the incumbents are uniformly resented for ads, watermarks, year-two price hikes, paywalled basics, and content that goes stale.

## The 6 apps
- **Lumina** — built — `01-lumina` — Affirmations & daily motivation with a deterministic daily, themed deck, and a breathing practice player — Monetization: freemium, one-time "Lumina+" packs/widget — Why it can boom: affirmation apps are top-grossing (~$600k/mo leader) but hated for ads-in-feed, data loss, and cancellation traps; we're the calm private version.
- **Cortex** — built — `02-cortex` — Five generated brain games + a deterministic daily workout — Monetization: freemium, one-time "Cortex Pro" analytics/variants — Why it can boom: brain-training is a validated market whose leaders cap free play at 3 games/day, repeat content, and hike prices in year two; we have no cap and never repeat.
- **Glyph** — built — `03-glyph` — Sudoku with a uniqueness-verified generator, teaching hints, and a daily puzzle — Monetization: freemium, one-time "Glyph Plus" technique/packs — Why it can boom: evergreen top puzzle category; clones are ad-buried with sloppy generation, the loved ones are paid-only — we're clean, free, and teach the technique.
- **Lexic** — built — `04-lexic` — Daily + unlimited five-letter word game with correct duplicate-letter coloring and shareable grids — Monetization: freemium, one-time "Lexic Plus" modes/archive — Why it can boom: Wordle's loop is globally viral; clones bombard with ads and the official paywalls extras — we're ad-free with unlimited practice and honest sharing.
- **Mosaic** — built — `05-mosaic` — Photo collage maker: 9 layouts, per-cell pan/zoom + filters, high-res **watermark-free** export — Monetization: freemium, one-time "Mosaic Pro" stickers/text/batch — Why it can boom: huge photo category whose leaders watermark free exports and paywall basics; the clean no-watermark alternatives are loved — we're that, with more layouts and filters.
- **Pitch** — built — `06-pitch` — On-device tuner + tap-tempo metronome with presets + synthesized reference tones, every tuning free — Monetization: freemium, one-time "Pitch Pro" temperaments/voices — Why it can boom: tuners are a 100M+-download utility; the leader bombards with ads and paywalls basic tunings — we're fast, clean, and include every tuning plus custom CRUD.

## Top recommendation
**Lexic** and **Glyph** are the strongest "boom" bets: both ride globally proven, daily-habit puzzle loops with viral/share mechanics, are fully self-contained (no content licensing, no backend), and slot straight into the "clean version of a megahit" thesis. If I had to pick one to push: **Lexic** — the daily-streak + shareable-grid loop is a proven organic-growth engine, and "ad-free, unlimited, honest sharing" is a sharp wedge against the ad-stuffed clones. **Mosaic** is the highest-ceiling non-game (photo is enormous) but the most engineering-heavy to polish further.

## Research signals worth following next run
- **Stoic/daily-wisdom quotes** ("Motivation", "Stoic") are top-grossing and adjacent to Lumina but distinct (curated quote library + widget + reminders) — strong, not yet built.
- **Solitaire / classic card games** remain a top-grossing gap in our registry (we now have Sudoku + Wordle, no card game).
- **Aesthetic lock-screen / home widgets** (Widgetsmith-style) — proven but engineering-heavy (WidgetKit).
- **Plant / object identification** and **AI-assisted everyday tasks** — big, but need on-device ML or a tasteful offline approach.
- Universal wedge that worked this run: target a proven top-charts category, then ship the calm, ad-free, no-watermark, no-price-hike, never-repeats version with content generated on-device.

## Build notes
- All six use a shared Orbioom `Brand` design system (glass, ink-gradient buttons, calm motion, green as a rare accent); Mosaic uses a justified warm-terracotta accent for its creative tool.
- Each app: SwiftData persistence (Mosaic also FileManager for photo bytes), onboarding gated by a persisted flag, ≥4 substantive feature screens, Settings with ≥3 real persisted prefs, full empty/loading/success/error states, Dynamic Type + accessibility + Reduce Motion + light/dark, real on-brand 1024 app icon.
- Ship as XcodeGen `project.yml` (no hand-written `.xcodeproj`). Generate with `./gen.sh` or `xcodegen generate` in each app's `ios/`.
- Self-reviewed by hand (no Xcode in sandbox); anti-stub grep clean; all `project.yml` validated as YAML and all `Info.plist` validated as XML. Two real bugs caught and fixed in review: a `@GestureState`-across-modifier error in Mosaic and a `didSet`-on-`@Observable` risk in Pitch's metronome. 103 Swift files total.
