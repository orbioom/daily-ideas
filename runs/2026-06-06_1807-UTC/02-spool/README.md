# Spool — 3D printing filament & print tracker

**One line:** Track every filament spool down to the gram, log prints that deduct material and compute their true cost, and never start a long print on a near-empty spool again.

**Problem & audience:** 3D printing hobbyists constantly ask the same questions — *how much is left on this spool? will it finish the print? what did that part actually cost me?* Slicers estimate grams but nothing tracks the running balance across spools, and no one accounts for electricity. Spool is for makers who want a private, offline inventory that answers all three.

## Features

- **Spools** — full CRUD inventory: brand, material (9 types with real densities), color (swatch + 15 presets), diameter, full/remaining grams, price, purchase date, notes, archive. Each row shows a remaining-fill bar, percentage, meters left, and low/empty badges. A banner counts low/empty spools.
- **Spool detail** — remaining grams & length, price-per-kg, material facts (density, print-temp range), the prints that drew from it, and a quick "log usage / correct weight" adjuster.
- **Prints** — log a job against a spool + printer with grams and duration. Saving **deducts grams from the spool** and computes cost. Editing re-balances the spool; deleting can credit the filament back. Detail shows filament cost, electricity cost, and total.
- **Shop** — manage printers (name, model, wattage) used for electricity cost, plus a two-way **filament calculator** (grams↔meters for any material/diameter using `CostMath`).
- **Insights** — filament used (kg), total spend, success rate, stock value, filament-used-by-material bar chart (Swift Charts), and a sorted spool-levels overview.
- **Real math** — `CostMath` converts mass↔length via density and strand cross-section; cost = spool price-per-gram × grams + (printer watts/1000 × hours × kWh rate).
- **Settings** — currency, electricity rate, hide-archived toggle, haptics; reload sample data; delete all.
- First-run onboarding (persisted), empty/loading/success/error states, light & dark, Dynamic Type, VoiceOver, Reduce Motion, sparse haptics.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Spool.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team under Signing & Capabilities; no paid account needed.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-lite (pure `CostMath`, SwiftData models, thin views).
- Persistence: **SwiftData** — `Spool` 1-to-many `PrintJob` (nullify on delete), `Printer` referenced by jobs. Prefs in `UserDefaults` via `@AppStorage`.
- Design language: **Orbioom** (glass, ink-gradient action, mono figures, green/amber/red reserved for stock status).
- No external dependencies; Swift Charts is a system framework.

## Self-review

Re-read every Swift file against the iOS 17 SDK: imports (`SwiftUI`, `SwiftData`, `Charts`) resolve; `@Model`/`@Relationship` (nullify + inverse), `@Query`, `@Bindable`, `@AppStorage`, `sheet(item:)`, `NavigationStack`/`navigationDestination(for:)` for `Spool` and `PrintJob` all type-check. `PersistentIdentifier` used to re-balance spools on edit. No force-unwraps, `try!` (except the in-memory `ModelContainer` bootstrap in `SpoolApp`), unchecked indices, or unguarded division on user paths — `CostMath` guards every divisor and clamps inputs. Anti-stub grep clean. Seeds 5 spools, 2 printers, 7 prints.
