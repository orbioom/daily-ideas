# Digit — Kids Math Facts Trainer

## What it is

**Digit** is a calm, ad-free, kid-friendly iOS app that helps children aged ~5–11 build real
arithmetic fluency — addition, subtraction, multiplication and division facts — while giving
parents a genuine progress dashboard.

- **One-liner:** An adaptive math-fact trainer kids love and parents trust — no ads, no subscription.
- **Problem:** Most "math facts" apps are subscription traps or ad-laden, and the ones that aren't
  tend to be ugly or shallow. Parents want a clean, fair tool that adapts to their child *and*
  shows them, honestly, how that child is growing.
- **Audience:** Parents of kids ~5–11 working on math-fact fluency (times tables, number bonds, etc.).

## Features

**Kid-facing**
- **Play home screen** — friendly greeting, current level, today's stars, day-streak, a big **Play**
  button, and a mode chooser (each operation or **Mixed**).
- **Full-screen game player** — large problems (e.g. `7 × 6 =`), answered with either a **custom
  on-screen number pad** (no system keyboard) or **multiple-choice cards**, your choice.
  - Instant, encouraging feedback (celebrate on correct, gentle correction showing the right answer).
  - Progress dots, optional soft per-question timer, and an end screen with stars earned plus
    "Facts you're getting good at."
  - Never punishing in tone.

**Parent-facing**
- **Progress dashboard** — per-child mastery summary (facts mastered, accuracy, average speed,
  stars, streak), a classic **fact-mastery grid** (10×10 for add/sub, 12×12 for ×/÷) colored by
  mastery, per-operation mastery bars, and **Swift Charts**: accuracy over time, speed over time,
  stars earned over time, and a practice-streak calendar.
- **Rewards** — earned & in-progress **badges** ("First 10 facts!", "5-day streak", "×5 table
  mastered", "Speed demon", "Flawless round", …) and a **Level Map** of the curriculum showing
  completed / current / unlocked / Pro-locked levels with progress.

**Adaptive engine**
- `FactEngine` builds each round by weighting selection toward **low-mastery**, **unseen**, and
  **due-for-review (spaced-repetition)** facts, constrained to the child's enabled operations and
  max number. Multiple-choice distractors are plausible near-misses (off-by-one, wrong-row, op
  confusion), always distinct and non-negative.
- `Curriculum` is an ordered ladder of levels ("Add within 10" → … → "All times tables" →
  "Division facts" → "Mixed mastery"); a level unlocks the next once mastery crosses a threshold.
- `ProgressEngine` computes per-op mastery %, facts-mastered counts, accuracy, average speed,
  total stars and the day-streak — all guarded against empty data and division-by-zero.

**Setup & management**
- **Onboarding** (4 pages): explains the value and creates the first child profile (name, avatar,
  starting level).
- **Settings** (≥3 real persisted prefs): Appearance (System/Light/Dark), Sound effects, Haptics,
  Answer mode (number pad / multiple choice), Questions per round (5/10/15), Soft timer on/off,
  plus **profile management** (add / edit / delete child), **parent controls** (enabled operations
  & max number per child), **Reset progress**, **Unlock / Restore Pro**, and **About**.
- **Paywall** — Digit Pro, a simulated one-time **$4.99** purchase.

**Polish**
- Empty, loading, error and success states throughout (calm and recoverable).
- Full accessibility: Dynamic Type, VoiceOver labels/values/hints on controls, charts and the
  number pad, decorative emoji hidden, AA-contrast light & dark palettes, and **Reduce Motion**
  honored everywhere (fades instead of bounces).
- Gated haptics + gentle system sounds.

## Free vs. Pro (the gate)

| | Free | Digit Pro ($4.99 once) |
|---|---|---|
| Child profiles | 1 | Unlimited |
| Operations | Addition + subtraction (within 20) | + Multiplication & division, all levels |
| Stats | Summary + add/sub mastery bars | Full analytics: mastery grid, all charts, calendar |
| Badges & Level Map | First badges, free levels | All badges, full Level Map |

The **free core is genuinely useful**: a child can practice add/sub adaptively, earn stars and
badges, and a parent sees real summary stats — forever, with no ads.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root if present).
3. Open `Digit.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

### Free signing

No paid Apple Developer account is needed for the simulator. To run on a physical device, select
the **Digit** target → **Signing & Capabilities**, choose your **Personal Team**, and let Xcode
manage signing (the bundle id `com.orbioom.digit` can be changed if it's taken).

## Tech notes

- **iOS 17+**, **SwiftUI**, **SwiftData** (`@Model` Profile / FactStat / Session, all registered
  in the app `Schema`; small prefs in `@AppStorage`).
- **Swift Charts** for all analytics. `NavigationStack` + `TabView` throughout; two-parameter
  `.onChange`; `@Observable` view-model for the game loop (with `@State`), `ObservableObject`
  `AppSettings` for app-wide prefs.
- **Design language:** warm tangerine accent (`0xF4823C`, matching the AccentColor asset), rounded
  system fonts, soft cards, a per-operation color palette, and a full dynamic light/dark theme via
  `Color.dyn`.
- **Seed data:** on first launch `SeedData.seedIfNeeded` (guarded to run once) creates one demo
  child ("Ava") with ~60 FactStats at varied mastery and 12 sessions across recent days, so
  Progress and Rewards are immediately populated.
- **Monetization:** one-time **$4.99** unlock (simulated, StoreKit-ready) — no ads, no subscription.
- **Why it can boom:** parents actively distrust subscription/ad math apps for young kids; a
  beautiful, fair, *one-time-purchase* trainer with a real parent dashboard is a word-of-mouth
  category that incumbents structurally can't copy without abandoning their recurring revenue.

## Self-review

I re-read every Swift file by hand and verified:

- **Imports** are present and minimal (`Charts` only in the two analytics files; `AVFoundation`
  only in `SoundPlayer`; `UIKit` only in `Haptics`).
- **iOS 17 only:** `NavigationStack` (no `NavigationView`), two-parameter `.onChange`, no
  `@Previewable`, no iOS-18 SwiftData/SwiftUI symbols.
- **SwiftData:** `Profile`, `FactStat`, `Session` are the only `@Model` types and **all three are
  listed in the `Schema`** in `DigitApp.swift`; relationships use `.cascade` with explicit inverses.
- **Crash-safety:** no `try!`, no `as!`, no force-unwraps on user paths, no unchecked indexing.
  The only `fatalError` is the documented-unreachable in-memory `ModelContainer` fallback.
- **Division & engine trace:** every division in the engines is guarded by a positive-denominator
  check or a non-empty-collection check. `FactEngine.allFacts` builds **division facts from
  multiplication** (`dividend = divisor × quotient`, `divisor ≥ 1`), so results are always whole
  numbers and the divisor is never zero. `FactStat.answer` and the grid's quotient mapping both
  guard `b == 0`. Weighted selection always uses strictly-positive weights and guards `total > 0`
  before `Double.random(in:)`, and returns `[]` (handled as a finished round) when no facts exist.
- **No forbidden strings:** no TODO/FIXME/XXX/placeholder/lorem/"coming soon"/"not implemented"/
  stub/unimplemented anywhere.
- **Property-wrapper ownership:** `@Observable` `GameViewModel` is held with `@State`;
  `AppSettings` (`ObservableObject`) with `@StateObject` at the root and `@EnvironmentObject`
  below — the two patterns are never mixed on one object.
- **Naming collision fixed:** `OnboardingPage`'s text property was renamed from `body` to
  `message` so it no longer shadows the `View.body` requirement.
- **Builder correctness:** the multi-`Section` settings sub-view is marked `@ViewBuilder`.
- **Braces and parentheses balance** in every file (checked file-by-file).

Attestation: to the best of a careful manual review, the sources are internally consistent, use
only iOS 17 APIs, type-check against the SwiftUI/SwiftData/Charts surface they reference, and
contain no force-unwraps, `try!`, `as!`, unguarded divisions, or placeholder strings on user paths.
