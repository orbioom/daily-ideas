# Tetra

A calm, gorgeous, **ad-free 2048 done right** — the classic number-merge puzzle with no popups, no nagging, and a single fair one-time unlock.

## What it is
2048 is one of the most durable casual hits ever made: swipe to slide tiles, merge equal numbers into ever-bigger powers of two, and chase the 2048 tile (then keep going). It's an evergreen top-charts money-maker — but the popular incumbents are buried in interstitial ads, forced video, and aggressive IAP. **Tetra** is the version for people who just want to play: a tactile candy-arcade board, springy merges, light + dark themes, honest stats and achievements, and a one-time **Tetra Pro** unlock instead of an ad firehose. Audience: anyone who loves a quick, beautiful number puzzle and resents being interrupted.

## Features
- **Play** — a recessed candy-arcade board with directional swipe gestures (dominant-axis `DragGesture`), live score / best / moves header, springy spawn & merge animations (opacity fades under Reduce Motion).
- **Board sizes** — classic 4×4 free; 5×5 and 6×6 unlocked by Pro (gated with a tailored paywall).
- **New Game** (confirms if a game is in progress), **Undo** (3 free per game, unlimited with Pro), and a **Daily Challenge** — a date-seeded board everyone shares, recorded once per day.
- **Win overlay** ("You made 2048! Keep going / New game") and a calm **Game-Over** overlay with final score and "Play again".
- **Stats** (Swift Charts) — scores over time (`LineMark`), highest-tile distribution (`BarMark`), games played, win rate, total moves & time, best score per board size, and current / best day streaks. Empty state before any games.
- **Awards** — milestone badges with live progress bars: reach 128 → 4096, first 2048, play 10/50/100 games, score 5k/10k/20k.
- **Guide** — how-to-play, strategy tips, and the full per-value tile-color legend.
- **Settings** — Appearance (System/Light/Dark), Haptics, best-score chip, Undo control, default board size, and a guarded "reset all data".
- First-run **Onboarding** gated by `@AppStorage("hasOnboarded")`; resumes your exact game on relaunch (one saved game per board size).
- Full **accessibility**: Dynamic Type, `accessibilityLabel`/`Hint`/`Value`, decorative images hidden, WCAG-AA tile contrast in both modes, Reduce Motion honored everywhere. Sparse, setting-gated **haptics** on merge and win.

## Substantive core logic
**`BoardEngine`** (`Engine/BoardEngine.swift`) is a pure, SwiftUI-free, fully testable struct implementing correct 2048 rules for any board size:
- `collapseLine` slides non-zeros and merges equal adjacent pairs **once** each (a tile formed by a merge this move can't merge again), then compacts gaps.
- `move(_:)` applies a direction by collapsing rows/columns (with reversal for right/down) and reports the new grid, points gained, whether anything moved, and the merge count.
- `spawnTile(using:)` places a 2 (90%) or 4 (10%) into a random empty cell via an **injected RNG** — a `SplitMix64` seeded from the calendar day makes the Daily Challenge reproducible for everyone.
- `isGameOver`, `hasReached`, `emptyCells`, `highestTile`, all index-guarded so no size or malformed grid can crash.

Supporting pure engines: **`StatsEngine`** (aggregations, score points, tile buckets, streaks) and **`AchievementEngine`** (badge progress) — both off the UI path and testable. **`GameViewModel`** (`@MainActor ObservableObject`) holds live grid/score/best/undo, persists `SavedGame` every move, writes a `GameRecord` on game end, and tracks elapsed time and move count.

## Run
1. `brew install xcodegen`
2. `cd runs/2026-06-15_1809-UTC/01-tetra/ios && xcodegen generate`
3. `open Tetra.xcodeproj`, pick an iOS 17+ simulator, press **Cmd+R**.

## Free signing
No paid Apple Developer account needed: open the project, select the **Tetra** target → Signing & Capabilities → set your personal team, and Xcode will free-sign it onto a simulator or a device.

## Tech notes
- **iOS 17+**, SwiftUI 5, MVVM. NavigationStack (no deprecated NavigationView), two/zero-param `onChange` where applicable, no iOS-18 APIs, no external dependencies, no network.
- **Persistence**: SwiftData (`@Model GameRecord`, `@Model SavedGame`) for durable data that survives relaunch; `@AppStorage` only for small prefs/flags. Grids stored as JSON `Data` with safe decode fallbacks. Robust `ModelContainer` init (on-disk → in-memory → documented unreachable fallback).
- **Charts** via `import Charts` (`LineMark`, `BarMark`, `PointMark`).
- **Design language**: "tactile candy-arcade" — a warm orange accent (0xF29A4E), `Color.dyn` light/dark pairs throughout, a per-value tile color ramp (`Theme.tileColors(forValue:)`), bold rounded numerals.
- **Monetization**: one-time **Tetra Pro $2.99** — bigger boards, daily archive, themes, unlimited undo. Simulated locally via `@AppStorage("isPro")`; StoreKit 2 would wire in at `Pro`/`PaywallView` for production. No ads, no account, no network.
- **Why it can boom**: 2048 is an evergreen top-charts casual money-maker whose incumbents are buried in ads/IAP; Tetra is the calm, gorgeous, fair, one-time version.

## Self-review
Re-read every Swift file as the compiler against the iOS 17 SDK. Files reviewed:
`TetraApp.swift`; `Theme/Theme.swift`; `Engine/BoardEngine.swift`, `Engine/StatsEngine.swift`, `Engine/Achievements.swift`; `Models/AppSettings.swift`, `Models/Pro.swift`, `Models/GameRecord.swift`, `Models/SavedGame.swift`; `ViewModels/GameViewModel.swift`; `Persistence/DailyChallenge.swift`, `Persistence/SeedData.swift`; `Utilities/Haptics.swift`; `Views/RootView.swift`, `Views/Components/SharedComponents.swift`, `Views/Onboarding/OnboardingView.swift`, `Views/Settings/SettingsView.swift`, `Views/Paywall/PaywallView.swift`, `Views/Play/PlayView.swift`, `Views/Play/BoardView.swift`, `Views/Stats/StatsView.swift`, `Views/Achievements/AchievementsView.swift`, `Views/Guide/GuideView.swift`.

Verified: all imports, types, initializers, and modifiers exist in the iOS 17 SDK; `@State`/`@StateObject`/`@Binding`/`@Environment`/`@Query`/`@ObservedObject`/`modelContainer` ownership is correct; `NavigationStack`/sheet/confirmationDialog bindings type-check; Charts marks are iOS 17. **Anti-stub-clean** — no TODO/FIXME/XXX/placeholder/lorem/"coming soon"/"not implemented"/stub. **No force-unwrap / `try!` / `as!`** on any user path; the only `fatalError` is the documented unreachable empty in-memory `ModelContainer` fallback. Every array index and division is guarded (board engine clamps to any size; win-rate guards zero games; progress bars clamp 0–1).
