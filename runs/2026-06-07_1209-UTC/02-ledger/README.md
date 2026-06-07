# Ledger

**Net-worth and asset-allocation tracker — fully on-device.** Add your assets and debts, net them into one number, snapshot it over time, and rebalance against target weights. No accounts, no bank logins, no cloud.

For people who want a calm, private picture of what they own and how it's allocated — the gap left by budgeting-focused apps.

## Features

- **Accounts** — assets and liabilities with institution, asset class (cash, stocks, bonds, real estate, crypto, other / debt), and balance. Net worth headline with assets/debts split, per-class icons, full add/edit/delete, and a "count toward net worth" toggle.
- **Snapshots & history** — tap "Take snapshot" to capture every account's value; the History tab plots your net-worth trend (Swift Charts area+line with currency axis), shows period change, and lists every snapshot. Snapshot detail reconstructs the allocation and account values at that date.
- **Allocation** — a donut of your current allocation, a current-vs-target view with per-class drift bars (target tick over the current fill), and exact rebalance amounts ("add $X" / "trim $Y") to reach your plan. A max-drift "out of balance" score.
- **Targets** — set target weights per class with sliders and a live total that flags when it isn't 100%.
- **Settings** — currency (USD/EUR/GBP/JPY), compact large numbers, skin-out vs base headline toggle, confirm-before-delete, haptics, appearance, erase-all.

Onboarding gate, empty/loading/success states, light & dark, Dynamic Type, VoiceOver, Reduce Motion, designed app icon.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Ledger.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**.

**Free signing:** pick your personal team under Signing & Capabilities; bundle id `com.orbioom.ledger`. No paid account needed.

## Tech notes

iOS 17+, SwiftUI 5, pure `AllocationEngine` for net-worth, allocation, and rebalancing math; `Money` for currency/percent formatting. Persistence in **SwiftData** (`Account`, `Target`, `Snapshot → SnapshotEntry`); prefs in `@AppStorage`. **Swift Charts** for the trend line and allocation donut (`SectorMark`, iOS 17). Orbioom design language. No third-party dependencies; a realistic portfolio, targets, and a year of monthly snapshots are seeded on first launch.

## Self-review

Anti-stub grep clean (only the in-memory `ModelContainer` fallback uses `try!`). By-hand compile pass: SwiftData models with String-backed enum accessors, `SectorMark`/`AreaMark`/`LineMark` over `Identifiable` data, chart axis builders, and all `ForEach` ids (no tuple key paths — index- or struct-based) verified against the iOS 17 SDK. Correctness is by inspection (no Xcode in the sandbox).
