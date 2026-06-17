# Lexicon

A calm, native daily word-guessing game for iOS 17 — a Wordle-beater that's
**unlimited, ad-free, and fully offline**. Guess the hidden word in six tries;
tiles flip to reveal greens, yellows and grays with correct duplicate-letter
scoring. Play today's shared daily puzzle, an endless stream of practice rounds in
three word lengths, and a full archive of past days.

## What it is

Lexicon is a polished SwiftUI word game built around a deterministic daily puzzle
(everyone gets the same word on the same calendar day) plus unlimited free practice.
It has a tactile, paper-warm identity with rounded letter tiles, a custom on-screen
keyboard that tracks each letter's best-known state, a flip-to-reveal animation
(with a still fallback for Reduce Motion), and first-class accessibility.

## Full feature list

- **Today (daily puzzle)** — the day's word at length 5, identical for everyone, with
  a tile grid, custom keyboard, flip reveals, calm "not enough letters / not in word"
  messages, a win/lose end card with lifetime stats, and an emoji-grid **Share**.
  In-progress games **resume on relaunch**.
- **Practice** — start unlimited random games; pick **4, 5, or 6 letters** (6 is Pro).
  Finish a game and instantly start another. Practice never affects your daily streak.
- **Stats** — Swift Charts guess-distribution histogram, plus games played, win %,
  current streak and max streak — all division-guarded, with a friendly empty state.
- **Archive** — a list of past daily puzzles with played / won badges; tap any day to
  play it. Free users get the last **7 days**; Pro unlocks the full 60-day archive.
- **How to Play** — tile-color legend, a worked example, and the hard-mode rules.
- **Settings** — persisted **Hard mode**, **High-contrast colors** (colorblind-friendly
  orange/blue), **Haptics**, plus Pro status, Restore Purchase, and an About row.
- **Correct evaluator** — a pure, deterministic two-pass `GuessEvaluator` that handles
  duplicate letters exactly like the classic game.
- **Hard mode** — revealed greens must stay in place and revealed yellows must be
  reused; violating guesses are rejected with a calm, specific message.
- **Deterministic daily** — date → SplitMix64 seed → stable index into the answer list.
- **Accessibility** — Dynamic Type, VoiceOver labels/values on tiles, keys and the
  chart, decorative imagery hidden, WCAG-AA contrast in light and dark, a high-contrast
  palette, a Reduce-Motion still fallback, and Settings-gated haptics.
- **Light & dark** first-class throughout, via a cohesive `LexTheme`.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Lexicon.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing:** set your Apple ID team in Signing & Capabilities; the bundle id is
`com.orbioom.lexicon`.

## Tech notes

- **iOS 17+, SwiftUI 5.** `NavigationStack` only; Swift Charts (`BarMark`) for the
  histogram.
- **MVVM** with the Observation framework: `GameViewModel` is `@Observable`, stored with
  `@State` (no `@StateObject`/`ObservableObject` mixing).
- **SwiftData** for primary data: `GameResult` (stats) and `SavedGame` (resumable board,
  stored as a JSON-encoded `BoardSnapshot`), both registered in the `Schema`. Small
  flags use `@AppStorage`. State survives relaunch.
- **Crash-proofing:** no force-unwraps on user paths, no `try!`/`as!`/`fatalError`, a
  safe array subscript, and guarded division throughout. A store-open failure shows a
  calm recoverable screen instead of crashing.
- **Design language:** warm paper background, rounded letter tiles, a Wordle-green accent
  (`#6AAA64`), calm rounded type, and a tactile tile-flip feel — applied on every screen.
- **Monetization:** simulated one-time **$2.99 Lexicon Pro** (`@AppStorage("isPro")`,
  StoreKit-ready in spirit). Core — unlimited daily, practice at 4/5 letters, stats, and
  the last 7 days of archive — is fully free. Pro unlocks the full archive, 6-letter
  words / future length packs, and extra high-contrast theme variants.
- **Why it can boom:** the daily word genre is proven and sticky, but the big apps are
  ad-heavy and online-only — Lexicon is ad-free, offline, accessibility-first, with
  unlimited practice and a playable archive, making it an easy, shareable upgrade that
  monetizes on goodwill rather than interruption.

## Self-review

- Re-read every Swift file: all imports, types, initializers and modifiers used exist in
  the iOS 17 SDK; `import Charts` is present only where charts are used.
- Property-wrapper ownership is consistent: `@Observable` view model held with `@State`;
  `@AppStorage` for flags; `@Query`/`modelContext` for SwiftData.
- All `.onChange(of:)` use the iOS 17 two-parameter closure form.
- Anti-stub grep (`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub|
  unimplemented`) is **clean** across all sources.
- No banned APIs: no `fatalError`, `try!`, `as!`, `@StateObject`, `NavigationView`, or
  `@Previewable`. No force-unwraps on user paths, no unchecked array indexing (safe
  subscript), no unguarded division (win % guarded by `played > 0`).
- The `GuessEvaluator` two-pass duplicate-letter logic was validated against the classic
  cases (e.g. ALLEY/APPLE, SPEED/ERASE) and matches expected behavior.
- Word data is genuine English: 484 five-letter answers (1585-word valid-guess set),
  300 four-letter and 160 six-letter answers, all lowercased, deduplicated, and
  length-filtered at load.
- Braces balanced in every file.
