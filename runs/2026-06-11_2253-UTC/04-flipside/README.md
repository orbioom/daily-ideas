# Flipside — reseller profit tracker

**What it is.** Flipside is the back office for thrift-flippers and online resellers: every find tracked from sourcing to sale with real net profit (price − fees − shipping − cost of goods), ROI, days-to-sell, platform comparison, and death-pile/stale-listing accountability. For the millions of eBay/Poshmark/Mercari side-hustlers currently paying Vendoo ($12.49–50/mo) or My Reseller Genie ($9.99/mo) for web dashboards — or suffering in spreadsheets.

## Full feature list

- **Inventory** — items with title/category (10)/source (6)/cost/sourced date/notes; status flow **Death pile → Listed → Sold**; filter menu (Active/Death pile/Listed/Sold/All) + search; header rollup (active count, cash invested, unlisted count); swipe-to-delete; full add/edit form with money validation.
- **Item detail** — status-aware action card: "Mark as listed" sheet (price + date), "Record sale" sheet with **platform fee prefill** (eBay 13.6%, Poshmark 20%, Mercari 12.9%, Depop 13.9%, FB 5%, Etsy 9.5%, in-person 0% — editable, recalculates until you touch it); sold ledger card (price / − fees / − shipping / − COGS / net profit, ROI, days-to-sell); quick-math card estimating net at asking price; delete with confirmation.
- **Sales** — sold items grouped by month with month-profit subtotals in headers; per-row profit + ROI + platform + days-to-sell.
- **Insights** — 8 KPI tiles (total profit, revenue, avg ROI, avg days-to-sell, sell-through rate, active items, cash tied up, listed value); 6-month profit bars; profit-by-platform horizontal bars with sale counts; "Needs attention": death-pile sunk-cost callout + stale listings (configurable threshold) with price-drop nudges.
- **Settings** — currency picker (USD/EUR/GBP/CAD/AUD, all money formatting respects it), stale-days stepper, haptics, appearance, 18-item sample shop (every status/platform exercised), delete-all with confirmation.
- Onboarding (3 pages, persisted), empty states everywhere, inline validation errors, Dynamic Type, accessibility labels, Reduce Motion-safe (no gratuitous motion), dark + light.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Flipside.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

*Free signing:* Xcode → Signing & Capabilities → personal team.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM: pure `ProfitEngine` (profit/ROI/days-to-sell/monthly/platform/stale/sell-through — no UI imports), SwiftData `Item` 1→1 cascade `Sale`.
- Design language: sunny thrift-haul — warm cream, kraft cards, tangerine price-tag accent, teal profit; full dark palette.
- **Monetization:** resellers already pay monthly (Vendoo, List Perfectly, My Reseller Genie); Flipside Pro one-time ~$24.99 unlocks insights + unlimited items (free tier: 30 items). Tax-time P&L export is the obvious follow-on upsell.
- **Why it can boom:** the reselling economy is huge and underserved on mobile — incumbents are web-first subscription stacks costing $120–600/yr; a fast native tracker with honest one-time pricing is exactly what r/Flipping keeps asking for.

## Self-review

Re-read every Swift file: imports verified; iOS 17 APIs only; `@Model` 1:1 cascade relationship with explicit inverse; all money parsing guarded (no force-unwraps, bounded values, comma tolerance); fee-prefill onChange uses two-parameter iOS 17 form; Chart axes type-consistent; filtered onDelete indexes the rendered array. Anti-stub grep clean. project.yml names the real `Flipside` folder and Info.plist.
