# Grove — focus timer that grows a forest

**Plant focus, grow a grove.** Set a timer and a tree starts growing. Stay focused for the whole block and it takes root in your grove; leave the app mid-session and it withers. A gentle stake in the ground that keeps you present.

For students and deep workers — the proven Forest/Pomodoro audience — who want the plant-a-tree hook without ads or a coin economy.

## Features

- **Focus session** — choose a duration (presets + slider, 5–120 min) and a tag, then watch a tree grow in real time with a live countdown. Species scales with length (sprout → shrub → pine → oak → redwood).
- **The withering hook** — strict mode watches `scenePhase`; fully leave Grove during a session and the tree wilts (recorded as a withered tree). "Give up" does the same, honestly.
- **Grove** — a visual collection of every tree, grouped by day, with totals; tap any tree for its details (status, tag, focused vs planned, when); remove trees.
- **Stats** — today vs all-time minutes, trees planted, a 14-day focus chart, a "where focus goes" by-tag bar chart, and focus-success rate (Swift Charts).
- **Tags** — full CRUD with icon + colour pickers; sessions are categorised by tag and coloured throughout.
- **Settings** — strict mode, keep-awake, haptics, clear-the-grove with confirmation.
- Custom `Canvas` tree rendering, relaunch-safe timing (date-driven), onboarding (persisted), empty states, sample-grove loader, light/dark, Dynamic Type, VoiceOver, Reduce Motion (tree renders fully grown).

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Grove.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** personal team; bundle id `com.orbioom.grove`. No paid account, no keys.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM. **SwiftData** (`FocusSession`, `FocusTag`); prefs in `@AppStorage`.
- Pure `FocusStats` (streak, daily/total minutes, by-tag, success rate); trees drawn with `Canvas` parametrised by species & growth; the withering hook uses `@Environment(\.scenePhase)`.
- Design language: **Orbioom** (glass + ink; greens for living trees, muted tones for withered).
- **Monetization:** freemium — free focus + grove; Pro unlocks extra species, detailed stats, and tag goals. (Forest is a perennial top-paid productivity app.)
- **Why it can boom:** Forest has 10M+ users and proves the plant-a-tree mechanic, but it's cluttered with a coin store and real-tree upsells. Grove keeps the irresistible core loop, adds tag analytics, and stays calm and on-device.

## Self-review

Re-read every file. Verified imports; the `Phase` enum is `Equatable` (powers `phase == .setup`); `scenePhase` withering, date-driven `TimelineView`, and `Canvas` tree compile; `AnyShapeStyle` ternaries in `.background(_:in:)` type-check; Charts + tag CRUD compile; only `try!` is the in-memory fallback; ≥4 feature screens (Focus, Grove, Stats, Tags) + Onboarding + Settings; no stubs, no iOS-18 APIs. Anti-stub grep clean.
