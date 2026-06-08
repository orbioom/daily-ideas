# Wayfare

**Plan a trip once, clearly — itinerary, stays, packing, and budget in one calm place.**

The problem: travel planners are a proven market, but Wanderlog nags with constant Pro pop-ups and — by its own users' accounts — makes it hard to see *where you're sleeping each night*, while TripIt's UI "feels like 2015." Wayfare is the planner people wish existed: a readable day-by-day itinerary, an at-a-glance nightly-lodging coverage view that flags gaps, honest budgeting, and zero spam. Audience: trip planners, couples, families, frequent weekenders.

## Features

- **Trips list** split into Upcoming and Past, each card showing a live status ("In 5 days" / "Day 2 of 4" / "Completed"), date range, and an unbooked-nights warning.
- **Trip hub** with four sections.
- **Itinerary** — activities grouped by day, sorted by time (with untimed "all-day" items), each with a category, location, cost, and a Booked flag.
- **Stays** — the headline feature: a per-night coverage list that maps every night of the trip to the lodging that covers it and **flags gaps** ("No stay booked"), plus full lodging CRUD with nights computed from check-in/out.
- **Packing** — categorized checklist with a live packed/total progress bar and quick add.
- **Budget** — set a budget; track expenses by category against a ring (over-budget aware), with a category donut (Swift Charts).
- **Settings** — theme, default currency (used for new trips), haptics, erase-all.
- Onboarding (persisted), empty/loading/success states, Dynamic Type + VoiceOver, light & dark, Reduce-Motion-aware, on-brand icon.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Wayfare.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team under Signing & Capabilities; bundle id `com.orbioom.wayfare`.

## Tech notes

iOS 17+, SwiftUI 5, MVVM with a pure `TripEngine` (status, day spans, **per-night lodging coverage**, itinerary grouping, budget rollups). Persistence in **SwiftData** — `Trip` cascades to `Activity`, `Lodging`, `PackingItem`, and `Expense`. Design language: **Orbioom**. No account, no network.

- **Monetization:** freemium — one or two trips free; a Pro subscription/one-time unlock raises the trip cap and adds export. Who pays: travelers planning multiple trips a year.
- **Why it can boom:** large validated category; we win on the exact gaps reviewers cite (nightly-lodging clarity, calm no-spam UX, real design) instead of cloning.

## Self-review

Re-read every Swift file by hand. Imports resolve; SwiftData relationships/cascades, `@Query`, `navigationDestination(for:)` for both `Trip` and `TripSection`, and sheet bindings type-check; enums are `Hashable`; no iOS-18 APIs; no force-unwraps/`try!`/`fatalError` on user paths (only container bootstrap). Added `Format.shortTime` used by the itinerary. Anti-stub grep clean.
