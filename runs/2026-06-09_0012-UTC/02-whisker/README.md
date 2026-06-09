# Whisker — multi-pet health & care tracker

**One line:** Every pet's weight, vet visits, meds and routines in one calm, private place.
**Problem & audience:** Pet owners juggle feeding schedules, flea/tick cycles, vaccinations, weight and vet history — usually in their head or a Notes file. The category leaders (11Pets, Pawprint, Tractive) prove demand, but they're cluttered, ad-supported, or locked behind hardware. Whisker is the tasteful, on-device tracker any multi-pet household actually wants.

## Full feature list
- **Care** — an aggregated cross-pet board of every recurring task, bucketed into Overdue / Today / Soon / Upcoming, each with a one-tap "Done" that logs and reschedules from the interval.
- **Pets** — cards with avatar, age, latest weight and a due-count badge (window configurable in Settings); add unlimited pets (9 species, 8 avatar colors, breed, birthday, notes).
- **Pet detail** — segmented Overview / Weight / Care / Timeline:
  - *Weight* — Swift Charts trend (line + area), recent change, log/delete entries (kg or lb, kg canonical).
  - *Care* — recurring tasks with sensible default cadences (feeding, flea & tick, deworming, grooming, vet, vaccine, litter…), pause/edit/delete.
  - *Timeline* — point-in-time health events (vet visit, vaccine, symptom, milestone, note) with full CRUD.
- **Insights** — household tiles (pets, tasks, due-now, records), a per-pet weight chart with a pet switcher, and a per-pet care-mix breakdown.
- **Settings** — weight unit (kg/lb), "soon" reminder window, haptics, load sample pets, reset onboarding.
- Onboarding (persisted) with an "explore with sample pets" path; empty/loading/success states; light & dark; Dynamic Type; VoiceOver; Reduce Motion.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Whisker.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** no paid Apple Developer account needed — personal team, simulator or your own device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `PetEngine` (age math, due-task bucketing, weight series & change). **SwiftData** models `Pet → CareTask / WeightEntry / HealthEvent` (cascade delete); prefs in `@AppStorage`. Weights stored canonically in kilograms with a display-time unit converter. Orbioom design language.
- **Monetization:** freemium — free for a couple of pets and core tracking; Pro unlocks unlimited pets, local notifications for due care, document/photo attachments, and export.
- **Why it can boom:** huge, high-spend pet market with dated, ad-heavy or hardware-tied incumbents; Whisker is private, multi-pet, beautiful, and free to start — the version owners wish existed.

## Self-review
Hand-checked every file: imports resolve; SwiftUI/SwiftData/Charts APIs are iOS-17-valid; relationships and inverses (`\CareTask.pet`, `\WeightEntry.pet`, `\HealthEvent.pet`) type-check; sheets use `item:`/`isPresented:` correctly; no force-unwrap/`try!`/`fatalError` on user paths. Anti-stub grep clean. `project.yml` valid YAML referencing the `Whisker` sources and `Info.plist`.
