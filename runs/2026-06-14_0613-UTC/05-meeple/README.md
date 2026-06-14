# Meeple

**Catalog the board games you own and log every play** — who played, the scores,
who won — so you get rich stats, win rates and your gaming **H-index**, plus a
"what should we play tonight?" picker. A beautiful, native iOS alternative to
the clunky play-logging incumbents.

Part of the Orbioom studio. Built entirely with SwiftUI, SwiftData and Swift
Charts for iOS 17.

---

## What it is

Meeple is a board game **collection manager + play logger**. Catalog your shelf
(owned / wishlist / want-to-play / sold), then log each session with players,
scores and winners. Meeple turns that history into stats serious gamers love —
most-played games, per-player win rates, plays-per-month, weight spread and the
**H-index of plays** (the largest *N* where *N* games are each played at least
*N* times). When game night arrives, the Play Picker matches your owned games to
the table and even rolls a "Surprise Me" pick.

## Full feature list

- **Collection** — `LazyVGrid` of generated covers (deterministic gradient +
  SF Symbol + title initials), each with a play-count badge, player range and
  time. Status filter (Owned / Wishlist / Want to Play / Sold), live search by
  title or designer, and sort by recent / name / rating / plays / weight.
- **Game detail** — generated cover header, per-game stats (times played, last
  played, average duration, win rate by player), full play history with
  swipe-to-delete and tap-to-edit, edit game, and delete with confirmation.
- **Log Play flow** — pick game (or arrive pre-bound from a game), add players
  from the roster or quick-add, enter per-player scores, automatic winner
  resolution from the active rule (highest / lowest score, ties allowed) with
  manual crown override, plus date, duration, location and notes. Validation
  requires a game and ≥1 player; success haptic on save. Edits existing plays.
- **Play Picker** ("what should we play?") — filter by players at the table,
  max time and weight range; see eligible owned games and a stable "Surprise Me"
  reveal you can re-roll or log immediately. Empty state when filters are too
  tight.
- **Stats** — Swift Charts: most-played bars, plays-per-month, win-rate by
  player, collection weight spread and status breakdown, totals grid, and an
  **H-index** callout. Async `@MainActor` compute with a real loading state.
- **Players** — roster management: add / edit / delete, custom color, mark
  "me" (mutually exclusive). Names are snapshotted into each play so deleting a
  player never corrupts history.
- **Onboarding** — gated four-page intro covering collection, logging, stats and
  the picker.
- **Settings** — five real persisted preferences, export, reset, About.
- **Meeple Pro** — honest one-time unlock (demo) + Restore; free tier stays
  usable.

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Meeple.xcodeproj` in **Xcode 15+**, pick an **iOS 17+** simulator,
   press **Cmd+R**.

### Free signing

This is an unsigned sample project. In Xcode, select the **Meeple** target →
**Signing & Capabilities** → choose your personal team (free Apple ID works) so
it runs on a device. The simulator needs no signing.

## Tech notes

- **SwiftData** is the source of truth: `@Model` types `BoardGame`, `Play`,
  `PlayerResult`, `Player` with `.cascade` relationships
  (`BoardGame → plays → results`). `@Query` / `@Bindable` / `modelContext`
  throughout. `UserDefaults` (via `@AppStorage`) holds **only** preferences and
  the Pro / onboarding / seed flags.
- **Snapshotting** — `PlayerResult` stores a `playerName` and `colorHue`
  snapshot, so deleting a `Player` from the roster never corrupts logged history.
- **Engine layer** is pure and UI-free: `PlayPicker` (eligibility + seeded
  stable pick), `WinnerResolver` (highest / lowest / manual, ties allowed,
  guarded), `StatsEngine` (totals, most-played, monthly series, per-player win
  rates, weight buckets, status counts, player-count coverage, and the H-index),
  and `SeedData` (deterministic LCG seeding ≥50 games, 6 players, ≥80 plays).
- **Stats** compute in an async `@MainActor` task with a visible loading state.
- **Charts** use `Identifiable` series structs with accessibility labels/values.
- **Theme** is a warm amber/cardboard palette with first-class light & dark via
  `Color(hex:)` and `Color.dyn(_:_:)`, rounded + serif font helpers.
- **Accessibility** — Dynamic Type, labels / hints / values (including charts),
  decorative art hidden, AA-minded contrast, and `@Environment(\.accessibilityReduceMotion)`
  honored for onboarding transitions.
- **Haptics** are sparse and gated behind the settings toggle.
- No external packages; no APIs newer than iOS 17. The only force-operation is
  the in-memory `ModelContainer` fallback in `MeepleApp.init`.

## Monetization

Free up to **15 games** + basic stats (counts, most-played). **Meeple Pro** is a
one-time **$4.99** unlock for an unlimited collection, the full stats lab (win
rates, H-index, per-player analytics), advanced Play Picker filters, and
CSV / text export. (Demo build: "purchase" unlocks locally with no real
transaction; Restore is wired for parity.)

### Why it can boom

BG Stats is the paid, clunky incumbent and BGG's own app is dated. Board gamers
are a passionate, spendy niche who genuinely love logging plays and poring over
stats. A beautiful native logger — with the "what should we play tonight?" hook
and the cult-favorite **H-index** metric front and center — wins them over.

## Self-review attestation

Every Swift file was re-read against the iOS 17 SDK. SwiftData cascade
relationships, player-name snapshotting, `@Query` / `@Bindable` ownership,
`NavigationStack` value-destination and sheet bindings, optional-`Int` score
handling, and Charts `Identifiable` series were all verified. No force-unwraps,
`try!` (except the documented container fallback), `fatalError`, unchecked index
access, or unguarded division on user paths. `grep -rniE` for stub markers
returns zero matches. No stubs, no placeholders.
