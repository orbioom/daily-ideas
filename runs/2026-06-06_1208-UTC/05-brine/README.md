# Brine

**Keep the water right.** A reef/saltwater aquarium parameter tracker: log water tests, see each parameter trend against its ideal range, keep a dosing log, and never miss recurring maintenance.

**Audience:** reef and saltwater aquarists who want quiet, offline parameter tracking with trends and care reminders — instead of a spreadsheet or a cloud app.

**Design language:** Orbioom.

## Features

- **Multiple tanks** — full CRUD; a tank switcher in the dashboard toolbar and an active-tank concept across the app. Each tank owns its readings, dosing log, and care tasks.
- **Dashboard** — a water-health score (share of latest readings in the ideal range), a status-coloured grid of latest parameters, due-now tasks, and a one-tap "log test".
- **Log test** — record any subset of nine parameters (temperature, pH, salinity, alkalinity, calcium, magnesium, nitrate, phosphate, ammonia) in one session, with live in-range dots and unit-aware entry.
- **Parameters** — every parameter with its latest value, status, and a sparkline; tap through to a full **trend chart with the ideal-range band** and the editable reading log.
- **Dosing log** — record supplement, amount (mL), date, note; totals and 7-day count; delete entries.
- **Care tasks** — recurring maintenance with an interval, due/overdue status, one-tap "done", and last-done relative dates.
- **Settings** — temperature in °F, salinity as specific gravity, haptics; reload sample data; delete all (confirmed).
- Reef target ranges (ideal + safe) per parameter classify each reading good/watch/bad. Onboarding gate, "no tank" first-run state, empty/loading/success/error states, light + dark, Dynamic Type, VoiceOver, Reduce Motion.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Brine.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, **Cmd+R**.

**Free signing:** Signing & Capabilities → your personal team.

## Tech notes

iOS 17+, SwiftUI 5, Swift Charts. Values stored in canonical units (°C, ppt, ppm, dKH) and converted for display. Persistence is **SwiftData** (`Tank`, `Reading`, `DoseEntry`, `CareTask`, all cascade-owned by the tank); prefs in `@AppStorage`. Range/status logic and display conversion in pure helpers. No dependencies, no network.

## Self-review

Hand-checked every file: imports (incl. `Charts`), iOS 17 APIs, the four SwiftData cascade relationships, the active-tank `@Bindable`/`@Binding` plumbing through `MainTabs`, `navigationDestination(for: WaterParameter.self)`, and chart `RectangleMark` band usage. Anti-stub grep clean. No force-unwrap/`try!`/unguarded division on user paths (only the bootstrap in-memory container fallback uses `try!`). States, accessibility, light/dark verified by reading.
