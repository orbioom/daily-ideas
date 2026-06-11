# Horizon — FIRE & Coast-FIRE wealth projector

**What it is.** A native, private financial-independence planner for the enormous FIRE/coast-FIRE community, which today lives on ad-covered web calculators (WalletBurst, coastfirecalc) and spreadsheets. Four inputs become the age your money sets you free — with coast-FIRE made visible, scenario racing, and everything inflation-adjusted and on-device (no bank linking, ever).

## Features

- **Dashboard** — animated FI progress ring (respects Reduce Motion), invested / FIRE number / projected FI age tiles; **Coast FIRE card** that flips to a celebration state once growth alone can finish the job, with progress bar and projected coast-crossing age; projection chart (Swift Charts) with ±2 pp confidence band, FIRE rule line and FI-age marker; milestone ladder (Coast → Lean → FIRE → Fat) with reached-state checkmarks; honest assumptions footer.
- **Scenarios** — full CRUD: list with per-scenario FI age + progress, swipe to set primary (star) / duplicate / delete (primary reassigns safely), editor form with steppers, currency text fields, sliders for return/inflation/SWR, **live preview section** (FIRE number, FI age, coast number recompute as you type), field-by-field validation with specific messages.
- **Compare** — multi-scenario projection race on one chart with color legend, head-to-head table (FIRE/coast numbers, FI age), "earliest independence" verdict; empty state until 2+ scenarios exist.
- **Settings** — currency symbol (9 options), compact chart labels, haptics, full methodology write-up, not-financial-advice disclosure.
- One sample scenario seeded on first launch; onboarding gated by persisted flag; Dynamic Type; light/dark; accessibility values on rings, sliders, and milestones.

## The engine (`FireEngine`, pure functions)

- Fisher real return: `(1+nominal)/(1+inflation) − 1`; all projections in today's money.
- FIRE number = spending ÷ SWR; Lean/Fat at 70%/130% of spending; Coast number = FIRE ÷ (1+r)^(years to target).
- Monthly compounding with end-of-month contributions to age 80; FI age found by linear interpolation between yearly samples; coast age by walking the contribution path month-by-month and testing growth-only sufficiency.

## Run

1. `brew install xcodegen` (one-time). 2. In `ios/`, `xcodegen generate` (or `./gen.sh` at repo root). 3. Open `Horizon.xcodeproj` in Xcode 15+, iOS 17+ simulator, Cmd+R.

## Tech notes

- iOS 17+, SwiftUI 5, SwiftData (`Scenario`), pure-function engine fully separated from views, Swift Charts (band AreaMark + multi-series LineMark), `@AppStorage` prefs.
- Design language: "first light" — evergreen mint + dawn gold, serif numerals for money.
- **Monetization:** FIRE adherents are high-income savers who pay readily; one-time Pro (unlimited scenarios + compare).
- **Why it can boom:** coast-FIRE content is a persistent engine on Reddit/TikTok with no good native, private iOS tool; "see the day you can stop saving" is a screenshot people share.

## Self-review

Re-read every Swift file: engine math hand-verified (Fisher conversion, monthly compounding, interpolation bounds, division guards on SWR/empty arrays), SwiftData/`@Query` wiring, chart API usage, sheet/alert bindings, no force-unwraps/`try!` on user paths, anti-stub grep clean.
