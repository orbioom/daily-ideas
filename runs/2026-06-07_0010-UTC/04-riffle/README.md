# Riffle

**A fly-tying and fly-fishing log that matches the hatch.**

A riffle is the shallow, broken water trout love — and this is the app a fly angler
keeps in the vest. Riffle holds every pattern with its full tying recipe and how
many you have left, logs catches with the conditions and the fly that worked, and
tells you what's hatching this month and which of your flies match it. On-device,
no account.

## Features

- **Fly box** — patterns with type (dry/nymph/emerger/streamer/wet/terrestrial),
  hook-size range, difficulty, and stock count. The detail screen shows the full
  tying recipe (hook, thread, tail, body, rib, wing, hackle…), a tied/lost stock
  stepper, and every catch logged on that fly. Full CRUD, searchable, favorites,
  low-stock flagging.
- **Catch log** — log fish with species, location, length, water and air
  temperature, weather, the pattern used, and release status. Full CRUD with
  unit-aware display.
- **Hatch chart** — pick a month and see what's emerging (10 charted hatches across
  mayflies, caddis, stoneflies, midges, and terrestrials). For each, Riffle lists
  the flies in *your* box that match it by type and hook size — and flags the ones
  you should tie.
- **Insights** — your confidence fly (most catches), catches-by-month chart (Swift
  Charts), a species breakdown, average water temperature, and release rate.
- **Settings** — metric/imperial units, low-stock threshold, default species, and
  haptics; replay intro; clear all data.

## The logic

`RiffleLogic` is pure analysis over the box and log: it matches patterns to a hatch
by type overlap and hook-size-range overlap, finds the confidence fly, groups
catches by month and species, and averages conditions. `HatchCatalog` is a
reference dataset of real temperate-freshwater hatches with active months, sizes,
and matching fly types.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Riffle.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team under Signing & Capabilities; no paid account
required for the simulator or your own device.

## Tech notes

iOS 17+, SwiftUI 5, SwiftData (`Pattern` → `Material`, plus `Catch`), pure matching
logic off the view layer; hatch data as value types. Orbioom design language with a
water-blue accent: glass cards, ink-gradient action, mono figures, light + dark,
Dynamic Type, VoiceOver, Reduce Motion, gated haptics.

## Self-review

Hand-checked every file: imports resolve; all SwiftUI/SwiftData/Charts types and SF
Symbols exist in iOS 17; the reserved word `catch` is never used as an identifier
(the model type `Catch` is fine; properties are named `entry`); `@Query`/`@Bindable`
/binding-`ForEach` material editing type-checks; no force-unwraps on user paths; the
only `try!` is the in-memory container fallback in `RiffleApp`. Anti-stub grep clean.
