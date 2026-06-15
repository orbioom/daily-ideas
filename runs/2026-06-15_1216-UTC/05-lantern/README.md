# Lantern

A calm, ad-free game of Mahjong solitaire — warm, lantern-lit, and fair.

## What it is

Lantern is a native iOS Mahjong solitaire game (the classic "Turtle"-style
tile-matching solitaire): clear matching pairs of **free** tiles to empty the
board. It is built for people who love this evergreen casual game but are tired
of the top-charts incumbents — the free Mahjong apps that bury a 30-second game
under full-screen video ads, "watch an ad to continue" pop-ups, fake timers, and
aggressive subscriptions. Lantern is the opposite: no ads, no pop-ups, no
account, no data selling. Just a beautiful board, a soft gold glow, and one
small optional one-time unlock.

Audience: casual puzzle players, commuters, and anyone who wants a quiet,
premium tile game that respects their attention.

## Features

- **Four hand-built layouts**: Classic Turtle (144 tiles), Pyramid (120),
  Fortress (140), and a smaller Garden (60) for quick games.
- **Guaranteed-solvable boards** — every deal can be finished (see core logic).
- **Full game toolkit**: tap-to-match, hint (highlights a legal pair), undo
  stack, shuffle (re-deals remaining tiles, preserving solvability), pause,
  restart, live timer, move count, and tiles-remaining.
- **Dead-end detection** with a recoverable sheet (shuffle or restart).
- **Daily Challenge**: one deterministically-seeded board per day — the same
  puzzle for everyone — with a recent-days list, win/time results, and a streak.
- **Stats**: per-layout games / win rate / best & average time, current and
  longest daily streak, and two Swift Charts (games over the last 14 days,
  win-rate by layout), with a calm empty state.
- **Resume on relaunch**: an in-progress game is saved to SwiftData and restored
  via a "Continue" card on the menu.
- **Accessibility**: every tile is VoiceOver-labeled with its suit/value and
  free/blocked state; Dynamic Type across chrome; Reduce Motion honored;
  WCAG-AA contrast in light and dark.
- **Settings**: appearance (System/Light/Dark), haptics toggle, free-tile
  highlight toggle, confirm-on-restart toggle, and tile theme — all persisted.
- **Lantern Pro**: a single, optional one-time unlock. No subscription, no ads.

## Substantive core logic

The engine is pure Swift (no UI), in `Utilities/` and `Models/`:

- **Tiles & set** (`Models/Tile.swift`): the full standard 144-tile set — Bamboo,
  Characters, Circles 1–9 (×4), Winds (×4), Dragons (×4), Flowers (×1), Seasons
  (×1). Matching rule: identical suit+value, with Flowers matching any Flower and
  Seasons matching any Season.
- **Layouts** (`Models/Layout.swift`): slots are `{x, y, layer}` in **half-step**
  units (a tile is a 2×2 footprint), giving the classic half-tile overlap. Slot
  coordinates are generated programmatically with documented block patterns; each
  layout's slot count is even (144 / 120 / 140 / 60).
- **Free-tile rule** (`Utilities/BoardEngine.swift`): a tile is free iff (a) no
  not-removed tile on a strictly higher layer overlaps its footprint, and (b) at
  least one of its immediate left/right neighbor positions on the same layer is
  empty. Footprint overlap is computed correctly for half-step coordinates.
- **Guaranteed-solvable deal** (`Utilities/SolvableDealer.swift`): we use a
  **forward-removal simulation**. Treat the layout as fully populated, then
  repeatedly find the currently-free tiles (using the exact live free rule), pick
  two at random, and remove them — recording the order — until the board is
  empty. That removal order *is* a valid full solution; we then dress each removed
  pair with a matching face-pair. Replaying the order clears the dealt board, so
  it is solvable by construction. A random order can occasionally strand tiles, so
  we retry (capped); a fully-valid fallback guarantees the caller never fails.
- **Shuffle** re-runs the same solver over only the remaining slots, so the
  reshuffled remainder stays solvable.
- The deterministic `SeededRNG` (SplitMix64) makes the Daily Challenge identical
  for a given date and makes generation reproducible/testable.

**Verification:** the sandbox has no Xcode, so the geometry + dealer were ported
to a reference Python solver and validated: across **150 seeds per layout**, the
shipped algorithm produced **0 deal failures and 0 unsolvable boards** for all
four layouts, with slot counts confirmed even (Turtle 144, Pyramid 120, Fortress
140, Garden 60). The replay solver confirmed every recorded removal order is a
legal full solution under the same free-tile rule the app uses at runtime.

## Run

1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. `open Lantern.xcodeproj` — select an iOS 17+ simulator and press **Cmd+R**.

**Free signing:** in the Lantern target's *Signing & Capabilities*, pick your
personal team (Automatic). No paid account is required to run on the simulator or
a personal device.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM. `@MainActor` view models; pure value-type engine.
- **SwiftData** for persistence: `GameRecord` (history/stats), `SavedGame`
  (one resumable in-progress game, board serialized as Codable `Data`),
  `DailyResult` (per-day result). `@AppStorage` holds only small prefs/flags.
- **Swift Charts** for the stats screen (`BarMark`).
- Design language: warm ivory paper, deep lacquer red accent (`#B5342C`), soft
  gold glow; rounded + serif type; beveled ivory tiles with crisp drawn glyphs;
  first-class light and dark mode via a semantic `Theme`.
- **Monetization:** one-time **Lantern Pro** (~$3.99) simulated locally via
  `@AppStorage("isPro")` — no real StoreKit, ads, account, or network. Free tier:
  2 layouts, limited hints/shuffles per game, today's daily only. Pro: all
  layouts, unlimited hints/shuffles, daily archive, premium tile themes.
  Production wires StoreKit 2 in place of the simulated unlock/restore.
- **Why it can boom:** Mahjong solitaire is a proven, evergreen casual
  money-maker, but the category leaders are saturated with ads and dark-pattern
  IAP. Lantern wins on calm: a gorgeous, genuinely ad-free experience with one
  fair unlock — exactly the premium, no-clutter alternative that loyal players of
  this genre keep asking for.

## Self-review

Re-read every Swift file and verified by inspection: all imports
(`SwiftUI`/`SwiftData`/`Charts`/`Combine`/`UIKit`/`Foundation`/`CoreGraphics`);
iOS-17 SDK types, modifiers, and SF Symbols only; correct
`@State`/`@StateObject`/`@Binding`/`@Environment`/`@AppStorage`/`@Query`/
`@EnvironmentObject` ownership; `NavigationStack` + `navigationDestination` and
sheet/alert bindings; `modelContainer`/`modelContext` wiring; two-parameter
`onChange`; Codable board serialization round-trips. The free-tile and
solvable-deal logic was validated with an external reference solver (see above)
and terminates (bounded retries + guaranteed fallback). No force-unwrap, `try!`,
unchecked index, or unguarded division on user paths; the only `fatalError` is
the documented unreachable in-memory `ModelContainer` fallback. Anti-stub grep
(`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/
`stub`) is clean. 31 Swift files; 6 substantive feature screens (Home, Board,
Daily, Stats, plus How to Play and Paywall) beyond Onboarding and Settings.
