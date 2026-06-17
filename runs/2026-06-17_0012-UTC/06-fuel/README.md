# Fuel — Macro & TDEE Coach

**Fuel** is a native iOS 17 SwiftUI app that computes your calorie and macro
targets for **cutting, maintaining, or a lean bulk** — then *adaptively
recalibrates your real TDEE* from your weekly weigh-ins. It is the MacroFactor
"secret sauce" (adaptive expenditure) as a one-time purchase, with **no
subscription** and **no food diary**. Fuel is a planner/coach, not a logging app.

## What it is

You build a profile (sex, age, height, weight, optional body-fat, activity,
goal, rate, diet style). Fuel shows your daily calorie target on a bold ring,
your protein/carb/fat split as three bars, and a transparent BMR → TDEE → target
breakdown. Each week you log a weigh-in; Fuel smooths the noise, estimates your
*actual* expenditure, and recommends a new target with a plain-English rationale.

## Full feature list

- **Today / Dashboard** — calorie-target ring, three macro bars (grams + %),
  current phase pill (cut/maintain/bulk + weekly rate), EMA trend weight vs goal,
  weekly change, days-to-goal, a "next check-in due" nudge, and a trend chart.
- **Plan** — full profile & goal editor: sex, age, height (cm or ft/in), weight
  (kg/lb), optional body-fat (enables Katch-McArdle), activity level, goal, a
  rate slider with **live safe-rate warnings**, diet-style picker with a **live
  macro preview**, and goal weight. Saving recomputes targets, writes a snapshot,
  and shows the math (BMR → TDEE → deficit/surplus → target).
- **Check-ins** — log weigh-ins (weight + optional avg intake + note),
  edit/delete history, raw + EMA trend chart with a goal line, and the
  **adaptive recalibration** card: estimated true TDEE, recommended target change
  with rationale and a confidence level, plus an **Apply new target** button.
- **Insights** — Swift Charts: estimated **TDEE over time** (LineMark), calorie
  **target history** (step Area/Line), **weekly weight-change** bars (BarMark),
  a **macro-split donut** (SectorMark), projected finish dates (your pace vs
  planned pace), and a **refeed / diet-break schedule**.
- **Settings** — weight units (kg/lb), height units (cm/ft-in), BMR formula
  (Mifflin / Katch), default protein (g/kg), calorie rounding (exact/5/10),
  adaptive aggressiveness, refeed cadence (weeks), haptics toggle, CSV export,
  Unlock/Restore Pro, About, and a not-medical-advice disclaimer.

## The engine (pure Swift)

- **BMR** — Mifflin-St Jeor by default; Katch-McArdle (`370 + 21.6 × LBM`) when
  body-fat % is supplied.
- **TDEE** — `BMR × activity multiplier` (sedentary 1.2 … extra 1.9).
- **Goal delta** — rate is `% bodyweight / week`; daily delta =
  `(rate% × weight_kg × 7700) / 7`. Cut/bulk safe-rate guardrails warn past
  ~1%/wk (cut) and ~0.5%/wk (bulk); the target is clamped to a safe floor
  (1200 women / 1500 men, or BMR) with a warning.
- **Macros** — presets (Balanced, High-protein, Low-carb, Keto ~5% carb, Custom)
  with protein anchored as g/kg, a fat minimum (0.6 g/kg), the remainder to
  carbs, and 4/4/9 kcal. All branches guard against negative grams.
- **Adaptive TDEE** — see below.
- **Timeline & scheduler** — projected finish date at observed and planned rates;
  a maintenance diet break every *N* weeks of a cut.

All values are unit-aware: stored canonically in metric, displayed in your units.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Fuel.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: set your Apple ID team in Signing & Capabilities; the bundle id is
`com.orbioom.fuel`.

## Tech notes

- **SwiftUI 5 / iOS 17**, `NavigationStack` + `TabView`, Swift Charts
  (`LineMark`, `BarMark`, `AreaMark`, `SectorMark`).
- **SwiftData** for all primary data (`Profile`, `CheckIn`, `TargetSnapshot`),
  registered in one `Schema`; small prefs/flags via `@AppStorage`/UserDefaults.
- **`@Observable`** view models (`PlanEditorModel`) and app state (`AppSettings`,
  `ProStore`) stored with `@State` and injected via `.environment`.
- Seeds a realistic male cutter + ~11 weeks of noisy weigh-ins on first run so
  every chart and the adaptive logic demonstrate immediately.
- Full accessibility (ring/bars/charts carry labels + values), Dynamic Type,
  light + dark via a cohesive `FuelTheme`, Reduce-Motion fallbacks, and sparse
  haptics gated by a Settings toggle.
- Crash-proof: no `try!`/`fatalError`/`as!`, no force-unwraps on user paths,
  guarded divisions (days, weight, totals), and a safe `Collection[safe:]`
  subscript.

**Monetization:** one-time **Fuel Pro — $5.99** unlocks adaptive recalibration &
apply, the refeed/diet-break scheduler, unlimited check-in & target history,
multi-phase goals, and CSV export. Free includes the full calculator (targets +
macros) and a limited check-in history. (Simulated entitlement, StoreKit-ready
in spirit — `Unlock`/`Restore` flip a persisted flag.)

**Why it can boom:** adaptive TDEE is the one feature that makes calorie targets
actually *work*, and today it's locked behind a recurring subscription elsewhere.
Fuel delivers it for a single $5.99 — a planner that gets smarter every week
without becoming another monthly bill.

## The adaptive-TDEE approach

Fuel uses two strategies on an **EMA-smoothed** weight series (to cut daily
noise). When you log average intake, it computes your true expenditure by energy
balance over a rolling window: `estimatedTDEE = avgIntake − (Δweight_kg × 7700 /
days)`, then re-derives your target from it. When intake isn't logged, it falls
back to a **trend-vs-plan correction**: it compares your observed weekly change
against the planned change and nudges the target by the kcal value of the gap.
Either correction is scaled by your chosen aggressiveness and capped per week, so
the target moves smoothly rather than swinging. Every divide (days, weight,
macro totals) is guarded, and a confidence label reflects how much data backs the
estimate.

## Self-review attestation

Re-read every Swift file: imports present; all types/initializers/modifiers exist
in the iOS 17 SDK; `@Observable` state stored with `@State`/`@Environment` (no
`ObservableObject`/`@StateObject` mix); `.onChange` uses the two-parameter form;
SwiftData models registered in the `Schema`; Charts use iOS-17 marks. No banned
APIs (`try!`, `fatalError`, `as!`), no force-unwraps on user paths, no unguarded
divisions, balanced braces, exactly one `@main`. Light and dark are first-class
through `FuelTheme`; accessibility and Reduce-Motion handled throughout.
