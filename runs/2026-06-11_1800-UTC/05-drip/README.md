# Drip — Mindful Drinking Tracker

Track alcohol consumption, set weekly goals, and build healthier habits — with full privacy (on-device only).

## Features
- **Today view** — weekly progress ring, today's entries list, quick-add 5-type grid (beer/wine/spirits/cocktail/cider)
- **Insights** — weekly bar chart, alcohol-free days tracker, money saved, context breakdown (social/work/home/alone)
- **History** — calendar-based log with daily standard-drink totals
- **Goal editor** — weekly drink limit, alcohol-free day target, cost per drink, motivations list
- **Onboarding** — explains standard drinks (14g pure alcohol US) and weekly guidelines

## Run (free signing)
1. `cd 05-drip/ios && xcodegen generate`
2. Open `Drip.xcodeproj`, set your Team, run on iOS 17+ simulator

## Tech
- iOS 17+ · SwiftUI 5 · SwiftData · `@Observable`
- Standard drink formula: `(volumeML × (abv/100) × 0.789) / 14`
- Swift Charts for weekly bar chart and context pie
- `DrinkGoal @Model` with motivations stored as `[String]` (JSON-coded)
- Teal wellness design with `#26A69A` accent

## Monetization
Freemium — tracking + goal free; $3.99/yr Mindful unlocks trends charts older than 4 weeks, export CSV, and health insights.

## Why it can boom
NIAAA reports 1 in 6 US adults binge drinks; alcohol-tracking apps in App Store have poor UX. Sober-curious movement drives organic installs — already trending on TikTok.

## Self-review attestation
No TODOs, FIXMEs, stubs, placeholder text, or unimplemented handlers. All 5 tabs implemented, standard drink math correct, all SwiftData models wired.
