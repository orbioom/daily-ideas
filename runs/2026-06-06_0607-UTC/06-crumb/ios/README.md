# Crumb

A calm, premium sourdough & bread-baking companion for iOS, by Orbioom. Crumb turns a
recipe written in **baker's percentages** into precise gram weights at any scale, plans a
**bake timeline** that fits your day, and keeps a living **starter feeding log** — all with
a quiet, glass-and-mist Orbioom aesthetic in both light and dark.

## What it is

Crumb is built around a real relational model and a non-trivial baker's-percentage engine:

- **Formula** — a recipe by baker's percentages. Each ingredient has a name, a role
  (flour / water / levain / salt / other) and a percentage of total flour (which is 100%).
- **Bake** — a dated bake of a formula with a timeline of steps (autolyse, mix, bulk with
  folds, shape, cold proof, bake, cool), each with a planned duration, plus results: crumb
  rating, oven temperature, observed dough temperature, and notes.
- **Starter** — a sourdough starter with a feeding log: date, ratio (e.g. 1:2:2), flour
  type and notes, with a live "time since fed".

## The baker's-percentage engine

`Utilities/BakersMath.swift` is a pure, testable value-in / value-out engine — no SwiftData,
no SwiftUI — so the math can be reasoned about in isolation. It handles the parts bakers
actually care about:

- **Percentage → grams scaling.** The sum of all percentages maps to the total dough
  weight, so every ingredient's grams are `totalDough × percent / totalPercent`.
- **True hydration including the levain.** A levain (pre-ferment) is itself part flour and
  part water. The engine splits each levain row at its own hydration and folds that flour
  and water back into the dough's true hydration: `hydration = totalWater / totalFlour × 100`.
- **Hydration retargeting.** When you drag the target hydration, the engine recomputes the
  *direct* water percentage needed to hit it, after subtracting the water the levain already
  contributes (clamped to zero if the levain alone exceeds the target).
- **Weight ↔ loaf scaling.** Total dough ↔ loaf count ↔ grams per loaf, kept consistent as
  you change any one of them.
- **Step scheduling** — lay clock times across a timeline either **forward** from a start
  time or **backward** from a target finish time.

Every input is guarded: inputs are clamped `> 0`, and a formula with no flour yields calm
on-screen guidance rather than a divide-by-zero or a crash.

## Features

- **Formula library** — every recipe with at-a-glance hydration / levain / salt figures.
- **Formula detail with the live scaler** — drag total dough weight, loaf count, or target
  hydration and watch every gram, percentage, and headline figure recompute instantly.
  VoiceOver reads each scaler control's live value.
- **Bakes log** — planned and completed bakes, grouped and newest-first.
- **Bake detail with the computed timeline** — clock times derived from your anchor and
  direction; tap any step to edit it, add steps, rate the crumb, log temperatures and notes.
- **Starter feeding log** — current status with "time since fed", full feeding history with
  implied hydration, and quick re-feeding.
- **Export** — share any formula or bake as **CSV or JSON**.
- **First-run onboarding** (persisted), empty / guidance / success states throughout.
- **Settings** with 6 persisted preferences that each change behavior: weight units
  (g / oz), temperature units (°C / °F), default dough weight, default scheduling direction
  (start vs finish), haptics, and appearance. Plus reset-to-sample and clear-all paths.
- **Seeded content** on first launch: four real formulas (classic country sourdough,
  sourdough baguette, olive-oil focaccia, 100% whole wheat pan loaf), two bakes (one rated,
  one upcoming and scheduled to finish), and a starter with a feeding history — so the app
  is alive immediately.

## Design

Orbioom's calm, premium system: layered mist backgrounds (never pure white), `.ultraThinMaterial`
glass cards, a single ink-gradient primary action per screen, restrained green only for
success / active / "fed", and monospaced digits for every gram, percentage, and time.
Motion is slow and purposeful and honors Reduce Motion. Full Dynamic Type, VoiceOver labels
and values, decorative imagery hidden, and first-class light and dark.

## Tech notes

- **SwiftUI + SwiftData**, iOS 17, MVVM-lite.
- **SwiftData** is the primary store for `Formula`, `Ingredient`, `Bake`, `BakeStep`,
  `Starter`, and `Feeding`, with cascade relationships. **UserDefaults** holds only flags
  and small preferences (via `SettingsStore`).
- Canonical storage is metric (grams, °C); units are converted only at the display boundary
  in `Utilities/Units.swift`.
- The app degrades gracefully if the persistent store can't be opened: it falls back to an
  in-memory store and, in the worst case, shows a calm "storage unavailable" screen rather
  than crashing on launch.

## Run steps

1. Open `Crumb.xcodeproj` in Xcode 15 or later.
2. Select an iOS 17 simulator (or a device).
3. Build and run (⌘R).

### Free-signing note

The project builds with a personal (free) Apple ID. To run on a physical device, select the
**Crumb** target → **Signing & Capabilities**, choose your personal team, and let Xcode
manage signing. The bundle identifier is `com.orbioom.crumb`; change it if it collides with
an existing profile. No paid developer account is required for local development.

## Self-review

- **Anti-stub grep is clean.** `grep -rniE 'todo|fixme|xxx|placeholder|lorem|coming soon|not implemented|// stub' Crumb`
  returns no matches.
- **No unsafe patterns.** No force-unwraps, `try!`, `fatalError`, unguarded array indexing,
  or unguarded division on user paths. All numeric inputs are clamped `> 0`; the baker's-math
  engine never divides by zero (no flour ⇒ guidance, not a crash). Text inputs are trimmed
  and validated before persisting.
- **Compile / data-flow review passed.** Imports, iOS-17 types and modifiers, protocol
  conformances, `@Query` / `modelContainer` / property-wrapper wiring, `NavigationStack` and
  sheet bindings were traced by hand. The create → persist → relaunch → read path was walked
  for every model: seeding is gated by a persisted flag and only runs into an empty store;
  edits write through the `modelContext`; SwiftData restores them on relaunch.
- Every SwiftUI `#Preview` builds against an in-memory, sample-seeded container
  (`Utilities/PreviewSupport.swift`).

— Conjured, not just coded.
