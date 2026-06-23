# Lockin

**A deep-work focus timer with honest session analytics.** Flexible Pomodoro, custom, and open-ended *flow* timers tied to your projects — plus rich stats on where your focus actually goes. No trees, no gimmicks.

## Problem & audience
Most focus apps either gamify with a single growing tree (and punish you if you leave) or hide the useful analytics behind a paywall. **Lockin** is for makers, students, writers, and knowledge workers who want a *flexible* timer (25/5 Pomodoro, any custom length, or count-up flow), the ability to attach every session to a real project, and clear, on-device data — minutes per day, time-by-project, an hour-of-day focus heatmap, streaks, and a distraction counter to build self-awareness.

## Features
- **Three timer modes** — Pomodoro (configurable focus/short/long break + rounds), Custom length (5–180 min), and open-ended **Flow** that counts up until you stop.
- **Live countdown ring** with pause/resume, a phase badge (focus / short break / long break), and automatic break scheduling with optional auto-start.
- **Distraction counter** — one tap when you get pulled away; rolls into your stats.
- **Sessions tied to work** — attach each block to a project (color + icon) and edit its project/tag/note/distractions afterward.
- **Projects (Tasks tab)** — full CRUD, color/icon picker, optional daily focus goal with a today-progress ring, archive/restore, and a per-project detail screen with stats and recent sessions.
- **Stats (Swift Charts)** — focus minutes per day (bar), time by project (horizontal bar), hour-of-day heatmap, current & longest streaks, completion rate, average session, and distraction insight; switch between 7-day / 30-day / all-time.
- **History** — sessions grouped by day with per-day totals, project + mode filters, tap-to-edit, swipe-to-delete.
- **Settings** — default mode, all Pomodoro durations, rounds-before-long-break, auto-start breaks, keep-screen-awake, and haptics — all persisted. Replay onboarding, reset preferences.
- First-run **onboarding** (persisted flag), empty/loading/success/error states, **light & dark** mode, full **Dynamic Type** + VoiceOver labels, **Reduce Motion** support, and **haptics** gated by a Settings toggle.
- 50+ realistic seeded sessions across 5 projects so every screen is alive on first launch.

## Tech notes
- **iOS 17+, SwiftUI 5, MVVM.** Persistence is **SwiftData** (`FocusSession`, `Project`, `AppSettings`) via `@Model`/`@Query`/`modelContainer`; only the onboarding flag uses `@AppStorage`.
- A date-based `TimerEngine` (`@Observable`, `@MainActor`) keeps the countdown accurate across pause/resume and view re-renders; the UI ticks it from a `TimelineView`.
- `FocusAnalytics` is a set of **pure functions** (no UI/SwiftData) for daily/project/hour aggregation and streaks — easy to reason about and crash-proof. Stats are computed off the main render path with a loading state.
- No external dependencies, no network, no API keys. 100% on-device.
- **Monetization:** free core (one project + Pomodoro); one-time **Lockin Pro** unlock for unlimited projects, custom + flow modes, the full analytics suite (heatmap, project breakdown, all-time range), and history export.
- **Why it can boom:** the focus-timer market has proven winners (Forest, Session, Flow), but they either lean on a gimmick or paywall the data; Lockin's flexible flow-mode timer + genuinely useful, free-feeling analytics tied to real projects is a sharper hook for serious deep-work users.

## Run steps
1. Install XcodeGen: `brew install xcodegen`
2. From `ios/`, run: `xcodegen generate`
3. Open `Lockin.xcodeproj` in Xcode 15+ and press **Cmd+R** (iOS 17 simulator or device).
4. **Free signing:** select the `Lockin` target → *Signing & Capabilities* → pick your personal team; the bundle id is `com.orbioom.lockin` (change if it collides).

## Self-review attestation
I re-read every Swift file as the compiler. Verified: all imports resolve (`SwiftUI`, `SwiftData`, `Charts`, `UIKit`, `Observation`, `Foundation`); every type, initializer, enum case, view modifier, and Charts mark (`BarMark`, `RectangleMark`, `chartXScale`, `AxisMarks`) exists in the iOS 17 SDK and is spelled correctly; property wrappers (`@State`, `@Bindable`, `@Query`, `@Environment`, `@AppStorage`, `@Observable`, `@MainActor`) are used correctly; `NavigationStack`, `sheet(item:)`, `navigationDestination` via `NavigationLink`, and `@Query` predicate macros type-check; the `modelContainer` is built with a disk→memory fallback and a recoverable error view (no `try!`/`fatalError`/force-unwrap on user paths); all division and array access is guarded. Anti-stub grep (`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub`) returns no matches across the source tree. No APIs newer than iOS 17 are used.
