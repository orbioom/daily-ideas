# Bench

**A pocket electronics lab: the calculators you reach for, a saved-calc notebook, and a parts inventory — all offline.** Ohm's law, resistor colour codes, LED droppers, voltage dividers, 555 timers, RC filters and battery life, with proper engineering notation.

For makers, students and tinkerers who want fast, trustworthy calculators plus somewhere to keep the results and track the drawer.

## Features

- **Calculators** (7) — each with engineering-notation output and a "save to notebook" action:
  - **Ohm's Law** — enter any two of V/I/R/P, solve the rest.
  - **Resistor Colour Code** — 4/5-band decode with live band preview, value, tolerance and range.
  - **LED Series Resistor** — exact value, nearest E12, resistor power.
  - **Voltage Divider** — find Vout from R1/R2, or solve R2 for a target Vout (nearest E12).
  - **555 Astable** — frequency, period, duty cycle, time high/low.
  - **RC Filter** — cutoff frequency, time constant, 5τ settle.
  - **Battery Life** — runtime from capacity, load and efficiency.
- **Notebook** — every saved calculation with tool, title, one-line summary and full detail; tap for the working, delete when done.
- **Parts** — inventory grouped by kind (resistor, capacitor, IC, transistor, diode, LED, …) with value, package and quantity; low-stock flags, totals, search, full add/edit/delete.
- **Reference** — resistor colour chart, E12 values, SI prefixes and the formulas behind the calculators.
- **Settings** — preferred E-series, default LED current, confirm-before-delete, haptics, appearance, erase-all.

Onboarding gate, empty/loading/success states, light & dark, Dynamic Type, VoiceOver, Reduce Motion, designed app icon.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Bench.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**.

**Free signing:** pick your personal team under Signing & Capabilities; bundle id `com.orbioom.bench`. No paid account needed.

## Tech notes

iOS 17+, SwiftUI 5, a single pure `EE` engine (engineering formatting, E-series snapping, and every formula) with reusable calculator building blocks (`NumberField`, `ScaledField`, `ResultRow`, `SaveCalcButton`). Persistence in **SwiftData** (`SavedCalc`, `Component`); prefs in `@AppStorage`. Orbioom design language. No third-party dependencies; a starter parts bin and a couple of saved calculations are seeded on first launch.

## Self-review

Anti-stub grep clean (only the in-memory `ModelContainer` fallback uses `try!`). By-hand compile pass: division/`isFinite` guards across `EE`, `Picker` tags over `Double` scales via `indices` (no tuple key-path ids), navigation to per-tool calculators, and engineering-notation edge cases verified against the iOS 17 SDK. Correctness is by inspection (no Xcode in the sandbox).
