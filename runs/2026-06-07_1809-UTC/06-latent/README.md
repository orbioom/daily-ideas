# Latent

A calm, native iOS 17 SwiftUI darkroom companion for developing black-and-white
film at home. Save your film + developer recipes (base develop time at 20 °C),
then for each run enter the real chemistry **temperature** and any **push/pull** —
Latent computes the adjusted development time, runs a relaunch-safe multi-phase
process timer (Develop → Stop → Fix → Wash) with agitation reminders, and logs
every session. On-device only.

Built for the Orbioom studio. _"Conjured, not just coded."_

## Features

- **Recipes** — full CRUD over film/developer recipes. Each detail screen shows
  the phase plan, a temperature-compensation chart + table (dev time at
  18/20/22/24 °C), recent sessions, and a **Develop now** shortcut.
- **Develop** — pick a saved recipe or enter ad-hoc details, set the chemistry
  temperature, push/pull and EI, and watch the four phase durations update live.
  Then a full-screen **process timer**: big mono countdown, progress ring,
  agitation cues, next-phase preview, pause/skip/cancel. On completion it offers
  to save a session (rolls, rating, notes).
- **Log** — every past run, newest first, with insights (most-used film and
  developer, total rolls). Detail view edits rating/notes and deletes.
- **Reference** — a time–temperature explainer with a chart, the push/pull factor
  guide, and an embedded catalog of ~12 common film+developer base times you can
  turn into recipes with one tap.
- **Settings** — Haptics, Appearance (System/Light/Dark), Temperature units
  (°C/°F), default agitation interval, keep-screen-awake, library counts,
  Erase-all (guarded), and About.

## The relaunch-safe timer

The timer never trusts a wall-clock tick as its source of truth. When a run
starts, `TimerEngine` computes the **absolute end `Date`** of the current phase
and persists the full ordered plan, current phase index, end date, and paused
state as JSON in a single `@AppStorage` string. On appear / relaunch it
reconstructs the remaining time from that end date and *catches up* across any
phase boundaries crossed while the app was backgrounded or closed. A 1 Hz
`Timer.publish` heartbeat only drives the visible redraw. Reduce Motion is
respected: a numeric countdown and a linear `MeterBar` are always shown; the ring
is purely decorative.

## Engine math (`DevEngine`)

- **Temperature factor:** `exp(−0.081 · (tempC − baseTempC))` ≈ −8 %/°C warmer
  (shorter time), +8 %/°C cooler (longer time); exactly 1.0 at the base temp.
- **Push/pull factor:** anchored multipliers — −2 ×0.72, −1 ×0.85, 0 ×1.0,
  +1 ×1.25, +2 ×1.5, +3 ×2.0; clamped to −2…+3, linearly interpolated between
  anchors for generality.
- **Adjusted develop time:** `round(baseTimeSec · pushFactor · tempFactor)`,
  clamped to a 30 s minimum. Stop/fix/wash carry from the recipe.
- Helpers build the four-`Phase` plan and a temperature what-if table for the
  charts.

## Architecture

- **SwiftData** for `Recipe` and `DevSession` (cascade relationship, snapshotted
  session fields so the log stays correct if a recipe changes/deletes).
- **`@AppStorage`** for all preferences and the timer state blob.
- Pure, testable `DevEngine`; a `@MainActor` `TimerEngine` observable object
  shared via the environment so a run survives tab switches and relaunch.
- Orbioom `Brand` design system; light + dark first-class; mono type for all
  numbers and times; motion via `Brand.ease()`.

## Project layout

```
ios/Latent/
  LatentApp.swift              @main, ModelContainer
  Models/                      Recipe, DevSession (pre-provided)
  Utilities/                   DevEngine, FilmCatalog, TimerEngine (pre-provided),
                               SampleData, Formatting, Haptics
  Theme/Brand.swift            design system (pre-provided)
  Views/
    RootView.swift             onboarding gate + TabView
    Onboarding/                OnboardingView
    Recipes/                   RecipesView, RecipeEditorView, RecipeDetailView
    Develop/                   DevelopView, DevelopSetupView, TimerView, SaveSessionView
    Log/                       LogView, SessionDetailView
    Reference/                 ReferenceView
    Settings/                  SettingsView, AboutView
    Components/                shared primitives (pre-provided)
```

## Build

The project uses XcodeGen (`ios/project.yml`). Generate and open:

```
cd ios && xcodegen generate && open Latent.xcodeproj
```

Target: iOS 17.0+. No third-party dependencies (uses SwiftUI, SwiftData, Charts).
