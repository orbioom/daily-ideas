# Iris — calm eye-care & screen-break wellness

A soft, restful iOS app for tired screen eyes: 20-20-20 breaks, guided eye exercises, and gentle vision self-check tools. No ads, no account, no network — everything stays on your device.

## What it is
Screen fatigue affects nearly everyone who works on a device all day: dryness, strain, and a focusing system stuck at one distance. The "eye exercise / eye care" category charts well but is dominated by ad-heavy, cluttered incumbents that nag rather than soothe. **Iris** is the calm, beautiful alternative — a quiet blue-teal interface, a signature focus dot that guides your eyes, full Reduce-Motion support (this is an *eye-comfort* app, so every moving element degrades to a still, text-guided version), and a single fair one-time unlock instead of a subscription.

Audience: anyone with a long screen day — knowledge workers, students, designers, developers.

## Features
- **Today** — an eye-health dashboard with a live "time since last break" ring and a "due now" state, breaks-today vs daily goal, current streak, a primary "Take a 20-20-20 break" button, today's recommended routine, and a recent-activity feed. Empty state for first run.
- **20-20-20 Break** — a full-screen, 20-second calming countdown coaching you to "look ~20 feet away," with a focus target that slowly recedes (still + numeric countdown under Reduce Motion). Completion logs a break and shows a gentle success screen.
- **Exercises** — guided routines grouped by category (Relax / Strengthen / Focus / Dry Eye), a routine detail screen, and a full-screen **player**: a focus dot moving along a figure-8 / near-far / side-to-side / circle path to follow with the eyes, big instruction text, per-exercise countdown, pause/skip, and progress. Reduce Motion → static target + text cues. Logs an exercise session on completion.
- **Insights** — Swift Charts: breaks-per-day bars (with a goal line), an exercise-minutes trend line, streak/totals, and an adherence ring vs your goal. Empty + loading states.
- **Tools** — vision self-check & comfort tools, clearly *not a medical exam*: a Canvas-drawn **Amsler grid** for self-monitoring, a near/far **focus-flexibility** drill, a **blink-rate trainer**, and the break-interval/daily-goal config.
- **Settings** — appearance (System/Light/Dark), haptics, break interval, daily goal, on-Today reminders, Pro unlock, clear-history, and a medical-disclaimer note.
- First-run **Onboarding** gated by `@AppStorage("hasOnboarded")`.

## Substantive core logic
- **`BreakScheduler`** (pure struct) — 20-20-20 timing: time-since-last-break, interval progress, "due now", seconds-until-due, and goal progress. All divisions guarded; interval and goal clamped to ≥1.
- **`StatsEngine`** (pure struct) — breaks/day, current streak (consecutive active days anchored on today or yesterday), total exercise minutes, adherence vs goal, and a daily series for Charts. O(n) bucketed aggregation; every division guarded.
- **`RoutinePlayer`** (`@MainActor ObservableObject`) — a wall-clock state machine stepping through a routine's exercises with per-exercise countdown, pause/resume (banks elapsed time), and skip. Driven by a `Timer` publisher *outside* the view-update cycle; a `TimelineView` separately animates the focus dot.
- **`RoutineCatalog`** — a bundled static catalog of 6 routines across all four categories (~4–6 exercises each), with a free starter routine and a day-rotating recommendation.
- **`GuidedPath`** — pure math mapping an exercise type + time phase to a normalized point/scale (lemniscate figure-8, circle, side-to-side sweep, near/far depth pulse).

## Persistence
Primary data is **SwiftData**: `BreakLog` and `ExerciseSession` `@Model`s, queried with `@Query`, surviving relaunch. `SeedData.seedIfNeeded` plants ~8 weeks of realistic, deterministic history (50+ breaks + sessions, a believable recent streak, mixed routines) on first run so Today and Insights are alive immediately — gated by a flag and an empty store. Small prefs/flags use `@AppStorage`.

## Monetization
One-time **Iris Pro $3.99** (simulated locally via `@AppStorage("isPro")` + `Pro` enum + `PaywallView` + `PaywallReason`). Free = the 20-20-20 break + one starter routine + this week's stats + the Amsler grid. Pro = **all exercise routines, full stats history, all tools**. No real StoreKit, ads, account, or network — StoreKit 2 would wire into `Pro`/`PaywallView` for production.

## Why it can boom
Screen-fatigue eye care is a broad, evergreen wellness need with ad-heavy, mediocre incumbents. Iris is the calm, beautiful, Reduce-Motion-respecting, one-time-purchase version — the app people actually want to open when their eyes hurt.

## Design language
"Restful blue-teal calm" around accent `0x2F86B8`: soft cool gradients, gentle eased motion, a calming focus dot as the signature element, rounded type, lots of breathing room, first-class light + dark via `Theme.dyn` pairs. Critically, **every moving element degrades to a still, text-guided version under Reduce Motion** — appropriate for an eye-comfort app.

## Run
1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. `open Iris.xcodeproj` — select an iOS 17+ simulator and press **Cmd+R**.

**Free signing:** in the target's *Signing & Capabilities*, pick your personal team; the bundle id is `com.orbioom.iris`. No paid account is required for the simulator.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM-ish (pure engines + an `ObservableObject` player), SwiftData persistence, Swift Charts.
- `NavigationStack` only; two/zero-param `onChange`; no iOS-18 APIs; no external dependencies; no network.
- Full accessibility: Dynamic Type, labels/hints/values, decorative imagery hidden, AA-contrast light/dark, and Reduce Motion fallbacks everywhere there is motion.
- Sparse, Settings-gated haptics on break/exercise completion.

## Self-review
I re-read every Swift file as the compiler against the iOS 17 SDK:
- Verified all imports, initializers, modifiers, enum cases and protocol conformances exist and are spelled correctly for iOS 17; `EyeRoutine` is `Hashable`/`Identifiable` for navigation and covers.
- Verified `@State`/`@StateObject`/`@Binding`/`@Environment`/`@EnvironmentObject`/`@Query`/`modelContainer` ownership and wiring; `RoutinePlayer` uses a `nonisolated init` so `@StateObject` construction is clean.
- Confirmed `TimelineView` usage (periodic + animation schedules), the Canvas Amsler grid, the guided animation paths, and that **every** motion has a Reduce-Motion still/text fallback (break target, routine player, focus-flexibility, blink trainer, onboarding, pressable scale).
- Guarded every division and array index on user paths; the only `fatalError` is the documented unreachable in-memory `ModelContainer` fallback. No `try!`/`as!`/force-unwrap on user paths.
- Fixed `CGFloat`/`Double` ternary and arithmetic mismatches found during the read-through (focus target scale, break target scale, blink pacer dimension).
- Anti-stub grep (`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`stub`) returns **clean**; no `NavigationView`; `import Charts` only where used.

**Not a medical eye exam.** Iris supports healthy screen habits; it does not diagnose or treat. See an optometrist for vision concerns. (Stated in Onboarding, Settings, Tools, and routine detail.)
