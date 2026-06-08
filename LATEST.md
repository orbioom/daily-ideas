# Latest run — 2026-06-08_0611-UTC

**6 production-ready native iOS apps**, all built (no specs needed). Folder: `runs/2026-06-08_0611-UTC/`.

This run continues the move into **big, proven, monetised consumer markets** — habits, nutrition, recovery, plants, parenting, and sleep — each "our version of a chart-topping winner, done cleaner, calmer, more private, and without the dark patterns the incumbents are hated for." All SwiftUI 5 + SwiftData (iOS 17), Orbioom design language, no dependencies, no accounts, fully on-device. Each ships a XcodeGen `project.yml` (run `xcodegen generate` or `./gen.sh`, then open in Xcode 15+).

| # | App | Status | Folder | One-line | Monetization | Why it can boom |
|---|-----|--------|--------|----------|--------------|-----------------|
| 1 | **Anchor** | built | `01-anchor` | Habit tracker: unlimited habits, flexible scheduling, streak engine, calendar heatmap, insights | Freemium → Pro (unlimited reminders, themes, advanced stats) | Streaks/Habitica are top-grossing but Streaks caps you at 24 habits with unintuitive gestures — Anchor removes the cap and the friction |
| 2 | **Plate** | built | `02-plate` | Calorie & macro diary: Mifflin-St Jeor TDEE engine, meal diary, calorie ring, macro targets, trends | Freemium → Pro (custom foods, trends, export) | MyFitnessPal is #1 grossing but now paywalls scanning, buries the diary, and glitches on sync — Plate is the clean, free-core, on-device diary |
| 3 | **Anew** | built | `03-anew` | Sobriety / quit-anything tracker: live clean-time, money saved, milestone + health-recovery timelines | Freemium → Pro (unlimited quits' analytics, themes) | I Am Sober is proven but caps the free tier at 2 addictions and paywalls stats — Anew gives unlimited quits and all stats free |
| 4 | **Verdant** | built | `04-verdant` | Plant-care companion: watering/fertilizing engine, seasonal adjust, rooms, care log, today's tasks | Freemium → Pro (unlimited plants, reminders, light meter) | Planta is top-grossing lifestyle but overwhelming, slow, and paywall-heavy — Verdant is the calm, fast care scheduler |
| 5 | **Cradle** | built | `05-cradle` | Baby tracker: one-tap feed/sleep/diaper logging, live timers, multi-baby, daily patterns & insights | Freemium → Pro (multi-baby, full history export, insights) | Huckleberry/Baby Tracker are huge but cluttered and subscription-walled — Cradle keeps logging dead-simple and core features free |
| 6 | **Nocturne** | built | `06-nocturne` | Sleep tracker: sleep-debt engine, regularity score, recommended bedtime, trends — no wearable needed | One-time Pro unlock (trends, tag correlations, export) | Sleep Cycle/Pillow are pricey and sensor-heavy — Nocturne wins the "I just want to log and understand my sleep" crowd, manual & on-device |

## Top recommendation

**Plate.** It targets the single largest, most reliably monetised category we've touched — calorie tracking, whose category leader (MyFitnessPal, #1 top-grossing Health & Fitness) is at its most vulnerable: a 2026 redesign users openly revolt against, a paywall on what used to be free, and chronic sync glitches. "Clean, fast, free-core, on-device, no buried menus" is a genuine wedge, the TDEE/macro engine is real and substantive, and the audience is enormous. **Anchor** is the close second — habit tracking is evergreen and high-retention, and "no 24-habit cap, intuitive taps" directly answers the top complaints against Streaks. Both are the purest "proven winner, done 10× better" plays in the set.

## Research signals worth following next run

- **Strength/hypertrophy program logging** (Strong/Hevy are top-grossing & clunky): program-driven progressive-overload with auto-suggested weights — distinct from our set-logger Forge.
- **Language vocab / phrasebook** with elegant spaced repetition for travellers (distinct from generic Anki/Recall).
- **Gratitude / one-line-a-day journal** (Five-Minute Journal is a proven paid niche) — strong fit for Orbioom's calm voice; keep clearly distinct from Tide (mood) and any future journal.
- **Meal planner + auto grocery list** (Mealime/Paprika): plan the week → consolidated shopping list; pairs naturally with Plate.
- **Pregnancy week-by-week** (What to Expect/Ovia) and **toddler/parenting** as a Cradle adjacency — large, high-spend, emotionally sticky.
- iOS 17/18 leverage to revisit: interactive widgets + Live Activities (Cradle live feed/sleep timer, Anew clean-time, Nocturne bedtime, Plate calorie ring), App Intents/Shortcuts, StoreKit 2 paywalls.
