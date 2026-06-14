# Daybreak — routine builder & guided runner

**One-liner:** Chain small habits into a morning, evening, or focus routine — then *run it* step-by-step with a calm guided player that keeps you moving.

**The problem + audience:** Habit checkboxes tell you what to do but not *how to actually do it*. The top-grossing wellness apps (Fabulous, Routinery) proved that people will pay for a guided routine that walks them through it — but they're subscription-locked, content-heavy, and pushy. Daybreak is for anyone building a morning kickstart, wind-down, or deep-work ritual who wants a beautiful builder and a distraction-free runner, one-time and on-device.

## Full feature list
- **Today** — a dawn-gradient header, your routines surfaced by time of day, each card showing step count, estimated minutes, and today's done-state, with a big **Start** that opens the full-screen player; an overall streak ring; an empty state that points to templates.
- **Routines (Library)** — reorderable list with full CRUD; a routine editor (name, time of day, icon, color) and an ordered **steps editor** (timed or checkbox steps, titles, durations, reorder, delete); plus a **Templates** gallery (Morning Kickstart, Wind-Down, Deep-Work Start, Workout Warm-up, Evening Reset).
- **Player (guided run)** — the current step large with a **countdown ring** (timed) or a tap-to-complete check (checkbox), a segment progress bar, Pause / Skip / Back, gentle step-change haptic and optional sound cue, and a celebratory completion screen with the streak bump. Wall-clock driven so it stays correct across backgrounding; abandoned runs still record.
- **Progress** — current/longest streaks, a runs heatmap, total minutes, per-routine completion, and Swift Charts (runs per week, minutes trend, per-routine completion), with a loading state.
- **Settings** — keep-screen-awake during runs, sound cue on step change, haptics, week-start, and a **completion threshold** (100% vs 80%) that drives streak logic; plus Pro, export, Load sample data, reset, About.
- **Onboarding** (3 pages), first-run gated; 5 seeded routines + ~70–80 runs across 35 days (with realistic gaps) so streaks, heatmap, and charts are alive immediately.

## Run steps
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Daybreak.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing note:** No paid account needed — set a Personal Team and use the `com.orbioom.daybreak` bundle id (or your own). No entitlements required.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. **SwiftData** (`Routine` cascade `RoutineStep`, `RoutineRun`), prefs in `@AppStorage`. The player is an `@Observable` `PlayerEngine` owned by `@State`.
- Wall-clock player: a timed step stores its start `Date`; `remaining = ceil(duration − (now − start − paused))`; it auto-advances at zero and **recomputes from the stored start on `scenePhase` active**, so it's correct even if backgrounded. Streak rule = consecutive days with ≥1 run meeting the chosen completion threshold, applied identically everywhere.
- Design language: warm sunrise calm — gold/amber accent with verified WCAG-AA text pairings (`Theme.onAccent`, `Theme.onHeader`), dawn gradients, generous spacing; first-class light & dark via `Theme.dyn`; Dynamic Type, VoiceOver on the player countdown/controls, Reduce Motion respected (no motion-only information).
- **Monetization:** free covers up to 2 routines and the basic templates; **unlimited routines, all templates, and stats export** are a one-time **$5.99** Pro unlock (StoreKit not wired; demo unlock + Restore). Who pays: routine-builders who'd otherwise pay Fabulous/Routinery monthly.
- **Why it can boom:** guided routines are a proven top-grossing wellness mechanic, and the leaders are resented for aggressive subscriptions and bloat. Daybreak nails the core loop — build a routine, press play, keep your streak — with taste, privacy, and a one-time price.

## Self-review
38 Swift files. Static audit clean: one `@main`, one `try!` (in-memory fallback), anti-stub grep clean, valid asset JSON, real 1024² icon, balanced delimiters, `@Observable` engine not mixed with `@StateObject`. All 3 `@Model` types registered in both `ModelContainer` calls; cascade `RoutineStep` under `Routine`; ≥4 feature screens + Settings; empty/loading/error/success states; all divisions/indices guarded; AA contrast verified. A dedicated compile-review pass verified Timer/scenePhase wiring and cross-file types against the iOS 17 SDK.
