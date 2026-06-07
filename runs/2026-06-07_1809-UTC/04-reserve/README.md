# Reserve

An on-device **off-grid power budget planner** for vanlife, RVs, boats and cabins, built by the Orbioom studio. Native iOS 17, SwiftUI + SwiftData + Swift Charts.

List your electrical loads (watts × hours/day × quantity), describe your battery bank and solar array, and Reserve tells you daily energy use (Wh & Ah), days of autonomy without sun, daily solar harvest, net surplus/deficit, recharge time, and inverter headroom — and it sizes the battery and solar you'd actually need.

## What it does

- **Systems** — a list of saved power systems with at-a-glance balance verdicts (surplus / deficit) and daily draw. Tap into a full dashboard: headline StatTiles, a usable-battery meter, solar coverage meter, inverter headroom check, an energy-by-category donut (Swift Charts `SectorMark`), and an editable loads list. Full CRUD on systems and loads, including a one-tap catalog picker.
- **Sizing** — a what-if calculator independent of saved systems. Enter daily Wh (or import a saved system's total), choose desired days of autonomy, voltage, chemistry, and solar assumptions; get a recommended battery bank and solar array with live updates and plain-English guidance.
- **Reference** — the appliance catalog (~24 real vanlife/RV appliances) grouped by category with AC/DC badges and typical runtimes, plus a glossary of off-grid terms (DoD, peak sun hours, derate, etc.).
- **Settings** — Haptics, Appearance (system/light/dark), default chemistry, default peak-sun-hours, library counts, Erase-all, and About.

## Architecture

- **Models** (`Models/`): `PowerSystem` and `Load` as `@Model final class` with defaults, full initializers, cascade relationship, and `String`-raw enums (`Chemistry`, `LoadCategory`) exposed as computed properties.
- **Engine** (`Utilities/PowerEngine.swift`): a pure, side-effect-free `enum` that turns a system (or raw inputs) into a `PowerResult` — daily Wh/Ah, usable storage, autonomy (with and without solar), solar harvest, net balance, recharge time, inverter status, category breakdown, and sizing recommendations. Every division is guarded; "indefinite" autonomy is `Double.infinity`, rendered as `∞` by `Fmt`.
- **Catalog** (`Utilities/ApplianceCatalog.swift`): typical appliance templates used by the Reference tab, the catalog picker, and `SampleData`.
- **Persistence**: SwiftData for systems/loads; `@AppStorage` for preferences only. State survives relaunch.
- **Theme/Components**: shared Orbioom `Brand` tokens and glass component library (untouched scaffolding).

## Onboarding & sample data

First launch shows a four-page onboarding gated by `@AppStorage("reserve.hasOnboarded")`. Finishing seeds two believable systems (a near-break-even LiFePO4 Sprinter van and a flooded-lead lake cabin) via `SampleData` if the store is empty.

## Safety & polish

- No force-unwraps, `try!`, `fatalError`, or unguarded division in app code (the one `try!` is the required in-memory fallback in `ReserveApp`).
- Empty, loading-derived, validation, and success states throughout.
- Full accessibility labels; respects Reduce Motion; light and dark are both first-class; sparse, meaningful haptics; animation via `Brand.ease()`; lazy containers with stable ids.

## Build

Generated with XcodeGen from `ios/project.yml` (iOS 17 deployment target).
