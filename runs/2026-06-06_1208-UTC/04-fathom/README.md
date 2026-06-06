# Fathom

**Go down well-informed.** A scuba dive logbook and nitrox/no-stop planner that records every dive, computes your real air consumption, and gives MOD, equivalent air depth, and no-stop limits offline.

**Audience:** recreational divers who want a private, offline logbook plus quick nitrox planning — without a cloud account or a subscription.

**Design language:** Orbioom.

> Planning aid only — never a substitute for training, certified tables, or a dive computer.

## Features

- **Logbook** — full CRUD of numbered dives: site, date, max/avg depth, duration, temperature, gas (air or nitrox %), cylinder pressures and size, type, buddy, visibility, 5-star rating, notes. Totals strip (dives, bottom time, deepest). Live ppO₂ warning while editing.
- **Dive detail** — derived figures: SAC (surface air consumption) computed from gas used, tank volume, duration, and average depth; max ppO₂ (flagged over 1.4); air/EAD no-stop limit; gas used.
- **Sites** — reusable dive sites (own their dives) with location, notes, dive count, and deepest depth; tap through to each dive.
- **Planner** — enter a depth and mix and get MOD (at 1.4 or 1.6 ppO₂), ppO₂ at depth, equivalent air depth, no-stop limit, and the **best mix** for the depth — all live, with over-MOD warnings.
- **Stats** — totals, average max depth, average SAC, a depth-band distribution, and dives by type.
- **Settings** — units (metric/imperial), default gas, default ppO₂ limit, haptics; reload sample data; delete all (confirmed).
- Nitrox/NDL math (MOD, EAD, ppO₂, best mix, DSAT-style air no-stop table with conservative rounding) in a pure engine. Onboarding gate, empty/loading/success/error states, light + dark, Dynamic Type, VoiceOver, Reduce Motion.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Fathom.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, **Cmd+R**.

**Free signing:** Signing & Capabilities → your personal team.

## Tech notes

iOS 17+, SwiftUI 5. Depth stored in metres and temperature in °C internally, converted for display. Persistence is **SwiftData** (`Dive`, `DiveSite`, with a nullify relationship so deleting a site keeps its dives). Dive physics live in a pure `DiveMath` enum. No dependencies, no network, no API keys.

## Self-review

Hand-checked every file: imports, iOS 17 APIs, SwiftData relationships (cascade vs nullify), optional `DiveSite` Picker tags, and nested `navigationDestination(for: Dive.self)` in two stacks. Math guards against zero/negative input. Anti-stub grep clean. No force-unwrap/`try!`/unguarded division on user paths (only the bootstrap in-memory container fallback uses `try!`). States, accessibility, light/dark verified by reading.
