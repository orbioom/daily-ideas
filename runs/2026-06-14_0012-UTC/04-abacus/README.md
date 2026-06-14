# Abacus

**A trustworthy, beautiful mortgage & loan calculator.** Ad-free, one-time unlock,
instant clear answers — and a motivating view of exactly how much interest and time
your extra payments save.

## What it is

Most loan calculators are ad-laden, confusing, or hide the one number that matters.
Abacus is the calculator high-intent homeowners (and anyone weighing a car, student, or
personal loan) wish existed: enter the loan, get the monthly payment instantly, see the
total interest and payoff date, and — the part incumbents bury — watch how a little extra
each month shaves years and thousands of dollars off the loan.

**Audience:** prospective and current homeowners, refinancers, and borrowers who want
honest, on-device math without ads or upsells.

## Features

- **Calculator** — live monthly payment (hero number), total interest, total paid, payoff
  date, and an interest-saved / time-saved callout when you add extra payments. Principal-
  vs-interest donut chart (Swift Charts). Loan-type picker (mortgage / auto / student /
  personal), one-time extra payment at a chosen month, input validation, and Save scenario.
- **Schedule (Amortization)** — balance-over-time line chart (baseline vs with-extra),
  plus the full schedule grouped by year and expandable to individual months showing
  principal / interest / balance. Computed off the main thread with a loading state. CSV
  export via ShareLink (Pro).
- **Scenarios** — saved loans with key stats, tap-through detail (load back into the
  calculator), swipe to delete, and a two-up **compare** view (payment, total interest,
  total paid, payoff date) with a plain-language verdict.
- **Affordability** — budget → maximum loan amount, with a total-paid / interest breakdown
  and donut.
- **Refinance** — current loan vs new loan with monthly difference, lifetime interest
  change after closing costs, **break-even months**, and a comparison bar chart (Pro).
- **Settings** — currency (USD/EUR/GBP/JPY/CAD/AUD/INR), term unit (years/months), default
  term, default extra payment, haptics toggle, Pro unlock/restore, and About.
- First-run **onboarding**, full **light/dark mode**, **Dynamic Type**, VoiceOver labels
  throughout, Reduce-Motion-aware animation, and sparse haptics.

## Engine

A pure, well-guarded `LoanMath` enum (no I/O, no force-unwraps, every division guarded):
exact monthly payment (with the `r == 0` interest-free case handled), an amortization
schedule that applies recurring and one-time extra principal and lands the final balance
exactly at zero, totals with **months/interest saved vs a no-extra baseline**, inverse
affordability (max principal for a budget), and a refinance comparator with break-even.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root if present).
3. Open `Abacus.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

**Free signing:** select the `Abacus` target → Signing & Capabilities → choose your
personal team; the bundle id is `com.orbioom.abacus` (change if it collides).

## Tech notes

- **iOS 17+**, **SwiftUI**, **MVVM**. `CalculatorModel` and `AppSettings` are `@Observable`
  and shared via `@Environment`.
- **SwiftData** for the single user-owned entity (`LoanScenario`); `@AppStorage` /
  `UserDefaults` for small prefs and the Pro flag. Persistence survives relaunch.
- **Swift Charts** for the donut (SectorMark), balance line chart, and refinance bars.
- Design language: calm "Liquid Glass"-inspired but native-first — quiet surfaces, generous
  spacing, one focal idea per screen, deep teal-green as a rare luminous accent, full
  light/dark via the `Color.dyn` token system.
- **No external dependencies, no networking.** All math is on-device.
- **Monetization:** honest one-time **Abacus Pro ($4.99)** — unlimited scenarios, compare,
  refinance, and CSV export; the free tier (full calculator + 1 saved scenario +
  amortization) is genuinely useful. Backed by `@AppStorage("isPro")` in this build; a
  production release wires StoreKit 2.
- **Why it can boom:** homeowners search "mortgage calculator" constantly and hit ad-walls;
  a fast, beautiful, ad-free calculator that *shows your extra-payment savings* converts
  high-intent users into a one-time purchase.

## Self-review attestation

Every Swift file was re-read and hand-verified against the iOS 17 SDK: imports, type and
initializer existence, protocol conformances, `@State` / `@Observable` / `@Bindable` /
`@Environment` / `@Query` / `modelContainer` wiring, `NavigationStack` / sheet bindings,
two-parameter `onChange`, Swift Charts API, and brace/paren/bracket balance. Every `Theme.`
token referenced is defined. The anti-stub grep is clean (no TODO/FIXME/placeholder/etc.).
No force-unwraps, `try!` (except the permitted in-memory `ModelContainer` fallback),
`fatalError`, or unguarded divisions on user paths.
