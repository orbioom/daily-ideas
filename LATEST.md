# Latest run — 2026-06-17_0012-UTC

Folder: `runs/2026-06-17_0012-UTC/` — 6 production-ready native iOS apps, all **built** (none deferred).
Each ships a XcodeGen `project.yml` (no hand-written `.xcodeproj`), a real designed 1024 AppIcon
(per-app glyph on a gradient) + AccentColor + LaunchBackground (light+dark), SwiftData persistence,
onboarding/empty/loading/error/success states, ≥3 persisted Settings prefs, full accessibility
(Dynamic Type + VoiceOver + Reduce Motion), first-class light+dark, and a simulated one-time Pro
unlock (StoreKit-ready in spirit). **164 Swift files total** (Spindle 25, Conduit 25, Stub 30,
Recur 28, Parcel 24, Fuel 32).

Self-reviewed compile-by-inspection (each app), then independently audited at the top level across
all six with `runs/_tools/audit.sh` plus cross-app greps: **zero** `try!`/`as!`/`fatalError`/
`NavigationView`/`@Previewable`/`ObservableObject`/`@StateObject`/single-arg `.onChange`; no
force-unwraps on user paths (only the in-memory `ModelContainer` fallback uses `try?`); every
`@Model` registered in its app's `Schema` (verified per app — Spindle 2, Conduit 3, Stub 1, Recur 2,
Parcel 2, Fuel 3, all matching); no duplicate top-level type names per app; every `Chart {}` has
`import Charts`; all six `project.yml` parse as valid YAML and are discoverable by `gen.sh`; every
`Info.plist` and 1024 AppIcon present. (The audit's per-app "MISSING icon" line is a known path
quirk — the PNG correctly lives in the inner `<App>/<App>/Assets.xcassets`.) Parcel's build agent
timed out mid-scaffold (8 files); the top-level agent finished it by hand (engines, all views, app
entry, the 120-question bank, README) and re-audited it clean.

This batch targets **proven, large, monetizable markets the 255-entry registry had not touched** —
two genuinely different casual-game mechanics (Spider cards / Flow-Free path-drawing), two distinct
finance/work tools (a W-2 paycheck calculator and a subscription tracker), a fresh test-prep vertical
(real-estate licensing), and a proven health category (adaptive macro coaching). Checked against
SHIPPED.md: Spider/`Spindle` ≠ Klondike `Palace` / FreeCell `Citadel` / Mahjong `Lantern`;
Flow-Free/`Conduit` is a new connect mechanic (no prior path-drawing puzzle); a W-2 paycheck
calculator/`Stub` ≠ self-employed `Quarter`; an iOS subscription tracker/`Recur` ≠ bills `Remit` /
spending `Tally` (and the old webapp `Renewal`); real-estate exam/`Parcel` ≠ DMV `Permit` / civics
`Citizen`; adaptive macro coach/`Fuel` (planner, not a food diary) ≠ calorie diary `Plate` / weight
trend `Tare`.

## The 6 apps

- **Spindle** — built — `runs/2026-06-17_0012-UTC/01-spindle` — Spider Solitaire: a pure `Codable`
  `SpiderEngine` (1/2/4-suit 104-card deck, 54-card deal + 5 deals of 10, same-suit run moves,
  auto-collect K–A runs to 8 foundations, Microsoft-style scoring, snapshot undo, hint, auto-collect)
  with an `@Observable` `GameViewModel` (double-tap auto-move, wall-clock timer re-anchored on
  scenePhase), SplitMix64 daily/numbered/random deals, `GameResult` + single-row `SavedGame` (JSON
  resume), and five screens (Play / New Game / Stats / How-to-Play / Settings ×8 prefs); SwiftData. —
  **Monetization:** one-time Spindle Pro $2.99 (4-suit, daily archive, extra felt themes, full stats).
  — **Why it can boom:** Spider is a proven evergreen and the top free apps are ad-saturated (users
  resent paying $2/mo just to play solitaire) — Spindle is the calm, ad-free, premium version with
  classic numbered deals and real engine math.
- **Conduit** — built — `runs/2026-06-17_0012-UTC/02-conduit` — Flow-Free-style connect puzzle: an
  `@Observable` `ConduitEngine` (drag-draw pipes, Flow-rule conflict truncation, live coverage %,
  undo/hint/reset) over a **45-puzzle bank** built from Hamiltonian snakes cut into per-color segments
  (guarantees a solvable 100%-coverage solution; all 45 simulation-verified), five packs 5×5–9×9,
  `SavedBoard` resume + date-seeded Daily + streak, and Play / Levels / Daily / Stats / Settings with a
  color-blind mode; SwiftData. — **Monetization:** one-time Conduit Pro $2.99 (Master/Mind-bender 8×8/
  9×9 packs, daily archive, color-blind palettes). — **Why it can boom:** Flow Free is a 100M+-download
  proven mechanic; incumbents are ad-heavy — Conduit is the ad-free, one-time version with a real
  guaranteed-solvable generator and a calm design.
- **Stub** — built — `runs/2026-06-17_0012-UTC/03-stub` — Take-home paycheck calculator + job-offer
  comparator: a pure **Decimal** `PaycheckEngine` (2025 federal brackets per filing status + standard
  deduction, FICA with the $176,100 SS cap + 0.9% additional Medicare, 50-state+DC approximate rates,
  documented pre-tax treatment for 401(k)/HSA/§125 premiums), a live net-per-paycheck hero, a breakdown
  donut with marginal/effective rates, multi-scenario Compare (BarMark), and `PayScenario` CRUD;
  SwiftData (money in Decimal). — **Monetization:** one-time Stub Pro $4.99 (unlimited scenarios +
  3-way compare, full state detail, CSV export). — **Why it can boom:** everyone with a job wants to
  know their real take-home, paycheck/offer calculators are massively used (ADP/SmartAsset), and a
  private native one-time app that does the real bracket+FICA+state math fills the gap.
- **Recur** — built — `runs/2026-06-17_0012-UTC/04-recur` — Subscription & recurring-payment tracker:
  Decimal `CostEngine` (cycle→monthly/annual), a month-end/leap-safe `RenewalEngine` (next/previous
  renewal + upcoming feed), trial-ending alerts, and a `SummaryEngine` (totals, by-category, by-cycle);
  `Subscription` cascades `PriceChange`, seeded with 13 realistic subs; Dashboard (donut) /
  Subscriptions (sort/filter/search/swipe) / Detail+Editor (color + SF-Symbol + price-history
  sparkline) / Calendar+Insights (Charts) / Settings, with capped local renewal+trial reminders;
  SwiftData. — **Monetization:** one-time Recur Pro $3.99 (unlimited subs, push reminders, full
  insights, price logging, CSV). — **Why it can boom:** subscription fatigue is real and the "save you
  money" trackers are themselves subscriptions; Bobby's one-time model is the praised exception — Recur
  is the private, one-time, trial-catching version done with taste.
- **Parcel** — built — `runs/2026-06-17_0012-UTC/05-parcel` — Real-estate license exam prep: **120
  national-portion questions** across 10 topics (each explained), a `SessionBuilder` + `@Observable`
  `ExamSession` with five modes (mock / quick / topic / review / adaptive — SplitMix64 option shuffle +
  mastery-weighted selection), a `ProgressEngine` (readiness / per-topic mastery / pass-rate / streak,
  all division-guarded), instant-feedback study vs deferred mock grading, a full per-question review +
  redo-missed, AVSpeech read-aloud, and Home / Exam / Topics(+browse) / Progress(Charts) / Settings;
  SwiftData. — **Monetization:** one-time Parcel Pro $6.99 (unlimited mocks, adaptive + review, all
  topics, audio, analytics). — **Why it can boom:** real-estate students routinely pay $50–$200+ for
  prep and incumbents are short-window subscriptions (PrepAgent) or ad apps — Parcel is the private,
  native, one-time exam simulator with adaptive weak-area targeting and explanations on every question.
- **Fuel** — built — `runs/2026-06-17_0012-UTC/06-fuel` — Macro & TDEE adaptive coach: a pure engine
  (Mifflin/Katch BMR × activity → TDEE; a %-bodyweight goal rate converted via 7700 kcal/kg with
  safe-rate guardrails + a calorie floor; protein-g/kg macro presets) plus the differentiator — an
  **adaptive TDEE** that re-estimates true expenditure from EMA-smoothed weigh-ins via energy balance
  (`avgIntake − Δweight·7700/days`) and recommends a weekly target change with a rationale — a
  refeed/diet-break scheduler, and a projected finish date; `Profile` / `CheckIn` / `TargetSnapshot`,
  Today (ring + macro bars) / Plan / Check-ins / Insights(Charts) / Settings, kg-lb units; SwiftData. —
  **Monetization:** one-time Fuel Pro $5.99 (adaptive recalibration, refeed scheduler, unlimited
  history, CSV). — **Why it can boom:** MacroFactor proved people pay for adaptive-TDEE coaching, but
  it's a subscription — Fuel delivers the same on-device adaptive math (without a food diary) for one
  purchase.

## Top recommendation

**Stub.** Broadest audience in the batch (essentially everyone who earns a W-2 paycheck or is weighing
a job offer), an instantly-understood value prop ("what's my real take-home?"), and the proven Orbioom
moat — doing the hard math the free web tools fragment or gate, all-`Decimal` and private, for one
purchase. Clear expansion path (multi-state precise tables, hourly/overtime nuances, bonus withholding,
HSA/FSA modeling). **Parcel** is the strongest willingness-to-pay runner-up (a career-investment
audience that already pays real money for subscription prep, beaten with a one-time native app), and
**Spindle**/**Conduit** are the high-volume top-charts plays where ad-free execution wins.

## Research signals worth following next run

- The registry now spans **261 builds**. Proven gaps still open: more **fair casual games** (Spider is
  done now, but Forty Thieves / Pyramid / Tri-Peaks / Golf solitaires, dominoes, Hearts/Spades/Gin
  with AI, bubble-shooter, Kakuro/cross-sums remain), and **"subscription-refugee" finance tools** (a
  rent-vs-buy decision calculator, an HSA/FSA optimizer, a Roth-conversion or RMD planner, a 1099-vs-W2
  comparator that builds on `Stub`'s engine).
- **Test-prep verticals keep paying off** with a fresh question bank on the reusable `ExamEngine`/
  `ProgressEngine` pattern — Permit (DMV), Citizen (civics), now Parcel (real estate). Adjacent
  one-time plays: ASVAB, CDL, NCLEX-style, insurance/series-7, cosmetology/contractor, or a teacher
  (Praxis) exam — same engine, new content.
- **Engine/accuracy moats remain the durable wedge** — Spindle (deal generator + supermove), Conduit
  (guaranteed-solvable Hamiltonian bank), Stub (Decimal tax engine), Fuel (adaptive TDEE) all reinforce
  that doing the hard logic the incumbent gates is what differentiates. Avoid anything resembling our
  own past builds (now 261, heavily covering health/fitness/finance/food/journaling/games/collections/
  test-prep) — keep checking SHIPPED.md first.
