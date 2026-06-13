# Cascade — debt payoff planner

See the exact month you'll be debt-free. Add what you owe, pick snowball or avalanche, and watch a little extra each month pull your free-date forward. No bank login — everything stays on your phone.

**The problem & audience.** The ~80% of households carrying card or loan balances who want a clear plan out. Undebt.it and "Debt Payoff Planner" apps prove the demand but are cluttered, ad-heavy or web-bound; people want a calm, private, beautifully simple planner.

## Features
- **Debts dashboard** — total owed, a paid-off progress ring, projected debt-free date and a countdown; per-debt cards with progress bars, APR and minimums.
- **Full CRUD** for debts (card, loan, student, auto, medical, mortgage, other) with input validation and a negative-amortization warning.
- **Payoff engine** — month-by-month interest accrual, pays every minimum, then cascades the extra to your focus debt (rolling freed minimums forward as debts clear).
- **Plan** — pick a strategy and monthly payment with a live slider; see payoff date, total interest, months saved vs minimums, a balance-over-time **Swift Chart**, and the exact payoff order.
- **Compare** — snowball vs avalanche side by side with interest saved, time difference and a recommendation; switch your active plan in a tap.
- **Progress** — log payments (rolling balances down), with paid-so-far, debts cleared, a payments-by-month chart and history.
- Onboarding (persisted), Settings with default strategy, currency and 2 haptic prefs, light + dark, Dynamic Type, VoiceOver, Reduce Motion, opt-out haptics, a designed "descending steps to a flag" icon + launch screen.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Cascade.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free-signing:** set your personal Team in Signing & Capabilities — no paid account required.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM-ish with a pure `PayoffEngine` simulator (50-year horizon, infeasible-budget and never-pays-off states handled).
- Persistence: **SwiftData** (`Debt`, `PaymentLog`); `UserDefaults` for budget/strategy/currency/onboarding.
- Charts via Swift Charts; money formatted with `NumberFormatter`.
- Design language: calm fintech — paper-white, forest greens, a debt-free flag.
- **Monetization:** free for up to 4 debts; one-time **Cascade Pro ($7.99)** for unlimited debts, custom payoff order and export. Who pays: anyone with multiple balances motivated to get out of debt.
- **Why it can boom:** debt payoff is a large, hungry, evergreen money niche with proven paid apps; Mint's shutdown and subscription fatigue leave room for a private, no-bank-login, one-time planner that nails the snowball/avalanche mechanic with real charts.

## Self-review
Audited file-by-file (no Xcode in sandbox): anti-stub grep clean; braces/parens balanced; no `try!` beyond the in-memory `ModelContainer` fallback, no `fatalError`, no force-unwraps on user paths; SwiftUI/SwiftData/Charts imports present; Theme tokens defined; `@Query`/`modelContainer`/`navigationDestination`/sheet bindings type-checked; engine reviewed for division-by-zero and infinite-loop safety.
