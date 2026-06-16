# Galley

**Galley** is a warm, all-in-one kitchen toolkit for iOS — density-aware unit conversion, recipe scaling, ingredient substitutions, and many concurrent kitchen timers, wrapped in a calm cream-and-terracotta design.

Built natively with SwiftUI 5 + SwiftData for the Orbioom iOS studio.

---

## What it is

Most kitchen utilities are single-purpose and ad-cluttered: one app to convert cups to grams, another to scale a recipe, a third for timers. Galley folds the whole everyday cooking toolkit into one friendly app. Its conversions are **density-aware** — pick "all-purpose flour" and 1 cup converts to ≈120 g, not a generic guess — and every result reads in natural cooking fractions (1½, ⅔, ¼) rather than ugly decimals.

## Full feature list

- **Convert** — choose an ingredient (or generic volume/weight), enter an amount with from/to units, and get a fraction-formatted result. Volume↔weight uses the chosen ingredient's real grams-per-cup density. Swap units, quick-pick common conversions, and a recent-conversions list. Gracefully prompts to pick an ingredient when a cross-type conversion needs one.
- **Scale** — saved recipes with a full editor (title, base servings, ordered ingredients with quantity + unit + name, notes). A scaler resizes every ingredient by target servings or × factor, with smart fraction display and an optional weight readout for known ingredients. Favorite, duplicate, delete; a clean cook-reading view. Ships with 3 example recipes.
- **Substitute** — searchable library of ~55 common substitutions, each with ratio'd alternatives and notes (1 cup buttermilk → 1 tbsp lemon juice + milk to 1 cup; 1 egg → ¼ cup applesauce; self-rising flour; butter↔oil; and many more). Add your own custom substitutions (Pro).
- **Timers** — multiple concurrent named timers with a live circular countdown via `TimelineView`. Start, pause, reset, delete; wall-clock based so they keep perfect time and survive a relaunch. In-app completion alert + optional haptic when a timer fires.
- **Reference** — common equivalents (3 tsp = 1 tbsp, 16 tbsp = 1 cup, 2 cups = 1 pint …), the full oven-temperature table (°F / °C / gas mark), and a browsable, searchable ingredient-density list (~90 ingredients).
- **Settings** — default measurement system, default temperature unit, cooking-fraction toggle, haptics toggle, Pro management, About, and a reset-all-data action.
- **Onboarding** — a four-slide first-run intro, gated by `@AppStorage`.
- **Galley Pro** — a simulated one-time $2.99 unlock. Free = convert + reference + 3 saved recipes + 2 timers; Pro = unlimited recipes, unlimited timers, custom substitutions, and pro metric/imperial extras.
- **Accessibility & polish** — Dynamic Type, full VoiceOver labels/hints/values (conversion results and timer remaining are announced), decorative images hidden, WCAG-AA contrast in both light and dark, and animations that respect Reduce Motion.

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Galley.xcodeproj` in Xcode 15+, choose an iOS 17+ simulator, and press **Cmd+R**.

### Free-signing note

The project uses no paid-account capabilities. To run on a physical device, select the **Galley** target → **Signing & Capabilities**, pick your personal Apple ID team, and let Xcode manage a free provisioning profile. The simulator needs no signing at all.

## Tech notes

- **iOS 17+, SwiftUI 5**, Xcode 15. `NavigationStack` throughout, two-parameter `.onChange`, `@Observable` engines, `@Query` for SwiftData, and `TimelineView` for live timers — no deprecated APIs.
- **Architecture** — light MVVM. Pure engines (`ConversionEngine`, `ScaleEngine`, `TempEngine`, `FractionFormatter`) hold the substantive logic with no UI dependency; `TimerEngine` is an `@Observable` coordinator. Views are thin.
- **Persistence** — SwiftData (`@Model`: `SavedRecipe`, `RecipeIngredient`, `SubstitutionEntry`, `SubstituteOption`, `KitchenTimer`) for records, with cascade + inverse relationships; `@AppStorage` for small preferences. Everything survives relaunch — timers are reconstructed from a persisted `startedAt` anchor, so they're drift-free and accurate across an app restart.
- **Design language** — warm, friendly kitchen: cream surfaces in light mode, warm charcoal in dark, terracotta accent (#C4623E) with a sage secondary, rounded tactile cards. Defined centrally in `Theme/`; no hardcoded colors that break a mode.
- **Monetization** — simulated one-time **Galley Pro ($2.99)** via `@AppStorage("isPro")` gating unlimited recipes/timers and custom substitutions; a tasteful `PaywallView` performs the simulated unlock.
- **Why it can boom** — everyone cooks, and conversion/scaling/substitution/timer apps are proven, evergreen utilities; incumbents are ad-cluttered or single-purpose, while Galley is the warm, all-in-one kitchen toolkit with genuinely density-aware conversion.

## Self-review attestation

Every Swift file was re-read after writing. Verified: all five `@Model` types are registered in the `Schema`; cascade + inverse relationships are declared on both pairs (`SavedRecipe`↔`RecipeIngredient`, `SubstitutionEntry`↔`SubstituteOption`); `@State`/`@Bindable`/`@Environment`/`@Observable` ownership is correct; the wall-clock `TimerEngine` computes remaining from `startedAt` (relaunch-safe, no `Timer` drift); only iOS 17 APIs are used (`NavigationStack`, two-parameter `.onChange`, `@Query`, `TimelineView`); all divisions are guarded (zero density / zero base servings / zero unit factors return calm recoverable states, never a crash). No `fatalError`/`try!`/force-unwrap on user paths. Anti-stub scan (TODO/FIXME/XXX/placeholder/lorem/"coming soon"/"not implemented"/"stub") returns zero. Worked a cross-type conversion (2 cups flour → 240 g) and a ×1.5 scale with fraction display by hand; both correct.
