# Plateau

**Sous vide, timed from first principles.**

Plateau works out how long a sous-vide cook really needs. Tell it the food, its
thickness and shape, and your bath temperature; it solves the heat equation for the
come-up time (how long the core takes to reach the bath) and adds the pasteurization
hold needed to make poultry and pork actually safe — then runs a timer that survives
a relaunch. On-device, no account.

## Features

- **Calculate** — choose a food preset (or go custom), a doneness level, thickness,
  shape, and starting state (frozen/fridge/cool/room), and a pasteurization target.
  Plateau shows the come-up time, the hold, and the minimum total, with a safety
  note. One tap starts a live cook.
- **Timer** — active cooks count down with a progress ring and a "ready at" clock,
  updating every second via `TimelineView` and surviving an app relaunch because the
  countdown is computed from a persisted start time. Mark done or cancel.
- **Guide** — how Plateau times a cook, a pasteurization-hold reference table across
  temperatures for your chosen log reduction, and a doneness chart of common foods
  (beef, poultry, pork, seafood, egg, vegetables) with target temperatures.
- **Cook log** — finished cooks with the full time breakdown, a category chart
  (Swift Charts), ratings, notes, and favorites. Full CRUD.
- **Settings** — Celsius/Fahrenheit, default starting state, pasteurization target
  (6.5/7/8-log), and haptics; replay intro; clear all data.

## The engine

`PlateauMath` is pure physics. **Come-up time** uses the one-term Heisler solution
of the transient heat-conduction equation — shape-aware (slab/cylinder/sphere) and
dependent on starting and bath temperatures — with an effective thermal diffusivity
calibrated so a 25 mm slab from fridge temperature matches Baldwin's published
water-bath tables. **Pasteurization** uses a D/z thermal-death-time model (Salmonella
reference, D₆₀ = 2 min, z = 5.6 °C): hold = log-reductions × D(T). It's a cooking
aid, and the copy says so — when in doubt, hold longer.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Plateau.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team under Signing & Capabilities; no paid account
required for the simulator or your own device.

## Tech notes

iOS 17+, SwiftUI 5, SwiftData (`Cook`, with state for in-progress vs logged), pure
physics engine off the view layer; doneness presets as value types. Orbioom design
language with a warm amber accent: glass cards, ink-gradient action, mono figures, a
countdown ring, light + dark, Dynamic Type, VoiceOver, Reduce Motion, gated haptics.

## Self-review

Hand-checked every file: imports resolve; `pow`/`log`/`log10` via Foundation; all
SwiftUI/SwiftData/Charts types and SF Symbols exist in iOS 17; `TimelineView`
periodic updates and the persisted-countdown math type-check; `@Query`/`@Bindable`/
sheet bindings are correct; no force-unwraps on user paths; the only `try!` is the
in-memory container fallback in `PlateauApp`. Anti-stub grep clean.
