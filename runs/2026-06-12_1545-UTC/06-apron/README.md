# Apron — tip & shift income tracker

**One-liner:** See your real take-home, shift by shift — log tips, hours and tip-outs, and discover your best days, your true hourly rate, and where the month is heading.

**The problem & audience:** Tens of millions of tipped and commission workers — servers, bartenders, baristas, drivers, stylists, dealers — obsess over their real earnings. ServerLife has 750k+ users and 65M+ logged entries, proving the demand, but it **stores everything in the cloud and "never to your device"** and gates much of its analytics behind premium. Apron is the private, on-device, fair-priced alternative for a large, money-motivated audience.

## Full feature list

- **Overview** — a hero "total earned" card for the selected period (week/month/year/all) with tips vs wages and your real hourly rate; a tips/wages split bar; an optional tax set-aside; and recent shifts.
- **Shifts** — every shift grouped by month with a monthly total, filterable by job; tap for detail.
- **Shift detail** — total take-home and effective hourly, plus a full breakdown (cash, card, tip-out, net tips, wages, tip rate, sales).
- **Log/Edit shift** — job, date, hours, cash/card tips, tip-out and sales, with a **live preview** of net tips, take-home and effective hourly as you type.
- **Insights** — all-time earned, real hourly rate, average per shift and best weekday; a 30-day earnings chart, an average-by-weekday chart, a this-month projection from your pace, and a by-job comparison.
- **Jobs** — manage workplaces (role, hourly wage), each with its own shifts and per-job stats; archive or delete.
- **Settings** — pay-week start day, tax set-aside rate, currency, haptics, data counts, delete-all.
- Onboarding (with optional first-job setup) gated by a flag; empty states; Dynamic Type, VoiceOver, Reduce Motion, light/dark throughout.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Apron.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R. Two seeded jobs and ~6 weeks of realistic shifts fill every screen (skip the onboarding job step to keep the demo data).

**Free-signing note:** Runs with a personal Apple ID — no paid account, no entitlements, no network.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM with a pure `EarningsEngine` (period filtering with custom pay-week start, effective hourly, best weekday, daily series, month projection, tax set-aside). **SwiftData** models `Job` (cascade) and `Shift`; `Identifiable` structs back the charts.
- Design language: "after the shift" — fresh teal-green on warm charcoal / clean off-white, with big confident numbers.
- **Monetization:** Free for logging and the core summary; one-time **Pro** unlock for full insights (projections, by-job, weekday rate) and export — undercutting ServerLife's premium subscription.
- **Why it can boom:** A huge, hungry, money-motivated audience whose proven incumbent is cloud-only and subscription-gated; "what did I *actually* make tonight, and which shifts pay best" is a daily, emotional question that an on-device app answers better.

## Self-review

Re-read every file: imports and all SwiftUI/SwiftData/Charts APIs verified for iOS 17; chart/`ForEach`/grouped series are `Identifiable` structs (no tuple key-paths); `NavigationLink(value:)` destinations registered for `Shift`; job color hue is a crash-safe deterministic FNV hash; currency/number parsing is sanitized and division-guarded; no `try!`/force-unwraps on user paths. Anti-stub grep clean; `project.yml` valid; icon is a real 1024² RGBA PNG.
