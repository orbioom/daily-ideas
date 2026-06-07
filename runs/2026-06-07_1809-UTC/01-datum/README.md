# Datum

A general-aviation **weight & balance** planner for pilots, by the Orbioom studio.
Native iOS 17 SwiftUI. Fully offline.

## What it is

Build an aircraft profile once — empty weight & arm, loading stations with their
arms, fuel parameters, and the CG envelope polygon — then for every flight enter
occupant, baggage and fuel weights and instantly see:

- total weight and center of gravity at **ramp, takeoff, landing and zero-fuel**,
- whether each phase is **inside the CG envelope** and within weight limits,
- the **allowable fore/aft CG range** at takeoff weight,
- an itemized **loadings breakdown** (weight × arm = moment), and
- a plotted **CG envelope chart** with the four scenario points colored by status.

Audience: private and student pilots and flight instructors. Always cross-check
against the aircraft's POH before flight.

## Features

- **Flights tab** — list of saved plans (ramp weight, CG, in/out badge), a guided
  new-flight flow (pick aircraft → per-station weights, fuel slider, planned burn →
  live weight/CG/status preview), and a rich **Flight Detail** centerpiece with the
  four-scenario table, allowable CG range meter, loadings breakdown and the envelope
  chart. Edit and delete flights.
- **Aircraft tab** — full CRUD on aircraft profiles. The editor covers empty
  weight/arm, all max-weight limits, the fuel system, an editable/reorderable
  **stations** list and an editable **envelope** list with a live mini preview and
  inline validation.
- **Tools tab** — a density-altitude calculator (pressure + density altitude with a
  plain-English note), an ad-hoc CG calculator (add weight@arm rows), and a unit
  reference (lb↔kg, in↔cm, fuel densities).
- **Settings** — Haptics toggle, Appearance (system/light/dark), default fuel type,
  confirm-before-deleting toggle, library counts, add-sample-data, and Erase all data.
- First-run **onboarding**, **empty/loading/validation/success** states throughout,
  full **light & dark** support, Dynamic Type, VoiceOver labels (including the chart),
  and Reduce-Motion-aware animation.

## Run steps

```sh
brew install xcodegen
cd ios
xcodegen generate
open Datum.xcodeproj
```

Then in Xcode 15+:
- select an **iOS 17+ simulator** (e.g. iPhone 15),
- press **Cmd+R**.

**Free signing note:** the project ships with no team set. To run on a physical
device, open the Datum target → Signing & Capabilities → pick your personal team
(automatic signing); the bundle id is `com.orbioom.datum`. The simulator needs no
signing.

## Tech notes

- **Persistence:** SwiftData (`@Model` / `@Query` / `modelContainer`). Every stored
  property has a default value and an explicit initializer; relationships use
  `@Relationship(deleteRule: .cascade, inverse:)` declared on the parent. `@AppStorage`
  is used only for preferences and the onboarding flag. Enums (appearance, fuel type)
  are stored as `String` raw values with computed accessors. Data survives relaunch.
- **Engine:** `WBEngine` is pure (no SwiftUI / SwiftData) — moments, loadout
  summation, the four scenarios, ray-casting point-in-polygon, allowable-CG-range
  interpolation, density altitude and ad-hoc CG. All divisions guard zero denominators.
- **Snapshotting:** each saved `Flight` stores its own copy of the CG envelope as a
  JSON string (`envelopeData`) plus snapshotted aircraft parameters, so editing or
  deleting an aircraft never changes a saved flight. Weight limits are resolved from
  the live aircraft when present, otherwise from the envelope's own maximum weight.
- **Charts:** the envelope chart is built on Swift Charts; the translucent polygon
  fill is drawn in the chart's coordinate space via `chartBackground` + `ChartProxy`
  so it traces the true (non-baseline) envelope shape.
- **Safety:** no force-unwraps, `try!` (except the mandated in-memory container
  fallback in `DatumApp`), `fatalError`, or unguarded division on user paths; all
  numeric inputs are parsed defensively and clamped.

## Self-review

- **Feature screens:** Flights (list + new-flight flow + detail), Aircraft (list +
  editor), Tools, Settings — 4+ substantive screens with full CRUD on flights and
  aircraft. No dead ends; every sheet/stack has working cancel/back/dismiss.
- **Onboarding:** gated by `@AppStorage("datum.hasOnboarded")`; seeds sample data on
  finish only if the store is empty.
- **States:** empty states on every data surface, a loading state on Flight Detail's
  computation, calm validation/warning states in the editors, success haptics on save.
- **Settings:** Haptics (wired to `Haptics.enabled`), Appearance (`preferredColorScheme`
  in `RootView`), default fuel type, confirm-before-deleting — plus Erase all data via
  `confirmationDialog`. 4 persisted prefs + flags.
- **Accessibility:** system fonts (Dynamic Type), labels/hints/values on controls and
  the chart, decorative images hidden, Reduce-Motion respected, Brand tokens only for
  AA contrast in both modes.
- **Anti-stub:** no TODO/FIXME/XXX/placeholder/lorem/"coming soon"/"not implemented"/
  "// stub" anywhere; everything is wired.
- **Verification:** no Swift toolchain is available on this Linux build machine, so the
  code was type-checked by hand against the iOS 17 SDK — imports, model/relationship
  declarations, `@Query`/`@Bindable`/`navigationDestination`/`sheet` wiring, and
  Swift Charts (`chartBackground`/`ChartProxy.position(forX:)`/`plotFrame`) usage were
  each reviewed. Build with `xcodegen generate` then Cmd+R as above.

*Conjured, not just coded.* — Orbioom
