# Plume — Birdwatching life list & sightings

**A private life list and sighting journal for birders.** Log what you see, where and when; Plume builds your life list in checklist order, marks every lifer, and tracks your year.

Design language: **Orbioom** (Liquid Glass, ink-gradient buttons, SF Pro + JetBrains Mono, green as a rare lifer/live accent).

## The problem
Birders want to keep a life list and trip notes without uploading everything to a cloud platform. Plume ships a 65-species starter catalog, lets you add any species, and keeps your whole record on-device.

## Features
- **Life List** — every species you've seen in taxonomic checklist order, with search and sort (Checklist / A–Z / Recent), first-seen month, and sighting count. Header shows life-species and family totals.
- **Species detail** — header stats (sightings, individuals, first seen, family) and the full sighting history with a Lifer badge on the first observation.
- **Sightings** feed — chronological log with one-tap lifer detection (computed by earliest observation per species), add/edit/delete.
- **Add sighting** — searchable species picker (with an inline "add a new species" form for birds not in the catalog), date, location, count, optional trip, notes.
- **Trips** — group sightings into outings; each shows species/individual/record counts; trip detail lists the checklist, lets you add birds bound to that trip, and edit trip details.
- **Insights** — life species, year-list count, lifers this year, individuals; "most observed" and "top families" bars; a species-by-month chart. Computed asynchronously with a loading state.
- **Engine** (`Utilities/LifeListEngine.swift`): lifer detection, life/year lists, and aggregate stats (top species, by family, distinct species per month).
- **Settings** — haptics, appearance, confirm-before-delete, record counts, guarded erase-all.
- Onboarding gated by a persisted flag; empty/loading states; full Dynamic Type, VoiceOver, Reduce Motion, light & dark, designed feather app icon.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Plume.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** personal team under Signing & Capabilities; bundle id `com.orbioom.plume`. No network, accounts, or API keys.

## Tech
iOS 17+, SwiftUI 5, SwiftData (`Species`/`Sighting`/`Trip` with cascade and nullify delete rules), pure value-type engine, `Canvas`/native bars for charts, `UserDefaults` for prefs. No third-party dependencies.

## Self-review
Re-read every Swift file by hand: imports, iOS 17 SDK symbols, SwiftData relationships (Species→Sighting cascade, Trip→Sighting nullify), `@Query` keypaths, `Picker` optional tags, `.onChange` two-parameter form, `project.yml`. Anti-stub grep clean. No force-unwraps/`try!` (except the in-memory container fallback)/unguarded division on user paths. An automated by-hand compile review pass was also run. Believed to compile cleanly under Xcode 15+ after `xcodegen generate`.
