# Reverie — dream journal & lucid dreaming

**One-liner:** Capture dreams before they fade, discover your recurring dream signs, and train yourself to go lucid — all private, on-device.

**The problem & audience:** Lucid dreaming has a large, devoted community, and the category's best-known app (Awoken) is **Android-only — there's a real gap on iOS**. Reviews of the space stress three things: sub-30-second capture (you lose half a dream within five minutes), strong privacy ("dreams are deeply personal"), and customizable reality-check reminders. Reverie nails exactly those.

## Full feature list

- **Dream journal** — dreams grouped by month, each with mood, lucidity and vividness; full-text + dream-sign search and a lucid-only filter. Fast capture is the priority.
- **Dream detail** — the narrative in dreamlike serif, lucidity/mood/vividness, tagged dream signs, technique used and recurring/nightmare flags.
- **New/Edit dream** — title, night, narrative, lucidity, vividness stepper, mood, recurring/nightmare toggles, technique, and tap-to-toggle dream signs (create new ones inline).
- **Dream signs** — your recurring people/places/themes ranked by frequency, with a highlighted top sign and a reality-check prompt ("when you notice this, question reality"). Add/delete signs.
- **Insights** — lucidity rate, recall streak, dreams logged, average vividness; a 21-day recall chart with lucid dreams highlighted, a mood donut, and lucidity-by-technique ("what's working").
- **Learn** — a lucid-dreaming technique library (Reality Checks, MILD, WBTB, WILD, Journaling) with expandable steps, plus configurable **reality-check reminders** delivered via local notifications (count per day + time window).
- **Settings** — light/dark/system theme (app-wide), serif dream-text toggle, haptics, journal counts, delete-all.
- Onboarding gated by a flag; empty states; Dynamic Type, VoiceOver, Reduce Motion, light/dark throughout.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Reverie.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R. Seeded dreams, signs and a couple of lucid nights fill every screen. (Allow notifications to try reality-check reminders.)

**Free-signing note:** Runs with a personal Apple ID — no paid account or special entitlements. Local notifications need no usage-description key.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM with a pure `DreamEngine` (lucidity rate, recall streak, mood/technique breakdowns) and a `ReminderScheduler` over `UNUserNotificationCenter`. **SwiftData** models `Dream` and a many-to-many `DreamSign`; `Identifiable` structs back the charts; a custom `FlowLayout` wraps sign chips.
- Design language: "moonlit" — periwinkle/indigo on midnight blue with serif narratives.
- **Monetization:** Free for journaling and signs; one-time **Pro** unlock for advanced insights, unlimited reality-check schedules and themes.
- **Why it can boom:** A passionate niche with a glaring iOS gap (Awoken is Android-only), a privacy story that resonates, and a clear daily habit loop (capture → find signs → reality checks → lucidity).

## Self-review

Re-read every file: imports and all SwiftUI/SwiftData/Charts/UserNotifications APIs verified for iOS 17; chart/`ForEach`/grouped series are `Identifiable` structs (no tuple key-paths; the technique step list iterates `indices`); many-to-many relationship declared with one inverse; notification scheduling marshalled correctly; no `try!`/force-unwraps on user paths. Anti-stub grep clean; `project.yml` valid; icon is a real 1024² RGBA PNG.
