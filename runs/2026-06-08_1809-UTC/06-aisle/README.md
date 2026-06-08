# Aisle — wedding planner

**Aisle organizes the whole wedding — guests & RSVPs, budget, seating, and the planning checklist — privately, for the two of you.** For engaged couples who want The Knot/Zola-style planning without ads, upsells, vendor spam, or accounts.

## What it is
A native iOS wedding planner anchored on your date. Track guests and RSVPs with headcounts, manage a real budget (estimated vs actual vs paid), assign guests to tables with capacity checks, and work a standard planning checklist.

## Features
- **Overview** — a countdown hero, RSVP headcounts (attending / pending / declined / invited), a budget summary with progress, checklist progress with overdue count, and a seating snapshot.
- **Guests** — add parties with size, side, RSVP, meal choice, table, and notes; filter by RSVP, search, swipe to set Yes/No or delete; live headcount bar.
- **Budget** — items with category, estimated/actual/paid and vendor; totals (planned/paid/owed), over-budget detection vs your total, and a by-category donut.
- **Checklist** — a built-in ~15-item planning timeline keyed to your date, plus your own tasks; overdue surfacing, progress bar, hide-completed.
- **Seating** — tables with capacity, per-table guest lists, over-capacity warnings, an "not yet seated" list, and a sheet to assign/unassign attending guests.
- **Settings** — couple names, date, venue, total budget, currency, add-standard-checklist, haptics, full reset. All persisted.
- Onboarding collects the basics and optionally seeds checklist + sample data; empty/loading/success states; Dynamic Type + VoiceOver; light/dark; Reduce Motion; sparse haptics.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Aisle.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: personal team, free Apple ID, simulator or device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `WeddingEngine` (countdown, RSVP/meal tallies, budget rollups, seating capacity, checklist progress). **SwiftData** for `Wedding`, `Guest`, `SeatingTable` (nullify relationship to guests), `BudgetLine`, `ChecklistTask`; small prefs in `UserDefaults`. Swift Charts for the budget donut. Design language: **Orbioom** (warm rose accent). No external dependencies; optional seeded guests/budget/checklist.
- **Monetization:** freemium — planning free; Pro (one-time unlock or subscription) for partner sharing, exports/printable seating charts, and unlimited events (planners). The Knot/Zola monetize heavily via vendors/ads — a clean paid app is a clear alternative.
- **Why it can boom:** weddings are a high-spend, deadline-driven, emotional event with mediocre, ad/vendor-driven incumbents. A private, all-in-one planner couples actually enjoy using — guests, budget, *and* seating together — is a strong, monetizable wedge.

## Self-review
Re-read every file. Verified imports, iOS 17 SDK usage, SwiftData relationships (`SeatingTable.guests` nullify inverse `Guest.table`), `@Bindable`/`@Query`/`PersistentIdentifier` table pickers, that pushed screens (Seating) avoid nested `NavigationStack`s, Charts `SectorMark`. Engine tallies/rollups/capacity checked by hand; divisions guarded. Anti-stub grep clean (only onboarding "placeholder" parameter names). No `try!`/force-unwrap on user paths; only the documented container-fallback `fatalError`.
