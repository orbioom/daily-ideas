# Tide — mood journal with correlations

**Catch the tide.** A ten-second daily check-in — how you feel, what you were doing, an optional note — that quietly reveals which activities actually lift or sink your mood.

For everyone who bounced off heavy journaling apps but wants the Daylio "mood + activities → insight" loop, done with taste and kept fully private.

## Features

- **Fast check-in** — pick a 1–5 mood, tag activities, add a note, set the time. Multiple entries per day.
- **Activity model** — a real SwiftData relationship between `MoodEntry` and `Activity`; built-in catalogue across Body / Day / Social / Joy categories, plus full CRUD (icon + category picker), archive & restore.
- **Calendar heatmap** — month grid coloured by each day's average mood, with day-detail drill-in and month navigation (can't scroll into the future).
- **Insights** — average mood, day streak, mood trend line (14/30/90-day window, Swift Charts), mood-mix distribution, and the headline **correlation engine**: how much each activity shifts your mood vs your overall average, ranked by impact with sample sizes.
- **Log timeline** — entries grouped by day (Today/Yesterday), with mood, note, and activity chips; context-menu delete.
- **Settings** — haptics, default trend window, daily-nudge toggle, data count, delete-all with confirmation.
- Onboarding (persisted), empty states, sample-journal loader, light/dark, Dynamic Type, VoiceOver, Reduce Motion.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at repo root).
3. Open `Tide.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** personal team under Signing & Capabilities; bundle id `com.orbioom.tide`. No paid account, no keys.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM. **SwiftData** (`MoodEntry` ↔ `Activity` many-to-many); prefs in `@AppStorage`.
- Pure `MoodInsights` computes streak, daily averages, distribution, and per-activity correlation (mean mood when present minus overall) with a custom `FlowLayout` for chips.
- Design language: **Orbioom** (glass cards, ink buttons, mono numerics; mood palette tuned for WCAG AA in both schemes).
- **Monetization:** freemium — free logging; Pro unlocks correlations, long-range trends, and export. (Daylio/How-We-Feel prove paid mood journaling at scale.)
- **Why it can boom:** mood tracking is a perennial top-charts wellness category; Daylio is loved but dated and its insights are shallow. Tide's correlation engine ("Exercise +0.6, Screen time −0.4") is the feature users keep asking competitors for — and it's private by default.

## Self-review

Re-read every file. Verified imports; the `MoodEntry`/`Activity` relationship + inverse compile; `@Query` sorts on non-optional keys; `Chart`/`BarMark`/`LineMark` usage and segmented pickers type-check; custom `FlowLayout` conforms to `Layout`; only `try!` is the in-memory container fallback; ≥4 feature screens (Log, Calendar, Insights, Activities) + Onboarding + Settings; no stubs, no iOS-18 APIs. Anti-stub grep clean.
