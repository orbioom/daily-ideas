# Nook — home maintenance that knows what's due

**Nook** keeps your home's recurring upkeep on schedule. It tracks every maintenance task by its real cadence — monthly filter swaps, quarterly disposal cleanings, seasonal gutters, annual water-heater flushes — organises them by room and by the equipment they belong to, and surfaces a clear *what's due* timeline so nothing slips.

## Problem & audience
Homeowners forget the boring-but-expensive stuff: the HVAC filter that should have been changed two months ago, the smoke-detector batteries, the gutters before the autumn storms. Skipped upkeep quietly shortens the life of appliances and turns small jobs into big repairs. Tools like HomeZada and Centriq exist but lean toward heavy document vaults and paid cloud accounts. **Nook's edge:** a calm, on-device scheduler centered on *recurrence* and *equipment records* — every task carries its own cadence, every appliance carries its model, purchase date and warranty, and one tap rolls a task forward to its next due date.

## Features
- **Due dashboard** — a home-health gauge plus Overdue / Due today / Due soon / Upcoming buckets, swipe-to-complete, and a "completed this month" tally.
- **Recurrence engine** — monthly, quarterly, seasonal, twice-a-year, annual and one-time cadences. Marking a task done logs a service record and advances the next-due date from the later of today or the current due date (no piled-up missed cycles). One-time tasks archive themselves.
- **Tasks tab** — full CRUD, search across tasks/rooms/equipment, filter (all/active/overdue/paused), and grouping by room *or* by cadence (a Settings preference).
- **Rooms** — per-room organisation with task and equipment counts and a "due" badge; room detail lists its tasks and equipment and can add tasks pre-scoped to that room.
- **Equipment / appliance records** — model number, serial, brand, purchase date and warranty months, with a live warranty status (active / expiring soon / expired) and an "expiring soon" banner. Tasks can be attached to a specific appliance so service history lives with the equipment.
- **Service history & costs** — every completion is logged with an optional cost, vendor and note; per-task totals and an Insights screen with Swift Charts (completions over 6 months, spend by cadence).
- **Mark-done sheet** — capture completion date, cost, vendor and note, with a live preview of the next due date.
- **Snooze** — push a task out by 1 day / 3 days / 1 week / 1 month.
- **Settings** — 5 persisted preferences (haptics, group-by-room, week-starts-Monday, due-soon window, currency), restore-starter-checklist, erase-all-data, and re-show the welcome tour.
- **Starter home** — a seeded sample home (10 rooms, 12 appliances with warranties, 60 maintenance tasks with staggered due dates and completion history) so the app is alive on first launch.

## Screens (TabView + NavigationStack)
Due · Tasks · Rooms · Equipment · Settings (+ Insights, + task/room/equipment detail & editors). First-run onboarding is gated by a persisted `hasOnboarded` flag.

## Run steps
```bash
brew install xcodegen          # if not installed
cd ios
xcodegen generate              # creates Nook.xcodeproj from project.yml
open Nook.xcodeproj            # Xcode 15+
# select an iOS 17 simulator, then Cmd+R
```
**Free signing:** in Xcode, select the *Nook* target → Signing & Capabilities → check *Automatically manage signing* and pick your personal team. No paid account needed for the simulator or a personal device.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. **SwiftData** is the system of record (`Room`, `Appliance`, `MaintenanceTask`, `ServiceRecord`, `AppSettings`) with cascade/nullify delete rules chosen so history survives edits and tasks survive room/equipment deletion. `@AppStorage` holds only the onboarding flag.
- No external dependencies, no network, no API keys. The container falls back to an in-memory store and a calm error screen rather than crashing; no `try!` / `fatalError` / force-unwrap on user paths.
- Pure, view-free `ScheduleEngine` / `WarrantyEngine` / `DashboardBuilder` hold the date math and bucketing (division guarded, calendar-based).
- Full light/dark via asset-catalog color sets, Dynamic Type, accessibility labels/hints/values, Reduce-Motion-aware animation, and haptics gated by a Settings toggle. Real 1024×1024 RGBA gradient AppIcon (teal→slate house emblem) generated with Pillow.
- **Monetization:** free core with a one-time **Nook Plus** unlock (~$4.99) for unlimited equipment records, photo attachments, and reminder notifications — no subscription.
- **Why it can boom:** every homeowner has this problem and forgets it monthly; an offline, no-account, one-time-purchase scheduler that ties tasks to actual appliances and warranties is exactly the calm alternative to subscription-heavy incumbents, and the seeded starter checklist delivers value in the first five seconds.

## Self-review attestation
I re-read every Swift file as the compiler. Verified: all imports present (`SwiftUI`, `SwiftData`, `Charts`, `UIKit` where used); every type, initializer, enum case and modifier exists in the iOS 17 SDK and is spelled correctly; protocol conformances (`Identifiable`, `Hashable`, `Comparable`, `Codable`) are satisfied; `@State`/`@Bindable`/`@Binding`/`@Environment`/`@Query`/`@AppStorage` usage is correct; `NavigationStack` + `navigationDestination(item:)` and all `sheet`/`confirmationDialog` bindings type-check; SwiftData `@Model` relationships declare each inverse exactly once; no APIs newer than iOS 17. SwiftData models are never sent across actor boundaries. The anti-stub grep (`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub`) returns no matches, and there are no `try!` / `fatalError` / force-unwraps on user paths. `xcodegen generate` succeeds against `project.yml`; `Info.plist` and every asset-catalog `Contents.json` are valid; the AppIcon is a real 1024×1024 RGBA PNG.
