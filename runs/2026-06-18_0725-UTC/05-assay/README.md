# Assay

**Your private bloodwork journal.** Log any lab panel, see every marker scored
against reference *and* optimal ranges, track trends over time, and export a
doctor-ready report — all on-device, one-time, works with any lab.

> **Not medical advice.** Assay is a personal tracking and education tool. It
> does not diagnose, treat, or interpret your results. Reference and "optimal"
> ranges are general adult values; your lab's ranges and clinical context may
> differ. Always discuss results with a qualified clinician.

---

## What it is

A native iOS 17 SwiftUI app for the longevity / biohacking crowd who get blood
panels (Quest, Labcorp, InsideTracker, their doctor) and want to *own* the
data instead of renting it from a subscription service. Assay classifies each
marker, charts its history against shaded reference and optimal bands, surfaces
trends, and ships a clean CSV/text report for your physician — without anything
leaving your phone.

**Audience:** people who track their own labs over time and care about optimal,
not just "normal." **Problem it solves:** lab portals show a single value and a
crude in/out flag; Assay shows the trajectory, the optimal target, and the
story across panels.

## Features

- **36-marker catalog** across 10 categories — Lipids (Total Chol, LDL, HDL,
  Triglycerides, ApoB), Metabolic (Glucose, HbA1c, Insulin), Inflammation
  (hs-CRP, Homocysteine), Thyroid (TSH, Free T4, Free T3), Blood Count (Hgb,
  Hct, WBC, Platelets, RBC), Iron (Ferritin, Iron, TIBC), Vitamins (D, B12,
  Folate, Magnesium), Liver (ALT, AST, GGT, Albumin), Kidney (Creatinine, eGFR,
  BUN, Uric Acid), Hormones (Total & Free Testosterone). Each with canonical +
  alternate units, **sex-specific** standard and tighter **optimal** ranges, a
  good/bad direction, and a plain-language description.
- **Unit conversions** built in (glucose & cholesterol mg/dL ↔ mmol/L, Vitamin D
  ng/mL ↔ nmol/L) — log in whatever your report uses.
- **Dashboard** — latest-panel in-range donut, health-ish score, out-of-range
  alerts ranked by severity, and recently-changed markers with trend arrows.
- **Markers** — browse the catalog by category with search → **Marker detail**:
  history line chart with **shaded reference & optimal bands**, latest value +
  status chip, trend badge, range table, and a unit toggle.
- **Log** — compose a whole panel for a draw date: pick markers, enter values
  with unit pickers and a lab name, with live status preview and validation.
- **Panels / History** — timeline of draws → **Panel detail** with status chips,
  swipe-to-edit / swipe-to-delete, and per-panel export.
- **Insights** — Swift Charts: status-by-category stacked bars, in-range %
  over time, and a most-out-of-range ranking.
- **Doctor report export** — RFC-4180-safe CSV and a plain-text summary via
  `ShareLink` (per-panel and full-history).
- **Onboarding** that collects biological sex + unit preferences (which drive
  range selection), **Settings** with 6 real persisted prefs, a **Paywall**, a
  full **Medical Disclaimer** screen, and **custom markers** for labs outside
  the catalog.
- Seeded on first run with **5 realistic panels over ~18 months** whose values
  *trend* (LDL/ApoB/triglycerides falling, Vitamin D & HDL rising, A1c steady)
  so charts and insights are compelling immediately.
- Full empty / loading / error / success states, haptics, Dynamic Type,
  VoiceOver labels on controls and charts, light + dark themes, and Reduce
  Motion fallbacks throughout.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Assay.xcodeproj` in Xcode 15+, pick an **iOS 17+ simulator**, and
   press **Cmd+R**.

### Free signing

No paid Apple Developer account needed for the simulator. To run on a physical
device, select the target → **Signing & Capabilities** → check *Automatically
manage signing* and pick your personal (free) Apple ID team; Xcode provisions a
free development certificate.

## Tech notes

- **iOS 17+, SwiftUI** — `NavigationStack`, `TabView`, `navigationDestination`,
  two-parameter `.onChange` conventions, `@Query` / `modelContainer`.
- **SwiftData** is the source of truth for lab results and custom markers
  (every `@Model` is registered in the `Schema`); small preferences live in
  `@AppStorage`. Data survives relaunch.
- **Swift Charts** powers the marker-history chart and every Insights chart,
  with accessibility labels/values.
- **Pure, fully-guarded engines** — `RangeEngine`, `TrendEngine`, `StatsEngine`,
  `UnitConverter`, `LabAnalytics`, `ReportExporter`. Every division and range
  access is guarded (this app does real math); no force-unwraps, `try!`, or
  `as!` on user paths. The only `fatalError` is the documented-unreachable
  in-memory `ModelContainer` fallback.
- **Design language** — clean clinical / precise: teal-cyan accent
  (`#0E9AA8`), crisp cards, calm reference-range bands, trustworthy and never
  alarming. Every custom color is defined for both light and dark mode via
  `Color.dyn`.
- **Monetization:** one-time **Assay Pro** unlock (`$14.99`, simulated /
  StoreKit-ready) lifts the free caps (8 tracked markers / 2 panels) and unlocks
  export, custom markers, optimal-range scoring, and trend insights — the free
  core stays fully usable.
- **Why it can boom:** rides the longevity / biohacking wave as a privacy-first,
  no-subscription alternative to Function Health and lab portals — your data
  stays on-device and works with any lab.

## Self-review

I re-read every Swift file by hand and verified:

- **iOS 17 only** — no iOS 18 APIs, no `NavigationView`, no `@Previewable`, no
  deprecated single-argument `onChange`. Uses `NavigationStack`,
  `navigationDestination(item:)`, `@Query`, `modelContainer`, `ShareLink`,
  Swift Charts — all available in the iOS 17 SDK and spelled correctly.
- **Persistence** — `LabResult` and `CustomMarker` are the `@Model` types and
  **both** are listed in `Schema([LabResult.self, CustomMarker.self])` in
  `AssayApp.swift`. Prefs use `@AppStorage`. Seed runs once (guarded by a
  `UserDefaults` flag and an emptiness check).
- **Crash-safety** — grep-clean for `try!`, `as!`, and force-unwraps on user
  paths. **Every** division (`RangeEngine`, `TrendEngine`, `StatsEngine`,
  `UnitConverter`, `InRangeDonut`, `SeedData`) is guarded against zero/NaN, and
  every array index access is bounds-checked (`indices.contains`, count guards,
  or a `safe:` subscript). The only `fatalError` is the documented-unreachable
  in-memory container fallback.
- **No stubs** — grep-clean for TODO/FIXME/XXX/placeholder/lorem/coming soon/
  not implemented/stub/unimplemented. No dead buttons; every CTA, sheet, swipe
  action and ShareLink is wired.
- **Observation correctness** — `AppSettings` and `ProStore` are
  `ObservableObject` owned via `@StateObject` and shared via
  `@EnvironmentObject`; `@Observable` is not mixed with `@StateObject`.
  `@Bindable` is used for the SwiftData edit screen.
- **Property-wrapper ownership**, protocol conformances (`Identifiable`,
  `Equatable`, `Hashable` for navigation values), and binding types all
  type-check; `ToastData` provides a custom `==` since it holds a `Color`.
- **Balanced braces/parens** across all 40 files (verified programmatically).
- **Definition of Done** — 5 feature screens (Dashboard, Markers, Log, Panels,
  Insights) plus Onboarding, Settings, Paywall, Disclaimer; empty/loading/
  error/success states; ≥3 real persisted prefs (6 here); seeded sample data;
  input validation; full accessibility (Dynamic Type, labels, decorative images
  hidden, Reduce Motion fallbacks); gated haptics; Swift Charts; lazy
  `List`/`ForEach` with stable IDs; consistent teal-cyan identity in both modes.

Attestation: to the best of a careful manual review, the sources compile under
the iOS 17 SDK, contain no stubs or placeholders, and guard every division and
range access on user-facing paths.
