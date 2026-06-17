# Abode

A native, instant, **private** mortgage & home-affordability calculator for iOS 17 — a
Karl's-Mortgage-Calculator / Zillow-calc beater that runs entirely on your device. No ads,
no accounts, no tracking. The centerpiece is a correct, all-`Decimal` mortgage math engine.

## What it is

Incumbent mortgage calculators are web-only, ad-laden, and clunky. Abode does the same math —
correctly, to the cent — as a clean, confident, offline iOS app. Enter a home price and you see
your full monthly payment (principal, interest, taxes, insurance, PMI, HOA) the instant you type,
plus a complete amortization schedule, an affordability solver, a refinance comparison, and saved
scenarios you can line up side by side.

## Full feature list

- **Calculator (free)** — home price, down payment (% or $), rate, term, property tax, insurance,
  PMI, and HOA → a large monthly-payment hero, a `SectorMark` donut of the PITI breakdown
  (principal+interest / tax / insurance / PMI / HOA), total interest, total of payments, payoff
  date, loan-to-value, and the auto-computed **PMI drop month** (when the balance reaches 78% LTV).
  Live, calm inline validation — non-negative, sane bounds, never a crash.
- **Schedule (free)** — the full amortization table in a year-grouped, expandable `LazyVStack`
  (a 360+ row schedule scrolls smoothly), a Swift Charts **balance-over-time** area chart and a
  **cumulative principal-vs-interest** chart, and an **extra-payment toggle** that recomputes
  months and interest saved. The schedule is built **off the main thread** with a loading state.
- **Affordability (Pro)** — gross monthly income, existing debts, down payment, rate, term, and
  **front-/back-end DTI** targets (≈28% / 36%) plus tax/insurance assumptions → **max home price**,
  **max loan**, and resulting payment, with a DTI gauge and a plain-language explanation.
- **Refinance (Pro)** — current loan (balance, rate, remaining term) vs a new loan (rate, term,
  closing costs) → monthly savings, **break-even months**, a payment bar chart, and the **lifetime
  interest delta**.
- **Scenarios (free to save up to 2; Pro for unlimited + compare)** — save / rename / delete
  scenarios, then select two or more for a **side-by-side comparison** (payment, total interest,
  payoff) with a comparison chart. Empty state included.
- **Settings** — currency, show-cents, default rate, default term, default property tax, and a
  haptics toggle — all persisted and functional.
- **Onboarding** gated by a persisted `hasOnboarded` flag; a **Paywall** for one-time Pro.
- Throughout: empty / loading / success / calm-error states, full Dynamic Type, accessibility
  labels & values on the payment hero, fields, and charts, Reduce-Motion fallbacks, sparse haptics
  gated by the Settings toggle, and first-class light **and** dark mode.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Abode.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing:** set your Apple ID team in Signing & Capabilities; the bundle id is
`com.orbioom.abode`.

## Tech notes

- **iOS 17+, SwiftUI 5**, `NavigationStack`, Swift Charts (`SectorMark`, `AreaMark`, `LineMark`,
  `BarMark`).
- **MVVM** with one consistent ownership pattern: Observation framework `@Observable` models held
  by `@State` (`CalculatorModel`, `AppSettings`, `ProStore`) and shared via `.environment`.
- **SwiftData** for primary data — `MortgageScenario` and `AffordabilityProfile` `@Model` types,
  both registered in the `Schema`, queried with `@Query`, surviving relaunch. Money is stored as
  `Double` and converted to `Decimal` only inside the engine. Schedule rows are computed on demand,
  never persisted. `@AppStorage` / `UserDefaults` only for small prefs and the `isPro` flag.
- **All-`Decimal` engine.** `MortgageEngine` computes monthly P&I via
  `M = P·r(1+r)^n / ((1+r)^n − 1)` with the `r == 0` guard (`M = P/n`), a full amortization
  schedule (per-month interest = balance·r, principal = payment − interest, running balance → 0),
  **PITI** with PMI that **auto-drops at 78% LTV** (the drop month is computed), extra-payment
  payoff (recurring / one-time / biweekly-equivalent), **refinance break-even** (closing costs ÷
  monthly savings, ceil), and **DTI affordability** solved against front- and back-end caps. Every
  division and parse is guarded; `Decimal(string:)` is never force-unwrapped; integer
  exponentiation avoids `Double` drift. Heavy schedule builds run off the main thread and publish
  results on `@MainActor`.
- **Design language:** a trustworthy navy/blue accent (#2D6CB3), generous whitespace, soft cards,
  and **monospaced figures** for all money — calm, confident fintech. A single `AbodeTheme`
  (palette, typography, card / button / chip styles) is applied across every screen, AA-contrast in
  both light and dark.
- **Sanity check:** $300,000 loan at 6.5% over 30 years → **$1,896.20** monthly principal &
  interest.

**Monetization:** one-time **$3.99** Abode Pro (unlocks Affordability, Refinance, unlimited saved
Scenarios + compare, and the extra-payment optimizer). The Calculator and the full amortization
Schedule are always free.

**Why it can boom:** every prospective buyer and refinancer runs these numbers, the web incumbents
are ad-laden and slow, and a fast, private, correct, one-time-purchase native app with no
subscription is exactly what people want to trust with the biggest number of their life.

## Self-review

Re-read every Swift file. Verified: all imports/types/modifiers exist in iOS 17 (SwiftUI 5,
SwiftData, Swift Charts `SectorMark`/`AreaMark`/`LineMark`/`BarMark`); one consistent
`@Observable` + `@State`/`@Bindable` ownership pattern (no `ObservableObject`/`@StateObject`,
no `@Previewable`); `NavigationStack` only; `.onChange(of:)` uses the two-parameter form. The
mortgage math is correct (the $300k/6.5%/30yr ≈ $1,896.20 sanity check passes). No
`try!`/`as!`/`fatalError`, no `NavigationView`, no force-unwrapped `Decimal(string:)`, no
unchecked array index (a `subscript(safe:)` helper is used), and no unguarded division (a single
guarded `divide` helper plus division only by non-zero literals). All money math is in `Decimal`
and formatted through a currency `NumberFormatter`. Onboarding is gated by `hasOnboarded`; empty,
loading, success, and calm-error states are present; full accessibility, Reduce-Motion fallbacks,
gated haptics, and first-class light/dark are in place. Anti-stub grep over all sources is clean
(the only `placeholder` match is a doc comment describing the empty-state view).
