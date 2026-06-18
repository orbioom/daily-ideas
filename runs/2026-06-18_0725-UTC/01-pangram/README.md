# Pangram

**A warm, honeycomb word game — free, offline, and unlimited.**

Pangram is a native iOS 17 SwiftUI take on the spelling-bee genre: seven letters arranged as an
amber honeycomb, one required center letter, and as many words as you can build. It is a *beater*
for the well-known daily word bee — there is no paywall on the core game, no network requirement,
and you are never capped on how many words you can find. The audience is anyone who plays a daily
word puzzle with their coffee and wishes it were free, prettier, and always available.

The problem it solves: the popular spelling bee is subscription-gated, online-only, and one puzzle
a day. Pangram gives you the same satisfying mechanic with a generous daily puzzle, a streak
calendar, practice puzzles, full analytics — all on-device.

---

## What it is

- **Mechanic:** 7 letters (1 amber **center** + 6 outer) shown as a honeycomb. Build words of **4+
  letters** using only those seven letters (letters may repeat); **every word must contain the
  center letter**. A word that uses **all 7 distinct letters** is a **pangram**.
- **Scoring:** 4-letter word = 1 point; longer words score their length; a pangram adds a **+7**
  bonus.
- **Rank ladder:** Beginner → Good Start → Moving Up → Good → Solid → Nice → Great → Amazing →
  **Genius** (≈70% of the maximum) → **Queen Bee** (100%), scaled to each puzzle's total possible
  score.

---

## Features

**Four core feature screens (plus How-to-Play, Settings, Onboarding, Paywall):**

1. **Play** — the honeycomb board (center + six outer hex tiles), tap-to-append word building with
   **Delete**, **Enter**, and **Shuffle**; a live current-word display that colors the center letter
   and flags bad letters; a **found-words drawer** (count + full list, pangrams highlighted in
   amber); a **live score + rank progress bar** with rank tick marks; an animated **accepted /
   rejected** feedback toast; **rank-up celebration overlays**; and a **hints page** (Pro) showing
   the two-way grid of word counts by first letter × length, plus pangram and remaining-word totals.
2. **Daily** — today's puzzle entry that resumes in place, a **month streak heatmap** (played vs.
   Genius days, today highlighted), and **current / longest streak** counters.
3. **Practice / Archive** — start a fresh random puzzle (free: a few per day; Pro: unlimited) and
   **browse / replay past Dailies** (free: most recent few; Pro: full archive).
4. **Stats** — **Swift Charts**: words found over time (area/line), score per day (Genius days
   highlighted), pangrams per day, plus Genius rate, totals, and streaks.

**Supporting:**
- **Onboarding** — multi-page, value-first, gated by `hasOnboarded`.
- **How to Play** — the full rules at a glance.
- **Settings** — five real persisted preferences: **Appearance** (System/Light/Dark),
  **Color-blind safe palette**, **Haptics**, **Confirm on submit**, **Show rank toasts**; plus an
  Unlock/Restore Pro row and an About section.
- **Empty, loading, error, and success states** throughout; tasteful animation that honors **Reduce
  Motion**; haptics gated by the setting; full Dynamic Type and VoiceOver labels.

**Content:**
- A **curated offline dictionary of 2,400 common English words** (length 4–9, lowercase, no proper
  nouns), bundled in Swift.
- **40 curated pangram seeds**, each verified by construction to spell **30+** valid dictionary
  words including the center letter (well above the 18 minimum), each with at least one pangram and
  seven distinct letters.
- **30+ seeded past Daily results** on first run, so Stats and streaks look alive immediately.

**Engineering:**
- **Deterministic Daily** via SplitMix64 seeded from the date key — the same puzzle for everyone on
  a given day; random for Practice.
- **Resume anywhere** — in-progress puzzles persist; solution sets are recomputed from the seed
  rather than stored in bulk.

---

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root, if present).
3. Open `Pangram.xcodeproj` in Xcode 15+, pick an **iOS 17+ simulator**, and press **Cmd+R**.

### Free signing
No paid Apple Developer account is required to run on the simulator. To run on a physical device,
select the Pangram target → **Signing & Capabilities** → check **Automatically manage signing** and
choose your **Personal Team**; Xcode will provision a free development signature.

---

## Tech notes

- **iOS 17+**, **SwiftUI**, **NavigationStack** throughout (no `NavigationView`).
- **MVVM with `@Observable`** for the game session (`GameViewModel`), `ObservableObject` +
  `@StateObject` for app-wide settings / Pro / practice ledger (the two ownership models are never
  mixed on one type).
- **SwiftData** (`@Model`, `@Query`, `modelContainer`) is the source of truth for `SavedPuzzle`
  (resume + history) and `DailyResult` (stats + streaks); both are registered in the app's
  `Schema`. Small preferences live in `@AppStorage`.
- **Swift Charts** powers the Stats screen, with accessibility labels and values on every chart.
- **Design language:** a warm honeycomb / amber identity — accent `#E0A92B`, background
  `#FFF7E6` / `#14100A`, rounded SF type, real hexagon tiles, and a `Color.dyn(light, dark)` helper
  so every custom color reads well (AA contrast) in both light and dark mode.
- **Crash-proofing:** no force-unwraps / `try!` / `as!` / unchecked indices / unguarded division on
  user paths; the only `fatalError` is the documented, unreachable in-memory `ModelContainer`
  fallback.
- **Monetization:** a single simulated one-time **Pangram Pro** unlock (`@AppStorage("isPro")`,
  StoreKit-ready) that adds unlimited practice, the full daily archive, the hints page, extra hex
  themes, and full-history stats — the free daily-plus-a-few-practice core is complete and
  satisfying on its own.
- **Why it can boom:** it is a free, offline, unlimited, prettier clone of a beloved subscription
  word game — the exact pitch (no paywall, no login, play forever) that drives organic word-of-mouth
  in the daily-puzzle crowd.

---

## Self-review

I re-read every Swift file and verified by hand:

- **iOS 17 only:** no `NavigationView`, no `@Previewable`, no single-parameter deprecated
  `onChange`, no iOS-18 SwiftData/SwiftUI symbols. Navigation uses `NavigationStack` +
  `navigationDestination(for:)` / `NavigationPath`.
- **Persistence:** both `@Model` types (`SavedPuzzle`, `DailyResult`) appear in the `Schema([...])`
  in `PangramApp.swift`; `@Query`, `modelContext`, and `FetchDescriptor` + `#Predicate` (capturing
  local constants) type-check; primary data in SwiftData, prefs in `@AppStorage`.
- **Ownership:** `@Observable` `GameViewModel` is held in `@State`; `AppSettings`, `ProStore`, and
  `PracticeLedger` are `ObservableObject` + `@StateObject`/`@EnvironmentObject`. The two patterns are
  never mixed on one type.
- **Safety:** grep confirms **no** `try!`, `as!`, `NavigationView`, or force-unwrap on user paths,
  and **no** `TODO/FIXME/XXX/placeholder/lorem/coming soon/not implemented/stub/unimplemented`
  strings. The lone `fatalError` is the documented in-memory container fallback. Fixed one
  operator-precedence bug (`?? 0 > 0` → `(?? 0) > 0`) and removed a duplicate
  `navigationDestination` for `Puzzle` (switched Practice to a `NavigationPath`).
- **Data integrity (verified programmatically against the actual bundled `WordData.swift`):** 2,400
  words, 40 seeds; **every seed yields ≥18 valid words (all ≥30) including the center and ≥1
  pangram**, and each seed has exactly 7 distinct letters. The deterministic Daily picker
  (FNV-1a → SplitMix64) was reproduced to confirm it selects a valid seed.
- **Definition of Done:** ≥4 substantive feature screens; onboarding gated by `hasOnboarded`; empty,
  loading, error, and success states present; ≥3 (here 5) real persisted settings; first-run seed of
  30+ rows guarded by a flag; input validation on all word paths; Dynamic Type + accessibility
  labels/values/hints on controls, tiles, charts, and calendar; AA-contrast `Color.dyn` colors in
  both modes; haptics gated by `settings.hapticsEnabled`; animations honor
  `accessibilityReduceMotion`; lazy containers with stable IDs; Swift Charts on Stats.
- **Compilation sanity:** balanced braces/parens in all 42 files; every needed `import` present
  (`Charts` only where used); no money math (no `Decimal`/`Double` currency in this app).

Attestation: to the best of my static review, every type, initializer, enum case, and modifier used
exists in the iOS 17 SDK and is spelled correctly; protocol conformances are satisfied; and the app
is complete and wired end-to-end with no stubs or dead controls.
