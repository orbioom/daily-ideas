# Portion — recipe nutrition calculator

**One line:** Build a recipe from ingredients and Portion computes the full nutrition label — total and per serving — entirely on-device, for free.

**Problem & audience:** Everyone who cooks and cares about what they eat hits the same wall: working out a recipe's real nutrition is tedious, and the tools that do it are paywalled, web-only, or buried inside a calorie-diary app. Home cooks, meal-preppers, macro-counters, and anyone reverse-engineering a dish want one clean job done well — grams in, nutrition label out. Portion is that focused, native, free tool. It is deliberately not a food diary and not a meal manager; the core is the nutrition COMPUTATION from ingredient grams.

## Full feature list
- **Recipes** — every recipe as a glass card with its per-serving calorie badge and per-serving protein/carbs/fat, a Favorites section, favorite toggle, and an empty state. Tap through to the label; "+" opens the editor.
- **Nutrition label (Recipe Detail)** — big per-serving calories, the four macros, and the whole-recipe totals; a Swift Charts donut of the calorie split (protein/carbs/fat by the 4/4/9 rule) with a legend; %Daily Value bars vs your calorie target; and a per-ingredient list with each ingredient's calorie contribution.
- **Live serving scaler** — a stepper recomputes the per-serving label instantly without touching the stored recipe, with a one-tap "save these servings" action.
- **Recipe editor** — name, servings stepper, notes; add ingredients via a catalog picker (choose quantity + unit, preview live grams and calories before adding); reorder and remove ingredients; validate non-empty name; delete recipe.
- **Foods catalog** — 60+ built-in foods across ten categories with per-100 g calories and macros, searchable and grouped; "+" adds a custom food; built-in foods open read-only, custom foods are editable.
- **Food editor** — add/edit a custom food: name, category, per-100 g macros, and optional grams-per-piece / grams-per-cup household measures; delete custom foods only.
- **Unit conversion** — grams, ounces, tablespoons, plus pieces and cups when the food defines them, all reduced to canonical grams by a guarded pure engine. Ingredients **snapshot** their macros, so editing or deleting a food never silently changes a saved recipe.
- **Settings** — daily calorie target (drives %DV), default unit system (metric/imperial), interface haptics, catalog/recipe counts, "Reset food catalog to defaults", and "Clear all recipes".
- First-run onboarding (persisted), empty/guard/success states throughout, light & dark, Dynamic Type, VoiceOver labels/hints/values, Reduce Motion, sparse haptics.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Portion.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free signing:** no paid Apple Developer account needed — select your personal team under Signing & Capabilities and run on the simulator or your own device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `NutritionEngine` (per-ingredient macros, recipe totals, per-serving scaling, 4/4/9 calorie split, %Daily Value, unit→grams conversion — every division guarded). Persistence in **SwiftData** (`FoodItem`, `Recipe`, `RecipeIngredient` with a cascade relationship; ingredients snapshot macros for stability); small prefs in `UserDefaults` via `@AppStorage` (keys prefixed `portion.`). Swift Charts `SectorMark` donut for the calorie split. Orbioom design language (liquid glass, ink-gradient buttons, JetBrains-style mono numerals, green reserved for live/success).
- **Monetization:** free for a few recipes plus the full core catalog; Pro unlocks unlimited recipes, custom foods, and nutrition-label export/share.
- **Why it can boom:** a cooking + health crossover with no good free native recipe-nutrition calculator — diary apps don't produce recipe labels and recipe managers don't compute nutrition, so Portion owns the focused middle.

## Self-review
Re-read every Swift file by hand: imports resolve (`SwiftUI`, `SwiftData`, `Charts`, `UIKit`); all SwiftUI/SwiftData/Charts APIs exist in the iOS 17 SDK (`SectorMark` with `innerRadius`/`angularInset`/`cornerRadius`, two-parameter `onChange`, `.topBarTrailing`, `TextField(value:format:)`, `Stepper(value:in:)`, `searchable`). `@Model`/`@Query`/`@Bindable`/`modelContainer` wiring type-checks; `@Query` sort key paths (`\Recipe.createdAt`, `\FoodItem.name`) are valid; `RecipeIngredient.recipe` inverse + `.cascade` delete rule match. Sheet and navigation bindings type-check; the food picker passes its selection back via a closure. No force-unwrap/`try!`/`fatalError` on user paths — the only `fatalError` is the in-memory `ModelContainer` fallback (mirrors the reference app). All divisions are guarded (servings via `max(1,…)`, calorie split returns zero when total kcal is 0, `dailyValuePercents` guards zero references). Anti-stub grep (TODO/FIXME/XXX/placeholder/lorem/coming soon/not implemented/stub) is clean. `project.yml` is valid YAML naming the real `Portion` sources and `Info.plist`.
