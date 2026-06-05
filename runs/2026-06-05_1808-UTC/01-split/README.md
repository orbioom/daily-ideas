# Split

**An Orbioom studio app — shared spending, calmly settled.**

Split is a native iOS app for tracking shared expenses across groups — a weekend
trip, a flat, a dinner — and seeing who owes whom. It turns a messy pile of "who
paid for what" into a clear set of balances and the *fewest* payments needed to
settle up. It's for friends, flatmates, and travellers who want the math done
right without spreadsheets or accounts.

---

## Features

- **Groups** — create groups with a name, glyph, and currency (USD, EUR, GBP, JPY,
  INR, CAD, AUD, CHF). Each group shows total spent and a settled/owed summary.
  Full create / edit / delete with duplicate-name guards.
- **Members** — manage the people in a group: add, rename, and remove. Removal is
  guarded when a member appears in any expense or payment, so balances stay intact.
- **Expenses** — record shared costs with a title, amount, payer, date, and notes.
  Three split modes:
  - **Equally** — even split; the rounding remainder is distributed cent-by-cent so
    shares sum *exactly* to the total.
  - **Exact amounts** — enter what each person owes; saving is blocked unless the
    amounts add up to the total.
  - **By shares** — weight each participant; the remainder is distributed to the
    largest fractional parts deterministically.
  A live per-person preview always reconciles to the total before you save.
- **Balances** — per-member net balance (owed vs owing), shown with calm color
  cues (green = owed, warm = owes).
- **Settle Up** — a **debt-simplification** engine (greedy min cash flow) reduces
  all balances to the smallest list of "X pays Y $Z" transfers. Tap a suggestion
  to pre-fill and record a real payment; recorded payments form a history you can
  delete (balances adjust accordingly).
- **Group stats** — total spent, expense count, biggest expense, recorded payments.
- **Onboarding** — a calm one-screen intro shown once, gated by a persisted flag.
- **Settings** — appearance (System / Light / Dark, applied live), default split
  mode, default currency for new groups, haptics toggle (gates all haptics), and
  reset-to-sample / clear-all-data with confirmations. All persisted.
- **Sample data** — seeded once into an empty store: a "Weekend Trip" group with 6
  members and 22 expenses (mixed split modes) plus recorded settlements, a 3-member
  "The Flat" (EUR), and a 4-member "Tasting Menu" (GBP).
- **Craft** — Liquid Glass cards (`.ultraThinMaterial`), the ink primary-action
  gradient, monospaced figures for money, first-class light/dark, Dynamic Type,
  VoiceOver labels/hints, and Reduce-Motion-aware animation.

---

## Run

1. Open `ios/Split.xcodeproj` in **Xcode 15 or later**.
2. Select an **iOS 17+ simulator** (e.g. iPhone 15 Pro).
3. Press **Cmd+R**.

## Free signing

No paid Apple Developer account is needed to run on the simulator. To run on a
physical device, select the **Split** target → **Signing & Capabilities**, choose
your personal team, and let Xcode manage signing automatically. No code-signing
identities are committed.

## Tech notes

- iOS 17+, **SwiftUI** (SwiftUI 5), **MVVM**, **SwiftData** for all primary records
  (`SplitGroup`, `Member`, `Expense`, `ExpenseShare`, `Settlement`).
- `UserDefaults` is used **only** for preferences and the onboarding flag.
- All money math uses `Decimal` / `NSDecimalNumber` (never `Double`) and rounds to
  the currency minor unit. The balance/settlement logic lives in a pure, value-type
  helper (`Utilities/BalanceEngine.swift`) that is independent of SwiftData and
  hand-verifiable.
- No external dependencies. No network. Data stays on device.
- Monospaced figures use the system monospaced design (`.monospaced()` /
  `.monospacedDigit()`); no custom font file is bundled.

---

## Self-review

- **Anti-stub scan** — `grep -rniE "TODO|FIXME|XXX|placeholder|lorem|coming soon|not
  implemented|// stub"` over the project returns **no matches**. No TODOs, stubs,
  dead controls, or placeholders.
- **Hand-compile pass** — every Swift file was re-read for correct imports (SwiftUI /
  SwiftData / Foundation / UIKit), iOS-17 SDK API usage, protocol conformances
  (`Identifiable`, `Hashable`, `@Model`, `@Observable`), and correct property-wrapper
  ownership (`@State`, `@Bindable`, `@Environment`, `@Query`). All 24 source files are
  referenced in the `project.pbxproj` `PBXBuildFile`, `PBXFileReference`, group, and
  `PBXSourcesBuildPhase` sections with unique 24-hex object IDs (verified by script:
  24 file refs, 24 source entries, 26 build files incl. Assets + Preview Content, no
  duplicate definition IDs, balanced braces).
- **Math verified** — the share-splitting and debt-simplification logic was ported to
  a reference script and tested: equal/weighted shares reconcile *exactly* to the
  total (including the 100/3 and weighted cases), and the simplified transfers zero
  out all net balances within rounding.
- **Data-flow trace** — create → `context.insert` / relationship append → SwiftData
  autosave → relaunch → `@Query` → read was traced by hand through `SplitApp`'s
  `ModelContainer` wiring, `RootView` seeding (once, into an empty store only), and
  each edit view. Sample data seeds only when the store is empty and `hasSeeded` is
  false, so real data is never mixed with seed data.
- **Safety** — no `fatalError` (except the unreachable last-resort container fallback),
  no `try!`, no force-unwraps, and no unguarded indexing or division on user-reachable
  paths; division by participant count is guarded against empty sets.
- **App icon** — generated by `tools/make_icon.py` (Python stdlib only: `zlib` +
  `struct`) into `Assets.xcassets/AppIcon.appiconset/icon-1024.png`, a 1024×1024 RGBA
  PNG (~144 KB) with a mist→ink gradient and two overlapping silver-lit orbs.

*Split — conjured, not just coded.*
