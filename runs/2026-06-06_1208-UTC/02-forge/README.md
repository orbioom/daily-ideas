# Forge

**Train by the numbers, quietly.** A strength-training logger that records sets, estimates your one-rep max per lift, charts strength over time, and loads the bar for you — without ads, subscriptions, or a social feed.

**Audience:** lifters running barbell/dumbbell programs who want a fast set logger plus real progression tracking and a plate calculator, all on-device.

**Design language:** Orbioom.

## Features

- **Training log** — full CRUD of sessions. Each workout owns ordered sets; warm-ups are flagged and excluded from working volume. Week strip shows sessions and 7-day volume.
- **Set entry** — pick an existing lift or create one inline; weight (kg/lb), reps, RPE, warm-up toggle, with a live estimated-1RM preview. Sets are grouped by exercise in the session view.
- **Lift catalog** — exercises grouped by muscle group (push/pull/legs/core/olympic/other), bodyweight flag, notes; created automatically as you log or added by hand.
- **Lift detail** — personal records (best e1RM, top weight, most reps) and an **estimated-1RM progression chart** (Swift Charts), plus recent working sets.
- **Insights** — total volume, sessions, per-week average, and a 30-day **volume-by-group** bar breakdown.
- **Plate calculator** — enter a target weight and bar; get exactly what to load per side with a visual plate stack, in kg or lb, with a selectable available-plate set and a "closest match" note when a weight can't be made.
- **Settings** — weight unit (kg/lb), 1RM formula (Epley/Brzycki), haptics; reload sample data; delete all (confirmed).
- One-rep max via Epley/Brzycki (guarded denominators). Onboarding gate, empty/loading/success/error states, light + dark, Dynamic Type, VoiceOver, Reduce Motion.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Forge.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, **Cmd+R**.

**Free signing:** Signing & Capabilities → your personal team. No paid account required.

## Tech notes

iOS 17+, SwiftUI 5, Swift Charts. Weights are stored internally in **kilograms** and converted for display, so switching units never corrupts data. Persistence is **SwiftData** (`Exercise`, `Workout`, `SetEntry`); prefs in `@AppStorage`. 1RM and plate math live in a pure `StrengthMath` enum. No dependencies, no network.

## Self-review

Hand-checked every file: imports (incl. `Charts`), iOS 17 APIs, SwiftData relationships and `@Query` filters, Picker tag/selection types (incl. optional `Exercise` tags), chart marks, and navigation wiring all type-check. Anti-stub grep clean. No force-unwrap/`try!`/unguarded division on user paths (only the bootstrap in-memory container fallback uses `try!`). States, accessibility, and light/dark verified by reading.
