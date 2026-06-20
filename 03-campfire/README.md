# 03 — Campfire: Camping Trip Planner

A full-featured camping companion app for planning trips, packing gear, logging meals, and journaling nature sightings — all offline, no account needed.

## Features

- **Trip Management** — upcoming/past trips with status tracking (Planned → Active → Completed)
- **Gear Checklist** — category-filtered pack list with owned/need-to-buy badges and progress bar
- **Meal Planner** — day-by-day meal schedule with prep method (campfire, stove, no-cook)
- **Nature Journal** — log wildlife, plants, weather, sky events with category icons
- **Camp Stats** — trips by year chart, camp style breakdown, nature sightings, favorite spots
- **2-step Onboarding** — dark forest-green welcome flow

## Screens

1. Onboarding (2 steps: welcome + ready)
2. Trips List (upcoming / past sections, status filter chips)
3. Trip Detail (segmented Gear / Meals / Nature tabs)
4. Gear Checklist (category filter, tap-to-pack, delete)
5. Meal Planner (day grouping, prep method)
6. Nature Journal (sorted by date, category icons)
7. Add/Edit Trip form
8. Add Gear form
9. Add Meal form
10. Add Nature Log form
11. Stats (Charts, breakdowns)
12. Settings (weight unit, countdown toggle, camp type default)

## Tech

- SwiftUI 5 + SwiftData (iOS 17+)
- Swift Charts for stats visualization
- XcodeGen `project.yml`
- No external dependencies

## Monetization

One-time Pro unlock ($3.99): unlimited trips stored (free tier = 5), stats screen, and export packing list as PDF.

## Market Signal

Camping participation hit a 10-year high post-2020 and has stayed elevated. "Camping checklist app" has 40K+ monthly searches. The App Store has outdated competitors (last updated 2019–2021) with poor SwiftUI support and no nature journaling feature. Campfire differentiates with the nature journal, meal planner, and offline-first SwiftData persistence.
