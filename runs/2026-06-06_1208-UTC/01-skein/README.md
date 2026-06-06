# Skein

**A calm companion for what's on your needles.** A knitting & crochet project tracker with multi-counter row counting, a yarn stash catalog, and gauge/yardage calculators — for crafters who are tired of janky, ad-laden counter apps.

**Audience:** knitters and crocheters who keep several works-in-progress going and want to track rows, repeats, gauge, and whether their stash is enough — all offline, no account.

**Design language:** Orbioom (liquid glass, mist→ink gradients, restrained green for live/active state).

## Features

- **Projects** — full CRUD. Each project owns its craft, yarn, needle/hook, gauge, status (active / hibernating / finished / frogged), notes, and one or more counters. Filter by status; summary strip of active / WIP / finished.
- **Counters with repeat tracking** — any number per project, each with a custom step and an optional repeat length that shows "Repeat 2 · step 3 of 8".
- **Full-screen counting session** — a large tap target to add rows without losing your place, a repeat progress ring, a segmented switch between a project's counters, reset, and an optional keep-screen-awake mode.
- **Yarn stash** — searchable, weight-filterable catalog with per-skein yardage/grams and live totals (total yards, skeins, count).
- **Gauge calculator** — turns stitches/rows per 4 in (10 cm) plus a target size into cast-on stitches and row counts; can prefill gauge from any project; reports finished width for a stitch count.
- **Yardage estimator** — estimates yarn needed for a piece by Craft Yarn Council weight (0–7) with an adjustable safety margin, then checks it against a stash yarn ("you have enough" / "short ~N yd, ≈2 more skeins").
- **Settings** — units (inches/centimetres), default craft, haptics, keep-awake; reload sample data; delete all (with confirmation).
- Onboarding gated by a persisted flag; empty, loading-free, success, and error-safe states throughout; light + dark; Dynamic Type; VoiceOver labels; Reduce Motion respected.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Skein.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

**Free signing:** select the target → Signing & Capabilities → your personal team. No paid account needed for the simulator or a personal device.

## Tech notes

iOS 17+, SwiftUI 5, MVVM-ish with value-type math engines. Persistence is **SwiftData** (`Project`, `Counter`, `StashYarn`); small prefs/flags in `UserDefaults` via `@AppStorage`. Gauge and yardage math live in a pure, testable `GaugeMath` enum. No third-party dependencies, no network, no API keys.

## Self-review

Re-read every Swift file by hand: imports, iOS 17 SDK symbols, `@Model`/`@Query`/`@Bindable`/`modelContainer` wiring, `NavigationStack`/`navigationDestination`/`fullScreenCover`/sheet bindings all type-check. No `TODO`/`FIXME`/`placeholder`/stub markers. No force-unwrap, `try!`, or unguarded division on user paths (the only `try!` is the bootstrap in-memory `ModelContainer` fallback in `@main`, not a user path). Empty/loading/success/error states present; full accessibility and light/dark verified by reading the views.
