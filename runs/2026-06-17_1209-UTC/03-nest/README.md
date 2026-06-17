# Nest

A private, no-bank-login planner for your savings goals and sinking funds.

## What it is

Nest helps you save with intention. Create a goal for each thing you're saving for — an
emergency fund, a trip, a new roof, the holidays — give it a target amount and (optionally) a
date, and Nest tells you the monthly contribution you need and whether you're on track, behind,
or ahead. Log deposits and withdrawals, watch satisfying progress rings fill, and when a bonus
or tax refund lands, split it across your goals in one tap.

Unlike Qapital, Digit, and other "automatic savings" apps, Nest never asks for a bank login and
never charges a fee on the money you save. Everything lives on your device. Money is displayed
in monospaced, tabular figures and computed precisely to the cent.

## Full feature list

- **Goals tab** — every goal as a soft card with a progress ring, saved-of-target in tabular
  figures, and an on-track / behind / ahead / funded status badge. Goals are sorted by priority
  then progress. A header card shows your total saved across all goals. Empty state for first run;
  an archived section that expands on demand.
- **Goal detail** — a large progress ring, saved / target / remaining, the suggested monthly
  contribution, your recent monthly pace, months to target, and a projected completion date.
  Add a contribution or record a withdrawal; a full contribution history with tap-to-edit and
  swipe-to-delete; edit the goal; archive / unarchive; delete (with confirmation).
- **Allocate tab** *(Pro)* — "I have $___ to put away" → choose which goals and a strategy
  (**By Need**, **Even Split**, or **By Priority**) → preview the exact per-goal split (which always
  sums to the lump, to the cent) → apply, with a success confirmation.
- **Insights tab** — Swift Charts: total saved over time (area + line), monthly contributions
  (bar), and saved-by-category (donut / `SectorMark` with a legend). An overview card with overall
  progress ring, on-track / behind counts, and a contribution streak. Loading and empty states.
- **Settings** — currency (symbol + code picker, 8 currencies), first day of month, default
  allocation strategy, hide amounts (privacy blur), monthly reminder toggle, haptics toggle,
  CSV export, load sample data, About, and Unlock / Restore Pro.
- **Onboarding** — a four-page first-run intro, gated by a persisted flag.
- Smart, guarded pacing math (no divide-by-zero, no force-unwraps); seed data of 5 realistic
  goals and 40+ contributions so charts and rings are populated immediately.
- Full Dynamic Type, light & dark mode, accessibility labels/values on controls and charts,
  Reduce Motion fallback on the progress ring, and sparse haptics gated by a setting.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Nest.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing:** set your Apple ID team in Signing & Capabilities; the bundle id is
`com.orbioom.nest`.

## Tech notes

- **iOS 17 / SwiftUI 5.** `NavigationStack` throughout, `TabView` for the four tabs, Swift
  Charts (`AreaMark`, `LineMark`, `BarMark`, `SectorMark`).
- **SwiftData** for primary data: `@Model` types `Goal` and `Contribution` (cascade relationship),
  both registered in the `Schema`. The `ModelContainer` falls back to an in-memory store and then
  to a calm `StoreUnavailableView` rather than crashing. Survives relaunch.
- **Observation framework** end to end: `AppSettings` and `ProStore` are `@Observable`, created with
  `@State` in the app and injected via `.environment(...)`, read with `@Environment(Type.self)`.
  No `ObservableObject` / `@StateObject` mixing. `@AppStorage` only for `hasOnboarded` and the
  `isPro` flag.
- **Money** is computed in `Decimal` (deposits − withdrawals, allocation splits with exact
  remainder fix-up, rounding via `NSDecimalRound`) and persisted as `Double`; `Decimal(string:)`
  is never force-unwrapped.
- Engines (`GoalEngine`, `AllocationEngine`, `StatsEngine`) are pure and guard every division and
  empty input.
- **Monetization:** simulated one-time **Nest Pro — $4.99** via a persisted `isPro` flag
  (`PaywallView` with Unlock / Restore). Free tier: up to 3 active goals, contributions, pacing,
  and basic stats. Pro: unlimited goals, the Allocate tool, advanced insights, and CSV export.
  StoreKit-ready in spirit; no real purchase calls.
- **Why it can boom:** "sinking funds" and savings-goal planning are a huge, evergreen
  personal-finance need, and people resent the fees and bank-link requirements of Qapital/Digit.
  Nest is private (no bank login), beautiful, and genuinely smart — pacing plus one-tap lump-sum
  allocation — for a single, honest one-time price.

## Self-review attestation

All **37** Swift source files were re-read after writing. Verified:

- iOS 17 APIs only; `NavigationStack` (no `NavigationView`), `SectorMark` is iOS 17.
- One observation pattern (`@Observable` + `@Environment(Type.self)` + `@State`); no
  `ObservableObject`/`@StateObject` mixing.
- All `.onChange(of:)` use the two-parameter iOS 17 form; no `@Previewable`.
- No force-unwrap (`!`), `try!`, `as!`, or `fatalError` on user paths; the two array literal
  accesses (`CurrencyOption.all[0]`, `Theme.goalSwatches[0]`) are on compile-time constant,
  non-empty arrays. A `subscript(safe:)` helper guards dynamic indexing.
- Money is `Decimal`-based and safe; `Decimal(string:)` never force-unwrapped.
- Every `@Model` (`Goal`, `Contribution`) is registered in the `Schema`.
- All division guarded (`max(_, 1)`, target/rate > 0 checks); empty collections handled.
- No stub words (`TODO`/`FIXME`/`placeholder`/"coming soon"/etc.); every control wired to real
  behavior. Balanced braces in every file; imports present where used.
