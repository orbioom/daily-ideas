# Orbioom Daily Ideas — Latest Run

**Run:** 2026-06-06_1807-UTC
**Folder:** `runs/2026-06-06_1807-UTC/`
**Output:** 6 production-ready native iOS apps (SwiftUI 5, iOS 17+, SwiftData), all Orbioom design language.

Each app ships a XcodeGen `project.yml` (no hand-written `.xcodeproj`), a real 1024² on-brand `AppIcon`, `AccentColor`, launch screen, onboarding gate, ≥4 substantive feature screens, a Settings screen with ≥3 persisted prefs, empty/loading/success/error states, light + dark, Dynamic Type, VoiceOver, Reduce Motion, and haptics. Build locally: `brew install xcodegen` → `cd <app>/ios && xcodegen generate` → open in Xcode 15+ → Cmd+R.

## The six apps

- **Beacon** — built — `runs/2026-06-06_1807-UTC/01-beacon` — amateur radio QSO logbook: Maidenhead grid encode/decode with great-circle distance & bearing, POTA/SOTA outings that own contacts (with activation targets), band/mode/grid insights, and a standalone grid calculator with a compass rose.
- **Spool** — built — `runs/2026-06-06_1807-UTC/02-spool` — 3D-printing filament & print tracker: spools track grams/length remaining, logging a print deducts material and computes filament + electricity cost, a mass↔length calculator from real densities, printers, low-stock alerts, and spend insights.
- **Stride** — built — `runs/2026-06-06_1807-UTC/03-stride` — running paces & race calculator + log: Riegel race prediction, Daniels VDOT training paces, an even/negative-split race planner, and a run log with weekly mileage and a 14-day chart — all driven by one shared benchmark.
- **Apiary** — built — `runs/2026-06-06_1807-UTC/04-apiary` — beekeeping hive log: apiaries → hives → inspections/treatments/harvests, queen-marking colors, a colony-health read, swarm risk, the ~3% varroa threshold, treatment remove-by windows, a Tasks aggregator, and mite/honey charts.
- **Jigger** — built — `runs/2026-06-06_1807-UTC/05-jigger` — home-bar "what can I make" matcher: your shelf vs every recipe, a match engine that finds makeable / one-away drinks and ranks the single bottle that unlocks the most cocktails, plus a servings scaler.
- **Curfew** — built — `runs/2026-06-06_1807-UTC/06-curfew` — caffeine half-life & sleep tracker: a first-order decay engine (live level, 24-hour curve, time-to-threshold, and an inverted "last safe time" solver), a drink catalog with quick-add, daily-log charts, and a bedtime curfew calculator.

## Top recommendation

**Curfew.** It pairs the broadest possible audience (anyone who drinks coffee and cares about sleep) with a genuinely non-trivial, correct engine — first-order pharmacokinetics that not only sums the decay of every dose but *inverts* it to answer the question people actually have ("how late can I have this?"). The live "in your system now" number and the bedtime curve make an invisible thing legible. Runner-up: **Jigger**, whose unlock-ranked shopping list ("buy this one bottle → make N more drinks") is a delightful, sticky hook on top of a real set-matching engine.

## Research signals worth following next run

- **r/somebodymakethis / somebodymakethis.org** continues to be a live, upvoted feed of unmet app needs — a strong source for the next batch.
- **Offline-first, one-time-purchase, "your data never leaves the phone" framing is still the dominant ask** in 2026 roundups (LocalOneLabs, VoiceScriber, MainlandMoment). Every app this run leans into it.
- **Validated hobby/profession verticals still without a calm offline app:** ham radio (built Beacon), 3D printing (built Spool), beekeeping (built Apiary) — remaining: pottery/kiln firing schedules + glaze recipes, fly-tying/fishing logs, ham-radio *contesting* scoring, model-paint inventory (Warhammer), leathercraft, sailing passage/sail-trim logs, disc-golf scorecards with handicap, darts checkout trainer, tarot/journaling.
- **"A calculator that's actually a tool" keeps working** (this run: Maidenhead geodesy, filament density math, VDOT/Riegel, varroa thresholds, cocktail set-cover, caffeine pharmacokinetics). Pick a domain where practitioners do real math by hand and make it calm and offline.

## Notes

- All math engines are pure value types (`GridMath`, `CostMath`, `PaceMath`, `BeeLogic`, `MatchEngine`, `CaffeineMath`) — testable and off the view layer.
- The only `try!` in any app is the in-memory `ModelContainer` bootstrap fallback in each `@main` — not a user path. No `TODO`/stub markers; anti-stub grep clean. The single guarded force-unwrap was refactored away.
- A shared, copied-per-app theme (`Theme/Brand.swift`) and `Utilities/Haptics.swift` keep the Orbioom language consistent across all six; new icon glyphs (signal, spool, hexcomb, glass, moon, track) were added to the deterministic stdlib icon generator.
