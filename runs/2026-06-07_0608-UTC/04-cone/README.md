# Cone — Pottery studio: glazes, firings & pieces

**A ceramicist's studio companion.** Store glaze recipes that scale to any batch, log kiln firings with ramp schedules and cost estimates, and track every piece from greenware to finished.

Design language: **Orbioom** (Liquid Glass, ink-gradient buttons, SF Pro + JetBrains Mono for figures, green as a rare accent).

## The problem
Potters juggle glaze recipes (in percentages), firing schedules, and a queue of pieces — usually across notebooks and spreadsheets. Cone puts all three in one calm, offline tool with the batch math and cone reference built in.

## Features
- **Glazes** — recipes by percentage with base materials and colorant additions; searchable list with cone/surface/atmosphere badges.
- **Glaze detail (batch calculator)** — pick a batch size (presets or stepper) and Cone scales every material to grams, scaling the base to your batch so additions stay proportional; flags non-100% bases.
- **Glaze editor** — full CRUD with a materials editor (name, %, base/addition toggle), cone range, surface, atmosphere, colour note, notes.
- **Firings** — kiln log with type, target cone, atmosphere, result; each shows total time, peak temp, and an estimated energy cost.
- **Firing detail / editor** — a ramp-segment schedule (rate °/hr with AFAP support, target temp, hold minutes), a "set target to cone peak" helper, live total-time estimate, and result notes.
- **Engine** (`Utilities/ConeMath.swift`): an Orton self-supporting cone→temperature table (slow 108°/hr and fast 270°/hr), °F⇄°C, glaze batch scaling, firing time from segments, and energy-cost estimate (kW × hours × duty cycle × price/kWh).
- **Pieces** — workflow tracker with stage filter chips; tap to edit and **advance** through Greenware → Bisque → Glazed → Fired → Finished; clay body, forming method, glaze, dimensions, notes.
- **Reference** — a clay shrinkage calculator (desired fired size → throw-it-this-wet) and the full cone temperature table in your chosen units.
- **Settings** — haptics, °C/°F units, appearance, confirm-before-delete, kiln power & electricity price, studio counts, guarded erase-all.
- Onboarding gated by a persisted flag; empty states; full Dynamic Type, VoiceOver, Reduce Motion, light & dark, designed vessel app icon. Seeds classic cone-6/10 recipes, firings and pieces.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Cone.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** personal team under Signing & Capabilities; bundle id `com.orbioom.cone`. No network, accounts, or API keys. Cone temperatures are approximate Orton values for reference — always confirm with witness cones.

## Tech
iOS 17+, SwiftUI 5, SwiftData (`Glaze`/`GlazeMaterial`/`Firing`/`FiringSegment`/`Piece`), pure value-type engine, `UserDefaults` for prefs and batch size. No third-party dependencies.

## Self-review
Re-read every Swift file by hand: imports, iOS 17 SDK symbols, SwiftData relationships & `@Query` keypaths, tuple `Comparable` sort in `orderedMaterials`, `Picker` tags, `.onChange` two-parameter form, `project.yml`. Anti-stub grep clean. Division paths guarded (`baseTotal>0`, rate≤0 → 500°/hr, shrinkage factor `f>0`). Only `try!` is the in-memory container fallback. An automated by-hand compile review of this app returned clean. Believed to compile cleanly under Xcode 15+ after `xcodegen generate`.
