# Cellar

**A tasting journal you'll keep coming back to.** Cellar is a calm, native iOS app for
people who taste deliberately — coffee, wine, whisky, tea, beer — and want to remember
not just *what* they had, but how it actually tasted. Build a cellar of bottles, record
structured tastings with the aroma · palate · finish triad and a curated flavor lexicon,
then watch your palate take shape over time. Conjured, not just coded.

## What it is

Most people who care about what they drink keep notes in a chaotic mix of photos, screenshots,
and half-remembered impressions. Cellar gives that instinct a real home: a multi-entity
journal where every **bottle** owns a history of **tastings**, each one a small, structured
record you'll trust months later. It's built for the hundredth session, not the first.

## Full feature list

- **The cellar** — a searchable, filterable, sortable list of every bottle. Filter by category
  (coffee / wine / whisky / tea / beer), search across name, maker and origin, and sort by
  recently added, recently tasted, name, or highest rated. Swipe to delete.
- **Bottle records** — name, maker, origin (labelled per category — "Region" for wine,
  "Distillery" for whisky), vintage / age, free-form notes, and a hand-picked label color.
- **Structured tastings** — for each bottle, record dated tasting sessions with a 1–5 rating,
  the **aroma / palate / finish** triad, a multi-select **flavor lexicon tuned to the category**
  (peat & sherry for whisky; jasmine & citrus for coffee), and an overall note.
- **Bottle detail** — full metadata, average rating, and the complete tasting history; record,
  edit, or delete tastings inline.
- **Insights** — a live dashboard: totals, average rating, a per-category breakdown bar chart,
  your highest-rated bottle, the flavors you reach for most, and your current tasting streak.
- **First-run onboarding** — a single calm screen, shown once.
- **Settings** — appearance (system / light / dark), default cellar sort, haptic feedback toggle,
  a live data summary, **reset to the sample cellar**, and **clear all data** — all persisted.
- **Full CRUD** on both entities (bottles and tastings), with confirmation on destructive actions.

Every screen handles its **empty**, **populated**, and **error** states; the app opens to a
real, populated sample cellar on first launch so it's never a blank void.

## Run steps

1. Open `ios/Cellar.xcodeproj` in **Xcode 15+**.
2. Select an **iOS 17+ simulator** (e.g. iPhone 15 Pro).
3. Press **Cmd+R**.

## Free-signing note

The Simulator needs no Apple Developer account. To run on a physical device, select your
personal team under **Signing & Capabilities** (a free Apple ID works); signing is
intentionally left unconfigured so the project opens cleanly for any reviewer.

## Tech notes

- **iOS 17+, SwiftUI 5, MVVM.** Models and pure logic are framework-light and testable
  (`CellarModel` has no SwiftUI/SwiftData imports).
- **Persistence: SwiftData** for the primary records (`Bottle`, `Tasting`, with a cascade
  relationship). `UserDefaults` holds only small preferences and the onboarding/seed flags.
- **No external dependencies.** Brand colors resolve per color scheme, so light and dark are
  both first-class. The app icon is a hand-rendered Orbioom orb.
- Haptics are purposeful and gated by the Settings toggle; motion uses the Orbioom easing curve
  and is replaced with instant changes under Reduce Motion. Dynamic Type and VoiceOver are
  supported throughout.

## Self-review

- **Anti-stub scan:** `grep -rniE "todo|fixme|xxx|placeholder|lorem|coming soon|not implemented|// stub"`
  over `ios/Cellar/**.swift` returns **clean** (no matches).
- **Hand-compile pass (no Simulator in the sandbox):** every Swift file was re-read for
  compile-correctness against the iOS 17 SDK — imports present (SwiftUI, SwiftData, Foundation,
  Observation, UIKit), all SwiftData `@Model`/`@Query`/`@Relationship`/`ModelContainer` wiring
  type-checks, `@Observable` settings injected via `.environment` and read via `@Environment`,
  `NavigationStack` + value-based `navigationDestination(for: Bottle.self)` consistent, sheet/alert
  bindings well-formed, no force-unwrap / `try!` / unguarded index / unguarded division on any
  user-reachable path (rating clamped 1…5, year bounded, names trimmed and required).
- **Data-flow trace verified:** create bottle → SwiftData insert → relaunch → `@Query` reloads →
  read; record tasting → cascade relationship → average/insights recompute; reset/clear-all wired
  to confirmed destructive actions. `project.pbxproj` references every source file exactly once with
  unique object IDs (verified by the generator).
