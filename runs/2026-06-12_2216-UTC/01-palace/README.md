# Palace — Klondike Solitaire Without the Ads

**What it is:** Classic Klondike solitaire built like a quiet members' card room — deep felt, ivory cards, brass-gold accents — for the millions of people who play solitaire daily and are fed up with the 15–20 full-screen ads per hour the category leaders serve. The audience is everyone: solitaire is a perennial top-charts game.

## Full feature list

- **Complete Klondike rules engine** — draw-one and draw-three, alternating-color tableau builds, partial-run moves, king-to-empty-column, foundation builds by suit, waste recycling, win detection.
- **Tap-to-move play** — tap any face-up card and it glides to its best legal destination (foundation first, then tableau); illegal taps shake the card with a warning haptic. Foundation cards can be tapped back down to the tableau.
- **Standard scoring** (+5 waste→tableau, +10 to foundation, +5 card flip, −15 foundation→tableau, −100 draw-one recycle, floored at zero) with a live score/time/moves bar (toggleable).
- **Pause-safe game clock** — accumulates only while you play; backgrounding pauses it.
- **Unlimited undo** (200-step history) that never rewinds the clock.
- **Auto-finish** — when nothing is hidden and the stock/waste are empty, a Finish Game button cascades the rest to the foundations with animation.
- **Resume on relaunch** — the in-progress game is saved to disk (JSON, Application Support) on backgrounding and restored at launch.
- **History tab** — every won/lost game recorded (score, moves, duration, draw mode) with swipe-to-delete.
- **Statistics tab** — win rate, current/longest win streaks, best time/score/fewest moves, and a 14-day won/lost stacked bar chart (Swift Charts).
- **Learn tab** — full rules, the exact scoring table, and a strategy primer.
- **Settings** — draw one/three, three felt styles (Classic Green / Midnight / Burgundy), left-handed layout, score-bar toggle, haptics toggle.
- **Onboarding** (3 pages, persisted flag), empty states, confirmation before abandoning a game, full Dynamic Type, VoiceOver labels on every pile and card, Reduce Motion honored (no shake/scale animations), light + dark felt variants.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Palace.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

*Free signing:* in Signing & Capabilities choose your personal team; the bundle id `com.orbioom.palace` can be suffixed if needed.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-ish: a pure `@Observable` `GameEngine` over a Codable `GameState`, views own persistence.
- SwiftData for finished-game records; `FileManager` JSON for the resumable in-progress game; `UserDefaults`/`@AppStorage` for preferences only.
- Design language: "members' card room" — felt gradients per color scheme, serif numerals, brass gold `#D6B25E`, custom card faces/backs drawn in SwiftUI.
- **Monetization:** free with a one-time "Palace Club" unlock (extra felt/back styles + stats history beyond 30 days) — the $1.99–4.99 remove-ads price point is the most-purchased IAP in this category; we sell delight instead of ad removal.
- **Why it can boom:** solitaire is permanently top-10 by playtime; the leader (MobilityWare) shows 15–20 ads/hour and even its paid tier draws complaints — a genuinely beautiful, honest, ad-free Klondike is the version everyone says they want.

## Self-review

Re-read every Swift file before commit: all imports resolve (SwiftUI/SwiftData/Charts/Observation/UIKit); `@Observable @MainActor` engine accessed only from views; no force-unwraps/`try!`/`fatalError` on user paths (the only `!` is on a guarded `best` optional immediately after a nil check); array indexing guarded (`index < pile.count`); `@Query` sorts on stored properties; Charts use `Identifiable` structs (no tuple key paths); iOS 17 APIs only (`ContentUnavailableView`, `.snappy`, `onChange(of:)` two-parameter form). Anti-stub grep clean (no TODO/FIXME/placeholder). `project.yml` names the real `Palace` folder and `Info.plist`.
