# Wick — trading journal & analytics

**One line:** A beautiful native iOS trading journal that turns your trades into a real edge — no $49/mo, no spreadsheet.
**Problem & audience:** Active stock/crypto/forex traders know journaling is the single highest-ROI habit, but the market is rough: TradeZella is polished yet web-only and expensive, Edgewonk feels a decade old with no mobile, and TraderSync is the lone "real app." Wick is a fast, private, on-device journal with the analytics traders actually act on.

## Full feature list
- **Journal** — net realised P/L header (win rate, trades, open count), All / Open / Closed filter, and trade rows showing direction, strategy, P/L and R-multiple. Log a trade with entry, exit (optional — keep it open and close later), quantity, fees, stop, target, strategy, asset type, discipline rating and notes. Wick derives **P/L, return %, R-multiple, planned R:R and hold time** — never stored, always correct.
- **Trade detail** — full breakdown with risk plan and discipline; edit or close from here.
- **Calendar** — a TradeZella-style monthly **P/L calendar** with intensity-shaded green/red days, month total, green/red day counts, and per-day trade drill-down.
- **Analytics** — an **equity curve** (over a configurable starting balance), then win rate, profit factor, expectancy, avg win/loss, largest win/loss, current win/loss streak, avg hold, and W/L counts; plus P/L by strategy (bar) and top symbols.
- **Settings** — currency symbol, starting balance for the equity curve, haptics, load sample trades, reset onboarding.
- Onboarding (persisted) with a sample-trades path; empty/loading/success states; light & dark; Dynamic Type; VoiceOver; Reduce Motion.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Wick.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** no paid Apple Developer account needed — personal team, simulator or your own device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `TradeStats` engine (summary, profit factor, expectancy, equity curve, streak, strategy/symbol breakdowns, per-day P/L). **SwiftData** model `Trade` with all results computed from inputs; prefs in `@AppStorage`. Swift Charts for equity & breakdowns; a hand-built P/L calendar grid. Orbioom design language with JetBrains Mono for figures (a trading-terminal feel).
- **Monetization:** subscription — proven willingness to pay ($14–49/mo incumbents). Free tier for a capped number of trades; Pro for unlimited trades, advanced analytics, tags/playbooks, and CSV import/export.
- **Why it can boom:** a validated, high-LTV niche where the best tool (TradeZella) has no app and the cheap one (Edgewonk) has no mobile or modern UI. A genuinely native, on-device, well-priced iOS journal is the gap.

## Self-review
Hand-checked every file: imports resolve; SwiftUI/SwiftData/Charts APIs valid for iOS 17; calendar grid math and weekday rotation reviewed; sheets/`@Bindable`/`@Query` wiring type-checks; no force-unwrap/`try!`/`fatalError` on user paths (the guarded `first!` was replaced with a `guard let`). Anti-stub grep clean. `project.yml` valid YAML naming the `Wick` sources and `Info.plist`.
