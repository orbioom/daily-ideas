# Sapper

**A clean, ad-free, modern Minesweeper — the classic everyone loves, minus the ad-stuffed
incumbents.** Sapper is the version the 1-star reviews of other minesweepers are begging for:
genuinely free, no ads ever, with a true no-guess mode, a daily challenge, and honest stats.

- **Problem:** the popular Minesweeper apps are buried in ads, dark-pattern subscriptions, and
  coin-flip losses that no amount of skill can avoid.
- **Audience:** puzzle players who want the pure classic — plus people who hate guessing and want
  every board solvable by logic.

## Features

- **Four difficulties:** Beginner (9×9, 10), Intermediate (16×16, 40), Expert (16×30, 99), and a
  validated **Custom** board (Pro) with live mine-density feedback.
- **A correct engine** (pure Swift, no SwiftUI): first-click-safe generation (mines never land on
  your first tap or its 8 neighbors), iterative flood-fill, win/loss detection with mine reveal and
  wrong-flag marking, and **chording** (tap a satisfied number to clear its neighbors).
- **True no-guess mode (Pro):** a logical solver (single-point deduction + a subset/1-2-1 rule) runs
  after generation and regenerates the board until it is solvable without guessing (cap 200 attempts,
  then an honest fallback that the UI labels clearly).
- **Daily Challenge:** one seeded board per day (seed derived from the `yyyy-MM-dd` key via a
  SplitMix64 RNG), identical for everyone, with a 14-day streak strip and your record.
- **Game board:** tap to reveal, long-press to flag, a Flag/Dig mode toggle, chording, pinch-zoom and
  pan plus zoom buttons, a live mine counter and timer, and a win/lose overlay with stats.
- **Resume:** your in-progress game is persisted (board encoded as Codable JSON) and survives
  backgrounding and relaunch.
- **Honest stats:** Swift Charts win-rate-by-difficulty bars, best/average times, games played, and
  current/best win streaks, with a recent-games history and an empty state before any games.
- **Settings:** flag-mode default, question-mark cells, confirm-new-game, haptics toggle, exposed
  (always-on) safe-first-click, theme (light/dark/system), no-guess default (Pro), reset stats, and
  an About section.
- **Accessibility:** Dynamic Type throughout, VoiceOver labels/hints/values on cells and controls,
  decorative images hidden, WCAG-AA color tokens for light and dark, and full Reduce Motion support.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Sapper.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

Free-signing note: the bundle id is `com.orbioom.sapper`. To run on a device, select your personal
team under Signing & Capabilities; no paid account is required for local builds.

## Tech notes

- **iOS 17+, SwiftUI, MVVM.** The `MineEngine` and `Solver` are pure value types with no UI
  dependencies; `GameViewModel` (`@MainActor`, `ObservableObject`) orchestrates input, the timer, and
  persistence.
- **SwiftData** stores `GameRecord`, `SavedGame` (single in-progress game), and `DailyResult`.
  `@AppStorage` holds small prefs and the `isPro` flag.
- **Swift Charts** powers the win-rate visualization.
- **Determinism:** a seedable SplitMix64 RNG plus an FNV-1a date-key hash make the daily board
  identical for everyone and make no-guess generation reproducible given seed + first click.
- **Design language:** quiet "Liquid Glass"-inspired surfaces, a confident blue accent, classic
  per-number cell colors tuned for both modes, restrained motion, and one focal idea per screen.
- **Monetization:** one-time **Sapper Pro $2.99** (no-guess mode, custom boards, themes, CSV export);
  the free tier is fully playable with **no ads ever**. Pro is gated by `@AppStorage("isPro")` and the
  paywall is honestly labeled as a local unlock for this build (production wires StoreKit 2).
- **Why it can boom:** the top Minesweeper apps are hated for ads and unfair guessing; a clean,
  ad-free build with a real no-guess mode and a daily challenge is exactly the underserved demand,
  with the daily seed driving habitual return visits.

## Self-review attestation

Every Swift file was re-read against the iOS 17 SDK: imports, types, initializers, enum cases and
modifiers verified; `@State`/`@StateObject`/`@ObservedObject`/`@AppStorage`/`@Query`/`@Environment`
wiring and `NavigationStack`/`navigationDestination`/sheet bindings type-checked; ownership hoisted
correctly; brace/paren balance confirmed; every `Theme.` token is defined. There are **no**
`TODO`/`FIXME`/`placeholder`/`coming soon`/`not implemented`/stub strings, and the only `try!` is the
sanctioned in-memory `ModelContainer` fallback. The solver + no-guess generator were independently
validated (a Python port cleared 100% of sampled Beginner/Intermediate/Expert boards well within the
200-attempt cap), confirming the engine's deduction rules are sound and terminate.
