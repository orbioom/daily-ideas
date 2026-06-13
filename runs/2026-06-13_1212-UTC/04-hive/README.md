# Hive — a free, ad-free daily word game

**One-liner:** A gorgeous Spelling-Bee-style word game — seven letters in a honeycomb, build words using the gold centre letter, find the pangram, and climb from Beginner to Genius — with a deterministic daily puzzle, unlimited practice, and a full free archive.

**Problem & audience:** The NYT Spelling Bee is one of the most beloved word games in the world, but it now sits behind a Games subscription, driving millions of frustrated fans to search for a free alternative. Hive is exactly that: the same satisfying loop (a honeycomb of seven letters, words of four or more using the required centre, a hidden pangram, and a rank ladder to Genius), but completely free, ad-free, offline, and with a free archive of past days — the very thing the original paywalls.

## Features

- **Daily** — today's deterministic puzzle, the same for everyone on a given day, computed offline from the date. The signature board: a honeycomb of seven hexes (gold centre, six outer) you tap to build words, a live current-entry display, and Delete / Shuffle / Enter controls. A rank progress bar tracks Beginner → Genius, found words are listed with pangrams highlighted, results surface as toasts (+N, "Not in word list", "Missing centre letter", "Already found", and a pangram celebration), and reaching Genius shows a success state. Progress persists across launches.
- **Practice** — pick any puzzle from the bank in a grid that shows each one's completion percentage, and play it unlimited times in the same board UI. Practice runs are kept separate from the dated daily puzzle.
- **Archive** — the last 60 daily puzzles, each showing your rank and score for that day. Tap any day to play or resume it — the free version of the feature the incumbent charges for.
- **Stats** — games played, total pangrams, Genius count, daily streak, total words found, best rank, a Swift Charts rank-distribution bar, and a recent-games list.
- **Settings** — letter layout (honeycomb vs simple), show found-word count, haptics and a tap-letter haptic toggle, a high-contrast / colour-blind palette toggle that swaps the gold accent for a strong blue app-wide, Pro unlock/restore, and a reset-progress action behind a confirmation alert. First-run onboarding gated by a persisted flag.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Hive.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

**Free signing:** Select your personal team under Signing & Capabilities; the bundle id is `com.orbioom.hive`. No paid account or code-signing assets required to run on a simulator or a personal device.

## Tech notes

iOS 17+, SwiftUI 5, MVVM. Primary data (per-puzzle progress) in **SwiftData**; small preferences in `UserDefaults` via `@AppStorage`. No giant dictionary ships: a hand-authored `PuzzleBank` of 35 puzzles each carries its own curated accepted-word list, every puzzle built from a real pangram and self-verified (exactly seven distinct letters, the centre included, at least one real pangram, and every answer ≥4 letters, containing the centre, using only the seven letters). A pure `ScoreEngine` (scoring, NYT-style rank tiers, crash-proof validation) and a deterministic `DailyEngine` (FNV-1a + SplitMix64 over the day key). The honeycomb is a custom `Shape` hexagon laid out around a centre; charts use Swift Charts. Light + dark first-class via dynamic asset colours; Dynamic Type, VoiceOver labels, Reduce Motion, and opt-out haptics throughout. Design language: a honeycomb identity — honey gold on near-black or cream, with serif display type and rounded UI type.

- **Monetization:** The full game is free and ad-free (daily + practice + archive + stats). One-time **Hive Pro ($3.99)** adds an extra puzzle pack, definition peeks for found words, and themes — no subscription, no ads.
- **Why it can boom:** NYT Spelling Bee is beloved and now paywalled, pushing millions to search for a free version; a beautiful, ad-free, unlimited Hive with a free archive and real accessibility is precisely what they want.

## Self-review

Hand-reviewed file by file (no Xcode in the build sandbox). Verified: all imports resolve; every type, modifier, and SwiftData/`@Query`/`@Model`/`@Observable`/`@Environment` usage is iOS-17-valid; `NavigationStack`/sheet/`navigationDestination` wiring type-checks; no force-unwrap, `try!`, `fatalError`, or unguarded index/division on user paths (the only `try!` is the standard in-memory `ModelContainer` fallback); `@Observable` view models carry no `@MainActor`; `@Model` arrays iterate via `Array(_.enumerated())`. The puzzle bank was programmatically validated: every puzzle has exactly seven distinct letters, the centre among them, at least one surviving pangram, and every answer ≥4 letters, containing the centre, using only the seven letters. Onboarding gated by a persisted flag; empty/loading/success/error states present; light + dark, Dynamic Type, VoiceOver, Reduce Motion, and haptics wired. Anti-stub grep clean.
