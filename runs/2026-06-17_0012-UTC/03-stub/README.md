# Stub — Take-home paycheck calculator & offer comparator

**Stub** estimates your real take-home pay after federal income tax, state income tax,
and FICA (Social Security + Medicare), accounting for pre-tax deductions like 401(k),
HSA, and health premiums. Save scenarios and compare job offers side by side.

> Estimates only — not tax advice. State rates are approximate flat effective rates.
> Federal & FICA parameters reflect 2025 figures.

## What it is

A clean, trustworthy fintech-styled iOS 17 SwiftUI app that turns a salary or hourly rate
into a transparent net-pay breakdown. The hero card answers the question everyone actually
asks — *"what lands in my account each paycheck?"* — and the breakdown shows exactly where
every dollar goes.

## Full feature list

- **Calculator** — segmented hourly/salary input, pay-frequency picker
  (weekly / biweekly / semimonthly / monthly), filing status, searchable 50-state + DC
  picker, and a full pre-tax / post-tax deductions section. A **live hero card** shows
  net per paycheck (big), with gross, total tax, and effective rate, updating as you type.
  "Save as scenario" persists the estimate.
- **Breakdown** — gross → pre-tax → taxable → federal / state / Social Security / Medicare → net
  waterfall, a **SectorMark donut** (take-home / federal / state / FICA), taxable-income detail,
  and marginal + effective rates. Per-paycheck vs annual toggle.
- **Compare** — pick 2–3 saved scenarios; a **BarMark** chart of net pay plus a side-by-side
  table of net/paycheck, net/year, gross, effective rate, take-home %, and state, with a
  "highest take-home" winner callout.
- **Scenarios** — saved scenarios list with full CRUD: tap to load into the Calculator,
  swipe to delete, duplicate, and rename. Empty state included.
- **Settings** — persisted defaults (filing status, work state, pay frequency) and display
  preferences (annual-vs-per-check default, round to whole dollars, haptics), plus
  "How estimates work", About, and Restore/Unlock Pro.
- First-run **onboarding** gated by a persisted flag.
- Empty / loading / validation / success states throughout; numeric input validated
  (negatives and non-numbers rejected, all division guarded).
- Full accessibility: labeled hero & charts, Dynamic Type semantic fonts, Reduce Motion
  fallbacks, light + dark mode via a cohesive Theme.

## The tax engine

A pure, deterministic Swift engine (`PaycheckEngine`) computes everything in `Decimal`:

- **Federal income tax (2025):** hard-coded progressive brackets (10/12/22/24/32/35/37%)
  per filing status, applied to wages after pre-tax deductions and the 2025 standard
  deduction (single $15,000 / MFJ $30,000 / MFS $15,000 / HoH $22,500).
- **FICA:** Social Security 6.2% up to the 2025 wage base **$176,100**; Medicare 1.45% on
  all wages plus 0.9% Additional Medicare over the filing-status threshold
  ($200k single/HoH, $250k MFJ, $125k MFS).
- **State income tax:** a curated table for all 50 states + DC using a single representative
  flat **approximate** effective rate; the nine no-income-tax states (AK, FL, NV, NH, SD, TN,
  TX, WA, WY) are 0%.
- **Pre-tax treatment (documented in code):** 401(k) and "other pre-tax" reduce income tax
  only; HSA and Section-125 health premiums reduce income tax **and** FICA wages.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Stub.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing:** set your Apple ID team in Signing & Capabilities; the bundle id is `com.orbioom.stub`.

## Tech notes

- **SwiftUI 5 / iOS 17**, `NavigationStack`, Swift Charts (`SectorMark`, `BarMark`).
- **SwiftData** `@Model PayScenario` (`@Query`, `modelContext`), enums persisted as rawValue
  strings, two example scenarios seeded idempotently on first run.
- **`@Observable`** view models (`CalculatorModel`, `AppPreferences`) stored with `@State` /
  shared via `.environment`; small flags via `@AppStorage`.
- **Money math in `Decimal`** end to end; `Double` only for charting and persistence.
  All division routed through a zero-safe helper; `Decimal(string:)` is never force-unwrapped.
- **Monetization:** one-time **Stub Pro — $4.99** (`@AppStorage("isPro")`, `PaywallView`,
  demo Unlock + Restore). Free: single calc + 2 saved scenarios + 2-way compare. Pro: unlimited
  scenarios, 3-way compare, all-state detail, CSV export.
- **Why it can boom:** everyone with a job or a job offer wants to know their *real* paycheck,
  and existing calculators are ad-cluttered web pages — a fast, private, native, offer-comparing
  app with a crisp breakdown is exactly the trustworthy tool people screenshot and share.

## Self-review attestation

Re-read every Swift file: all imports present; only iOS 17 APIs used; protocol conformances
satisfied; property-wrapper ownership correct (`@Observable` + `@State`/`@Bindable`, no
`@StateObject` mixing). No `try!`, `fatalError`, `as!`, or force-unwraps on user paths; all
user-facing division guarded against divide-by-zero; `Decimal(string:)` parsed safely. Exactly
one `@main`. Audit script passes clean.
