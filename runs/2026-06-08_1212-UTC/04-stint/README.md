# Stint

**Track time, bill honestly — a fast, on-device time tracker for freelancers.**

The problem: freelancers need time tracking, but Harvest (post-acquisition) hit users with brutal renewal price hikes, Toggl is great yet requires an account/cloud, and Clockify just cut billable hours and CSV export from its free plan. Stint is the version they wish existed: one-tap tracking, rates per client/project, live earnings, invoice-ready reports — all free and entirely on the device, with no surprise pricing. Audience: freelancers, contractors, consultants, agencies-of-one.

## Features

- **Timer** — a live `TimelineView` stopwatch with project picker and description; one timer at a time; shows running earnings; today's entries and total beneath it.
- **Entries** — grouped by day with per-day and this-week totals; tap to edit (start/end, project, mark still-running), swipe to delete, or add a past block manually.
- **Projects** — clients own projects; set a default rate per client and a custom rate per project; billable/non-billable; per-project tracked totals roll up here.
- **Reports** — This Week / Last Week / This Month with tracked vs billable hours and earnings, a by-project donut + list (Swift Charts), a by-day bar chart, and a one-tap **copy of an invoice-ready text summary**.
- **Rate resolution** — a project uses its own rate if set, otherwise its client's; earnings = hours × effective rate for billable work.
- **Settings** — theme, currency, report rounding (exact/5/15/30 min), haptics, erase-all.
- Onboarding (persisted), empty/loading/success states, Dynamic Type + VoiceOver, light & dark, Reduce-Motion-aware, on-brand icon.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Stint.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team; bundle id `com.orbioom.stint`.

## Tech notes

iOS 17+, SwiftUI 5, MVVM with a pure `TimeEngine` (durations, day/week/month ranges, project/client breakdowns, earnings, rounding). Persistence in **SwiftData** — `Client` → `Project` → `TimeEntry` (a nil `end` means running). Live timer via `TimelineView(.periodic)`. Design language: **Orbioom**. No account, no network.

- **Monetization:** freemium — tracking + reports free; a Pro one-time/low-annual unlock adds CSV/PDF export, more report ranges, and widgets. Who pays: freelancers fleeing per-seat price hikes.
- **Why it can boom:** validated paying audience actively shopping for alternatives after incumbent price hikes and free-plan cuts; "simple, beautiful, on-device, no surprise pricing" is the exact unmet ask.

## Self-review

Re-read every Swift file by hand. Imports resolve; SwiftData `#Predicate` `@Query`, optional-model `Picker` tags, `TimelineView`, and sheet bindings type-check; charts are iOS-17; durations are clamped non-negative; no force-unwraps/`try!`/`fatalError` on user paths. Added `Format.shortTime`. Anti-stub grep clean.
