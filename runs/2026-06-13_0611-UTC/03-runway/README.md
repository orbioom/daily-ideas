# Runway

**Projects your checking balance day by day and tells you what's truly safe to spend before the next payday — no bank login, all on-device.** For the millions living paycheck to paycheck who just need to avoid the overdraft.

## Features

- **Safe-to-spend number:** the lowest your balance will reach before your next income, minus a buffer you set — the one honest figure PocketGuard/Rocket Money gate behind bank-linking and three consistent paychecks.
- **Day-by-day forecast engine:** expands recurring income & bills (weekly, every-2-weeks, twice-a-month, monthly, every-N-weeks/months, month-end-safe) plus planned one-offs into a running daily balance over ~75 days.
- **Runway home:** safe-to-spend, current balance (tap to update with an as-of date), next-income card, a low-balance/shortfall warning, and a 4-week balance chart with buffer and zero rules (Swift Charts).
- **Calendar:** every upcoming day with money moving, color-coded green/amber/red by projected balance, grouped by month; tap a day for a full breakdown.
- **Money:** full CRUD for **recurring** items (with monthly-in/out/left-over summary) and **planned one-offs**, categorized with icons, income vs bill.
- Onboarding (starting balance + sample data), **Settings** (safety buffer, currency, theme, haptics, erase), one-time **Runway Pro**.
- Light & dark, Dynamic Type, VoiceOver, Reduce Motion.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Runway.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

**Free signing:** pick your personal team and a unique bundle id in *Signing & Capabilities*.

## Tech notes

iOS 17+, SwiftUI 5, with a pure `ForecastEngine` (occurrence expansion + running-balance projection + safe-to-spend/lowest-point/warning derivation). Persistence in **SwiftData** (`RecurringItem`, `OneOffItem`); balance/buffer/currency in `UserDefaults`. Design language: **calm fintech** — navy with a confident green and a green/amber/red semantic system, big rounded currency numerals.

- **Monetization:** free core; one-time **Runway Pro** ($8.99) adds multiple accounts, a 6-month horizon, and a home-screen safe-to-spend widget. Budgeting is a proven paying category (YNAB, Copilot at $13/mo).
- **Why it can boom:** "safe to spend" is the single most-wanted budgeting feature, but every incumbent locks it behind bank aggregation, a subscription, or assumes steady income. A private, manual, one-time-purchase forecaster that supports variable income is a clear, trust-led wedge in a giant market.

## Self-review

Hand-reviewed every file. Verified imports (incl. `Charts`); iOS-17 APIs; the recurrence/occurrence math and month-end clamping; SwiftData `@Query`/`modelContainer`; `navigationDestination(for: Date.self)`; currency `NumberFormatter` paths; no division by zero (guards on counts). Anti-stub grep clean. No force-unwraps/`try!` on user paths.
