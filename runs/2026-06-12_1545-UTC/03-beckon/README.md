# Beckon — the 369 manifestation journal

**One-liner:** A calm, beautiful home for the viral 369 method — write your affirmation 3 times in the morning, 6 in the afternoon, 9 at night — with streaks, scripting and a private journal.

**The problem & audience:** The 369 method went explosively viral on TikTok (#369method has 280M+ views) and the broader manifestation/affirmation app space is a proven money-maker (I Am, etc.). But there's no elegant, focused, private home for the actual 369 ritual — people use plain notebooks or generic note apps. Beckon is for the large, young, highly engaged manifestation audience that wants a guided, ad-free, shareable practice.

## Full feature list

- **Today** — a breathing daily-affirmation card (deterministic by date), plus a card per active intention showing the 3 / 6 / 9 phase rings, the recommended phase for the current time of day, and a one-tap "Write now". A streak flame tracks consecutive complete days.
- **369 writing ritual (full-screen)** — the heart of the app: your affirmation displayed, you write it the required number of times. A fuzzy matcher (normalized Levenshtein) accepts close-enough lines, fills progress dots, fires a sparkle on each rep, and walks you 3 → 6 → 9. A **Tap mode** alternative is available in Settings.
- **Intentions** — your manifestation list grouped into Active / Manifested / Released; each with category, affirmation and cycle progress.
- **Intention detail** — cycle ring (day X of 33/45), total reps, a 5-week practice heatmap, a free **scripting** space, and mark-manifested / reactivate / release actions.
- **New/Edit intention** — title, category, present-tense affirmation with a curated suggestion library, and a 33- or 45-day cycle.
- **Journey (insights)** — streak, days practiced, total affirmations, manifested count; a 3-week reps bar chart and active-cycle progress.
- **Settings** — writing vs tap mode, light/dark/system theme (app-wide), haptics, practice totals, delete-all.
- Onboarding gated by a flag; empty states; Dynamic Type, VoiceOver, Reduce Motion, light/dark throughout.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Beckon.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R. A seeded example intention with two weeks of practice fills every screen.

**Free-signing note:** Runs with a personal Apple ID — no paid account, no entitlements, no network.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM with a pure `PracticeEngine` (streaks, daily reps, totals) and a `TextMatch` fuzzy comparator. **SwiftData** models `Intention` (cascade) and `PracticeLog`; deterministic `SplitMix64` daily affirmation.
- Design language: "cosmic gold" — gold leaf on a deep plum night sky with serif affirmations and gentle breathing motion.
- **Monetization:** Free for one or two intentions; one-time **Beckon+** unlock for unlimited intentions, scripting history, themes and insights. (Affirmation/manifestation apps monetize strongly via subscriptions; a fair one-time unlock is the wedge.)
- **Why it can boom:** A genuinely viral, evergreen practice with no elegant dedicated app, a young shareable audience ("watch me manifest"), and a satisfying core loop the incumbents don't offer.

## Self-review

Re-read every file: imports and all SwiftUI/SwiftData/Charts APIs verified for iOS 17; `@State`/`@Bindable` ownership correct (SessionView's `intention`/`phase` synthesize the right init); chart series are `Identifiable` structs (no tuple key-paths); `fullScreenCover(item:)` uses `Identifiable` `Phase`; no `try!`/force-unwraps on user paths. Anti-stub grep clean; `project.yml` valid; icon is a real 1024² RGBA PNG.
