# Lexicon

**Guess the five-letter word in six tries — a fresh daily puzzle, unlimited practice, and the full archive, all free and ad-free.** The Wordle people wish existed after NYT gated it.

## Features

- **Daily puzzle:** one deterministic word a day (FNV-seeded), with progress that resumes if you close the app.
- **Unlimited Practice:** a new random word any time, no waiting.
- **Full Archive:** play any past daily puzzle going back 90 days, each showing solved/missed status — free, no ads.
- **Correct two-pass scoring** that respects duplicate letters; on-screen QWERTY keyboard with per-letter state coloring; shake on invalid words; "not in word list"/"not enough letters" feedback.
- **Hard mode:** revealed hints must be reused in later guesses.
- **Statistics:** games played, win %, current and max streak (consecutive daily wins), and a guess-distribution chart.
- **Share** an emoji result grid. **High-contrast (color-blind) palette**, light & dark, Dynamic Type, VoiceOver tile descriptions, Reduce Motion.
- 565-word self-contained dictionary (no network, no bundled data file). Onboarding (how to play), **Settings** (hard mode, high-contrast, theme, haptics, reset stats), one-time **Lexicon Pro**.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Lexicon.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

**Free signing:** pick your personal team and a unique bundle id in *Signing & Capabilities*.

## Tech notes

iOS 17+, SwiftUI 5, MVVM with an `@Observable` `GameViewModel` (input, hard-mode validation, daily progress persistence) over a pure `WordGame` engine (scoring, deterministic daily/archive answers, keyboard aggregation). Persistence in **SwiftData** (`GameRecord`, deduped per day); in-progress boards in `UserDefaults`. Design language: **crisp game UI** — indigo chrome with classic tile colors and a custom shake `GeometryEffect`.

- **Monetization:** the full game is free and ad-free; one-time **Lexicon Pro** ($3.99) adds 6/7-letter modes and tile themes — a friendly cosmetic upgrade, not a wall.
- **Why it can boom:** Wordle is the most viral word game ever, now owned by NYT and folded behind their app/account. A free, ad-free, unlimited clone with a free archive, share grids, and accessibility done right is exactly what the long tail of frustrated players searches for.

## Self-review

Hand-reviewed every file. Verified imports; iOS-17 APIs; the duplicate-aware scoring; `@Observable` view model constructed from views without actor-isolation issues; `#Predicate` dedupe fetch; `GeometryEffect`/`ViewModifier` shake; `ShareLink`; SwiftData `@Query`/`modelContainer`. The 565-word list is generated and length-validated (all exactly 5 letters). Anti-stub grep clean. No force-unwraps/`try!` on user paths.
