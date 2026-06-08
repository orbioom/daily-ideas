# Latest run — 2026-06-08_0011-UTC

**6 production-ready native iOS apps**, all built (no specs needed). Folder: `runs/2026-06-08_0011-UTC/`.

This run deliberately breaks the recent niche-hobby-tracker streak and goes after **big, proven, monetised consumer markets** — health, wellness, productivity, and women's health — each "our version of a chart-topping winner, done cleaner, calmer, and private." All SwiftUI 5 + SwiftData (iOS 17), Orbioom design language, no dependencies, no accounts, fully on-device. Each ships a XcodeGen `project.yml` (run `xcodegen generate` or `./gen.sh`, then open in Xcode 15+).

| # | App | Status | Folder | One-line | Monetization | Why it can boom |
|---|-----|--------|--------|----------|--------------|-----------------|
| 1 | **Ember** | built | `01-ember` | Intermittent-fasting tracker: live fasting ring + metabolic-stage engine, plans, streak insights | Freemium → Pro (custom plans, insights, widgets) | IF is top-grossing health; Zero/Fastic are bloated & paywalled — Ember is the clean on-device version |
| 2 | **Tide** | built | `02-tide` | Mood journal: 10-sec check-in + activity tags → calendar heatmap, trend, correlation engine | Freemium → Pro (correlations, long trends, export) | Daylio proves paid mood journaling; its insights are shallow — Tide surfaces "what moves your mood" |
| 3 | **Lull** | built | `03-lull` | Guided breathwork with a live breathing orb, patterns, sessions, streaks | Freemium → Pro (custom patterns, programs) | Calm/Headspace prove the spend; Lull is the instant, beautiful, low-cost breathing tool |
| 4 | **Tare** | built | `04-tare` | Weight-trend tracker: EMA smoothing + weekly rate + goal-date projection, kg/lb/st | One-time Pro unlock (projection, export) | Happy Scale proved people pay for trend smoothing; it's dated & imperial — Tare modernises it |
| 5 | **Grove** | built | `05-grove` | Focus timer that grows a tree; leave the app and it withers; tag analytics & grove | Freemium → Pro (species, stats, goals) | Forest has 10M+ users; it's cluttered with a coin store — Grove keeps the hook, drops the cruft |
| 6 | **Luna** | built | `06-luna` | Private on-device cycle tracker: predicts period/fertile/ovulation, symptom logs, insights | Freemium → Pro (analytics, reminders); privacy is the pitch | Period tracking is huge & monetised; post-2022 privacy is the #1 complaint — Luna is the trusted, no-cloud alternative |

## Top recommendation

**Luna.** It targets one of the largest, most reliably monetised categories in the App Store (period tracking) at the exact moment its incumbents are most vulnerable: privacy. "On-device, no account, no data sales" is a genuine, hard-to-copy wedge against Flo/Clue/Stardust, the prediction engine is real and substantive, and the audience is enormous and underserved by trustworthy options. **Lull** is the close second — it's the purest expression of the Orbioom brand (the breathing orb *is* the orb motif) and rides a proven, high-spend wellness wave with almost no quality competition at the free/light tier.

## Research signals worth following next run

- **Sleep**: Sleep Cycle / Pillow are pricey and sensor-heavy; a manual sleep-debt + ideal-bedtime (chronotype) journal could win the "I just want to log and understand sleep" crowd.
- **Strength/hypertrophy logging** beyond our Forge: a *program-driven* lifting app (progressive-overload auto-suggested weights) — Strong/Hevy are top-grossing and clunky.
- **Calorie/food**: the database problem blocks most clones, but a photo-portion / "plate method" tracker (no database) could sidestep it.
- **Language vocab**: an elegant spaced-repetition *phrasebook* (distinct from generic Anki/Recall) for travellers.
- **Gratitude / one-line-a-day journal** (Five-Minute Journal is a proven paid niche) — strong fit for Orbioom's calm voice.
- iOS 17/18 leverage to revisit: interactive widgets + Live Activities (Ember fasting ring, Grove focus, Luna countdown are all natural Live Activity candidates), App Intents/Shortcuts, StoreKit 2 paywalls.
