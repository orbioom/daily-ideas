# Deed

## What it is

**Deed** is a private, on-device rental property and landlord tracker for iPhone — a Stessa / Landlord Studio alternative that keeps your numbers off the cloud.

- **One-liner:** Your rental portfolio's cash flow, rent roll, and real investor math — private, on your phone, one-time purchase.
- **Problem:** Incumbent landlord apps are subscription-based, cloud-hosted, and constantly upsell. Small landlords and real-estate investors want their financials (cash flow, cap rate, rent roll) computed correctly and kept private.
- **Audience:** Small landlords and individual real-estate investors with 1–20 doors.

All money math uses `Decimal` end-to-end (never `Double`), so figures don't drift from floating-point error.

## Features

- **Portfolio dashboard** — hero tiles for total value, total equity, monthly cash flow, and overall occupancy; a "rent collected this month" progress meter; per-property cards showing monthly cash flow, occupancy, and a generated gradient identity. Calm empty state with a CTA.
- **Property detail** — financial metric cards (monthly cash flow, equity, NOI; plus cap rate, cash-on-cash, and gross rent multiplier for Pro). Units list with status, current tenant, and add/edit. Transactions list with category icons, swipe-to-delete, and an add-income/expense editor. Edit and delete the property.
- **Rent roll** — current- or last-month rent roll across all active leases: tenant, property/unit, amount due, and paid/partial/unpaid/late status. Tap to mark fully paid, record a partial payment, or reset. Collected vs. outstanding totals, on-time rate, and a one-tap "generate next month" action. Empty state.
- **Reports (Pro)** — Swift Charts: income vs. expense by month (grouped bars), cash-flow trend (line + area), expense breakdown (donut / `SectorMark` by category with legend), and NOI by property (bars). Period filter (3 / 6 / 12 months). RFC-4180 CSV export of transactions and rent roll via `ShareLink`. A blurred teaser previews the screen for free users.
- **Onboarding** — four pages explaining privacy, real investor math, rent tracking, and reports; gated by `hasOnboarded`.
- **Settings** — Appearance (System/Light/Dark), Haptics toggle, Rent-reminders toggle, Default currency picker, and a Closing-cost % assumption stepper (feeds cash-on-cash). Plus Unlock Pro / Restore and an About screen.
- **Finance engine** — pure, `Decimal`-only computations with guarded division: per-property monthly cash flow, annual NOI (excludes mortgage and CapEx), cap rate, cash-on-cash, equity, gross rent multiplier, expense ratio, and occupancy; portfolio rollups (total value/equity/cash flow/rent roll, portfolio cap rate, occupancy, collected-vs-due this month).
- **Rent ledger** — generates expected monthly `RentPayment`s per active lease on its due day, classifies paid/partial/unpaid/late vs. today, and computes outstanding balance and on-time rate.
- **Polish** — full Dynamic Type, accessibility labels/values/hints on controls and charts, light + dark theming via dynamic colors, gated haptics, tasteful animations that honor Reduce Motion, success toasts, validation and error states, and seeded sample data on first run.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Deed.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

## Free signing

No paid Apple Developer account is needed to run on a device: open the project in Xcode, select the **Deed** target → **Signing & Capabilities**, check **Automatically manage signing**, and pick your personal Apple ID team. A free personal team signs and runs the app on your own device for 7 days.

## Tech notes

- **Platform:** iOS 17.0+, SwiftUI, `NavigationStack` + `TabView`.
- **Persistence:** SwiftData (`@Model`, `@Query`, `modelContainer`) for all primary data — Property, Unit, Lease, RentPayment, Txn — with cascade delete relationships; `@AppStorage` for preferences and the simulated Pro flag. Data survives relaunch; realistic sample data (4 properties of different types, multiple units, active leases with tenants, 12 months of rent payments, ~60+ transactions across a year) is seeded once via `SeedData.seedIfNeeded`.
- **Money:** every currency value is `Decimal`; rounding goes through `NSDecimalRound` helpers and all division is zero-guarded.
- **Design language:** rounded SF typography, a deep-green accent (`0x2E8B6B`, matched to the AccentColor asset), gradient property identities, surface cards with hairline borders, and dynamic light/dark colors throughout.
- **Charts:** Swift Charts (`BarMark`, `LineMark`, `AreaMark`, `SectorMark`) with accessible labels and values.
- **Monetization:** one-time **Deed Pro** unlock at $7.99 (simulated, StoreKit-ready) — gates unlimited properties past a free cap of 2, the Reports screen, CSV export, and advanced per-property metrics; the free core (1–2 properties, units, leases, rent roll, transactions, cash flow/NOI/equity) is fully usable.
- **Why it can boom:** landlords are actively fleeing subscription, cloud-based trackers — a private, on-device, one-time-purchase app with correct investor math (cap rate, cash-on-cash, rent roll) hits a real, underserved demand and is cheap to operate (no backend).

## Self-review

I re-read every Swift source file and verified by hand:

- **Imports** are present and minimal per file (`SwiftUI`/`SwiftData`/`Charts`/`Foundation`/`UIKit`/`UniformTypeIdentifiers` only where used).
- **iOS 17 only:** `NavigationStack` everywhere (no `NavigationView`); both `.onChange` uses are the two-parameter `(_, _)` form; no `@Previewable`; no iOS 18 symbols. `SectorMark`, `ShareLink`, `Transferable`, and `@Bindable` are all iOS 17-available.
- **Safety:** no `try!`, `as!`, force-unwraps, unchecked indexing, or unguarded division on user paths (all division is guarded by `> 0` checks or the `FinanceEngine.ratio` helper that returns `nil` on a zero divisor). The only `fatalError` is the documented-unreachable in-memory `ModelContainer` fallback, copied verbatim from the convention.
- **No** `TODO`/`FIXME`/`placeholder`/`stub`/`lorem`/`coming soon`/`not implemented` strings (verified by grep).
- **SwiftData:** all five `@Model` types (Property, Unit, Lease, RentPayment, Txn) are listed in the `Schema([...])` in `DeedApp.swift`; relationships use single-sided `inverse:` cascade declarations; `@Query`/`modelContainer`/`@Bindable` type-check.
- **State ownership:** `AppSettings` and `ProStore` are `ObservableObject` + `@StateObject` (no mixing with `@Observable`); view-local state uses `@State`/`@Bindable`. Rent-roll payment generation was moved out of view `body` into a `reload()` called from `.task`/`.onChange` so the model context is never mutated during view evaluation.
- **Money** is `Decimal` throughout; conversions to `Double` happen only at the Swift Charts / progress-bar boundary via `NSDecimalNumber`.
- **Definition of Done:** 4 substantive feature screens (Portfolio, Property Detail, Rent, Reports) plus Onboarding, Settings, and Paywall; empty/loading/error/success states; ≥3 persisted prefs; seeded data; validation; full accessibility and Reduce Motion; gated haptics; lazy containers with stable `Identifiable` IDs; Swift Charts with accessible labels.
- **Balanced braces/parens** and consistent naming (no duplicate top-level type names) confirmed.

Attestation: to the best of a careful manual read, the sources conform to the binding conventions and should compile against the iOS 17 SDK with the provided boilerplate.
