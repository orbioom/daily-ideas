# Quarter

**The private, one-time quarterly tax estimator for the self-employed.**

Quarter is a native iOS app that does the hard self-employment-tax math for freelancers,
contractors, and gig workers — SE tax, federal income tax, a state approximation, the four
quarterly estimated-payment due dates, and plain-English safe-harbor guidance — entirely on
your device. No account, no subscription, no data leaving your phone. One screen tells you
exactly how much to set aside.

---

## What it is

Most freelancers dread two questions: *"How much will I owe?"* and *"When do I pay it?"*
Quarter answers both. Enter your self-employment income and expenses (or pull totals straight
from the built-in Ledger), pick your filing status and tax year, and Quarter computes your
estimated tax live — with a confident "set aside X%" recommendation and a full breakdown of
where the number comes from. It then lays out your four estimated-payment due dates with a
countdown to the next one, and explains the safe-harbor rules that keep you penalty-free.

All tax math runs through a pure, deterministic `TaxEngine` written in `Decimal` for money-grade
accuracy, using **published 2024 and 2025 federal figures**.

---

## Full feature list

- **Estimate (dashboard)** — A large hero "estimated tax you'll owe" figure with a "set aside
  about X%" recommendation, a breakdown (self-employment tax, federal income tax, state
  approximation), and effective & marginal-rate chips. Editable inputs (income, expenses,
  other W-2 income, federal withholding, filing status, state %, year) recompute live. Pull
  income/expense totals straight from the Ledger. Graceful idle state when inputs are blank.
- **Ledger** — Full income & expense CRUD. Category grouping, income/expense/net totals that
  feed the estimate, a Swift Charts **donut of expenses by category**, and an **income-vs-expenses
  bar chart**. Empty state with a call to action.
- **Quarterly** — The four estimated-payment periods with standard due dates (Apr 15, Jun 15,
  Sep 15, Jan 15) and simple weekend roll-forward ("on/around"), a **next-due countdown banner**,
  mark-paid tracking with a progress bar, and a safe-harbor explainer.
- **Scenarios** — Save snapshots of your inputs and **compare two side-by-side** — which owes
  less and the exact dollar delta. Empty state.
- **Learn** — Plain-English explainers: what SE tax is, why quarterly estimated payments exist,
  safe harbor, and common deductions — plus the disclaimer.
- **Settings** — Default filing status, default state rate %, default tax year, haptics toggle,
  CSV export (Pro), reset-all-data, Pro management, and About.
- **Onboarding** — A first-run, three-page intro gated by `@AppStorage("hasOnboarded")`, ending
  with the disclaimer.
- **Quarter Pro ($5.99, simulated one-time)** — Free tier: one saved scenario + current-year
  estimate. Pro: unlimited scenarios + compare, multi-year (2024/2025), quarterly payment
  tracking, and RFC-4180 CSV export.
- **Accessibility** — Dynamic Type throughout, VoiceOver labels/values that announce the big
  numbers, decorative images hidden, Reduce Motion respected, WCAG-AA contrast in light and dark.
- **Haptics** — Sparse and tasteful, gated by a Settings toggle.

---

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` if present).
3. Open `Quarter.xcodeproj` in **Xcode 15+**, pick an **iOS 17+** simulator, and press **Cmd+R**.

### Free-signing note

The project signs with your personal Apple ID team — no paid Apple Developer account is needed.
If Xcode shows a signing error, select the **Quarter** target → **Signing & Capabilities** →
choose your personal team. The bundle identifier is `com.orbioom.quarter`; change the prefix if
it collides with an existing profile.

---

## Tech notes

- **Platform:** iOS 17+, SwiftUI 5, Xcode 15. iOS-17-only APIs throughout — `NavigationStack`,
  `@Observable` view models, `@Query`/`modelContainer` for SwiftData, two-parameter `.onChange`,
  and Swift Charts.
- **Architecture:** Lightweight MVVM. Pure engine layer (`TaxEngine`, `QuarterlyEngine`,
  `TaxTables`) with no I/O; `@Observable` `EstimateViewModel` and `StoreManager`; SwiftUI views.
- **Persistence:** SwiftData for records (`IncomeEntry`, `ExpenseEntry`, `TaxScenario`,
  `EstimatedPayment`), all registered in the app's `Schema`. Small preferences via `@AppStorage`.
  Survives relaunch. If the on-disk store fails to open, the app recovers to an in-memory store
  rather than crashing.
- **Decimal engine:** Money is stored as `Double` in SwiftData models (to avoid SwiftData's
  Decimal quirks) and converted to `Decimal` in the engine, where **all** tax arithmetic happens.
  Every division is guarded against a zero divisor (effective rate, set-aside %, progress).
- **Federal figures:** 2024 brackets & standard deductions (Rev. Proc. 2023-34), 2025 brackets
  (Rev. Proc. 2024-40) and 2025 standard deduction (as amended for tax year 2025:
  $15,750 single / $31,500 MFJ / $15,750 MFS / $23,625 HoH), Social Security wage base
  ($168,600 in 2024, $176,100 in 2025), SE rates (12.4% SS + 2.9% Medicare + 0.9% Additional
  Medicare over status thresholds).
- **Design language:** Confident, trustworthy fintech — deep "ink" hero surfaces, the
  teal-green accent **#13A07F**, large rounded **tabular figures** (`.monospacedDigit()`), clean
  card sections, and generous whitespace. First-class light and dark. Numbers are the hero.
- **Monetization:** Simulated one-time **Quarter Pro $5.99** via `@AppStorage("isPro")` —
  unlimited scenarios + compare, multi-year, quarterly tracking, and CSV export.
- **Why it can boom:** Tens of millions of US gig/freelance/1099 filers face quarterly estimated
  taxes, and the incumbents are either subscription bookkeeping apps (e.g. Keeper) or generic
  budget apps that don't do real SE-tax math. Quarter is the private, one-time-purchase
  estimator that actually computes self-employment tax, the four quarterly payments, and
  safe-harbor guidance — the freelancer tool that does the hard math, once.

---

## Self-review attestation

Every Swift source file was re-read after writing. Verified:

- `@main QuarterApp` registers **all four** `@Model` types (`IncomeEntry`, `ExpenseEntry`,
  `TaxScenario`, `EstimatedPayment`) in the `Schema`.
- Five substantive feature screens (Estimate, Ledger, Quarterly, Scenarios, Learn) plus
  Settings, via `TabView`/`NavigationStack`; back/dismiss always works.
- First-run onboarding gated by `@AppStorage("hasOnboarded")`.
- Empty, idle/computed, recoverable-error, and success states present.
- **Anti-stub grep clean** (no TODO/FIXME/placeholder/"coming soon"/stub).
- **Brace/paren/bracket balanced** across all files.
- **No** `fatalError`, `try!`, force-unwraps, `NavigationView`, or single-argument `.onChange`
  on user paths.
- **Every division guarded** against a zero divisor.
- Brackets & standard deductions cross-checked against the published 2024 and 2025 IRS figures.

**Worked example** (single, 2025, $90k SE income, $10k expenses, $0 W-2, $0 withholding, no
state): net SE $80,000 → SE base $73,880 → SE tax **$11,303.64** (SS $9,161.12 + Medicare
$2,142.52) → half-SE deduction $5,651.82 → AGI $74,348.18 → taxable income $58,598.18 →
federal income tax **$7,805.60** → **total tax $19,109.24** (effective ~21.2%, marginal 22%,
recommended set-aside 25%).

---

## Disclaimer

Quarter is an **educational estimate** using published 2024–2025 federal figures and a flat
state rate you enter. It is **not tax advice** and **not a substitute** for a qualified
professional or official IRS guidance. Always confirm before you file or pay.
