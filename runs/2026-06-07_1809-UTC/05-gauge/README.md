# Gauge

A string-tension workshop for guitarists, bassists and luthiers. Build an
instrument — a scale length plus a set of gauges, materials and a tuning — and
Gauge computes the tension on every string (in lb and kg), the total pull on the
neck, and how balanced the set is. Use it to choose gauges for an alternate
tuning, a baritone or extended scale, or to design a perfectly balanced custom
set. Everything runs on-device.

Built for the Orbioom studio. Native iOS 17, SwiftUI, SwiftData, Swift Charts.

## What it does

- **Instruments** — a library of your guitars and basses with their total neck
  tension. Each instrument opens to a full per-string table: position, note,
  gauge, material and tension, each with a comfort-colour dot and a relative
  meter bar. Totals and balance appear as stat tiles, with a Swift Charts bar
  chart of tension per string. Drag the scale-length slider to recompute live.
  Edit any string inline (note, gauge stepper, material), and apply a factory
  string set or tuning preset from the Library.
- **Calculator** — a standalone single-string calculator. Forward mode turns a
  scale length, gauge, material and note into a tension (lb & kg). Reverse mode
  solves the other way: give it a target tension and it suggests a gauge.
- **Library** — browse eight factory string sets and eight tuning presets, each
  with the tension it would produce at your reference scale length, plus a
  glossary explaining scale length, unit weight and why tension matters.
- **Settings** — haptics, appearance (system / light / dark), tension units
  (lb / kg), the library reference scale length, catalog counts, restore sample
  data, an about section, and an erase-all action behind a confirmation.

## The engine

`TensionEngine` is pure and well-commented. The core relationship for a
vibrating string is:

```
T = UW * (2 * L * f)^2 / 386.4
```

- **T** — tension in pounds-force.
- **UW** — unit weight (mass per inch) in lb/in.
- **L** — scale length in inches.
- **f** — frequency in Hz, from the note name via equal temperament (A4 = 440).
- **386.4** — the gravitational constant in inch units.

Frequency parsing accepts scientific pitch (`E2`, `A#2`, `Bb1`); unparseable
notes return `nil` and the UI shows a calm invalid-note state. Unit weight uses a
closed form for plain steel (`UW = 0.2230 · d²`) and an embedded D'Addario-style
table (`UnitWeightTable`) for wound and nylon strings, with linear interpolation
between entries and a gauge²-scaled fallback beyond the table's range. Divisions
are guarded: scale length and frequency must both be positive, otherwise the
result is `nil`.

The engine also classifies each string into a comfort band (loose / balanced /
tight, with bass-specific thresholds) for colour, summarises an instrument
(total, average, balance spread, valid count) and provides a reverse solver that
inverts the closed form for plain steel and searches the table for wound strings.

### Sanity checks

- `.010` plain steel at E4 on a 25.5" scale ≈ **16.3 lb**.
- A regular `.010–.046` nickel-wound electric set in standard E on 25.5" totals
  ≈ **106 lb**; on a 24.75" Les-Paul scale ≈ **100 lb**.
- A `.045–.105` four-string bass set in standard tuning on 34" sits at roughly
  **37–52 lb** per string.

## Architecture

- `GaugeApp.swift` — `@main`, SwiftData `ModelContainer` over `Instrument` and
  `StringSlot` (in-memory fallback if the persistent store can't open).
- `Models/` — `Instrument` and `StringSlot` `@Model` classes; enums stored as
  String raw values with computed accessors; cascade delete from instrument to
  strings.
- `Utilities/` — `TensionEngine`, `UnitWeightTable`, `StringSets` (factory sets,
  tuning presets and the apply logic), `SampleData`, `Haptics`.
- `Views/` — `RootView` (onboarding gate + TabView + appearance/haptics),
  `Onboarding/`, `Instruments/`, `Calculator/`, `Library/`, `Settings/`.

Preferences are `@AppStorage` (`gauge.hasOnboarded`, `gauge.haptics`,
`gauge.appearance`, `gauge.unit`, `gauge.refScale`); instrument data is
SwiftData. Both survive relaunch.

## Accessibility & feel

Full VoiceOver labels on rows, tiles and the chart; Reduce Motion respected
(onboarding page dots and press scaling); first-class light and dark; sparse,
meaningful haptics; all animation through `Brand.ease()`.
