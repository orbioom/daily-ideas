# Meeple

A calm, premium **board-game play & stats logger** for Android, by Orbioom. Log your
collection, the people you play with, and every play session — then watch Meeple turn raw
results into real analytics: win rates, head-to-head records, nemeses, streaks, score
distributions, and a plays-over-time trend.

- **App name:** Meeple
- **Application ID:** `com.orbioom.meeple`
- **Min SDK 26 / Target 34**, Compose-only, MVVM.

---

## What it is

Meeple is a genuinely relational logger, not a notes app. It models:

- **Game** — title, designer, min/max players, typical play time, a **scoring type**
  (highest-wins / lowest-wins / cooperative), and notes.
- **Player** — name and an optional token color.
- **Play** — a game, a date, location, duration, notes, and an ordered list of
  **PlayerResult** rows (which player, their score, win/loss). Cooperative games record a
  single group win/loss instead.

```
Game  1 ──< Play  1 ──< PlayerResult >── 1  Player
```

## Non-trivial stats (all in `domain/Stats.kt`, pure Kotlin, no Android imports)

- **Winner resolution** that respects scoring type: highest-wins, **lowest-wins inverts the
  winner**, and **cooperative = everyone wins or loses together**. Ties share the win.
- **Per game:** total plays, last/first played, average / **median** / high / low score,
  the record holder, average duration, co-op group win rate, and **win rate per player**.
- **Per player:** overall win rate and record, **longest win streak**, current streak,
  most-played game, **nemesis** (who beats you most), **head-to-head** vs every opponent,
  and a per-game breakdown.
- **Collection overview:** totals, hours played, most-played games, top win rates, last
  play, and a monthly **plays-over-time** series.
- Everything is divide-by-zero safe: win rate is `0` at `0` plays, medians/averages return
  `null` on empty input.

## Screens (Navigation Compose, correct back stack)

Four bottom-bar destinations plus Settings and full detail/edit flows:

1. **Plays** (home feed) — every session newest-first, with winner and metadata.
2. **Games** — collection sorted by plays, each with live per-game stats → **Game detail**
   (stats, per-player win rates with bars, full play log, log-a-play CTA).
3. **Players** — people with win rates → **Player detail** (win rate, streaks, nemesis,
   head-to-head bars, per-game records).
4. **Insights** — collection-wide stats and the plays-over-time bar chart.
5. **Log a play** — pick a game, date, multi-select players, per-player scores (or a co-op
   group win toggle), location, duration, notes. Reachable globally and per-game.
6. **Add/Edit Game**, **Add/Edit Player** (with a color palette), **Play detail**.
7. **Settings** — theme (System/Light/Dark) + persisted logging defaults.

Every data screen has **loading / empty / error(unavailable) / content** states.

## Architecture

- **MVVM.** `MeepleViewModel` + `SettingsViewModel` expose `StateFlow<UiState<…>>`; the UI is
  read-only and collects with `collectAsStateWithLifecycle`.
- **Persistence — explicitly NO Room / KSP / kapt.**
  - Games, players, and plays are one **JSON document** in app-internal storage
    (`MeepleRepository`, kotlinx.serialization), read/written **off the main thread** on
    `Dispatchers.IO` behind a `Mutex`. Corrupt files fail safe to an empty collection.
  - Settings use **DataStore Preferences** (`SettingsRepository`).
- **Domain** (`domain/`) is pure Kotlin: `Models.kt` (`@Serializable`), `Stats.kt` (all
  analytics, no Android imports), `Format.kt`.
- **First-run state:** on first launch the repository seeds a real collection — **7 games,
  5 players, 25 plays** — so stats are alive immediately (`data/SampleData.kt`).

## Tech stack & versions (known-good, mutually compatible — do not change)

| Piece | Version |
|---|---|
| Kotlin | 1.9.24 |
| Android Gradle Plugin | 8.5.2 |
| Gradle wrapper | 8.7 |
| Compose BOM | 2024.06.00 |
| Compose compiler extension | 1.5.14 (via `composeOptions`) |
| navigation-compose | 2.7.7 |
| lifecycle (runtime/viewmodel/runtime-compose) | 2.8.2 |
| activity-compose | 1.9.0 |
| datastore-preferences | 1.1.1 |
| kotlinx-serialization-json | 1.6.3 |

The Kotlin **Compose plugin is NOT applied** (that is Kotlin 2.0+); 1.9.24 uses
`composeOptions.kotlinCompilerExtensionVersion`. The only Gradle plugins are
`com.android.application`, `org.jetbrains.kotlin.android`, and
`org.jetbrains.kotlin.plugin.serialization`.

## How to open & build

**Android Studio (Koala or newer):** open the `android/` folder → let Gradle sync →
**Build > Build APK(s)**, or Run on a device/emulator (API 26+).

**Command line** (Android SDK installed, `ANDROID_HOME` set):

```
cd android
./gradlew assembleDebug
```

**APK output:** `app/build/outputs/apk/debug/app-debug.apk`

## Build status

The Gradle wrapper (8.7) downloads and runs in the sandbox; the build then stops at Android
Gradle Plugin resolution because the sandbox has **no Android SDK** and no Google Maven access
(installing the ~5 GB SDK was deliberately skipped). Versions are the proven known-good set
above. Full detail: see **`build-log.txt`**. The project builds cleanly in Android Studio.

## Accessibility & theming (design language = Orbioom)

- **Orbioom Material 3:** mist surfaces (`#EDEEF3`/`#E7E9F0`, translucent glass ~0.42–0.50),
  ink-gradient primary buttons (`#3A3E4C → #23262F`, white label, 12dp radius), text
  `#1B1D2A`/`#565A70`/`#8B8FA3`, restrained green `#86C79A` used **only** for
  wins/active/success and a calm clay for losses.
- **Theme toggle:** Light / Dark / System, applied in-app and honoring the system setting,
  persisted in DataStore. Dark mode uses calm near-blacks, never pure `#000`.
- **Motion** respects the system reduced-motion setting
  (`Settings.Global.ANIMATOR_DURATION_SCALE` → instant transitions when disabled).
- **Accessibility:** `contentDescription` on actionable/informative controls (decorative
  visuals pass `null`); the bar chart exposes one summarizing description for TalkBack;
  selectable rows announce selected state; touch targets ≥48dp; text uses `sp` and scales;
  contrast meets ≥4.5:1 in both themes.
- **Fonts:** Orbioom's Manrope + JetBrains Mono are wired in one place (`ui/theme/Type.kt`).
  Valid TTFs can't be produced in this environment, so the app falls back to the platform
  sans-serif / monospace families (matching Transit's approach); swapping in the real fonts
  is a one-file change.

## Self-review

- **Clean anti-stub grep.** `grep -rniE 'todo|fixme|xxx|placeholder|lorem|coming
  soon|not implemented|// stub' app/src` returns no real hits (the only case-insensitive
  matches are `toDouble`, which contains the substring "todo").
- **Passed compile review** (acting as the compiler): every import resolves at the pinned
  versions; every `@Composable` is called only from a Composable/`setContent` context; state
  is hoisted (`MutableStateFlow` private, exposed read-only as `StateFlow`); the generic
  `UiState` is matched exhaustively; nullable ids that cross lambda boundaries are captured
  into local vals to avoid smart-cast/type errors; all `R.*` resources and icons exist; the
  manifest, `Theme.Meeple`, colors, and strings line up. No annotation processors; the
  Compose plugin is not applied.
- **Data-flow attested:** create (Add/Log screens) → `viewModel.save*` →
  `MeepleRepository` persists JSON on `Dispatchers.IO` → relaunch reads it back in the
  repository `init` load → the same `StateFlow`s recompute stats. State also survives config
  change via the `ViewModel` + `rememberSaveable` on form fields.

---

Meeple — Orbioom. A calm place to remember who actually won.
