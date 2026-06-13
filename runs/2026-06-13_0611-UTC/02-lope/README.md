# Lope

**A guided run-walk coach that turns non-runners into 5K runners — it tells you exactly when to run and when to walk, out loud.** For absolute beginners and returning runners who bounce off the gym.

## Features

- **Two progressive plans:** the classic **Couch to 5K** (9 weeks, authentic NHS-style intervals incl. the per-day weeks 5–6) and a gentler **Easy Start** (8 weeks, 30-second jogs to begin) built to beat the week-2 dropout cliff.
- **Full-screen guided run player** driven by a wall-clock `RunEngine` (correct even if the app is backgrounded): warm-up → run/walk intervals → cool-down, with a per-segment countdown ring, whole-workout progress, and the next segment preview.
- **Spoken coaching cues** (AVSpeechSynthesizer): "Run now," "Walk," one-minute and halfway warnings, plus **haptic** taps at every transition and a 3-2-1 countdown. Pause, skip, and keep-awake.
- **Today** hub: next session card with an interval bar, completion ring, day streak, and a this-week tracker.
- **Plan** screen: the whole multi-week schedule with per-session completion, switch plans any time.
- **Run logging** on finish: active time, optional distance (km/mi) → pace, a 1–5 "how it felt," and notes. Full history with **edit/delete** and a weekly-minutes Swift Chart.
- Onboarding (pick a plan), **Settings** (voice cues, haptics, units, theme, reset progress), one-time **Lope Pro**.
- Light & dark, Dynamic Type, VoiceOver, Reduce Motion.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Lope.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

**Free signing:** pick your personal team and a unique bundle id in *Signing & Capabilities*.

## Tech notes

iOS 17+, SwiftUI 5, MVVM with an `@Observable` `RunEngine` (Date-based timeline, segment math, cue scheduling) and pure `PlanLibrary`/`PlanProgress` value logic. Persistence in **SwiftData** (`RunLog`); plan/voice/unit prefs in `UserDefaults`. Design language: **athletic** — charcoal with a volt-lime accent and bold rounded numerals; the run player tints to the current segment's color.

- **Monetization:** free core (both plans, full coaching); one-time **Lope Pro** ($9.99) adds a custom interval builder, a 5K→10K plan, and Apple Health export. Running-onboarding apps have a proven paying audience.
- **Why it can boom:** Couch-to-5K is one of the most durable fitness categories, but paid incumbents have crept into subscriptions and rigid plans (only ~27% finish the standard NHS plan because of the week-2 jump). A gentler, beautifully-coached, one-time-purchase version targets exactly that gap.

## Self-review

Hand-reviewed every file. Verified imports (incl. `AVFoundation`, `UIKit`, `Charts`); iOS-17 APIs; SwiftData `@Query`/`modelContainer`; the wall-clock engine math and timer ownership; `fullScreenCover(item:)` flow; `@Observable` engine constructed from a view without actor-isolation issues (engine runs entirely on the main thread via a main-runloop timer). Anti-stub grep clean. No force-unwraps/`try!` on user paths.
