# Lexic — Daily + unlimited word puzzle

Guess the five-letter word in six tries — one shared daily puzzle to keep your streak, plus unlimited practice rounds. Correct duplicate-letter coloring, a smart on-screen keyboard, hard mode, full stats, and a spoiler-free shareable grid — with none of the ad bombardment or bot-behind-a-paywall friction of the Wordle clones.

## What it is
- **One-line:** A clean Wordle-style word game with a daily puzzle, unlimited play, and honest sharing.
- **Problem + audience:** Wordle proved an enormous appetite for the daily five-letter guess, but third-party clones flood players with unskippable ads and the official version paywalls extras. Lexic gives the huge word-puzzle audience the core loop, ad-free, with unlimited practice the original lacks.

## Full feature list
- **Daily:** one deterministic word per day (FNV-hashed by date), resumes if you reopen, with a "Daily #N" header.
- **Practice:** unlimited random words, "play again" / new-word any time.
- **Board + keyboard:** six rows of tiles; correct **two-pass duplicate-letter** evaluation (greens consume letters before yellows); on-screen QWERTY whose keys color to the best-known state; invalid words shake with a toast; not-in-word-list and not-enough-letters validation.
- **Hard mode:** revealed hints must be reused in later guesses (validated with a specific message).
- **Result card:** win/lose state, the answer on a loss, a mini color grid, and a spoiler-free **ShareLink** grid (`🟩🟨⬛️`) with a Lexic day number.
- **Stats:** played, win rate, current and max streak, and a guess-distribution bar chart.
- **Settings:** hard-mode toggle, appearance, haptics, how-to-play, reset statistics, honest "no paywall on the puzzle" copy.
- Onboarding gated by a persisted flag; empty/finished states; ~370-word curated list (length-guarded) serving as both answers and the accepted dictionary.

## Run steps
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Lexic.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

## Free-signing note
No paid account needed: select your personal team under Signing & Capabilities and run on a simulator or your own device.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM with a pure `WordEngine` (two-pass evaluation, keyboard-state merge, hard-mode validation, deterministic daily answer, share-grid builder) and `StatsEngine` (distribution + streaks). `LexicGame` is an `@Observable` controller.
- Persistence: **SwiftData** (`WordGame` stores answer + guesses + state, so the daily resumes and stats accrue); `@AppStorage` for prefs.
- Design language: **Orbioom**, with Wordle-familiar green/amber tile states resolved per color scheme.
- **Monetization:** freemium — daily + unlimited free; a one-time "Lexic Plus" (themes, longer-word and 6/7-letter modes, archive of past dailies) is the upsell. No ads.
- **Why it can boom:** Wordle's daily-word loop is a globally proven, viral hit; the clones monetize via ad bombardment and the official app paywalls extras. A clean, ad-free, unlimited, shareable version is the version players actually want.

## Self-review
Re-read every Swift file: imports verified; all SwiftUI/SwiftData/Charts symbols exist in iOS 17; the duplicate-letter evaluation is correct (greens decrement counts before yellows); `@Observable`/`@State`/`@Query`/`@AppStorage`/`modelContainer` and ShareLink wiring type-check; no force-unwraps/`try!`/`fatalError` on user paths (container falls back to in-memory); `Array[safe:]` defined once. Anti-stub grep clean. Dynamic Type, accessibility (row/key state labels), Reduce Motion, light/dark handled.
