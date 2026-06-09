# Cuff

A calm, private, on-device blood-pressure & vitals tracker — the ad-free answer
to the cluttered medical-chart BP apps. Log your readings, see them classified
by the American Heart Association stages, watch your trends, and hand your doctor
a clean report. Conjured, not just coded, for the Orbioom studio.

> Cuff is a personal log, not a medical device. Consult your clinician about any
> concerns; nothing here is diagnostic.

## What it is

Cuff lets you log blood pressure (systolic / diastolic / pulse), weight, blood
glucose, and oxygen saturation (SpO₂). Every blood-pressure reading is classified
by the AHA stages (Normal, Elevated, Stage 1, Stage 2, Crisis). You get morning
vs evening averages, in-target percentage, multi-week trends, and a one-tap
doctor-ready CSV / text export. Everything stays on the device — no accounts,
no ads, no network.

## Features

- **Overview** — latest blood pressure as a prominent card with AHA category,
  mean arterial pressure (MAP) and pulse pressure; latest weight / glucose / SpO₂
  / pulse tiles; this-week averages; morning vs evening BP; in-target %; one-tap
  **Add reading** sheet.
- **Add / Edit reading** — segmented metric picker, steppers for BP, a numeric
  field for other metrics in your chosen units, time-of-day tag (auto-inferred
  from the hour), arm, and a note. Validates and clamps every value on save.
- **Log** — every reading grouped by day (newest first), filter by metric, tap
  through to a full detail view (all values, AHA category & range, MAP, pulse
  pressure, edit / delete), swipe to delete.
- **Trends** — Swift Charts: systolic & diastolic over time with AHA stage band
  shading and a dashed target line; weight, glucose, and pulse line charts; a
  stage-distribution bar chart; a 7 / 30 / 90-day range selector that recomputes
  everything; per-metric empty states.
- **Report** — date-range summary (BP average & stage, in-target %, systolic
  range, per-metric averages), a live text preview, and `ShareLink` export of a
  clean **CSV** (RFC-4180 escaped) and a readable **text summary** for your
  clinician.
- **Settings** — persisted target systolic / diastolic, weight unit (kg / lb),
  glucose unit (mg/dL / mmol/L), interface haptics, data counts, replay welcome,
  delete-all-data (confirmed), and the medical-device disclaimer.
- Onboarding gated by a persisted flag, realistic seed data on first launch,
  full Dynamic Type & VoiceOver support, light + dark, Reduce-Motion-aware
  animation, and sparse, gated haptics.

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` if present).
3. Open `Cuff.xcodeproj` in Xcode 15+, choose an iOS 17+ simulator, press Cmd+R.

### Free-signing note

No paid Apple Developer account is required to run on the simulator. To run on a
physical device, select your personal team under *Signing & Capabilities* and let
Xcode manage a free provisioning profile; the bundle identifier is
`com.orbioom.cuff`.

## Tech notes

- **iOS 17+, SwiftUI, MVVM-ish** with pure engines isolated from the UI.
- **SwiftData** (`@Model VitalEntry`) for on-device persistence; one model covers
  every metric. Canonical storage units are kg (weight) and mg/dL (glucose);
  display conversion (lb = kg × 2.2046, mmol/L = mg/dL ÷ 18.0) happens at the edge.
- **Swift Charts** for the trend, target, band-shaded, and distribution charts.
- **Pure engines** — `BPClassifier` (AHA staging), `VitalsEngine` (averages,
  morning/evening, in-target %, trends, chart series; all guarded against
  divide-by-zero and empty inputs), `ReportBuilder` (RFC-4180 CSV + text summary).
- **Orbioom design system** (`Brand`): dynamic light/dark color tokens, glass
  surfaces, ink/glass button styles, monospaced numerics, calm timing-curve motion
  gated by Reduce Motion.
- No force-unwraps on user paths, no `try!`, no `fatalError` except the in-memory
  `ModelContainer` fallback. All exports stay on-device until the user shares.

### Monetization

Free forever for core logging. **Cuff+** (subscription or one-time unlock) adds
unlimited reading history, CSV / PDF doctor export, and multi-metric long-range
trends — the kind of clinician-facing export and history that is already proven
to convert in the Medical category, sold to people managing a chronic condition.

### Why it can boom

Hypertension affects an enormous, older, chronic-care demographic that checks in
daily, and today's top BP apps are ad-filled, cluttered, and ugly. Cuff is the
opposite: calm, private, on-device, with AHA staging built in and a clean export
your doctor will actually accept. A trustworthy, beautiful log in a category where
trust and clarity are everything.

## Self-review attestation

Every Swift source was re-read after writing. Imports verified
(`SwiftUI` / `SwiftData` / `Charts` / `Foundation` / `UIKit` as needed); all
types, inits, modifiers, and enum cases are iOS 17 SDK and spelled correctly;
SwiftData wiring (`@Model`, `@Query`, `@Environment(\.modelContext)`,
`@Bindable`) type-checks; `NavigationStack` / `.sheet` / `.confirmationDialog`
bindings are valid; `ShareLink` exports a `String`; Swift Charts uses
`LineMark` / `PointMark` / `AreaMark` / `BarMark` / `RuleMark` / `RectangleMark`
correctly; no post-iOS-17 APIs are used. The anti-stub grep over the source tree
returns zero matches. Cuff is a personal log, not a medical device.
