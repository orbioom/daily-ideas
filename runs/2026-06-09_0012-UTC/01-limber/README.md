# Limber — daily stretching & mobility

**One line:** A calm, guided daily stretch and mobility companion that actually fits into your life.
**Problem & audience:** Stretching is the habit everyone knows they should keep and almost nobody does — desk workers with stiff necks, runners cooling down, anyone who wakes up creaky. The hit apps (Bend, StretchIt) prove the market, but they're paywalled hard, noisy, or pitched at splits-goal athletes. Limber gives the broad middle a beautiful, free-core routine player that makes five minutes effortless.

## Full feature list
- **Today** — a goal ring (minutes stretched vs your daily goal), current streak, a smart suggested routine, and recent sessions.
- **Guided session player** — full-screen, count-in, per-stretch countdown, automatic both-sides cues ("Left side / Right side"), optional rest between stretches, up-next preview, pause/skip/end, keep-screen-awake, and gentle phase haptics. Ends with a body-feel star rating.
- **Routines** — built-in flows (Morning Wake-Up, Desk Reset, Hips & Lower Back, Post-Run Cooldown) plus a full **routine builder**: add stretches from the library, reorder, set per-stretch hold times, favorite, edit and delete.
- **Library** — 25-stretch catalog across 13 body areas with how-to detail, suggested hold, difficulty and both-sides flag; filter by area, search, and add your own **custom stretches** (full CRUD).
- **Insights** — current & best streak, total minutes, session count, a 14-day minutes chart against your goal, an area-focus breakdown, and full session history with feel ratings.
- **Settings** — daily minutes goal, count-in seconds, rest-between-stretches seconds, keep-screen-awake, haptics, reset onboarding.
- First-run onboarding (persisted), empty/loading/success states throughout, light & dark, Dynamic Type, VoiceOver, Reduce Motion.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Limber.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free signing:** no paid Apple Developer account needed — select your personal team under Signing & Capabilities and run on the simulator or your own device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `MobilityEngine` (streaks, daily minutes, session expansion, area balance). Persistence in **SwiftData** (`Stretch`, `Routine`, `RoutineStep`, `SessionLog`); small prefs in `UserDefaults` via `@AppStorage`. Swift Charts for insights. Orbioom design language (liquid glass, ink-gradient buttons, JetBrains Mono numerals, green reserved for live/success).
- **Monetization:** freemium — free core (routines + player + streak); Pro unlocks unlimited custom routines, reminders/Live Activity, and richer programs.
- **Why it can boom:** stretching/mobility is a proven top-grossing wellness category (Bend, StretchIt with ~2M subscribers); incumbents are paywalled and busy. Limber wins on a calmer, faster, genuinely free daily experience.

## Self-review
Re-read every Swift file by hand: imports resolve; all SwiftUI/SwiftData/Charts APIs exist in the iOS 17 SDK; `@Model`/`@Query`/`@Bindable`/`modelContainer` wiring type-checks; `NavigationStack`, `fullScreenCover(item:)`, sheet bindings correct; no force-unwrap/`try!`/`fatalError` on user paths (only the in-memory `ModelContainer` fallback). Anti-stub grep (TODO/FIXME/placeholder/lorem/coming soon/not implemented/stub) is clean. `project.yml` is valid YAML naming the real `Limber` sources and `Info.plist`.
