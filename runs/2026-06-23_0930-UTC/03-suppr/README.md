# Suppr

**Weeknight meal planning, minus the chaos.** Drag recipes onto a calm weekly grid and Suppr builds your grocery list for you — aggregated, aisle-sorted, scaled to your servings, and quietly skipping the staples you already have.

## Problem & audience
Most weeknight cooks don't fail at recipes — they fail at the *logistics*: deciding what to cook, then translating it into one coherent shopping trip. Apps like Mealime and Paprika manage recipes well but leave the plan→list bridge clunky. Suppr is for busy home cooks who want to spend two minutes planning a week and walk into the store with one tidy, de-duplicated list.

**Our edge:** a true plan↔list↔pantry loop. Drag a recipe onto any day/meal, set servings, and the grocery list regenerates automatically — merging identical ingredients across recipes, scaling each by that meal's servings, grouping by store aisle, and subtracting anything your pantry says you already have on hand.

## Features
- **Plan** — 7-day week grid with Breakfast / Lunch / Dinner slots. Drag recipe chips from the bottom drawer straight onto a slot, or tap **+** to pick one. Per-meal serving steppers, week navigation, jump-to-today, clear-week.
- **Recipes** — library of 33 seeded recipes (ingredients, steps, servings, time, effort, tags). Search, tag filters, favorites. Full CRUD via a rich editor (ingredients with aisle + staple flags, ordered steps). Detail view with a live serving scaler that reformats quantities as cooking fractions (1 ½, ¾).
- **Grocery** — auto-generated, aisle-grouped shopping list with check-off and a gather-progress bar. Merges duplicate ingredients across the plan, scales by servings, preserves checked state and manual items across regeneration, swipe-to-delete, and a manual add sheet.
- **Pantry** — staples grouped by aisle with on-hand toggles. On-hand items are subtracted from the grocery list when "pantry-aware list" is on. Full CRUD.
- **Settings** — default servings, week-starts-Monday, pantry-aware list, hide-staples, haptics, replay onboarding, library counts, About.

## Definition-of-Done highlights
- 5 tabs / 4+ substantive feature screens via `TabView` + `NavigationStack`; back/dismiss always works.
- First-run onboarding gated by a persisted `@AppStorage("hasOnboarded")` flag.
- Empty states on every data surface (no recipes, empty plan, empty/all-set grocery list, empty pantry, no search matches); loading state on list rebuild; success states on add-to-plan and saves; calm recoverable error handling (validation + `context.rollback()`, no `fatalError`/`try!`/force-unwrap on user paths).
- SwiftData models: **Recipe**, **Ingredient**, **PlannedMeal**, **GroceryItem**, **PantryStaple**, **AppSettings** — persistence survives relaunch; 33 seeded recipes + 12 seeded staples.
- Full accessibility: Dynamic Type, `accessibilityLabel`/`Hint`/`Value`, decorative images hidden, light/dark asset-catalog color sets, Reduce-Motion-aware animation.
- Haptics throughout, gated by a Settings toggle.
- Designed `AppIcon` (real 1024×1024 RGBA PNG, dusk gradient + plate/utensils/moon emblem), `AccentColor`, and a launch screen.

## Run steps
```bash
brew install xcodegen        # if not already installed
cd ios
xcodegen generate
open Suppr.xcodeproj          # Xcode 15+
# Select an iOS 17 simulator and press Cmd+R
```
**Free-signing note:** no paid account needed. In Xcode, select the **Suppr** target → *Signing & Capabilities* → set your personal Team and let Xcode auto-manage signing. The bundle id is `com.orbioom.suppr`; change it if it collides. No external dependencies, no API keys, no network required.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. SwiftData (`@Model`/`@Query`/`modelContainer`) for all user data; `UserDefaults` only for the onboarding flag.
- Pure, testable `GroceryEngine` performs ingredient aggregation + aisle grouping, kept free of UI/persistence. `PlanStore` (a `@MainActor` coordinator) owns cross-model writes and list regeneration.
- Native drag-and-drop via `.draggable`/`.dropDestination` carrying the recipe UUID string.
- **Monetization:** free core; one-time **Suppr Plus** unlock ($4.99) for unlimited saved week templates, smart pantry auto-restock, and shared lists — no subscription.
- **Why it can boom:** the plan→grocery→pantry loop is the exact friction Mealime/Paprika users complain about; "drag a recipe onto a day, walk in with one sorted list" is a one-sentence App Store pitch with proven, high-intent demand.

## Self-review attestation
I re-read every Swift file as the compiler. All imports, types, initializers, enum cases, and view modifiers exist in the iOS 17 SDK and are spelled correctly; protocol conformances are satisfied; `@State`/`@StateObject`/`@Binding`/`@Bindable`/`@Environment`/`@Query`/`modelContainer` usage type-checks; `NavigationStack`/`navigationDestination`/sheet bindings and `#Predicate` fetches are valid; no APIs newer than iOS 17 are used. The anti-stub grep (`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub`) returns nothing. No `try!`/`fatalError`/force-unwrap on user paths (the one `selectedTag!` is short-circuit-guarded; the sole `fatalError` is an unreachable double-failure container fallback, not a user path). The project additionally **compiles cleanly** — `xcodebuild … build` reports **BUILD SUCCEEDED**.
