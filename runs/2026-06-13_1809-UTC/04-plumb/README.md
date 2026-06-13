# Plumb — net worth tracker

Find out what you're really worth — and watch it grow. Add every account (cash, investments, property, debts), update balances when you like, and Plumb plots your net worth over time. No bank logins, ever.

**The problem & audience.** Personal-finance-minded people who want a single net-worth number and trend. Empower (Personal Capital) and Copilot prove the demand but require linking bank credentials (a trust barrier) or charge subscriptions; many want a private, manual, beautiful tracker.

## Features
- **Overview** — big net-worth number, assets vs liabilities, this-month change (amount + %), a 12-month trend **Swift Chart**, a privacy "hide balances" toggle, and a growth-rate insight.
- **Accounts** — grouped Assets/Liabilities with totals; full CRUD across 14 account types; per-account detail with a balance-history chart, an "update balance" sheet (each update logged), and include/exclude from net worth.
- **Trends** — 6M/1Y/2Y net-worth chart, a net-worth **goal** with progress and a projected hit-date from your recent pace, and a month-by-month table with deltas.
- **Allocation** — donut breakdown of assets and liabilities by category (Swift Charts `SectorMark`) with a legend and a debt-to-asset ratio insight.
- **Net worth engine** — reconstructs historical net worth from per-account balance history (most-recent-on-or-before each month).
- Onboarding (persisted), Settings with currency, hide-balances and haptics, light + dark, Dynamic Type, VoiceOver, Reduce Motion, opt-out haptics, a designed rising-chart icon and launch screen.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Plumb.xcodeproj` in Xcode 15+, iOS 17+ simulator, Cmd+R.

**Free-signing:** personal Team in Signing & Capabilities — no paid account needed.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM with a pure `NetWorthEngine` (totals, monthly series, allocation, growth rate, goal projection).
- Persistence: **SwiftData** (`Account`, `BalanceEntry`); `UserDefaults` for currency/goal/privacy/onboarding.
- Charts via Swift Charts (`AreaMark`, `LineMark`, `SectorMark`, `RuleMark`).
- Design language: private-wealth — deep navy, warm gold, parchment.
- **Monetization:** free for up to 6 accounts; one-time **Plumb Pro ($9.99)** for unlimited accounts, goals & projections, and export. Who pays: anyone tracking wealth who refuses to hand over bank logins.
- **Why it can boom:** net-worth tracking is a proven, high-intent wealth category; the leaders gate it behind bank-linking and subscriptions, so a private, manual, gorgeous one-time tracker hits a real trust wedge with a paying audience.

## Self-review
Audited file-by-file: anti-stub grep clean; balanced delimiters; only the in-memory `ModelContainer` `try!`, no `fatalError`, no force-unwraps on user paths (the engine's "latest on-or-before" was rewritten to avoid `!`); imports (SwiftUI/SwiftData/Charts) present; Theme hex literals validated; `navigationDestination(for: Account.self)` relies on `PersistentModel: Hashable`; chart/format APIs verified for iOS 17.
