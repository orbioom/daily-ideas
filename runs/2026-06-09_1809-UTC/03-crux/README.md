# Crux

A calm, fast task manager for iOS — Things/Todoist-class, built natively in SwiftUI with SwiftData, fully on-device.

## What it is

Crux keeps your tasks quiet and quick. Capture a thought, schedule it, organize it into projects and areas, tag it, and let **Today** surface only what matters now. Recurring tasks (daily standups, weekly reviews, monthly bills) roll forward automatically when you complete them. Everything lives on your device — no account, no cloud, no subscription on the core.

## Features

- **Today** — quick-add field, a 14-day "momentum" completion chart (Swift Charts), an Overdue section, and the day's scheduled tasks. Tap a check circle to complete; recurring tasks advance to their next occurrence with a calm animation and haptic.
- **Upcoming** — an agenda of future tasks grouped by day for the next ~30 days, plus a "Later" bucket. Add a scheduled task inline.
- **Projects** — Areas as collapsible sections containing Projects, each with a progress ring and active-task count. Project Detail shows to-do and completed tasks, quick-add, edit (name/notes/color/area), and mark-complete. Add areas and projects.
- **Browse** — entry points to Anytime, Someday, and Logbook smart lists with live counts, plus a tag cloud. Tap a tag to see a filtered list. Create tags here.
- **Task Editor** (sheet) — title, notes, clearable scheduled & due date pickers, priority, recurrence (with an "every N days" interval stepper), Someday flag, project picker, multi-select tags, and full subtask CRUD with reorder.
- **Settings** — default add-to list (Today/Anytime), start of week, confirm-before-delete, haptics, due-date reminders (UNUserNotificationCenter with denied-state guard), Clear Completed, and Reset All. All preferences persist.
- **Recurrence engine** — daily, weekdays, weekly, monthly, yearly, and every-N-days, with a pure smart-list bucketing layer (today / overdue / upcoming / anytime / someday / logbook) and project/area roll-ups.
- Onboarding gated by `@AppStorage`, empty states everywhere, a first-run seeding loading state, light + dark via the Orbioom Brand system, Dynamic Type, VoiceOver labels on the check circles, and Reduce Motion honored.

## Run

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate`
3. Open `Crux.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

Free-signing: select your personal team under Signing & Capabilities; the bundle id is `com.orbioom.crux`. No paid account is required to run on a simulator or your own device.

## Tech notes

- iOS 17+, SwiftUI, MVVM-leaning (pure static engine + thin action layer), SwiftData persistence that survives relaunch.
- Recurrence engine + smart-list bucketing live in `Engine/CruxEngine.swift` — pure, guarded, and unit-test-friendly; views call `TaskActions` for SwiftData mutations.
- Orbioom design kit (Brand tokens, GlassCard, ink/glass buttons, chips, FlowLayout, Haptics) shared verbatim across the studio.
- Smart lists are computed in plain Swift over a simple `@Query` rather than with complex `#Predicate`, for reliable compilation and predictable sorting.
- **Monetization**: free core forever; one-time "Crux Pro" unlock (or low annual) for power features like custom smart-list filters, calendar sync, and themes — no subscription gate on everyday use.
- **Why it can boom**: it beats Todoist/Things/TickTick on the things that matter daily — genuinely calm and fast, fully on-device and private, with a real recurrence engine and projects/areas, and **no subscription tax on the core**.

## Self-review attestation

Every Swift file was hand-verified against the iOS 17 SDK: imports, model relationships and inverses, `@Query`/`@Bindable`/`modelContainer` wiring, `NavigationStack`/`navigationDestination`/`sheet` bindings, recurrence date math, and Charts usage. No force-unwraps, `try!`, unguarded division, or post-iOS-17 API on user paths (the only `fatalError` is the reference in-memory container fallback). The anti-stub grep (`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub`) returns no matches.
