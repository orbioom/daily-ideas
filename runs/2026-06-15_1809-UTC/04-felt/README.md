# Felt — premium poker session & bankroll tracker

A clean, fast, native iOS app for serious poker players to log sessions, understand their real edge, and manage their bankroll responsibly.

## What it is

Serious poker players already pay for tracking software, but the incumbents (Poker Bankroll Tracker, Poker Analytics) are dated, cluttered, and slow. **Felt** is the modern, premium, one-time-purchase alternative: a calm "green-felt card room" interface, instant profit math, honest analytics, and a bankroll-management module — all private, on-device, with no account and no network.

Felt is a **responsible bankroll-management and analytics tool**, not gambling promotion. Every screen frames numbers as personal record-keeping, and guidance is explicitly "for your reference, not financial advice."

**Audience:** recreational-to-semi-pro cash and tournament players who want to know their hourly rate, win rate, ROI, and whether their bankroll is healthy for their stakes.

## Features

- **Dashboard** — hero current-bankroll (or hourly-rate) figure, total profit, hours, sessions, win rate; cumulative-profit area/line chart; recent sessions; one-tap "Add session"; privacy "hide amounts" blur. Empty + computing states.
- **Sessions** — full CRUD: searchable, filterable list (by format and game type), swipe-to-delete with confirmation, add/edit form with conditional tournament fields and **live profit** as you type, and a rich detail screen with per-session ROI. Free-tier cap (25 sessions) surfaces a tailored paywall.
- **Analytics** — `Charts`-powered: win-rate gauge, average/std-dev/ROI mini-stats, profit-over-time, monthly bars, and breakdowns by stake, game, and location (Pro). Period filter: All / YTD / 30d / 90d.
- **Bankroll** (Pro module) — deposit/withdrawal CRUD, bankroll-over-time timeline, tournament ROI, and a slider-driven "suggested minimum bankroll = N buy-ins" guidance card framed as informational only.
- **Settings** — 6 persisted prefs: appearance (System/Light/Dark), haptics, default game type, currency symbol, "lead with hourly rate", and "hide amounts" privacy blur; plus CSV export (Pro) and a "play responsibly" note.
- **Onboarding** gated by `@AppStorage("hasOnboarded")`; first-run seed of 56 realistic sessions + bankroll transactions over ~6 months.
- Full light/dark theming, Dynamic Type, accessibility labels/hints/values, Reduce-Motion-aware animation, sparse gated haptics.

## Substantive core logic

`StatsEngine` (pure struct, all `Decimal` money, every division guarded) computes: total profit, total hours, hourly rate, win rate, biggest win/loss, average session profit, tournament ROI, population standard deviation of results, current bankroll (Σ transactions ± Σ session profits), bankroll timeline, cumulative-profit series, breakdowns by stake/location/game/format/month, and a recommended-minimum-bankroll helper (N buy-ins × largest buy-in). `Money` centralizes guarded `Decimal` ↔ `NumberFormatter` formatting and parsing; `CSVExport` builds an escaped CSV; `StatsPeriod` scopes sessions to a time window.

## Run

1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. `open Felt.xcodeproj` — select an iOS 17+ simulator, press **Cmd+R**.

**Free signing:** open the project, select the Felt target → Signing & Capabilities, choose your personal Apple ID team; no paid account needed for the simulator or a personal device.

## Tech notes

- **iOS 17+**, SwiftUI 5, `NavigationStack` only, MVVM-lite (views compute via the pure `StatsEngine`).
- **SwiftData** (`@Model Session`, `@Model BankrollTransaction`, `@Query`, `modelContainer`) for persistence that survives relaunch; `@AppStorage` only for small prefs/flags.
- All money is **`Decimal`**; charts via `import Charts` (`LineMark`/`AreaMark`/`BarMark`/`Gauge`).
- Design language: deep felt-green + charcoal surfaces, gold/cream accents, chip motif, monospaced money figures, profit-green / loss-red (AA in both modes), `Color.dyn` light+dark pairs around accent `0x2E9E6A`.
- **Monetization:** one-time **Felt Pro $5.99** — unlimited sessions, full analytics breakdowns, bankroll module, CSV export. Simulated locally via `@AppStorage("isPro")` + `Pro` enum + `PaywallView` + `PaywallReason`; StoreKit 2 wires in here for production (no real purchase, ads, or account).
- **Why it can boom:** serious poker players are a proven, paying niche (like our trading-journal play) whose tracker incumbents are dated and clunky; Felt is the clean, fast, premium, one-time version.

## Self-review

I re-read every Swift file as the compiler against the iOS 17 SDK. Verified: all imports resolve (`SwiftUI`, `SwiftData`, `Charts`, `UIKit`, `Foundation`); every type/initializer/modifier exists in iOS 17 and is spelled correctly; `@Query`/`@Bindable`/`@EnvironmentObject`/`@State`/`@AppStorage` ownership is correct; `NavigationStack`/sheet/`navigationDestination` bindings type-check; two-param/zero-param `onChange` only (none needed); Charts API is iOS-16/17-safe (`Gauge .accessoryCircular`, `AxisMarks`). All money is `Decimal`; every division (`hourlyRate`, `winRate`, `averageProfit`, `tournamentROI`, ROI rows, std-dev) and array access is guarded; `Decimal`↔`Double` conversions are `isFinite`-checked. No force-unwraps, `try!`, `as!`, or `fatalError` on user paths — the only `fatalError` is the documented unreachable in-memory `ModelContainer` fallback in `FeltApp`. Anti-stub grep (`TODO`/`FIXME`/`placeholder`/`stub`/`coming soon`/`not implemented`) is clean. Definition-of-Done items confirmed present: 4 feature tabs + Onboarding + Settings; empty/computing/error/success states; ≥3 persisted prefs; SwiftData persistence; full accessibility; light+dark; Reduce-Motion-aware animation; sparse gated haptics; lazy containers with stable IDs.
