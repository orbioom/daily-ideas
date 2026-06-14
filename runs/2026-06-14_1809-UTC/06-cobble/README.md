# Cobble — block puzzle

**One-liner:** Drop blocks onto an 8×8 grid, clear full rows and columns, and chase combos — the addictive block puzzle, with no ads, ever.

**The problem + audience:** Block-drop puzzles (Block Blast, Woodoku, 1010!) are among the highest-grossing, most-downloaded mobile games on earth — and they are *drowning* in forced interstitial ads and dark patterns. Cobble is for the enormous casual-puzzle audience that loves the genre and would happily pay a couple of dollars once to never see an ad again.

## Full feature list
- **Play (Classic)** — an 8×8 board with a three-piece tray; **tap a piece to select it, then tap the board** to see a green/red ghost preview and place it; clearing any full row or column removes those cells with satisfying feedback; a combo multiplier rewards consecutive clears. Score + best header, Undo, a game-over overlay, and **resume of your in-progress game on relaunch**.
- **Daily Challenge** — a deterministic, seeded board-and-piece sequence that's the same for everyone each day, with its own best and a play streak. (Today is free; the past-days archive is Pro.)
- **How to Play** — clear, illustrated rules: placing, clearing rows/columns, combos, scoring, and how the game ends.
- **Stats** — best score, games played, total lines cleared, average score, longest combo, recent results, and Swift Charts (score over time, lines per game), with empty and loading states.
- **Settings** — haptics, block color theme (default free + Pro themes), show-placement-ghost, sound; plus Pro, reset stats, Load sample data, About.
- **Onboarding** (3 pages), first-run gated; 60 seeded past results across ~4 weeks so Stats and charts are alive immediately.

## Run steps
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Cobble.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing note:** No paid account needed — set a Personal Team and use the `com.orbioom.cobble` bundle id (or your own). No entitlements required.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. **SwiftData** (`GameResult`, `SavedGame`); the in-progress grid and pieces are stored as JSON Codable strings (never raw `[[Int]]`) and decoded with safe fallbacks, so a corrupt save can never crash the game.
- Pure, deterministic `BlockEngine`: bounds-checked `canPlace` / `place`, full-row/column detection with a de-duplicated cleared-cell set, a documented combo-scaled scoring function, `isGameOver` (true only when no offered piece fits anywhere), and a SplitMix64 piece dealer that replays deterministically (so daily challenges and refills are reproducible across relaunch).
- Tap-to-place interaction (reliable and accessible) with a clamped ghost preview; bounded Undo stack. Every grid subscript is bounds-checked; no force-unwrap or unguarded division on any game path.
- Design language: playful-but-premium — vivid blue accent, glassy rounded blocks with a soft highlight, a cohesive (not rainbow) palette; first-class light & dark via `Theme.dyn`; Dynamic Type, VoiceOver labels on board cells and pieces, Reduce Motion respected (clear/combo animations gated).
- **Monetization:** the full game is free with no ads; **premium color themes, unlimited Undo (free capped at 3/game), and the Daily Challenge archive** are a one-time **$2.99** Pro unlock (StoreKit not wired; demo unlock + Restore). Who pays: genre fans escaping the ad-soaked incumbents.
- **Why it can boom:** the block-puzzle genre is a proven mega-hit with massive download volume; its biggest weakness — relentless ads — is exactly what Cobble removes. "Block Blast without the ads, for the price of a coffee" is a clean, ride-the-trend pitch.

## Self-review
38 Swift files. Static audit clean: one `@main`, one `try!` (in-memory fallback), anti-stub grep clean, valid asset JSON, real 1024² icon, balanced delimiters. Both `@Model` types registered in both `ModelContainer` calls; ≥4 feature screens + Settings; empty/loading/error/success states; engine place/clear/game-over logic traced; all grid subscripts bounds-checked. A dedicated compile-review pass verified the engine, gesture/coordinate mapping, and Codable persistence against the iOS 17 SDK.
