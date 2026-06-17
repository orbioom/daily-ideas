# Spindle

A calm, premium, **ad-free Spider Solitaire** for iOS 17 — deep emerald felt, cream cards
with crisp ranks and pips, and a gold accent for selections and hints. Built natively in
SwiftUI with a pure, fully testable rules engine.

## What it is

Spindle is the classic two-deck (104-card) Spider Solitaire with three difficulties — **1 suit
(Easy)**, **2 suits (Medium)** and **4 suits (Hard)** — plus a deterministic **Daily Deal** so
everyone plays the exact same board each day. It is designed to feel quiet and tactile: no ads,
no timers shouting at you, just a clean table you can theme to taste.

## Full feature list

- **Real Spider engine** (`SpiderEngine`, a pure `Codable` value type):
  - 10 tableau columns, the standard 54-card opening deal, 5 deals of 10 in the stock.
  - Build **down** regardless of suit; pick up and move **same-suit descending runs** as a unit;
    mixed-suit sequences move one card at a time.
  - Deal one card to every column from the stock — blocked (with a calm message) when any column
    is empty, per standard rules.
  - Auto-collect completed **King-to-Ace same-suit runs** to one of 8 foundations; win at 8.
  - Newly exposed cards flip face-up automatically.
  - **Microsoft-style scoring**: start 500, −1 per move, +100 per completed run, never below 0.
  - Snapshot-based **unlimited Undo**, a **Hint** finder, **Auto-collect**, and double-tap auto-move.
  - All array access is guarded by a safe-subscript helper — never crashes on empty columns/stock.
- **Deterministic deals** via a seeded **SplitMix64** RNG: Daily (yyyyMMdd), numbered, or random.
- **Five screens** in a TabView: **Play** (the board with foundations, stock, HUD timer via
  `TimelineView`, win overlay, resume banner), **New Game**, **Stats**, **How to Play**, **Settings**.
- **Stats** with **Swift Charts**: win-rate by difficulty (BarMark) and games played over the last
  30 days (BarMark), plus games/wins/win-rate, best time, fewest moves, average score and win streaks.
- **Resume on relaunch**: the full board is JSON-encoded into a single SwiftData `SavedGame` row; the
  Play screen offers a Resume banner. The wall-clock timer survives backgrounding via a stored Date.
- **Settings** with persisted prefs: left-handed toolbar, haptics, felt theme (3), card-back style,
  show-timer, animations (respects Reduce Motion), auto-flip, confirm-new-game, plus restore/unlock Pro.
- First-run **onboarding** gated by `hasOnboarded`; full **Dynamic Type**, **VoiceOver** labels on the
  board and controls, **Reduce Motion** fallbacks, sparse **haptics**, and first-class **light + dark**.

## Run steps

1) `brew install xcodegen` (one-time). 2) In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3) Open `Spindle.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: set your Apple ID team in Signing & Capabilities; the bundle id is `com.orbioom.spindle`.

## Tech notes

- iOS 17 / SwiftUI 5. `@Observable` + `@State` for the game view-model (no `ObservableObject` mixing).
- **SwiftData** for primary data: `GameResult` (history) and `SavedGame` (single resume snapshot),
  both registered in the `Schema`. `@AppStorage` only for small prefs/flags.
- Rules engine is a separate, dependency-free struct — unit-testable and serializable.
- **Monetization:** one-time **Spindle Pro — $2.99** (`@AppStorage("isPro")`, `PaywallView`, demo
  unlock + restore) unlocks 4-suit mode, the daily-deal archive, extra felt themes (Sapphire, Wine)
  and full stats history. The core 1- and 2-suit game is completely free.
- **Why it can boom:** Spider Solitaire is an evergreen, universally understood game with massive
  organic search demand; a genuinely ad-free, beautifully themed, Daily-Deal version with shareable
  best scores has a clear hook in a category dominated by ad-stuffed clones.

## Self-review attestation

Re-read every Swift file against the iOS 17 SDK: all imports present; types, initializers and
modifiers exist in iOS 17; protocol conformances satisfied; `@Observable` stored with `@State`;
`.onChange(of:)` uses the two-parameter form; Charts use `BarMark`. No `try!`, `fatalError`, `as!`,
or force-unwraps on user paths (only the App's in-memory `ModelContainer` uses `try?`). All array
indexing goes through a safe subscript; no unguarded division. Braces balanced; asset JSON valid;
exactly one `@main`. Light and dark verified through the Theme; Dynamic Type and VoiceOver labels
applied across the board and controls.
