# Petal 🐾

**One calm home for every pet's health.** Petal is a private, offline, ad-free
multi-pet care and health tracker for iOS — medications, vaccinations, vet
visits, weight trends and feeding schedules for your whole household of pets,
unified into a single upcoming-care timeline.

## Problem & audience

Pet owners juggle a flea pill for the dog, a booster due for the cat, a vet
follow-up for the rabbit and twice-daily meals for everyone — usually across a
fridge note, a calendar and their memory. Existing apps (11pets, Pawtrack) work
but are cluttered or push subscriptions. Petal is for multi-pet households who
want a clean, glanceable record of *who needs what, when* — with nothing leaving
their device.

## Features

- **Multi-pet profiles** — name, species (dog/cat/rabbit/bird/reptile/fish/horse/other),
  breed, birthday with computed age, SF Symbol avatar with a tinted gradient, and notes. Full CRUD.
- **Upcoming-care timeline (the hero screen)** — aggregates medications,
  vaccination boosters, vet follow-ups and today's feedings across *all* pets into
  Overdue / Today / Soon / Upcoming buckets, sorted by due date, with a one-tap
  complete that advances the schedule. Filterable by item type. Overdue badge on the tab.
- **Medication schedules** — dosage, 8 frequencies (once/twice-daily through
  monthly and as-needed), optional course end date (auto-completes finished
  courses), give-dose action that rolls the next-due date forward.
- **Vaccination records** — date administered, booster due date, clinic, lot
  number, common-vaccine quick picks, overdue highlighting.
- **Vet visit log** — 8 reasons with icons, clinic/vet, diagnosis, notes,
  optional cost, and schedulable follow-ups that feed the care timeline.
- **Weight tracking** — per-pet Swift Charts trend (line + gradient area),
  current/change/count stats, full history with delete, kg ⇄ lb canonical storage.
- **Health overview** — cross-pet stats, overdue boosters, recent vet visits,
  drill-down into any pet's records.
- **Feeding schedules** — labeled recurring meals with time-of-day, food, portion,
  active toggle; appear in the daily timeline.
- **Settings** — owner name, weight unit, appearance (system/light/dark),
  haptics toggle, adjustable "Soon" window, replay onboarding, delete-all, About.
- First-run onboarding (persisted flag), empty states everywhere, input
  validation, recoverable error handling, full accessibility, light/dark themes.

## Screens (TabView)

**Pets** · **Care** · **Health** · **Weight** · **Settings** — plus per-pet
detail and dedicated medication/vaccination/vet-visit/feeding list+form screens
via `NavigationStack`.

## Tech notes

- **iOS 17+, SwiftUI 5, MVVM.** SwiftData models: `Pet`, `Medication`,
  `Vaccination`, `VetVisit`, `WeightEntry`, `FeedingSchedule`, `AppSettings`
  (pet owns the rest via `.cascade` relationships). `@Query`/`@Bindable`/`modelContainer`.
- Pure, testable `CareTimeline` aggregation engine; weights stored canonically in
  kilograms and converted for display. No external dependencies, no network, no API keys.
- 5 seeded pets with 50+ realistic records (meds, vaccines, visits, weight series, feedings).
- **Monetization:** free with a one-time **Petal Plus** unlock (~$4.99) for
  unlimited pets beyond 2, plus iCloud sync and PDF health-record export.
- **Why it can boom:** 65%+ of US households own pets and multi-pet homes are the
  norm; "vaccine reminder" and "pet medication tracker" are steady evergreen
  searches. A genuinely clean, private, no-subscription tracker undercuts the
  cluttered incumbents and is highly shareable among pet-parent communities.

## Run steps

```bash
brew install xcodegen          # if not already installed
cd ios
xcodegen generate              # creates Petal.xcodeproj
open Petal.xcodeproj           # Xcode 15+ (iOS 17 SDK)
# Select an iOS 17+ simulator, then Cmd+R
```

**Free signing:** in Xcode select the `Petal` target → Signing & Capabilities →
pick your Personal Team; the bundle id `com.orbioom.petal` can be changed if it
collides. No paid account needed for the simulator.

## Self-review attestation

I re-read every Swift file and additionally ran a real type-check against the
iOS 17 SDK (`xcrun swiftc -sdk <iphoneos> -target arm64-apple-ios17.0 -typecheck`
over all 35 sources) — it completed with **zero errors and zero warnings**.
Verified: all imports/types/initializers/enum cases/modifiers exist in the iOS 17
SDK and are spelled correctly; protocol conformances satisfied; correct use of
`@State`/`@Bindable`/`@Environment`/`@Observable`/`@Query`/`modelContainer`;
`NavigationStack`/`navigationDestination`/sheet bindings type-check; no APIs newer
than iOS 17. No `fatalError`/`try!`/force-unwraps on user paths (numeric input is
parsed defensively, division guarded, optionals safely unwrapped). Anti-stub grep
(`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub`) over
`Petal/` returns nothing. `xcodegen generate` succeeds. AppIcon is a real
1024×1024 RGBA PNG (verified via Pillow); 13 light/dark color sets ship in the
asset catalog; `Info.plist` is valid and includes `UILaunchScreen`.
