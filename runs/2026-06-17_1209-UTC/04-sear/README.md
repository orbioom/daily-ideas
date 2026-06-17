# Sear — live-fire BBQ & smoking companion

## What it is

Sear is a native iOS 17 app for people who cook over live fire — grillers and smokers.
It bundles the four things a backyard pitmaster actually reaches for, with none of the
ads, accounts or clutter of the popular meat apps:

- **A real doneness guide** — recommended pull temperatures by cut and doneness, with
  USDA-safe minimums noted, plus the smoker/grill temp, approximate minutes per pound,
  rest time, and a wood pairing for every cut.
- **A live cook timer** — a relaunch-safe wall-clock timer, a phase timeline
  (preheat → cook → stall → wrap → pull → rest), a stall hint while smoking, big
  current-vs-target temperature numerals with a live doneness state, and "done by" /
  "rest until" estimates.
- **A rub keeper** — built-in classics (Classic SPG, Memphis Dust, and more) plus your
  own recipes, with a scale-by-batch slider and copy-a-classic-to-edit.
- **A cook log** — every cook saved with its result rating, notes and a temperature
  curve, feeding a stats screen.

This is **live-fire grilling and smoking** — not sous-vide. There is no pasteurization
math; the guide reflects USDA-safe minimums and common chef pull temperatures.

Everything is offline, on-device (SwiftData), and there is no account.

## Full feature list

**Cook (live)**
- Big live elapsed timer driven by a stored start `Date` through `TimelineView`,
  re-anchored on `scenePhase` so it survives backgrounding and relaunch.
- Current internal temp vs target with a live doneness classification
  (climbing / almost / pull it / resting / past target).
- Phase timeline highlighting the current phase, derived from elapsed time and
  temperature progress; stall/wrap phases only appear for smoking.
- Stall hint ("the stall — consider wrapping") when smoking and the climb slows in the
  68–74 °C / 150–165 °F band, gated by a Settings toggle.
- "Done by" and "rest until" estimates.
- Quick "+ Log temp" entry, "Start resting", and "Mark done (rate it)".
- Empty state inviting you to start a cook.

**Cooks**
- Sections for Active, Planned and History.
- New Cook flow: pick protein → cut (auto-fills target temp, smoker temp and a wood
  suggestion from the guide), set weight/method, start now or save as planned.
- Cook detail with the temperature curve, result and notes; start a planned cook or
  jump into live tracking; swipe to delete.

**Guide**
- Searchable doneness reference grouped by protein, with a protein filter.
- Per-cut detail: pull temps by doneness (USDA-safe flagged), smoker temp, time/lb,
  rest, wood pairing and a tip. Chef-level temps and a reverse-sear calculator are Pro.

**Rubs**
- Built-in classics seeded on first launch, plus full create / edit / delete.
- Scale-by-batch slider that scales ingredient quantities.
- Duplicate any rub to edit your own version.

**Stats** (Swift Charts)
- Summary cards, cooks-by-protein (bar), by-method (bar), ratings over time (line),
  favorite woods (donut). Loading state while computing; empty state before any data.

**Settings** (all persisted, all functional)
- Temperature unit °C / °F, weight kg / lb, default cooking method, stall-alert toggle,
  haptics toggle, About, Unlock/Restore Pro, Export, Load sample data.

**Onboarding** — three pages, gated by a persisted `hasOnboarded` flag.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Sear.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: set your Apple ID team in Signing & Capabilities; the bundle id is
`com.orbioom.sear`.

## Tech notes

- **iOS 17 / SwiftUI 5 only.** `NavigationStack` + `.navigationDestination`, `TabView`,
  Swift Charts (`BarMark`, `LineMark`, `SectorMark`, `RuleMark`, `PointMark`).
- **SwiftData** is the source of truth. `@Model` types: `Cook`, `TempLog`, `Rub`, all
  registered in the app's `Schema([Cook.self, TempLog.self, Rub.self])`. `Cook` has a
  cascade relationship to `TempLog`. Enums are stored as their `rawValue` strings and
  exposed via computed accessors; ingredients are a SwiftData-supported `[String]`.
- **Observation framework throughout.** A single `@Observable AppSettings` is created
  with `@State` at the app root and shared via `.environment`; views read it with
  `@Environment(AppSettings.self)` and bind with `@Bindable`. No `ObservableObject`.
- **Relaunch-safe timer.** Elapsed time is always recomputed from the stored `startDate`
  (never accumulated), rendered via `TimelineView(.periodic)`, and re-anchored on
  `scenePhase == .active`.
- **Temperatures are canonical in Celsius (Double)** and converted to °F for display
  per the unit setting; weights are canonical in kilograms.
- **Crash-proofing.** No force-unwraps, `try!`, `as!`, or `fatalError` on user paths; a
  safe `Collection[safe:]` subscript; all divisions guarded (e.g. rise-rate, progress);
  the `ModelContainer` falls back to in-memory and finally to a calm
  `StoreUnavailableView` rather than crashing.
- **Accessibility.** Semantic/Dynamic-Type fonts, accessibility labels/values on
  controls and charts, decorative images hidden, Reduce Motion respected in onboarding
  animations, WCAG-AA dynamic colors in light and dark mode.
- **Haptics** are sparse and gated by the Settings toggle.

**Monetization:** one-time **Sear Pro** unlock at **$3.99** (simulated via an
`@AppStorage("isPro")` flag with a demo unlock + Restore; StoreKit-ready in spirit).
Free tier is fully usable: the complete doneness guide, one live cook at a time, the
cook log, basic stats and all built-in rubs. Pro adds more than one active cook at once,
unlimited custom rubs, the advanced guide (chef doneness levels + reverse-sear
calculator) and export.

**Why it can boom:** Grilling and smoking is a massive mainstream hobby with high
willingness to pay, but the popular meat apps are ad-laden, subscription-gated or ugly.
Sear gives a genuinely useful live cook timer, a real USDA/chef doneness guide, a rub
keeper and a cook log — one-time price, fully offline, no account.

## Self-review attestation

Every Swift file was re-read after writing. Verified:

- **51 Swift source files** under `ios/Sear/Sear/`, one primary type per file (a couple
  of small private helper views live beside their owner).
- All three `@Model` types (`Cook`, `TempLog`, `Rub`) are registered in the
  `Schema([...])` in `SearApp.swift`.
- iOS-17-only APIs; `NavigationStack` (no `NavigationView`); no `@Previewable`.
- A single observation pattern (`@Observable` + `@Environment` + `@Bindable`); no
  `ObservableObject`/`@StateObject`.
- Every `.onChange(of:)` uses the iOS-17 two-parameter closure.
- No `TODO`/`FIXME`/`placeholder`/stub language; every control wired to real behavior.
- No force-unwrap, `try!`, `as!`, `fatalError`, unchecked array index or unguarded
  division on user paths (verified by grep).
- Relaunch-safe wall-clock timer (stored `Date` + `TimelineView` + `scenePhase`
  re-anchor); empty / loading / success / calm-error states present.
- Light and dark mode via a dynamic-color `Theme`; Dynamic Type and accessibility
  labels throughout.
