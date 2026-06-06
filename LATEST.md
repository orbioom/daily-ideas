# Orbioom Daily Ideas — Latest Run

**Run:** 2026-06-06_1208-UTC
**Folder:** `runs/2026-06-06_1208-UTC/`
**Output:** 6 production-ready native iOS apps (SwiftUI 5, iOS 17+, SwiftData), all Orbioom design language.

Each app ships a XcodeGen `project.yml` (no hand-written `.xcodeproj`), a real 1024² on-brand `AppIcon`, `AccentColor`, launch screen, onboarding gate, ≥4 substantive feature screens, a Settings screen with ≥3 persisted prefs, empty/loading/success/error states, light + dark, Dynamic Type, VoiceOver, Reduce Motion, and haptics. Build locally: `brew install xcodegen` → `cd <app>/ios && xcodegen generate` → open in Xcode 15+ → Cmd+R.

## The six apps

- **Skein** — built — `runs/2026-06-06_1208-UTC/01-skein` — knitting/crochet companion: multi-counters with repeat tracking + a full-screen counting session, yarn stash, gauge calculator and CYC-weight yardage estimator that checks against your stash.
- **Forge** — built — `runs/2026-06-06_1208-UTC/02-forge` — strength logger: warm-up-aware sets, Epley/Brzycki e1RM with per-lift progression charts and PRs, volume-by-group insights, and a kg/lb barbell plate calculator.
- **Snowline** — built — `runs/2026-06-06_1208-UTC/03-snowline` — debt payoff planner: month-by-month avalanche/snowball simulation with rollover, real debt-free date, full amortization schedule, and strategy comparison vs minimum-only.
- **Fathom** — built — `runs/2026-06-06_1208-UTC/04-fathom` — scuba dive log & nitrox planner: sites own dives, SAC from logged gas, MOD/EAD/ppO₂/best-mix and no-stop limits, depth-distribution stats.
- **Brine** — built — `runs/2026-06-06_1208-UTC/05-brine` — reef aquarium tracker: nine water parameters classified against ideal/safe ranges, trend charts with a range band, dosing log, and recurring maintenance with due dates.
- **Kerf** — built — `runs/2026-06-06_1208-UTC/06-kerf` — woodworking cut-list optimizer: best-fit-decreasing 1D cutting-stock with kerf and limited stock, visual board layouts/waste/cost, plus board-foot and quick-plan calculators.

## Top recommendation

**Snowline.** It pairs the broadest audience (anyone with a card or loan) with a genuinely non-trivial engine — a correct month-by-month simulation that models interest accrual, minimum payments, snowball/avalanche rollover, stuck-debt detection, and a real amortization schedule — and delivers the one number people actually want: a debt-free date. It's fully offline and private, exactly what the research said people want from money apps. Runner-up: **Forge**, the largest evergreen niche, with real 1RM/progression math and a plate calculator that earns daily use.

## Research signals worth following next run

- **Offline-first, one-time-purchase utilities are a growing, underserved niche** (LocalOneLabs and several "best offline iPhone apps" roundups). Users are fleeing subscription/cloud apps — lean into "your data never leaves the phone."
- **unitQ (2026): users file 6× more complaints about broken basics than feature requests.** The winning move is a small, rock-solid core tool, not a feature pile. Keep scoping tight.
- **r/somebodymakethis / somebodymakethis.org** is a live, upvoted feed of unmet app needs — a strong source for the next batch.
- **Passionate hobby/profession verticals still lack a great calm app:** aquascaping/planted (freshwater) tanks, beekeeping logs, ham-radio logbooks, pottery/kiln firing schedules, fly-tying/fishing logs, EDC/gear inventory, sail trim & passage logs, 3D-printer filament & print logs, leathercraft, model-paint inventory.
- **"A calculator that's actually a tool" works well** (gauge, plate, nitrox, cut-list here): pick a domain with real math practitioners do by hand and make it delightful and offline.

## Notes

- All math engines are pure value types (GaugeMath, StrengthMath, PayoffEngine, DiveMath, CutOptimizer, parameter ranges) — testable and off the main thread (Kerf runs its optimizer via `Task.detached`).
- The only `try!` in any app is the bootstrap in-memory `ModelContainer` fallback in each `@main` — not a user path. No `TODO`/stub markers; anti-stub grep clean.
- A shared, copied-per-app theme (`Theme/Brand.swift`) and `Utilities/Haptics.swift` keep the Orbioom language consistent across all six.
