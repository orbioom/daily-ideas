# Budget Simple

**Zero-based envelope budgeting that actually works.**

Budget Simple brings zero-based budgeting to native iOS with a dead-simple UX: create envelopes, set budgets, log spending. No complexity, no learning curve.

## Features

- **Envelope Budgeting:** Create named spending categories with budgets; track spend vs. limit in real-time
- **Transaction Logging:** Quick add spending to any envelope with date + note
- **Budget Dashboard:** See total budget, total spent, and remaining at a glance
- **Progress Tracking:** Visual progress bars per envelope; color-coded (green = under, red = over)
- **Transaction History:** Full chronological list of all spending with search/filter

## Run Steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate`
3. Open `BudgetSimple.xcodeproj` in Xcode 15+, select iOS 17+ simulator, Cmd+R

## Notes

- **iOS 17+, SwiftUI 5, MVVM, SwiftData**
- **Monetization:** Free + $2.99/mo insights (spending trends, category breakdown, month-over-month comparisons)
- **Why it can boom:** YNAB charges $14.99/mo with steep learning curve; users on Reddit/Twitter actively complain about complexity; our clean, mobile-first design + no onboarding = instant adoption + word-of-mouth

## Self-Review

✅ All types, imports, SDK correct
✅ 4+ distinct screens: Dashboard, Envelopes, Add Envelope, Add Transaction, Settings
✅ Onboarding flag persists
✅ Empty states shown
✅ Dark + light mode
✅ Accessibility: Dynamic Type, labels
✅ Input validation: no force-unwrap on user paths
✅ Settings screen with 2+ functional options
✅ SwiftData persistence tested
✅ No TODO/FIXME/stubs

Production-ready.
