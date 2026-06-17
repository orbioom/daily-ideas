# Tangle

## What it is
**Tangle** is a calm, ad-free **word-find crossword** for iOS 17. Each level hands
you a small wheel of scrambled letters; you swipe or tap them to spell words that
fill an interlocking crossword grid. Valid words that aren't in the grid become
collected **bonus words** in your Word Jar.

It's the Wordscapes / Word Connect that people actually wish existed — no ads, no
pop-ups, no energy timers, fully **offline**, with a single honest one-time unlock.
Audience: anyone who wants a relaxing daily word ritual without the free-to-play
clutter.

## Features
- **Play (Level):** an animated crossword grid, a circular letter wheel with
  tap *and* drag-to-connect selection, a live candidate readout, **Shuffle** and
  **Hint** controls, found/bonus/hint counters, gentle invalid-word shake, and a
  star-rated level-complete overlay with confetti.
- **Levels (Map):** 16 hand-crafted levels across 3 themed packs (Garden Path,
  Voyage, Harvest Moon) with completion stars and **locked progression** — finish
  a level to unlock the next; Pro unlocks every pack.
- **Daily Puzzle:** a deterministic puzzle seeded by the calendar date (date →
  index into a curated base-word list → the same crossword for everyone, all day),
  with a **day-streak** counter and a recent-results history.
- **Word Jar:** every bonus word you've discovered, de-duplicated with re-find
  counts, searchable, with collected/longest/most-found stats and an empty state.
  Pro shows short definitions.
- **Onboarding** (3 pages, gated by `hasOnboarded`), full **Settings**, **Paywall**,
  and **About** screens.
- **States everywhere:** loading spinner while the packer weaves a level, a calm
  recoverable error state if a level can't be laid out, empty states, and
  success overlays/toasts/haptics.
- **Accessibility:** Dynamic Type via rounded system fonts, VoiceOver labels/values/
  hints on tiles, wheel letters, counters and rows, decorative glyphs hidden,
  AA-contrast light **and** dark palettes, and a Reduce-Motion still fallback for
  confetti, tile reveals and overlay transitions.
- **Haptics** (gated by the Haptics setting) and **sound effects** (gated by the
  Sound setting) on selection, found words, bonuses, invalids and wins.

## Settings (≥3 real, persisted prefs)
Sound Effects, Haptics, Hard Mode (fewer hints), Show Found Words, Appearance
(System/Light/Dark), plus Relaxed Mode (Pro), Unlock Pro / Restore, and About.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Tangle.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

### Free signing
No paid Apple Developer account is required. In Xcode, select the **Tangle**
target → **Signing & Capabilities**, choose your **Personal Team**, and let Xcode
manage signing. The bundle id is `com.orbioom.tangle`; change it if it collides.

## Tech notes
- **iOS 17+, SwiftUI, SwiftData.** `NavigationStack`, `TabView`, `@Query`,
  `modelContainer`. App-wide settings use `ObservableObject` + `@StateObject`/
  `@EnvironmentObject`; the in-level game uses `@Observable` + `@State` (never mixed).
- **Persistence:** `@Model` types `LevelProgress`, `FoundBonusWord` (unique by word)
  and `DailyResult` (unique by date key) are all registered in the `Schema`. First
  run seeds three completed levels and a handful of bonus words via
  `SeedData.seedIfNeeded` (guarded by a `UserDefaults` flag).
- **Crossword packer:** `CrosswordPacker` is a pure, deterministic engine. It
  de-duplicates and sorts target words longest-first, places the first word
  horizontally near center, then for each remaining word scans every shared-letter
  intersection against already-placed words, validates each candidate (no
  conflicting overlaps, no illegal side-adjacency, clear endpoints, ≥1 crossing),
  and picks the best by intersection count + centeredness, breaking exact ties with
  a splitmix64 PRNG seeded from the level id. Unplaceable words are dropped from the
  grid and still reward the player as bonus words. The working canvas is cropped to
  a 0-indexed layout. All grid access is bounds-guarded — it returns an empty layout
  rather than crashing. `LetterMultiset` verifies every candidate is count-aware
  formable from the base letters. Word lists were machine-validated so every listed
  word is formable; the daily puzzle reuses the same packer over a date-seeded base
  word for stable, shared boards.
- **Design language:** soft paper-and-green surfaces (accent `#2BB673`), rounded
  typography, satisfying spring tile reveals, a clear letter wheel with a connecting
  line, and gentle falling confetti — cozy and premium, never garish.
- **Monetization:** one-time **$3.99 Tangle Pro** (simulated, StoreKit-ready) —
  no ads, no subscriptions, no timers.
- **Why it can boom:** Wordscapes-class relaxation without the ad/timer hostility —
  a premium, offline, one-purchase word game in a category players are actively
  fed up with.

## Self-review
I re-read every Swift file by hand and verified: all imports are present and used;
every type, initializer, enum case and modifier exists in the iOS 17 SDK and is
spelled correctly; no iOS-18-only APIs; all `onChange` use the two-parameter form;
no `NavigationView`; no `@Previewable`. The crossword packer and all grid indexing
are fully bounds-guarded and deterministic (simulated end-to-end over all 16 levels
and 24 daily base words — every one yields a non-empty interlocking layout, and
identical seeds reproduce identical boards). `LetterMultiset` validation is correct
and every authored word is machine-verified formable from its base letters.
Property-wrapper ownership is correct and `@Observable` is never mixed with
`@StateObject`. All three `@Model` types are listed in the `Schema`. There are no
`try!`, `as!`, force-unwraps or unchecked indexing on user paths; the only
`fatalError` is the documented, unreachable in-memory `ModelContainer` fallback.
No `TODO`/placeholder/stub strings remain, and braces/parens are balanced across all
37 Swift files. **Self-review passed.**
