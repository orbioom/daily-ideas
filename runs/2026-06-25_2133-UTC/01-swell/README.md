# Swell — Surf Session Logger

Private, offline surf log for surfers, bodyboarders, and paddlers who want a beautiful session journal without a $30/year subscription.

## Features

- **Session Log** — Quick-log wave height, swell period, wind, conditions, duration, rating, and notes
- **History** — Full session history grouped by month, filterable by spot
- **Quiver** — Manage your board collection (type, length, volume, fins) and saved spots (break type, difficulty)
- **Stats** — Monthly session trends, conditions breakdown donut, rating trend, top spots — all via Swift Charts
- **Settings** — Imperial/metric units, haptics, default duration, data management

## Screens

1. Log (home with recent sessions + quick-add)
2. History (month-grouped, filterable)
3. Quiver (boards + spots CRUD)
4. Stats (Swift Charts — 4 charts)
5. Settings

## Run Steps

```bash
cd ios
xcodegen generate
open Swell.xcodeproj
```

Set your development team in Signing & Capabilities to free-sign, then build to device or simulator.

## Monetization

One-time **Swell Pro** (planned): advanced analytics export, Apple Watch companion, iCloud sync. Core logging and history are always free.

## Why it can boom

Surf apps (Surfline, Waterman's Log) charge $10-30/year and focus on forecasts. There is no good *private offline session logger* in the top charts. The surf community (3M US surfers alone) is passionate and word-of-mouth driven — a beautiful, ad-free, one-time-purchase log will spread fast.

## Architecture

- SwiftUI 5 / iOS 17+ / SwiftData / MVVM
- Models: `SurfSession`, `SurfSpot`, `Board`, `SurfSettings`
- 55 seeded realistic sessions spanning 10 months
- XcodeGen project (generate from `project.yml`)
- No external dependencies
