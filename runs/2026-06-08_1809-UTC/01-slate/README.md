# Slate — time-block day planner

**Slate turns your to-dos into a real timeline so you can see the shape of your day, not just a list.** For anyone who plans by time-blocking (knowledge workers, students, ADHD-friendly planning) and wants something calmer and less busy than the incumbents.

## What it is
A native iOS day planner built around a vertical timeline. You place blocks at real times, see overlaps and free gaps instantly, drop in reusable routines, and track how your time actually went — all on-device.

## Features
- **Timeline planner** — a true vertical day timeline with hour rails, a live "now" line, and side-by-side packing of overlapping blocks (interval-partitioning column layout).
- **7-day strip** to move between days; per-day summary of scheduled time, completion %, free time, and conflict count.
- **Blocks with checklists** — title, category (8 types with color), time, duration, notes, and an optional subtask checklist. Checking off all subtasks completes the block.
- **Agenda** — upcoming blocks grouped by day with per-day net, plus a detail screen that toggles checklist items.
- **Routines** — save blocks you schedule again and again; add one to today or stamp it across all five weekdays in a tap.
- **Insights** — Swift Charts: planned vs completed hours per day (14 days) and a time-by-category donut with legend.
- **Settings** — day start/end hours, default block length, show-completed toggle, haptics, and erase-all. All persisted.
- First-run onboarding (persisted flag), empty/loading/success states, full Dynamic Type + VoiceOver, light/dark, Reduce Motion, sparse haptics.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Slate.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: no paid account needed — select your personal team, it runs on the simulator and on-device with a free Apple ID.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `ScheduleEngine` (layout packing, conflict detection, free-gap finding, day/category stats). Persistence in **SwiftData** (`TimeBlock`, `ChecklistItem`, `BlockTemplate`); small prefs in `UserDefaults`. Design language: **Orbioom** (liquid glass, ink gradient, JetBrains Mono for clock/metrics). No external dependencies; seeded with a realistic day + routines.
- **Monetization:** freemium — core planning free; Pro (subscription) unlocks unlimited routines, widgets/Live Activities, and cross-device sync. Productivity planners (Structured, Sorted) have proven subscription willingness-to-pay.
- **Why it can boom:** time-blocking is a top, proven productivity category; Structured hit the charts. Slate gives the same timeline magic with a calmer design, real conflict/free-time intelligence, and no clutter — the version people wish existed.

## Self-review
Re-read every Swift file by hand. Verified: imports; iOS 17 SDK symbols/modifiers; `@State`/`@Bindable`/`@Query`/`@Environment` ownership; `NavigationStack`/`navigationDestination(for: PersistentIdentifier.self)`/sheet bindings; SwiftData schema + cascade relationship; Charts (`BarMark` grouped, `SectorMark` donut). Anti-stub grep clean (only "placeholder" as a TextField parameter name). No `try!`/force-unwrap/unguarded division on user paths; the only `fatalError` is the documented in-memory container fallback.
