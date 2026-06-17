# Lace

**Lace** is a native iOS run/walk coach that takes you from the couch to running 5K in nine weeks — the **whole plan, free**, ad-free and offline, with a guided wall-clock session player that calls out every run/walk transition in your ear. It's a Couch-to-5K beater: where the incumbents are "fake free" (a paywall after a few days) or buried in ads, Lace gives you the complete program for nothing and keeps Pro for genuine extras.

## What it is

A bold, motivational running coach built around three things:

1. **The full, real Couch-to-5K plan** — 9 weeks × 3 sessions, each an ordered list of warmup / run / walk / cooldown intervals that mirror the genuine, well-known C25K progression (60s-run/90s-walk in week 1 all the way to a 30-minute continuous run by week 9).
2. **A guided wall-clock player** — the centerpiece. It speaks "Run now", "Walk now", "Last interval", "Cool down" and "Workout complete", buzzes a haptic, and beeps a countdown in the final three seconds of each interval — so you never have to look at your phone. Because elapsed time is derived from a stored start `Date`, the session stays exact through backgrounding, lock-screen and even a full app relaunch.
3. **Progress you can feel** — streaks, minutes, run-minutes, week-by-week completion and Swift Charts of your training, all built automatically from finished sessions.

## Full feature list

- **Onboarding** with a motivational intro and a pick-a-plan flow, gated by a persisted `hasOnboarded` flag.
- **Today / Home** — current-plan card, today's session (interval preview, estimated duration), a big **Start session** button, week + overall progress rings, and a streak / this-week / total-runs strip. Calm empty state when you're not enrolled.
- **Plan** — the full week-by-week schedule for the active plan; every session row shows its structure, a completed badge and your "next" marker; tap to view the full interval breakdown or start it. Switch plans any time.
- **Session Player** (full-screen) — huge RUN / WALK label in the interval's color, a big countdown ring, total progress bar, next-up chip, pause / resume / stop with confirmation, and keep-awake. Survives backgrounding and relaunch and resumes exactly. A **completion success screen** captures an optional 1–5 feel rating and a manual distance, then records the session and advances your plan.
- **History** — completed-session list with stats (total sessions, total/run minutes, current & longest streak) and Swift Charts: minutes per week (`BarMark`) and cumulative sessions over time (`LineMark` + `AreaMark`). Empty state until your first run.
- **Settings** — voice cues, countdown beeps, haptics, keep-screen-awake, workout reminders, distance units (km / mi), CSV export (Pro), about and a disclaimer.
- **Paywall** — one-time Lace Pro.
- **Pro extras** — the gentler **Easy Start** plan (12 weeks), a **5K → 10K Bridge** plan (6 weeks), a **custom plan builder** (design your own sessions and intervals), **CSV export**, and extra themes.
- Spoken cues via `AVSpeechSynthesizer`, countdown/transition tones via `AudioToolbox`, sparse haptics — all individually toggle-able.
- Full accessibility: Dynamic Type throughout, `accessibilityLabel`/`Value` on the player (e.g. "Run, 45 seconds remaining"), controls and charts; decorative imagery hidden; a Reduce-Motion fallback that shows a static ring + numerals instead of a spinning trim; WCAG-AA contrast in light and dark.

## Run steps

1) `brew install xcodegen` (one-time). 2) In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3) Open `Lace.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing:** set your Apple ID team in Signing & Capabilities; the bundle id is `com.orbioom.lace`.

## Tech notes

- **iOS 17+, SwiftUI 5.** `NavigationStack` + `TabView` throughout; no iOS 18 API.
- **Architecture: MVVM.** One consistent ownership pattern: `@Observable` engines/stores held with `@State` and injected via `.environment` (`PlayerEngine`, `AppSettings`, `ProStore`); pure-function engines (`ProgressEngine`, `Enrollment`) over the data.
- **SwiftData** is the source of truth — `ActivePlan`, `CompletedSession`, `CustomPlan` → `CustomSession` → `CustomInterval` (cascade delete), all registered in the `Schema`. `@AppStorage`/`UserDefaults` only hold small prefs/flags and the transient active-run snapshot. Survives relaunch.
- **Wall-clock, relaunch-safe player:** `PlayerEngine` builds a timeline from the session's intervals and derives elapsed time from a stored start `Date` + a paused accumulator, recomputed on `scenePhase` change and re-hydrated from a JSON snapshot on relaunch. A `TimelineView` re-reads the derived state ~4×/second; cues and completion are driven from an `.onChange` tick so no observable state is mutated during view-body evaluation. All progress math is division-guarded and uses a safe array subscript.
- **AVSpeech cues:** spoken run/walk transitions via `AVSpeechSynthesizer` over a ducking, mixable `AVAudioSession`, plus `AudioToolbox` countdown beeps and haptics — each gated by a Settings toggle.
- **Design language:** energetic-but-clean — coral accent **#E4574C**, bold rounded display/numeral type, progress rings, tactile cards; light and dark both first-class via a cohesive `Theme`.
- **Crash-proofing:** no force-unwraps on user paths, no `try!`/`as!`/`fatalError`, no unchecked indices, no unguarded division.
- **Monetization:** one-time **$4.99** Lace Pro (simulated, StoreKit-ready in spirit) — unlocks Easy Start, the 5K→10K bridge, the custom builder, CSV export and extra themes. The entire Couch-to-5K plan, guided player and history stay free forever.
- **Why it can boom:** the category leaders bait-and-switch — "free" until a paywall lands days in, or drowned in ads. Lace hands you the complete, genuinely usable 9-week program with a real in-ear coach for free, so the goodwill (and word of mouth) is enormous; Pro then sells itself to graduates who want to keep going.

## Self-review

Every Swift file was re-read after writing. Verified: all imports resolve and every type/initializer/modifier used exists in the iOS 17 SDK (`AVSpeechSynthesizer`, `AVSpeechUtteranceDefaultSpeechRate`, `TimelineView(.periodic:)`, `Chart`/`BarMark`/`LineMark`/`AreaMark`, SwiftData `@Model`/`@Query`/`@Relationship`, `AudioServicesPlaySystemSound`). One ownership pattern (`@Observable` + `@State`/`@Bindable`, never `@StateObject`/`ObservableObject`). `.onChange(of:)` uses the iOS 17 two-parameter form everywhere. `NavigationStack` only. Braces balanced in all 38 files. Anti-stub grep over the sources is clean (no TODO/FIXME/XXX/placeholder/lorem/"coming soon"/"not implemented"/stub/unimplemented). No force-unwrap on user paths, no `try!`/`as!`/`fatalError`, no `NavigationView`; all array indexing uses a safe-subscript helper and every division is guarded against zero. Empty / loading / success / error states present; accessibility, Reduce-Motion fallback and toggle-gated haptics in place; light and dark both styled through the shared `Theme`.
