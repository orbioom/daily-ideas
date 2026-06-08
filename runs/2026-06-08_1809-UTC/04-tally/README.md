# Tally — calm spending tracker

**Tally is a fast, private spending tracker: log money in seconds, set gentle monthly budgets, and see exactly where it goes.** For everyday people who want a clean personal-finance tracker without bank-linking, accounts, ads, or anxiety.

## What it is
A native iOS expense + income tracker with categories, monthly budgets, recurring auto-posting, and real insights — entirely on-device.

## Features
- **Overview** — month stepper, big "spent this month" with income/net/projected, a spending-by-category donut with legend, and a recent list.
- **Activity** — transactions grouped by day with per-day net, search across notes/categories, add/edit/delete, month filtering.
- **Budgets** — recurring monthly limits per category with progress bars, an overall budget card, and over-budget highlighting (spent vs limit, remaining).
- **Insights** — Swift Charts: income vs expense over 6 months (grouped bars), cumulative spending pace for the month (area), and top categories.
- **Recurring** — bills and income that auto-post on their day each month (a deterministic `postDue` engine that backfills missed months on launch).
- **Settings** — currency, default new-entry type (expense/income), haptics, manage recurring, erase-all. All persisted.
- Onboarding (currency + optional sample data, persisted flag); empty/loading/success states; Dynamic Type + VoiceOver; light/dark; Reduce Motion; sparse haptics.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Tally.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: personal team, free Apple ID, simulator or device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `MoneyEngine` (month summaries, category breakdown, budget status, daily/cumulative series, projection, recurring `postDue`). **SwiftData** for `Transaction`, `BudgetItem`, `RecurringRule`; small prefs in `UserDefaults`. Swift Charts throughout. Design language: **Orbioom** (green used as the live/money accent). No external dependencies; amounts rounded to cents on save.
- **Monetization:** freemium — tracking + budgets free; Pro (subscription) for unlimited recurring, multi-account, iCloud sync, CSV export, and widgets. Spending-tracker apps (Spending Tracker, MoneyCoach, Buddy) have proven paid tiers.
- **Why it can boom:** millions want a simple money tracker but distrust bank-linking apps and resent ad-heavy ones. Tally is on-device, instant to log, and genuinely insightful — the manual-first tracker done with taste.

## Self-review
Re-read every file. Verified imports, iOS 17 SDK usage, SwiftData models, `@Query`/`@AppStorage`/`@Bindable` usage, `.searchable` inside `NavigationStack`, Charts (`BarMark` grouped, `AreaMark`, `SectorMark`). `postDue` uses component-built due dates with a loop guard (no `bySetting` surprises); all divisions guarded. Anti-stub grep clean. No `try!`/force-unwrap on user paths; only the documented container-fallback `fatalError`.
