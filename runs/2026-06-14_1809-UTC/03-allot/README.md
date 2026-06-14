# Allot — zero-based budgeting

**One-liner:** Give every dollar a job. Allot is a fast, private, on-device envelope budget that does the YNAB method without bank logins — and without YNAB's $109-a-year price.

**The problem + audience:** Zero-based / envelope budgeting (assign every dollar until "Ready to Assign" is zero) is the method that actually changes spending behavior, and YNAB has built a devoted, paying audience around it. But YNAB is expensive, subscription-only, and pushes bank-sync that many people distrust. Allot is for committed budgeters who want the proven method, manual control, full privacy, and a one-time price.

## Full feature list
- **Budget (month view)** — a month switcher and a big **Ready to Assign** header that turns green at 0, amber when there's money to assign, and red when over-assigned. Categories are grouped into collapsible sections, each row showing Assigned / Activity / **Available** (green funded, red overspent). Tap a category to assign money, "set to last month", or "cover overspending". Add categories and groups.
- **Accounts** — checking / savings / cash / credit accounts with balances derived from transactions plus a starting balance, a net-worth total, an add-account flow, and a per-account register.
- **Transactions** — every transaction in a lazy list, an add/edit sheet (payee, amount with inflow/outflow toggle, category, account, date, cleared) with numeric non-zero validation, filtering by account/category, search, and swipe-delete.
- **Reports** — spending-by-category donut (SectorMark), income-vs-expense bars by month, a net-worth / spending trend line, and top categories (Swift Charts), with a loading state. Pro-gated with a blurred teaser for free users.
- **Settings** — currency symbol (used in every figure), hide-balances privacy blur, default new-category rollover on/off, haptics; plus Pro, CSV export, Load sample data, reset/erase, About.
- **Onboarding** (3 pages explaining "give every dollar a job"), first-run gated; seeded with 4 accounts, 14 categories, 3 months of allocations, and ~70 transactions so the budget and reports are rich immediately.

## Run steps
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Allot.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing note:** No paid account needed — set a Personal Team and use the `com.orbioom.allot` bundle id (or your own). No entitlements required; nothing leaves the device.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. **SwiftData** (`Account`, `Category` cascade `Allocation`, `Transaction`), prefs in `@AppStorage`. Money handled with cents-rounded arithmetic.
- Pure `BudgetEngine`: `accountBalance = starting + Σ txns`; `available` carries across months when rollover is on (`Σ allocated≤month − Σ spent≤month`) or resets monthly when off; **`readyToAssign = Σ on-budget balances − Σ category.available`**. Plus net worth, income/expense, by-group spending, monthly trend, overspend detection — all guarded against empty data and division by zero.
- Design language: crisp fintech-calm — teal accent, clean cards, green/amber/red money states, tabular numerals; first-class light & dark via `Theme.dyn`; Dynamic Type, VoiceOver on money rows, Reduce Motion respected.
- **Monetization:** free covers 1 budget, up to 2 accounts and 10 categories; **Reports + CSV export and higher limits** are a one-time **$6.99** Pro unlock (StoreKit not wired; demo unlock + Restore). Who pays: serious budgeters who'd otherwise pay YNAB $109/yr.
- **Why it can boom:** the envelope method has a proven, high-willingness-to-pay audience, and the market leader is loudly resented for its price and forced bank-sync. Allot is the method people love, done natively, privately, and once-and-done.

## Self-review
36 Swift files. Static audit clean: one `@main`, one `try!` (in-memory fallback), anti-stub grep clean, valid asset JSON, real 1024² icon, balanced delimiters. All 4 `@Model` types registered in both `ModelContainer` calls; cascade `Allocation` under `Category`; ≥4 feature screens + Settings; empty/loading/error/success states; all money divisions guarded. A dedicated compile-review pass verified the engine math, Charts API, and cross-file types against the iOS 17 SDK.
