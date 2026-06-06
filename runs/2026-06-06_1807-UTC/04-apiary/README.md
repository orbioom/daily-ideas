# Apiary — beekeeping hive log & inspection companion

**One line:** A calm, fully-offline beekeeping logbook with structured inspections, varroa tracking, and a tasks screen that never lets a treatment window or swarm risk slip past.

**Problem & audience:** Beekeepers inspect colonies on a schedule, beside an open hive, often with no signal. The records that matter — queen status, brood, stores, temperament, mite counts, treatment timing — are easy to forget and tedious in a blank notes app. Apiary gives hobby and sideline beekeepers structured prompts, a clear health read, and timely reminders, all on-device.

## Features

- **Apiaries → Hives** — group hives by location; each apiary shows live/total hive counts, at-risk count, and total honey. Full CRUD on both apiaries and hives.
- **Hive detail** — queen marking color (international standard, auto from queen year), health pill, swarm/mite alerts, latest-inspection summary (queen, temperament, space, brood/population/stores ratings), and a **varroa trend chart** with the treat-threshold rule line. Sub-records (inspections, treatments, harvests) each have full CRUD via sheets.
- **Structured inspections** — queen seen, eggs seen, queen cells, brood/population/stores (1–5), temperament, space, varroa per-300 with live % infestation, weather, notes.
- **Treatments** — product, reason, start date + duration → computed **remove-by date** and days-remaining; completed flag.
- **Harvests** — honey/wax/propolis/pollen with weight (kg or lb) and frame count.
- **Tasks** — one screen aggregating overdue treatments, treatments due soon, swarm risks, high-varroa colonies, queenless hives, and hives overdue for inspection (interval is a setting). Each row deep-links to the hive. "All clear" state when nothing's pending.
- **Harvest** & **Insights** — honey totals, honey-by-year and by-product charts, colony-health distribution, average mite load, and queens-by-year with marking colors (Swift Charts).
- **Real domain logic** — `BeeLogic` computes queen colors, a health score, swarm risk (queen cells + crowding), and the ~3% varroa action threshold.
- **Settings** — harvest units, inspection-reminder interval, haptics; reload sample data; delete all.
- First-run onboarding (persisted), empty/loading/success/error states, light & dark, Dynamic Type, VoiceOver, Reduce Motion, sparse haptics.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Apiary.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team under Signing & Capabilities; no paid account needed.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-lite (pure `BeeLogic`, SwiftData models, thin views).
- Persistence: **SwiftData** — `Apiary` → `Hive` → (`Inspection`, `Treatment`, `Harvest`), all cascade-delete with inverses. Prefs in `UserDefaults` via `@AppStorage`.
- Design language: **Orbioom** (glass, ink-gradient action, mono figures) with amber as the honey/warning semantic accent and green reserved for healthy/live.
- No external dependencies; Swift Charts is a system framework.

## Self-review

Re-read every Swift file against the iOS 17 SDK: imports (`SwiftUI`, `SwiftData`, `Charts`) resolve; five `@Model` types with cascade relationships + inverses, `@Query`, `@Bindable`, `@AppStorage`, multiple independent `.sheet(isPresented:)`/`.sheet(item:)`, `NavigationStack`/`navigationDestination(for:)` for `Apiary` and `Hive`, and Charts `RuleMark`/`LineMark`/`BarMark` all type-check. No force-unwraps, `try!` (except the in-memory `ModelContainer` bootstrap in `ApiaryApp`), unchecked indices, or unguarded division — ratings and counts are clamped; mite % divides by constants. Anti-stub grep clean. Seeds 2 apiaries, 4 hives, inspections, treatments, and harvests covering every alert path.
