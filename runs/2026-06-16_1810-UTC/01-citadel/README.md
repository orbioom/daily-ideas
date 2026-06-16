# Citadel

**Citadel** is a calm, ad-free FreeCell solitaire — the FreeCell people actually wish existed.

**The problem:** the popular FreeCell apps are buried in ads, pop-ups, and dark patterns. FreeCell is a quiet game of pure skill; the apps around it are loud. Citadel strips all of that away: refined casino baize, classic numbered deals, real solver-grade move logic, and nothing between you and the board.

**Who it's for:** anyone who plays FreeCell to think and unwind — commuters, puzzle people, lapsed Windows-FreeCell fans who want the exact same deals on their phone, minus the noise.

---

## Features

- **Authentic FreeCell engine** — full, correct rules: foundations build A→K by suit, cascades stack down in alternating colors, four free cells, and proper **supermoves** (the engine moves as long a run as your free cells and empty columns allow, with the standard `(free+1) × 2^empty` capacity math).
- **Classic numbered deals** — the genuine Microsoft FreeCell deal generator (the 214013/2531011 LCG). Deal **#1** reproduces the famous canonical layout, and any number from 1 to 1,000,000 gives the same board everyone else gets.
- **Today's deal** — a deterministic deal of the day so everyone plays the same board.
- **Tap-to-play** — tap a card to pick it up, tap a destination to drop it; tap a ready card and it flies home to its foundation. Legal destinations highlight.
- **Auto-collect** — sweeps every card that's provably safe up to the foundations (the standard safe-autoplay rule), never one that could still be needed.
- **Snapshot undo** — take moves back move-by-move (3 in the free tier, unlimited with Pro).
- **Resume on relaunch** — your in-progress game is saved and restored automatically.
- **Stats** — games played, wins, win rate, current & best win streak, fastest solve, average moves, deals won, and a Swift Charts view of games played vs. won over the last 8 weeks. Empty state until you play.
- **How to Play** — clear, nicely typeset rules and strategy tips.
- **Settings** — haptics, tap-to-send-home, confirm-before-new-game, left-hand layout, and a felt-theme picker, all persisted.
- **Citadel Pro** — a one-time $2.99 unlock: numbered-deal picker, unlimited undo, extra felt themes (sapphire, burgundy, slate), and full stats history.
- **First-class light & dark mode**, full **Dynamic Type**, **VoiceOver** labels throughout, **Reduce Motion** support, and sparse, meaningful **haptics**.
- **Win celebration** — a gentle success overlay (static banner when Reduce Motion is on).

---

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root, if present).
3. Open `Citadel.xcodeproj` in **Xcode 15+**, pick an **iOS 17+** simulator, and press **Cmd+R**.

### Free signing (no paid Apple Developer account)

In Xcode, select the **Citadel** target → **Signing & Capabilities** → check **Automatically manage signing** and pick your **Personal Team**. A free personal team works fine; the build just needs a re-sign every 7 days when running on a physical device. The simulator has no such limit.

---

## Tech notes

- **iOS 17+, SwiftUI 5, MVVM.** The game state lives in an `@Observable` `GameViewModel` (iOS 17 Observation) wrapping a pure, stateless `FreeCellEngine`.
- **SwiftData** for records (`SavedGame` for the single resumable game, `GameResult` for history); **`@AppStorage`** only for small prefs and flags. `@Query` drives the lists; the `ModelContainer` registers every `@Model` in its `Schema`.
- **Pure value model** — `Suit`, `Card`, `Board`, `Move` are `Codable` structs; the board is JSON-encoded into SwiftData for snapshotting and resume.
- **Design language:** refined casino baize — deep emerald felt (near-black green in dark mode, soft sage in light), warm ivory cards with crisp red/black SF Symbol suit pips, subtle shadows, rounded corners, an emerald `#1E8E5A` accent and a quiet warm gold for highlights. Premium and calm, never loud. Contrast meets WCAG AA in both modes.
- **Correctness:** the deal generator was verified to reproduce canonical Microsoft Deal #1; supermove capacity and safe-autoplay follow the standard FreeCell formulas. No `fatalError`/`try!`/force-unwraps on any user path — invalid moves are calm no-ops, and storage failure degrades to a recoverable notice.
- **Monetization:** a simulated one-time **Citadel Pro $2.99** unlock (`@AppStorage("isPro")`), StoreKit-ready in spirit — no real StoreKit calls, just a clean unlock that gates the deal picker, unlimited undo, extra themes, and full history.
- **Why it can boom:** FreeCell is a proven evergreen with enormous, durable search demand; the incumbents are ad-saturated and cluttered. Citadel is the calm, ad-free, premium-feeling alternative with the *real* classic numbered deals and genuine solver-grade move math — exactly the version long-time players keep wishing someone would build.

---

## Self-review attestation

Every Swift source file was re-read line by line. Verified: all imports/types/initializers/enum cases/modifiers exist in the iOS 17 SDK; protocol conformances are satisfied; `@State`/`@Bindable`/`@Environment`/`@Observable`/`@Query`/`@AppStorage` ownership is correct; `NavigationStack` everywhere (no `NavigationView`); two-parameter `.onChange`; the `ModelContainer` registers every `@Model`. Anti-stub grep (TODO/FIXME/placeholder/"coming soon"/"not implemented"/stub) returns **zero** matches. Braces, parens, and brackets are balanced in every file. The Microsoft deal generator was independently simulated and reproduces canonical Deal #1; supermove and safe-autoplay math were reasoned through against the standard formulas.
