# Sprig

**Grow with confidence.** Sprig is a clean, accurate baby & child growth and development
tracker for iOS. Plot weight, height, and head circumference on real WHO percentile curves,
follow developmental milestones, and track the routine immunization schedule — all on-device.

## What it is

- **Name:** Sprig
- **One-liner:** Accurate WHO-percentile growth charts, milestones, and vaccines — focused and private.
- **Problem & audience:** Parents (especially of children 0–5) obsess over percentiles, but the
  incumbents (Glow Baby, Baby Tracker) bury growth charts under cluttered daily-logging UIs and
  subscriptions. Sprig does one thing well: the clinical picture — growth, milestones, vaccines —
  with correct math and no daily-logging noise. (It deliberately does **not** do feeding/sleep/
  diaper logging.)

> **Medical disclaimer:** Sprig is for informational and educational purposes only. It is not
> medical advice, diagnosis, or treatment, and is not a substitute for your pediatrician's
> judgment. Always seek professional guidance about your child's growth, development, and
> immunizations.

## Features

- **Children hub** — list of children with age, latest percentile snapshot (weight/height/head),
  next milestone, and next due/overdue vaccine. Add/edit/delete children; calm empty state.
- **Growth** — Swift Charts percentile chart with the standard WHO curves (P3/P15/P50/P85/P97),
  the child's measurements overlaid, a measure toggle (weight/height/head), a plain-language
  percentile readout ("50th percentile — right around the median"), and full measurement history
  with edit/delete. Units-aware input and display.
- **Milestones** — CDC-style developmental checklist grouped by age band and category
  (social, language, cognitive, motor), with on-track / keep-an-eye status, achieve dates,
  category filter, and progress.
- **Vaccines** — routine immunization schedule with given / due / overdue / upcoming status
  computed from the child's age, grouped by age band, with a status summary and one-tap mark-given.
- **Export (Pro)** — a printable pediatrician PDF growth report (`ImageRenderer` → PDF) and a
  CSV export of all measurements, both unit-aware.
- **Onboarding** — three-page intro ending in "add your first child", gated by `hasOnboarded`.
- **Settings** — units (kg/lb + cm/in, **converted app-wide**), default chart, percentile
  standard label (WHO/CDC), haptics toggle, sample data, and reset.

## The math (substantive core)

Percentiles use the **WHO LMS method**. For a measurement X at an age with interpolated
parameters L (power), M (median), S (coefficient of variation):

```
z = ((X / M)^L − 1) / (L · S)     for L ≠ 0
z = ln(X / M) / S                 for L ≈ 0
percentile = Φ(z)                 (standard normal CDF, Abramowitz–Stegun 7.1.26 erf)
```

The reference curves are the same model inverted at fixed z-scores:
`X = M · (1 + L·S·z)^(1/L)` (with the L≈0 log fallback). Real, condensed WHO Child Growth
Standards LMS tables for both sexes are embedded for weight-, length/height-, and
head-circumference-for-age at months 0–24 plus points to 60 months; L, M, S are linearly
interpolated between table ages. Every division and power is guarded (L≈0 fallback, M>0, S>0,
finite/positive inputs) so the engine never produces NaN on a user path. Age is computed with
`Calendar`/`DateComponents` (leap-safe).

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Sprig.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

## Free signing

Works with a personal Apple ID — no paid Apple Developer account required. Code-signing is only
needed to install on a physical device; the simulator needs none.

## Tech notes

- **iOS 17+**, SwiftUI 5, MVVM. Persistence in **SwiftData** (`@Model` / `@Query` /
  `modelContainer`); `@AppStorage`/`UserDefaults` only for small prefs and flags.
- **Swift Charts** for the percentile chart; `ImageRenderer` + Core Graphics for the PDF.
- Design language in `Theme.swift`: a warm nursery-meets-clinical green identity (accent
  #3F9D6B), cream/forest surfaces, first-class light and dark mode, Dynamic Type, VoiceOver
  labels and chart value summaries, Reduce-Motion-aware animation, and sparse haptics gated by a
  Settings toggle.
- **Monetization:** Free tier = one child with full growth charts, milestones, and vaccines.
  Sprig **Pro** is a one-time ~$4.99 unlock (simulated locally via `@AppStorage("isPro")`, with a
  tasteful paywall + restore) adding multiple children, the pediatrician PDF report, CSV export,
  and all five chart overlays.
- **Why it can boom:** Parents are percentile-obsessed and underserved — every competitor buries
  the growth chart under daily logging and a subscription. Sprig is the focused, accurate,
  on-device, pay-once alternative, with a shareable pediatrician report that turns the app into a
  recommended-at-the-checkup loop.

## Self-review

- **Compiles by inspection:** every file re-read; imports (`SwiftUI`, `SwiftData`, `Charts`,
  `UIKit`, `Foundation`) and APIs are iOS-17-valid; SwiftData `@Model`/relationships/`@Query`
  wiring and Swift Charts marks type-check; no APIs newer than iOS 17.
- **Anti-stub grep clean:** no TODO/FIXME/XXX/placeholder/lorem/coming soon/not implemented/stub.
- **Crash-proofing:** no force-unwrap/`try!`/`fatalError` on user paths (one launch-only,
  triple-guarded `try!` in the model-container fallback). All percentile divisions and powers are
  guarded; inputs clamped finite-and-positive.
- **Definition of Done met:** onboarding gated by `hasOnboarded`; 4 substantive feature screens
  (Children, Growth, Milestones, Vaccines) plus Onboarding and Settings; empty/loading/error/
  success states; Settings has 5 working prefs incl. app-wide unit conversion; SwiftData
  persistence; accessibility incl. Dynamic Type and chart value labels; Reduce Motion honored;
  sparse haptics gated by toggle; first-class light + dark via `Theme.swift`; lazy containers;
  seeded sample children with ~12 measurements each plus milestones/vaccines.
