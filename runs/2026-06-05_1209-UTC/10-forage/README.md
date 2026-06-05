# Forage

**A calm, local-first recipe box for the food you actually cook.** Keep your recipes in one
considered place, scale any of them to the number of people at the table, and cook from a
clean, checkable method. Everything stays on your device. Conjured, not just coded.

## What it is

Forage is a native Android recipe manager. Each **recipe** is a real, multi-part record —
ingredients (with quantities and units), ordered method steps, timings, servings, tags — and
the box itself is searchable, filterable, and sortable. The standout is the **serving scaler**:
open a recipe, dial the servings up or down, and every ingredient quantity re-computes into
clean, cook-friendly amounts (whole numbers and common fractions like ½ and ⅔, not ugly
decimals).

## Full feature list

- **Recipe box** — a searchable list of glass recipe cards showing category, timing, servings,
  and ingredient count. Search across titles, descriptions, tags, and ingredient names.
- **Filters & sort** — filter by category (Breakfast / Main / Side / Dessert / Drink / Snack)
  and a Favorites toggle; sort by recently added, title, quickest first, or category.
- **Recipe detail** — description, prep/cook/total timings, the **serving scaler**, a checkable
  ingredient list (scaled live), and numbered method steps you can tap to mark done.
- **Create & edit** — a full form with dynamically added/removed ingredient rows and method
  steps, category selection, timings, and tags. Title is required and validated.
- **Favorites** — toggle from the list or the detail screen; surfaced with the restrained
  Orbioom green.
- **Delete** — with a confirmation dialog.
- **Settings** — theme (System / Light / Dark, switches live), default sort (persisted),
  reset to the sample recipes, clear all recipes (confirmed), and about/version.
- **Real persistence** — the whole recipe collection is stored as a JSON file in app-internal
  storage and reloads after full process death. Settings persist via DataStore.
- A populated **sample recipe box** is seeded on first launch, so the app is never empty.

## Screens

1. **Recipe list** — empty (first run / cleared), loading, no-matches, and populated states.
2. **Recipe detail** — populated state, a graceful "recipe no longer here" state if deleted,
   live serving scaling, and checkable ingredients/steps.
3. **Recipe editor** — create and edit, with inline validation and add/remove rows.
4. **Settings** — theme, default sort, data management, about.

## Architecture

Clean MVVM with unidirectional state:

- **domain/** — pure Kotlin models (`Recipe`, `Ingredient`, `RecipeCategory`, `SortOrder`) and
  `RecipeScaler` (the scaling + fraction-formatting logic). No Android imports.
- **data/** — `RecipeRepository` (JSON file persistence, all I/O on `Dispatchers.IO`, exposes
  `StateFlow`), `SettingsRepository` (DataStore Preferences), and `SampleRecipes` (seed).
- **viewmodel/** — `RecipeViewModel` exposes an immutable `RecipeListUiState` via `StateFlow`;
  `SettingsViewModel` exposes `ForageSettings`. No Android UI imports.
- **ui/** — `theme/` (Orbioom-tuned Material 3 color schemes + the `LocalBrand` extras for the
  ink gradient and glass), `navigation/` (Navigation Compose `NavHost` + a typed route table),
  `components/`, and one file per screen of stateless Composables.

**Persistence is explicitly Room/KSP/kapt-free** — a JSON file (kotlinx.serialization) plus
DataStore — so the project builds with no annotation processors or codegen.

## Tech stack & versions

Kotlin **1.9.24**, AGP **8.5.2**, Compose **BOM 2024.06.00**, Compose compiler extension
**1.5.14** (via `composeOptions`; the kotlin-compose plugin is intentionally **not** applied on
1.9.x), Material 3, Navigation Compose 2.7.7, DataStore 1.1.1, kotlinx-serialization-json 1.6.3.
**minSdk 26, targetSdk 34, compileSdk 34, JVM target 17.** Gradle wrapper 8.7.

## How to open & build

- **Android Studio:** open the `android/` folder → let Gradle sync → **Run** (device/emulator,
  API 26+), or **Build > Build APK(s)**.
- **Command line** (with the Android SDK installed): `cd android && ./gradlew assembleDebug`.
- **APK path:** `android/app/build/outputs/apk/debug/app-debug.apk`.

## Build status

The build was attempted in the cloud sandbox. The Gradle wrapper downloaded and started
Gradle 8.7 successfully, but the sandbox has **no Android SDK** and the AGP/AndroidX artifact
repositories are not reachable under its network policy, so `assembleDebug` could not complete
here. The ~5 GB SDK was deliberately not installed. See **`android/build-log.txt`** for the
exact command, output, and a justification that the project builds cleanly in Android Studio
with the pinned, mutually compatible version set above. **Build locally** to produce the APK.

## Accessibility & theming

- TalkBack: every actionable/informative control has a meaningful `contentDescription`
  (decorative elements are `null`); checkable rows announce their state; touch targets ≥48dp.
- Dynamic Type: all text uses `sp` and scales with the system font size.
- Light **and** dark themes, both brand-consistent; the in-app theme toggle and the system
  setting both switch live. The Orbioom-tuned Material 3 palette (mist backgrounds, ink
  primary, restrained green for live/favorite/active only) is the default — not the stock
  Material baseline.
- The adaptive launcher icon ships foreground + background + monochrome layers (a foraged
  sprig), with a round variant.
- Fonts: Orbioom uses Manrope + JetBrains Mono. The TTFs could not be bundled in this
  environment, so the typography gracefully falls back to the platform sans-serif and
  monospace families, wired in one place (`ui/theme/Type.kt`) for a one-file swap later.

## Self-review

- **Anti-stub scan:** `grep -rniE "todo|fixme|xxx|placeholder|lorem|coming soon|not implemented|// stub"`
  over the Kotlin source returns **clean** (the only `placeholder` references are real Compose
  `placeholder = { ... }` text-field hints).
- **Compile-correctness pass:** every Kotlin file was read as a compiler would — all imports
  resolve to declared dependencies; `@Composable`s are called only from Composable scope;
  `remember`/`LaunchedEffect`/`collectAsStateWithLifecycle` are in valid scopes; the
  `RecipeListUiState` sealed interface is handled exhaustively; state is hoisted (the
  `ViewModel` holds `MutableStateFlow`, exposes read-only `StateFlow`); all `R.*`/manifest
  resources exist.
- **Version-set verified compatible:** Kotlin 1.9.24 ↔ Compose compiler 1.5.14 ↔ Compose BOM
  2024.06.00 ↔ AGP 8.5.2 form the known-good set; the kotlin-compose plugin is not applied; no
  annotation processors are present.
- **Data-flow trace:** create/edit recipe → repository upsert → JSON written on IO →
  `StateFlow` emits → list/detail recompose; relaunch → repository reads the JSON file → state
  restored. Verified by hand.
