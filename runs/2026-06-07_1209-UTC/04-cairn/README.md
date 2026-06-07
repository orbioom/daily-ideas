# Cairn

**Ultralight backpacking pack-weight planner with a reusable gear catalog.** Add each item once with its real weight, build a list for the trip, mark what's worn and consumable, and Cairn turns it into a clear base / total / skin-out weight breakdown — and shows where to cut.

For hikers chasing a lighter base weight who want a native, offline home for the LighterPack workflow.

## Features

- **Gear catalog** — every item once: name, brand, category (shelter, sleep, pack, clothing, cooking, water, electronics, first-aid, food, other), weight (entered in g or oz, stored in grams), and worn/consumable flags. Grouped by category with per-category totals and a category filter.
- **Pack lists** — pull gear from the catalog into a trip list with quantities and a packed checkbox. The list headline shows base weight and what's on your back.
- **Weight breakdown** — the standard ultralight split: base (gear, excluding worn & consumables), consumable, worn, total-on-back, skin-out, and the "big three" (shelter+sleep+pack), with a base-weight tier (super-ultralight → heavy) and a category donut.
- **Insights** — catalog weight by category (horizontal bar chart), base weight compared across all lists, and your heaviest items.
- **Settings** — weight unit (g / kg / oz / lb+oz), skin-out vs base headline, confirm-before-delete, haptics, appearance, erase-all.

Onboarding gate, empty/loading/success states, light & dark, Dynamic Type, VoiceOver, Reduce Motion, designed app icon.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Cairn.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**.

**Free signing:** pick your personal team under Signing & Capabilities; bundle id `com.orbioom.cairn`. No paid account needed.

## Tech notes

iOS 17+, SwiftUI 5, pure `PackMath` for the weight breakdown, category totals, and tier; `WeightFmt` for unit conversion. Persistence in **SwiftData** — a shared `GearItem` catalog with `PackList → PackEntry` referencing gear (to-one, nullify on delete so lists degrade gracefully). **Swift Charts** for the donut and bars. Orbioom design language. No third-party dependencies; a realistic gear closet and a three-season list are seeded on first launch.

## Self-review

Anti-stub grep clean (only the in-memory `ModelContainer` fallback uses `try!`). By-hand compile pass: SwiftData shared/optional relationships, `CatWeight`-backed charts (no tuple key-path ids — converted to an `Identifiable` struct), grouped sections via `indices`, and unit conversions verified against the iOS 17 SDK. Correctness is by inspection (no Xcode in the sandbox).
