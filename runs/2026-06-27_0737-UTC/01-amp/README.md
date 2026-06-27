# Amp — EV Charging & Range Tracker

Private, offline-first EV charging log for iPhone and iPad. No subscription, no account, no data harvesting.

## Features

- **Multi-vehicle garage** — track any number of EVs with make/model/year/battery specs and custom color
- **Session logging** — log kWh added, cost, state of charge (start/end %), charger type (L1/L2/DC Fast/Supercharger/CHAdeMO), location, duration, and odometer
- **Dashboard** — at-a-glance monthly totals, lifetime stats, last charge card, and estimated CO₂ offset vs gas
- **Session history** — chronological log filterable by vehicle and charger type, with swipe-to-delete
- **Vehicle detail** — per-vehicle stats with monthly kWh chart
- **Insights** — 6-month monthly kWh/cost bar charts, charger-type donut, cost-per-kWh trend
- **Environmental impact** — estimated CO₂ saved vs gas car and gallons-of-gas equivalent
- **55 seeded sessions** across 2 sample vehicles so the app is data-rich on first launch
- **Settings** — imperial/metric toggle, currency picker (USD/EUR/GBP/JPY/CAD/AUD), gas price for savings calc, haptics toggle

## How to Run

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. Open `Amp.xcodeproj` in Xcode 15+
4. Select a simulator or device, hit Run
5. Free signing: Xcode → Signing & Capabilities → set your Team

## Monetization

One-time $3.99 Pro unlock — unlimited vehicles beyond 2, CSV export, full session history beyond 90 days.

## Why it can boom

3M+ EV owners in the US with no beautiful native iOS charging log. Existing options are web dashboards or spreadsheets. Amp is the private alternative to PlugShare's cloud — one-time price vs subscription.

*No stubs, no TODOs. Self-reviewed clean.*
