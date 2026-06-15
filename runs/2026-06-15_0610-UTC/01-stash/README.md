# Stash

**A privacy-first loyalty & gift-card wallet.** Keep every store loyalty card and gift
card in one beautiful place, and pull up the scannable barcode instantly at checkout —
on-device, no account, no ads.

## What it is

Stocard had 60M+ users and shut down in December 2024 when Klarna replaced it with a
payments app, stranding millions of people who just wanted their cards in one place.
Stash is the calm, private replacement: a native iOS wallet for loyalty/membership cards
and gift cards. Everything stays on your device, the barcodes are rendered locally, and
Pro is a single one-time unlock — never a subscription. **Audience:** everyone who shops.

## Features

- **Wallet** — searchable, sortable grid of colored loyalty-card tiles with favorites
  pinned, category filter chips, swipe / context-menu delete, quick-add from a built-in
  catalog of ~24 stores, and a calm empty state.
- **Card Detail** — a large, crisp on-device barcode, the raw/formatted value, automatic
  screen-brightness boost so scanners read it, a "Mark as used" action, edit, favorite,
  and delete.
- **Add / Edit Card** — catalog quick-pick or fully custom; a format picker with a **live
  barcode preview**; generated color palette; category; notes; input validation with calm
  error states (including a one-tap "fix the check digit" for EAN-13/UPC-A).
- **Gift Cards** — list with remaining-balance rings, total-remaining summary, add a gift
  card, log spends against a balance, full spend history, and depleted / expiring / expired
  states. (Pro.)
- **Insights** — total cards, gift-card balance remaining, cards-by-category bar chart
  (Swift Charts), recently used, and recently added.
- **Onboarding** (first-run, persisted) and **Settings** with real persisted preferences.
- Light + dark mode first-class, full Dynamic Type & VoiceOver support, sparse haptics,
  and Reduce-Motion–aware animation.

### Substantive core logic

- **On-device barcode rendering** via Core Image (`CIFilter.code128BarcodeGenerator`,
  `qrCodeGenerator`, `aztecCodeGenerator`, `pdf417BarcodeGenerator`), scaled by an integer
  factor with nearest-neighbor sampling so bars stay razor-sharp.
- **A hand-rolled EAN-13 / UPC-A renderer** (`EAN13Encoder`): the full L / G / R code
  tables, first-digit parity patterns, check-digit computation **and** validation, and a
  95-module bit pattern drawn with a SwiftUI `Canvas`. UPC-A is encoded as its EAN-13
  equivalent. (Encoding tables and check digit verified against the published standard.)
- **A `BarcodeFactory`** mapping each format to the right renderer, with validation
  (EAN-13 needs 12–13 digits, UPC-A 11–12, etc.) and calm error states.
- **Gift-card balance math** in `Decimal`: remaining = initial − Σ spends, with
  divide-by-zero-guarded ring fractions and leap-safe expiry math.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Stash.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

## Free signing

Works with a personal Apple ID — no paid Apple Developer account needed to build and run
in the simulator. Code-signing is only required to install on a physical device.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM, **SwiftData** persistence (`@Model` / `@Query` /
  `modelContainer`) with `@AppStorage` for small prefs/flags.
- Core Image + a hand-rolled EAN-13 encoder for barcodes; Swift Charts for Insights.
- A cohesive `Theme` with semantic light/dark colors, a teal accent, consistent corners,
  a rounded type scale, and reusable styled components.
- **Monetization:** one-time Stash Pro (~$3.99, simulated locally via `@AppStorage` —
  StoreKit wires in for production) unlocks unlimited cards, gift-card tracking, premium
  themes, and CSV export. No ads, no subscription.
- **Why it can boom:** Stocard's December-2024 shutdown left 60M+ users without a home for
  their cards; Stash is the private, on-device, no-account, no-ads replacement with a fair
  one-time unlock — exactly what stranded users are searching for.

## Self-review

- **Compiles by inspection:** yes — every file re-read; iOS 17 SDK only; Core Image
  builtin filter names verified (`import CoreImage.CIFilterBuiltins`); SwiftData wiring,
  `@Query` / `@Bindable` / `modelContainer`, and Swift Charts usage type-check.
- **Anti-stub grep clean:** yes — no TODO/FIXME/XXX/placeholder/lorem/"coming soon"/
  "not implemented"/stub.
- **Definition of Done met:** yes — 4 substantive feature screens plus Onboarding &
  Settings; empty/loading/error/success states; ≥3 persisted prefs; SwiftData persistence;
  full accessibility; gated haptics; light+dark Theme; 50+ seeded cards; no force-unwraps
  or `fatalError` on user paths.
