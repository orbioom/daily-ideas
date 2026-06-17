# Upkeep

A calm, private, offline **home-maintenance scheduler** for iOS 17. Upkeep helps homeowners
stay ahead of the recurring upkeep that quietly keeps a home healthy — furnace filters, smoke and
CO batteries, gutters, water-heater flushes, seasonal HVAC service, dryer vents, caulking, and the
rest — with smart due/overdue scheduling, a single home-health score, cost tracking, and a
ready-made starter checklist.

No account. No cloud. Everything lives on the device.

## What it is

Tools like HomeZada and Centriq are clunky, cloud-bound, and account-gated. Upkeep is the opposite:
a focused, dependable, "home" app with a teal-slate identity, soft cards, a clear health gauge, and
Dynamic Type throughout. You open it, see exactly what's overdue and what's coming, tap **Done**,
and get back to your day.

## Full feature list

- **Home (Due)** — a circular home-health gauge (priority-weighted % of active tasks not overdue)
  plus live **Overdue / Due today / Due soon / Later** buckets. One-tap **Done** opens a quick
  completion sheet (date, optional cost & minutes) and advances the task's next due date. Calm
  empty state.
- **Tasks** — every task grouped by home system (HVAC, Plumbing, Exterior, Safety, Appliances,
  Lawn & Garden, Electrical, General) with full CRUD. A complete **cadence editor**: every N
  days / weeks / months / years, or **seasonal** (spring/summer/fall/winter). Swipe to delete,
  tap to view detail and history.
- **Starter checklist** — a built-in factory of **24** standard homeowner tasks (furnace filter
  q3mo, smoke/CO batteries q6mo, gutters spring + fall, water-heater flush yearly, HVAC tune-ups
  spring & fall, dryer vent yearly, caulk/seal yearly, GFCI tests, winterize faucets, and more).
  "Add starter checklist" is idempotent — it never duplicates tasks you already have.
- **Schedule** — an upcoming timeline of due tasks grouped by month, color-coded by urgency, with
  swipe-to-complete and tap-through to detail.
- **Insights** — Swift Charts with a loading state: completions over time (bar), on-time rate,
  completion streak, plus **Pro** spend-by-system (bar) and an upcoming + annualized **cost
  forecast**.
- **Settings** — hemisphere (N/S, drives seasonal scheduling), due-soon window (1–60 days),
  currency symbol, **reminders** toggle (capped, on-device local notifications with graceful
  authorization), haptics toggle, About, **Unlock / Restore Pro**, **Export (CSV)**, and **Load
  sample data**.
- **First-run onboarding** gated by a persisted flag, which also seeds realistic sample data so
  every screen is populated immediately.
- **Accessibility** — semantic Dynamic Type fonts, accessibility labels/values on the gauge,
  charts, and rows, decorative icons hidden, Reduce-Motion fallback for the gauge animation, and
  first-class light **and** dark mode via a dynamic theme.

## Run steps

1) `brew install xcodegen` (one-time).
2) In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3) Open `Upkeep.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing:** set your Apple ID team in Signing & Capabilities; the bundle id is
`com.orbioom.upkeep`.

## Tech notes

- **SwiftUI 5 / iOS 17 only.** `NavigationStack` + `TabView`, `.navigationDestination`/sheet
  bindings, Swift Charts (`BarMark`), `@Query`/`modelContext`/`@Bindable`.
- **SwiftData** is the source of truth. Three `@Model` types — `HomeSystem`, `MaintenanceTask`,
  `CompletionLog` — all registered in the `Schema([...])`, with `@Relationship(deleteRule: .cascade)`
  on both parent relationships. Enums (`CadenceType`, `Season`) persist as raw strings with computed
  accessors. The `ModelContainer` falls back to in-memory storage and then to a calm
  `StoreUnavailableView` rather than crashing.
- **Pure engines**, fully unit-testable and UI-free: `ScheduleEngine` (next-due, seasonal &
  hemisphere-aware date math, bucketing, freshness, home-health score), `CostEngine` (spend by
  system & year, upcoming and annualized forecast), `StatsEngine` (completions over time / by
  system, on-time rate, weekly streak). All divisions and empty collections are guarded.
- **Money** is formatted via `Decimal`; `Decimal(string:)` is always guarded, never force-unwrapped.
- **Local notifications** are optional, request authorization gracefully (no crash if denied), and
  are capped at 16 scheduled reminders.
- **Crash-proofing:** no force-unwraps on user paths, no `try!`/`as!`/`fatalError`, guarded array
  indexing, and safe date math throughout.
- **Monetization:** one-time **Upkeep Pro — $3.99** (simulated via `@AppStorage("isPro")`,
  StoreKit-ready in spirit). Free covers scheduling, done-logging, the home-health score, the
  starter checklist, and basic stats. Pro unlocks unlimited active tasks (free cap = 10), cost
  tracking & forecast, reminders, and CSV export.
- **Why it can boom:** homeowners are high-intent and routinely forget recurring upkeep that costs
  thousands when skipped, yet the incumbents (HomeZada, Centriq) are clunky, cloud, and
  account-bound. Upkeep is a calm, private, seasonal scheduler with cost tracking and a ready-made
  checklist — one-time, offline, and genuinely pleasant to open.

## Self-review attestation

All Swift sources were re-read after writing. Confirmed:

- iOS-17-only APIs; `NavigationStack` everywhere (no `NavigationView`); no `@Previewable`.
- One observation pattern throughout: `AppSettings` is an `ObservableObject`, owned by the `@main`
  app via `@StateObject` and consumed via `@EnvironmentObject` (no `@Observable`/`@StateObject`
  mixing).
- No `.onChange` is used; where present elsewhere it would use the iOS-17 two-parameter form.
- No force-unwrap on user paths, no `try!`, `as!`, `fatalError`, unchecked indexing, or unguarded
  division; `Decimal(string:)` is guarded.
- Seasonal/date math is hemisphere-aware and total (returns sensible fallbacks, never crashes).
- All three `@Model` types are registered in `Schema([...])`.
- No stub words (`TODO`, `FIXME`, `placeholder` outside TextField prompts, `coming soon`, etc.).
- Light & dark mode and Dynamic Type verified across screens; Reduce-Motion fallback on the gauge.

**Swift source files: 36** (under `ios/Upkeep/Upkeep/`).
**Schema models: `HomeSystem`, `MaintenanceTask`, `CompletionLog`.**
