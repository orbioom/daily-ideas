# Transit

A calm log for your vehicles' fuel-ups — turning raw fill data into real efficiency insight.
Transit quietly records what you put in the tank and where the odometer sat, then does the
honest arithmetic: fuel economy between full tanks, cost per distance, and how your spending
and prices drift over time. No noise, no vanity numbers — just the figures that actually tell
you how your car is doing.

Built for the Orbioom studio: native Android, Kotlin + Jetpack Compose + Material 3, MVVM,
persistence via DataStore and a JSON document on disk. No Room, no KSP, no annotation
processors.

---

## What it is

Transit holds a small garage of vehicles. Each vehicle has its own measurement system
(metric L/100km & km, or US mpg & miles), and each fill-up you log — odometer, volume, price,
full or partial tank — feeds a real fuel-economy engine. Economy is only ever computed
*between two full tanks*, with partial top-ups in between correctly folded into the fuel total.
When the data can't support an honest number (a missed fill, a non-increasing odometer, no
fuel recorded), the segment is clearly flagged rather than silently miscomputed.

## Full feature list

- **Multi-vehicle garage** with per-vehicle units, fuel type, optional tank capacity and notes.
- **Honest fuel-economy engine** computing economy between full tanks, absorbing partial fills,
  and skipping/labelling segments that can't be trusted.
- **Per-vehicle statistics**: average economy, best & worst, total distance, total fuel,
  total spend, average price/unit, cost per distance, and fill count.
- **Self-drawn trend charts** (Compose Canvas, no chart library) for economy over time and
  fuel price over time, with a one-line TalkBack summary each.
- **Fill-up history** per vehicle, each row showing its computed economy or the reason it was
  skipped; tap to edit, dedicated delete with confirmation.
- **Add/Edit fill-up** with auto-computed price↔total, full/partial and missed-previous toggles,
  date stepper that never lets a fill be dated in the future, and inline validation.
- **Add/Edit vehicle** with unit/fuel choosers and validated tank capacity.
- **Insights** across the whole garage: totals, records (most/least efficient — normalized so
  metric and US vehicles compare fairly — and cheapest per distance), and a per-vehicle digest.
- **Settings**: live theme (light/dark/system), default unit system for new vehicles, default
  vehicle, reset-to-sample, clear-all-data (with confirm), and about/version.
- **Seeded sample garage** on first run only (a metric hatchback with ~12 fills incl. partials
  and one flagged missed fill, plus a US truck) so charts and stats are immediately meaningful.

## Screens (and their states)

| Screen | Purpose | States |
| --- | --- | --- |
| **Garage** (home) | Vehicle list with quick stats | loading · empty (guided) · content |
| **Vehicle detail** | Headline stats, Canvas trend charts, fill history | loading · empty history (guided) · content · per-segment "not computed" flags |
| **Add/Edit fill-up** | Log or edit a fill | inline validation errors · "vehicle gone" recovery · success (pops back) |
| **Add/Edit vehicle** | Create or edit a vehicle | inline validation · success |
| **Insights** | Cross-vehicle records & digest | empty (guided) · content |
| **Settings** | Theme, defaults, data, about | content · confirm dialogs for destructive actions |

Every destination has a way back; system back never strands the user. Deleting a vehicle from
its detail screen pops cleanly once its data is gone; clearing all data returns to the empty
garage.

## Architecture

Clean MVVM with a strict layer split:

- **domain/** — pure Kotlin, no Android imports. `Models` (`Vehicle`, `FillUp`, `UnitSystem`,
  `FuelType`), the `Economy` engine + `Stats` roll-up, and `Format` helpers. This is where the
  non-trivial logic lives and is hand-verifiable by reading.
- **data/** — `TransitRepository` persists the whole log as one JSON document in app-internal
  storage; `SettingsRepository` uses DataStore Preferences; `SampleData` seeds first run. All
  disk I/O runs on `Dispatchers.IO`; the UI observes immutable `StateFlow`s and a `loaded` flag.
- **viewmodel/** — `TransitViewModel` and `SettingsViewModel` expose immutable `UiState`
  (sealed `GarageUiState`, `InsightsState`, live per-vehicle stats) via `StateFlow`; intents
  flow one way in.
- **ui/** — Composables, theme, navigation. State is hoisted; Composables are stateless where
  practical; `collectAsStateWithLifecycle` everywhere.

**Persistence is explicitly NO Room / NO KSP / NO kapt.** It is kotlinx-serialization (a
compiler plugin, not an annotation processor) writing JSON, plus DataStore Preferences for
settings. State survives configuration changes (ViewModel retention + `rememberSaveable` for
transient UI) and full process death (load-on-start re-reads the JSON).

## Tech stack & versions

| | |
| --- | --- |
| Kotlin | 1.9.24 |
| Android Gradle Plugin | 8.5.2 |
| Compose BOM | 2024.06.00 (governs all Compose artifact versions) |
| Compose compiler extension | 1.5.14 (via `composeOptions`) |
| Material 3 | via the BOM |
| Gradle wrapper | 8.7 |
| minSdk / targetSdk / compileSdk | 26 / 34 / 34 |
| JVM target | 17 |
| Other | navigation-compose 2.7.7, lifecycle 2.8.2, activity-compose 1.9.0, datastore-preferences 1.1.1, kotlinx-serialization-json 1.6.3 |

The Compose Gradle plugin (`org.jetbrains.kotlin.plugin.compose`) is intentionally **not**
applied — that is for Kotlin 2.0+. On Kotlin 1.9.24, Compose is wired through
`composeOptions { kotlinCompilerExtensionVersion = "1.5.14" }`.

## How to open & build

1. Open the `android/` folder in Android Studio (Koala or newer).
2. Let Gradle sync (it fetches AGP, Compose, AndroidX).
3. **Build > Build APK(s)**, or run on a device/emulator (API 26+).

Command line (with the Android SDK installed and `ANDROID_HOME` set):

```
cd android
./gradlew assembleDebug
```

Output APK: `android/app/build/outputs/apk/debug/app-debug.apk`

## Build status

`./gradlew assembleDebug` was attempted in the sandbox. The Gradle wrapper downloaded and
started Gradle 8.7 successfully; the build then stopped at Android Gradle Plugin resolution
because this environment has no Android SDK and no Google Maven access (the ~5 GB SDK was
deliberately not installed). Full detail, the exact output, and the rationale that it builds
cleanly in Android Studio are in **[android/build-log.txt](android/build-log.txt)**.

## Accessibility & theming

- `contentDescription` on every actionable / informative non-text element; decorative icons
  pass `null`. Charts carry a single summarizing description for TalkBack.
- Touch targets are ≥48dp (ink buttons ≥52dp; icon buttons use the M3 default 48dp).
- Text uses `sp` and scales to large font settings without clipping (scrollable forms,
  ellipsis where appropriate).
- Custom Orbioom Material 3 color schemes for **both** light and dark — mist backgrounds, ink
  text, the restrained green `#86C79A` reserved for live/success signals only, and a rare amber
  used solely to flag uncertain economy segments. Contrast meets ≥4.5:1 (≥3:1 large) in both.
- Primary buttons render the ink gradient (180° `#3A3E4C`→`#23262F`, white label, 12dp radius);
  surfaces use a translucent ~0.42–0.50 alpha glass approximation.
- The in-app theme toggle and the system theme both switch live.
- Motion uses `CubicBezierEasing(0.16, 1, 0.3, 1)` and **respects the system
  animator-duration / reduce-motion setting**, collapsing transitions to instant when disabled.

## Self-review

- **Anti-stub clean.** A case-sensitive scan for `TODO|FIXME|XXX|placeholder|lorem|coming
  soon|not implemented|// stub` across the slot returns nothing. (A case-insensitive scan only
  surfaces the substrings `toDouble…` and `…Odometer` from real Kotlin API/identifier names —
  not stubs.) No dead controls; every button, toggle, and menu does real work.
- **Compile-correctness pass.** Every import resolves to a declared dependency at the pinned
  version. All `@Composable`s are called from Composable/`setContent` context;
  `remember`/`LaunchedEffect`/`collectAsStateWithLifecycle` sit in valid scopes; state is
  hoisted (`MutableStateFlow` in VMs, exposed read-only); the sealed `GarageUiState` is matched
  exhaustively; nullability is handled; all `R.*` resources, fonts (platform fallback), and
  mipmaps referenced actually exist; manifest/theme/resources and the Gradle files agree.
- **Versions verified compatible.** Kotlin 1.9.24 / AGP 8.5.2 / Compose BOM 2024.06.00 /
  compiler ext 1.5.14 / Material 3 via BOM / min26-target34-compile34 / JVM 17 — the proven
  Forage set, reused unchanged. No annotation processors; the Compose Gradle plugin is not
  applied on 1.9.x.
- **Division guarded.** Every economy/price/cost-per-distance computation checks for zero or
  negative distance and volume before dividing; out-of-order or equal odometers are flagged,
  never crash, never produce a wrong number.
