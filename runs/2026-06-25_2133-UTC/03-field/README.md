# Field — Multi-Species Nature Observation Journal

The nature journal that covers everything: birds, mammals, plants, fungi, insects, reptiles, amphibians, fish, and more — not just birds. Log sightings with conditions, behaviour, and notes; build a life list across all kingdoms; track field trips and explore your data with Swift Charts.

## Features

- **Observe** — Quick-log any sighting: species name, class (bird/mammal/plant/fungi/insect/etc.), count, location, habitat, view quality, weather, behaviour, and notes. Mark first-ever sightings as Lifers with haptic celebration. Filter by class. Date-grouped log.
- **Catalog** — Full species index from all your sightings, deduplicated by species name. Filter by class, search by name, toggle Lifers-only view. Observation count per species.
- **Trips** — Log field trips with habitat type, duration, distance, weather. Trip names link to observations for easy grouping.
- **Insights** — 4 Swift Charts: class breakdown donut, monthly sightings bar, top locations bar, life list (lifers per month). Summary tiles: total species / lifers / trips.
- **Settings** — Metric/imperial distance, lifer celebration haptic, default habitat, data management.

## Screens

1. Observe (home with observation log, class filter chips, date groups)
2. Catalog (species index, searchable, lifer-filterable)
3. Trips (field trip CRUD with habitat/weather)
4. Insights (4 Swift Charts + summaries)
5. Settings

## Seed Data

58 realistic observations spanning 10 months across 11 species classes (from backyard sparrows to wild jaguars), 10 seeded field trips.

## Run Steps

```bash
cd ios
xcodegen generate
open Field.xcodeproj
```

Set your development team in Signing & Capabilities, then build to device or simulator.

## Monetization

One-time **Field Pro** (planned): iCloud sync, photo attachments per sighting, location map view, CSV/Markdown export, extended species classes.

## Why it can boom

iNaturalist has 50M+ users globally but is a social network — not a private journal. Birding apps (Merlin, eBird) are bird-only. There is no dedicated *multi-species private nature journal* in the App Store. Naturalists, foragers, hikers, and park rangers all want exactly this. Word-of-mouth from the dedicated naturalist community is powerful, and the "all kingdoms in one place" pitch is a clear differentiator.

## Architecture

- SwiftUI 5 / iOS 17+ / SwiftData / MVVM
- Models: `Observation`, `FieldTrip`, `FieldSettings`
- 58 seeded observations across 11 species classes
- XcodeGen project (generate from `project.yml`)
- No external dependencies
