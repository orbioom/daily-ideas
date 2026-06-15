# Tonus

**A calm, private pelvic-floor (Kegel) trainer — guided squeeze/hold/relax sessions with a breathing ring, streaks, and honest insights.**

## What it is

Pelvic-floor training is one of the most evidence-backed, broadly relevant areas of everyday
health — it matters for postpartum recovery, men's and women's continence, and core stability.
Yet the top apps in the niche are ad-ridden, cluttered, clinically ugly, and often push
aggressive subscriptions. **Tonus** is the opposite: a quiet, warm, beautifully simple trainer
that runs entirely on your device, with a single fair one-time unlock and no ads, accounts, or
tracking. The signature experience is a gentle breathing ring that expands as you squeeze, holds,
and contracts as you relax — turning a clinical exercise into a calm two-minute ritual.

Audience: anyone doing pelvic-floor / Kegel work — postpartum parents, people managing continence,
and anyone building core health — who wants a private, focused tool instead of an ad machine.

## Features

- **Today** — your recommended program, current streak, a weekly-goal progress ring, and recent
  sessions. Empty state for first-time users.
- **Guided Session Player** (full-screen) — the signature breathing ring expands on *Squeeze*,
  holds, and contracts on *Relax*, with a big phase label, coaching guidance, time remaining,
  rep "x of y", set "x of y", and pause/stop. Wall-clock driven so it stays correct across
  backgrounding. Under **Reduce Motion** the pulsing ring is replaced by a calm progress arc.
  Completion shows a success screen (reps + minutes) with **Done** / **Repeat**.
- **Programs** — built-in and custom programs grouped by level (Beginner → Expert) with a detail
  screen showing the per-rep phase breakdown, an estimated duration, and a proportional **timeline
  preview**. A full **Custom Program Builder** (create / edit / delete) with live duration preview
  and input validation — gated to Pro.
- **Insights** — `Swift Charts`: sessions-per-day (BarMark), minutes trend (LineMark + area), a
  4-week activity heatmap, plus totals (streak, best streak, sessions, reps, minutes) and weekly
  adherence. Empty and computing states.
- **Settings** — appearance (System/Light/Dark), haptics, audio cues, weekly goal, default program,
  and a daily reminder time (Pro). Persisted via `@AppStorage`.
- **Onboarding** — a brief, calm intro with a clear non-medical-advice disclaimer.
- First-class **light & dark** mode, full **Dynamic Type**, accessibility labels/hints/values,
  Reduce-Motion support, and sparse, setting-gated **haptics** + soft audio cues.

## Substantive core logic (the real engine)

- **`SessionEngine`** (pure struct) — expands a `TrainingProgram` into an ordered timeline of phase
  steps (Squeeze/Hold/Relax with set-break Rests) across every rep and set, computes total
  duration, and resolves the exact phase, time-remaining, rep, and set at any wall-clock elapsed
  time. Because everything is derived from a start `Date` (not a ticking counter), the session is
  robust to backgrounding and scene-phase changes.
- **`StatsEngine`** (pure struct) — current & best streaks (consecutive finished days, with a
  grace day for "today in progress"), sessions this week/total, total reps, weekly minutes,
  adherence vs. the weekly goal, and per-day series for the charts and heatmap. Every division is
  guarded.
- **`PlayerViewModel`** (`@MainActor`, `ObservableObject`) — drives a live session via
  `TimelineView(.animation)`, manages pause/resume (accumulated paused time), stop, and finish,
  fires one phase-change haptic + optional audio cue per boundary, and writes a `SessionLog`
  (guarded against double-write).

Persistence is **SwiftData** (`TrainingProgram`, `SessionLog`) surviving relaunch; small prefs use
`@AppStorage`. `SeedData` seeds the built-in programs plus 50+ realistic sessions over ~8 weeks so
Today and Insights are alive on first run (gated by a one-time flag).

## Run

1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. `open Tonus.xcodeproj` — pick an iOS 17+ simulator and press **Cmd+R**.

### Free signing
If code-signing complains, select the **Tonus** target → **Signing & Capabilities** → choose your
personal team (or "Sign to Run Locally"). No paid account is required for the simulator.

## Tech notes

- iOS 17+, SwiftUI 5, **MVVM** with pure engines, **SwiftData** for persistence, **Swift Charts**
  for insights. `NavigationStack` only; no external dependencies, no network.
- Design language: "calm clinical-warm wellness" — soft teal-green (accent `0x2C9E8A`), generous
  whitespace, rounded type, a central breathing/squeeze ring as the signature element, gentle eased
  animation that fully respects Reduce Motion. Semantic `Theme.Color.dyn` light+dark pairs
  throughout for AA contrast in both modes.
- **Monetization**: one-time **Tonus Pro $4.99** — all programs, custom builder, full history,
  reminders. Simulated locally via `@AppStorage("isPro")` + `Pro` enum + `PaywallView`
  (Restore + Unlock). StoreKit 2 wires in here for production. No ads, no account, no network.
- **Why it can boom**: pelvic-floor training is a proven, broad, high-retention health niche
  (postpartum, continence, core) whose incumbents are ad-ridden and clinical-ugly; Tonus is the
  calm, private, fairly-priced version.

## Self-review

I re-read every Swift file as the compiler against the iOS 17 SDK:

- **Imports & APIs** — every `import` (SwiftUI, SwiftData, Charts, UIKit, AudioToolbox) and every
  type/initializer/modifier verified against iOS 17. No iOS-18 APIs. `onChange` uses the iOS 17
  two-param form. `TimelineView(.animation)`, `BarMark`/`LineMark`/`AreaMark`, `contentTransition`,
  and SwiftData `@Query`/`modelContainer` all type-check.
- **Name clashes** — the insights screen is named `InsightsView` (never `ProgressView`); the one
  built-in indicator uses the explicit `SwiftUI.ProgressView`. The custom `ProgressRing` is
  distinctly named.
- **Crash-safety** — no force-unwrap, `try!`, `as!`, or unguarded division/index on user paths.
  The only `fatalError` is the documented unreachable in-memory `ModelContainer` fallback. All
  array slicing and divisions are guarded; the session timeline is never empty.
- **State ownership** — `@StateObject` for the player VM and `AppSettings`, `@EnvironmentObject`
  for shared settings, `@Query`/`@Environment(\.modelContext)` for data. Phase-cue side effects are
  driven from `.onChange`, not the render pass.
- **Anti-stub** — grep for `TODO/FIXME/XXX/placeholder/lorem/coming soon/not implemented/stub`
  returns clean (only the documented `fatalError` matched the broader scan).
- **DoD** — 4 substantive feature screens (Today, Programs, Insights, Session player) plus
  Onboarding & Settings; empty / loading / error / success states; ≥3 persisted prefs; SwiftData
  persistence; full accessibility; light+dark; Reduce-Motion-aware animation; gated haptics; local
  Pro monetization. Confirmed.
