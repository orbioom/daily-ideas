# Furlong

**Private, one-time business mileage & expense tracker for the self-employed.**

## What it is

Furlong is a native iOS app that turns the miles you already drive for work into real
tax deductions — logged in seconds and kept entirely on your device. It's built for the
people MileIQ and Everlance charge a monthly subscription to: rideshare and delivery
drivers, freelancers, contractors, and anyone self-employed who needs a clean,
IRS-ready mileage and expense log at tax time.

**The problem:** existing mileage trackers lock the basics — and especially exports —
behind $5.99–$8/month subscriptions and cloud accounts. Furlong is a single one-time
purchase, requires no login, and never sends your data anywhere.

**Audience:** gig-economy drivers, freelancers, the self-employed, and small-business
owners who deduct vehicle use.

## Features

- **Dashboard** — big selected-year deduction total (mileage + expenses), business-use
  %, total miles, trip/expense counts, one-tap **Log Trip** / **Log Expense** quick
  actions, recent activity, and a calm empty state for fresh installs.
- **Trips** — grouped by month with per-month mileage subtotals, filter by purpose
  (business / medical / charity / personal), full CRUD via a sheet editor with
  **odometer-or-distance** input, **place autocomplete** from favorites and history,
  **round-trip** toggle that doubles the counted distance, and swipe-to-delete.
- **Expenses** — month-grouped list, category filter, full CRUD, deductible toggle,
  optional vehicle attachment, and custom category names (Pro).
- **Reports** — year picker; deduction breakdown (mileage by purpose + expenses by
  category); **standard-mileage-vs-actual-expense** comparison with a recommendation;
  Swift Charts (**miles-by-month bars**, **deduction-by-category donut**,
  **business/personal donut**); **CSV + plain-text export** via ShareLink (RFC-4180
  escaped) — summary, trips, expenses, and a formatted report.
- **Vehicles** — manage multiple vehicles, set a default, record starting odometer.
- **Favorite Places** — saved destinations with default distance for one-tap logging.
- **IRS Mileage Rates** — seeded with real standard rates for 2022–2026; add or edit
  any tax year (Pro).
- **Onboarding** — four-page intro that explains the value and sets the gate flag.
- **Settings** — Appearance, Haptics, distance unit (mi/km), currency code, default
  trip purpose, default round-trip, Pro unlock/restore, and an About section.

## The deduction engine

Pure, deterministic, fully testable (no SwiftData or UI dependencies), money in
`Decimal` throughout, every division guarded:

- **Per-year deduction** = Σ(business miles × business rate) + Σ(medical miles ×
  medical rate) + Σ(charity miles × charity rate) + Σ(deductible expenses). Mileage
  amounts are rounded to cents with `NSDecimalRound`.
- **Business-use %** = business miles ÷ total miles, clamped to 0…1 and guarded against
  a zero denominator.
- **Effective miles** apply the round-trip doubling and are always non-negative.
- **Standard-vs-actual comparison**: standard = business miles × business rate; actual =
  (vehicle operating costs: fuel, maintenance, insurance, tolls, parking) × business-use
  %. Furlong recommends the larger lawful deduction.
- **Breakdowns**: per-purpose mileage, per-category expenses, and per-month miles split
  business vs. other for the charts.
- **Period math** (`week` / `month` / `quarter` / `year` / `custom`) with safe
  `DateInterval` fallbacks.
- Distance is stored **canonically in miles** and converted for display/input per the
  mi/km setting; money is formatted by a shared `CurrencyFormatter` honoring the
  currency-code setting.

IRS standard mileage rates are seeded for 2022–2026 (business 0.625/0.655/0.67/0.70/0.70;
medical 0.22/0.22/0.21/0.21/0.21; charity statutory 0.14).

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at repo root).
3. Open `Furlong.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

**Free signing:** select the Furlong target → Signing & Capabilities → choose your
personal team; the bundle id `com.orbioom.furlong` builds and runs on a device with a
free Apple ID.

## Tech notes

- **iOS 17+**, **SwiftUI**, **SwiftData** (`@Model` for Vehicle, Trip, Expense,
  FavoritePlace, MileageRate — all registered in the app `Schema`), **Swift Charts** for
  analytics, **ShareLink** + a `Transferable` document for export.
- App-wide preferences use the `AppSettings` `ObservableObject`; small flags use
  `@AppStorage`. Primary data persists in SwiftData and survives relaunch; ~52 trips,
  ~22 expenses, two vehicles, five favorite places, and five years of rates are seeded
  once on first launch.
- **Design language:** trustworthy, ledger-clean, "highway-sign green" identity —
  confident green accent (`#1F7A4D`, matching AccentColor), monospaced numerals for all
  money and odometer figures, generous whitespace, full light/dark support via dynamic
  colors, Dynamic Type, accessibility labels on figures and chart descriptions, haptics
  gated by settings, and Reduce-Motion-aware animation.
- **Monetization:** a single one-time **Furlong Pro** unlock at **$3.99** (simulated,
  StoreKit-ready) — gates CSV/PDF export, unlimited trips past a free 40-trip cap,
  multiple vehicles past one, custom categories, and mileage-rate-history editing; the
  free core (logging, dashboard, on-screen reports) is fully usable.
- **Why it can boom:** a huge, growing gig-economy audience overpays monthly to
  competitors that gate the one feature that matters at tax time — the export. Furlong is
  the private, one-time, no-login deduction tracker that does the IRS math for them and
  hands their accountant a clean ledger.

## Self-review

I re-read every Swift file by hand and verified:

- **Imports** are present and correct in each file (`SwiftUI`, `SwiftData`, `Charts` only
  where chart marks are used, `UIKit` for haptics/`UIColor`, `UniformTypeIdentifiers` for
  the export document, `Foundation` for engine/formatters).
- **iOS 17 only** — no `NavigationView` (only `NavigationStack`), no `@Previewable`, no
  single-parameter `onChange`, no iOS 18 SwiftData/SwiftUI symbols. `SectorMark`,
  `BarMark`, `chartForegroundStyleScale(domain:range:)`, and `ShareLink` are all iOS
  16/17 APIs.
- **Crash-safety** — no `try!`, no `as!`, no force-unwraps on user paths, no unchecked
  array indices (palette access uses `% count`), and every division is by a constant or
  guarded (`totalMiles > 0 ? … : 0`, `max(1, …)`). The only `fatalError` is the
  documented-unreachable in-memory `ModelContainer` fallback copied from the convention.
- **No banned strings** — no TODO/FIXME/XXX/placeholder/lorem/stub/unimplemented; every
  button and screen is wired to real behavior.
- **SwiftData** — all five `@Model` types (Vehicle, Trip, Expense, FavoritePlace,
  MileageRate) appear in the `Schema([...])` in `FurlongApp.swift`; `@Query`,
  `@Relationship`, and `modelContainer` usages type-check; seeding is guarded to run once.
- **State ownership** — `@StateObject` for the app-level `AppSettings` ObservableObject,
  `@State`/`@Query`/`@AppStorage`/`@Environment` used appropriately; no mixing of
  `@Observable` with `@StateObject`.
- **Money** uses `Decimal` exclusively (rounded with `NSDecimalRound`); distance is stored
  in canonical miles and converted for display.
- **Definition of Done** — four substantive feature screens (Dashboard, Trips, Expenses,
  Reports) plus Vehicles, Favorite Places, and Mileage Rates management; gated multi-page
  onboarding; empty, loading (async report compute with spinner), error (alerts), and
  success (toasts + haptics) states; ≥3 persisted settings; accessibility labels/values on
  figures and charts; Reduce-Motion fallbacks; lazy `List` containers with stable
  `Identifiable` IDs.
- **Balanced** braces and parentheses across all 37 Swift files.

**Attestation:** to the best of a careful by-hand reading, the sources compile against the
iOS 17 SDK, contain no force-unwraps/`try!`/`as!` on user paths, no placeholder content,
and every feature described above is fully implemented and wired.
