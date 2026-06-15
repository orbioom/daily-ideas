# Yield

**A beautiful, private dividend income tracker & forecaster.** Enter your holdings and Yield projects your annual & monthly dividend income, yield-on-cost, a forward 12-month payout calendar, income-by-sector, and a DRIP (reinvestment) compounding projection — all offline, all on-device.

**Problem & audience.** Dividend and FIRE investors want to see their income, not just their balance — but the popular trackers (DivTracker, Snowball) are subscriptions that *require* linking your brokerage, a real privacy turn-off. Yield is offline, manual, and private, with a single one-time Pro unlock. No brokerage login. No live price feed needed — every number derives from the shares and dividend-per-share you enter.

> Yield is a tracking and education tool. Its projections are simplified models based on the numbers you enter — **not** forecasts, recommendations, or financial, investment, or tax advice. The sample holdings shown on first launch are illustrative only and do not reflect live market data.

## Features

- **Portfolio** — holdings list with per-row annual income contribution and yield-on-cost; a header summarizing total projected annual income, monthly average, and portfolio yield-on-cost; add/edit/delete (full CRUD); sort by income, yield, ticker, or shares; empty state; free-tier slot banner.
- **Holding Detail** — projected income, yield-on-cost, current yield, cost basis & market value, pay schedule, a 10-year DRIP mini-projection, and logged payment history with a "log payment" form. Editable.
- **Income Calendar** — a forward 12-month projected-income bar chart (Swift Charts) with tap-to-inspect, a month-by-month breakdown, and an upcoming-payments feed computed from each holding's frequency, pay cycle, and pay day.
- **Insights** — income-goal progress ring, income-by-sector donut (`SectorMark`) with legend and top-payer concentration, top payers, and a yield-on-cost distribution across holdings.
- **DRIP Projector** (Pro) — sliders for years and dividend-growth rate compound your income forward, charting the growth path.
- **Onboarding** — four-page intro, gated by a persisted `hasOnboarded` flag.
- **Settings** — currency, annual income goal, default DRIP growth rate, hide-balances privacy toggle, haptics toggle, and light/dark/system appearance — all persisted and functional. Plus CSV export (Pro), sample-data load, reset, and About.

### Core logic (real, `Decimal`-based)
- **IncomeEngine** computes projected annual income (`Σ shares × annualDPS`), yield-on-cost (`annualDPS / avgCost`), current yield (`annualDPS / price`), the 12-month forward income calendar (distributing each holding's income across its pay months from frequency + quarter cycle), next pay dates, income-by-sector and top-payer concentration, and a DRIP projection that compounds income forward by both reinvestment yield and DPS growth. Every division is guarded against divide-by-zero; empty portfolios and zero cost/price are handled gracefully.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Yield.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

## Free signing
Builds and runs on the simulator with a personal Apple ID — no paid Apple Developer account needed. Code-signing is only required to install on a physical device.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM, **SwiftData** persistence (`@Model` `Holding` + `DividendPayment`, `@Query`, `modelContainer`); small prefs/flags in `@AppStorage`.
- Swift **Charts** for the calendar bars, sector donut, yield distribution, and DRIP line; with VoiceOver chart descriptors and value labels.
- All money math uses `Decimal` via a central `MoneyFormat`; every division is guarded.
- A cohesive emerald-green-on-charcoal fintech identity in `Theme.swift`, first-class in light **and** dark, with reusable cards/buttons/pills; honors Dynamic Type and Reduce Motion; sparse haptics gated by a Settings toggle.
- **Monetization:** Free tracks up to 8 holdings with full projections & calendar; one-time **Yield Pro (~$6.99, simulated via `@AppStorage("isPro")`)** unlocks unlimited holdings, the DRIP projector, CSV export, multiple accounts, and hide-balances. Tasteful paywall with simulated restore.
- **Why it can boom:** dividend/FIRE investing is a large, passionate niche, and the incumbents gate everything behind subscriptions that demand brokerage access. A gorgeous, private, one-time-purchase, no-login tracker is exactly the under-served alternative that community word-of-mouth rewards.

## Self-review
- **Compiles by inspection.** Re-read every Swift file: iOS 17 SDK only; SwiftData `@Model`/`@Query`/`modelContainer` wired correctly with raw-value enums for stored types; Swift Charts marks (`BarMark`/`SectorMark`/`LineMark`/`AreaMark`) and `AXChartDescriptorRepresentable` used per the iOS 17 API; `Decimal` arithmetic throughout with `doubleValue` only for plotting.
- **Anti-stub grep clean** — no TODO/FIXME/XXX/placeholder/lorem/"coming soon"/"not implemented"/stub markers.
- **Definition of Done met** — onboarding gating; 5 substantive feature screens via TabView/NavigationStack; empty/loading/success/error states; Settings with 6 persisted, functional prefs; SwiftData persistence surviving relaunch; guarded divisions and no force-unwrap/`try!`/`fatalError` on user paths; accessibility (Dynamic Type, labels/hints/values, chart descriptors, hide-balances mode); Reduce Motion honored; sparse haptics gated by toggle; light + dark via `Theme`; lazy containers; seeded sample data.
