# Mettle — fitness-challenge program tracker

**One line:** A calm, private tracker for fixed-length fitness challenges like 75 Hard, where a day only counts when every required task is done.

**Problem & audience:** "75 Hard" and its cousins are a genuine viral phenomenon — millions attempt them every year — yet the apps built around them are subscription-bloated, ad-heavy, and obsessed with social feeds and streaks-as-pressure. A challenge is fundamentally different from a habit tracker: it's a fixed-length program with multiple required daily tasks, where the day only "passes" if you complete all of them, and (in hard mode) missing any day resets you to Day 1. Mettle is for the broad middle of people doing these programs who just want a beautiful, on-device, free-core tool to do the work — no feed, no paywall to start.

## Full feature list
- **Today** — for the active challenge: Day N of M, a big task-completion ring, and the full daily checklist. Simple tasks toggle; measured tasks (water, minutes, pages) get an inline +N quick-add with a progress bar and a clear button, satisfied when value meets target. A "Day passed" success state with a success haptic when all tasks are done; a calm "streak broken — restart at Day 1" state for broken hard-mode runs; a "challenge complete" celebration at the end. Empty state directs you to Challenges when nothing is active.
- **Challenges** — built-in programs (**75 Hard**, **75 Soft**, **30-Day Reset**) plus your own custom challenges, as cards showing duration, task count, a hard/soft badge, and an ACTIVE badge. Only one challenge is active at a time; starting one deactivates the rest and begins a fresh run today.
- **Challenge detail** — tasks, duration, and mode explained; live progress ring when active; Start / Restart / Stop actions, plus Edit and Delete for custom challenges.
- **Challenge editor** — create or edit a custom program: name, summary, duration stepper (1–365), hard/soft toggle (defaulting to your preference), and add/remove/reorder daily tasks with an icon picker and an optional target + unit to make a task measured.
- **Progress** — for the active challenge: a month-style day grid colored by status (passed, today, missed, future), four stat tiles (current day, days passed, best streak, completion %), and a Swift Charts bar chart of passed days per week against the weekly target. Empty state when nothing is active.
- **Settings** — interface haptics, default hard mode for new challenges, week-starts-Monday (affects the grid alignment), a destructive "reset active challenge progress" with confirmation, and active-challenge status with an on-device/version footer.
- First-run onboarding (persisted), empty/success/broken states throughout, light & dark, Dynamic Type, VoiceOver labels/values/hints, Reduce Motion, sparse gated haptics.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Mettle.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free signing:** no paid Apple Developer account needed — select your personal team under Signing & Capabilities and run on the simulator or your own device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `ChallengeEngine` (day-index math, per-day and overall status, progress, streaks). Persistence in **SwiftData** (`Challenge`, `ChallengeTask`, `DayLog`, `TaskTick`); small prefs in `UserDefaults` via `@AppStorage` (keys prefixed `mettle.`). Swift Charts for the weekly chart. Orbioom design language (liquid glass, ink-gradient buttons, JetBrains-style mono numerals, green reserved for live/success).
- **Monetization:** freemium — free with one active challenge and the built-in programs; Pro unlocks unlimited custom programs, reminders, and photo notes / full history.
- **Why it can boom:** 75 Hard is a proven viral phenomenon, incumbents are subscription-bloated and social-heavy, and Mettle wins by being calm, private, and free at its core.

## Self-review
Re-read every Swift file by hand: imports resolve (`SwiftUI`, `SwiftData`, `Charts`, `Foundation`, `UIKit`); all SwiftUI/SwiftData/Charts APIs used exist in the iOS 17 SDK; `@Model` relationships with `@Relationship(deleteRule:inverse:)`, `@Query` with `#Predicate`/sort key paths, `@Bindable`, and `@Environment(\.modelContext)` type-check; `NavigationStack` + `navigationDestination(for: Challenge.self)`, `NavigationLink(value:)`, and `sheet` bindings are correct; `ProgressBoardView` avoids the `SwiftUI.ProgressView` name clash; all initializers clamp inputs and there are no force-unwraps / `try!` / `fatalError` on user paths (only the in-memory `ModelContainer` fallback, mirroring the reference app). The anti-stub grep (TODO/FIXME/XXX/placeholder/lorem/coming soon/not implemented/stub) is clean. `project.yml` is valid YAML naming the real `Mettle` sources and `Info.plist`.
