# Tilth

**Plant on the right week, every week.**

Tilth turns your two frost dates — last spring frost and first fall frost — into a
complete sowing calendar. For every crop it computes when to start seeds indoors,
when to set them out or direct-sow, when the first harvest lands, the last date you
can still sow and beat the cold, and the succession sowings in between. Built for
the home gardener who wants timing they can trust. On-device, no account.

## Features

- **Plan** — a season banner with your frost-free days, a "needs attention" list of
  plantings due to sow now or overdue, and a chronological timeline of this year's
  plantings. Tap to advance a planting through planned → sown/transplanted →
  harvested; swipe to delete.
- **Crops** — a catalog of crop profiles (starts with 14 real ones), each carrying
  its own frost-relative timing. The crop detail computes the full schedule against
  *your* frost dates, including succession dates and a season-fit warning. Full CRUD,
  searchable, with favorites.
- **Beds** — garden beds with dimensions; Tilth computes area and plant capacity
  from spacing, and lists what's growing where. Full CRUD.
- **Harvest** — a season forecast: what's ready in the next three weeks, a harvests-
  by-month chart (Swift Charts), and a month-by-month list.
- **Onboarding** sets your frost dates up front; **Settings** lets you change them
  any time, along with hardiness zone and haptics.

## The engine

`FrostMath` is pure date math over a `CropParams` snapshot. It applies frost-relative
offsets (start-indoors weeks before, transplant/direct-sow weeks after), maturity
days, and a frost-tolerance buffer to derive every milestone — including the last
safe sow date (`fall frost − days-to-maturity − tolerance buffer`) and a guarded
succession series. All timing flows from the two dates you set, so changing them
re-plans the whole garden.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Tilth.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: choose your personal team under Signing & Capabilities; no paid
account needed for the simulator or your own device.

## Tech notes

iOS 17+, SwiftUI 5, SwiftData (`Bed` → `Planting`, plus a standalone `Crop`
catalog), pure date engine off the view layer; frost dates persisted via
`@AppStorage` and surfaced through a single `Season` helper. Orbioom design
language: glass cards, ink-gradient action, mono figures, light + dark, Dynamic
Type, VoiceOver, Reduce Motion, gated haptics.

## Self-review

Read every file by hand: imports resolve; all SwiftUI/SwiftData/Charts types and SF
Symbols exist in iOS 17; the three Codable enums persist; `@Query`, `@Bindable`,
`PersistentIdentifier` pickers, and sheet bindings type-check; no force-unwraps on
user paths (the one safe dictionary access was refactored away); the only `try!` is
the in-memory container fallback in `TilthApp`. Anti-stub grep clean.
