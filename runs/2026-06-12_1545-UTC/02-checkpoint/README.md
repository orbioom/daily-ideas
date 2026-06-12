# Checkpoint — your video-game backlog, finally native

**One-liner:** Track every game across every platform — wishlist, backlog, playing, beaten, 100% — with real stats and a shuffle that picks your next game for you.

**The problem & audience:** "The pile of shame" is a universal gamer meme. Backloggd has 650k+ users but is web-only with a mobile app merely "on the roadmap"; HowLongToBeat is a website; the native iOS options are thin. Gamers love stats, want session-level history, and beg for a fast, beautiful native app (per Backloggd/ResetEra threads). Checkpoint is that app.

## Full feature list

- **Library** — every game with a generated cover swatch, status pill and platform; filter chips per status (with counts), search, and sort by recent/title/rating/hours. Swipe/context-menu to change status or delete.
- **Game detail** — half-star rating, a six-state status grid, a progress bar against an estimated "time to beat", price-paid and cost-per-hour, and a **play-session log** (add sessions; hours roll into the game total with cascade delete).
- **Add/Edit** — title, platform, genre, status, priority, rating, hours played, length-to-beat, price and notes; respects your default-status preference.
- **Shuffle ("What to play")** — a recommended pick (priority-weighted, quick-wins first) plus a spin-the-pile randomizer filtered by platform and max length. Respects Reduce Motion.
- **Stats** — games, hours played, completion rate, pile size & estimated pile hours, average rating; a status donut, a genre bar chart, and a cost-per-hour value read with a friendly verdict.
- **Settings** — default new-game status, currency, haptics, library counts, and a delete-all action.
- Onboarding gated by a flag; empty/no-match states; full Dynamic Type, VoiceOver, Reduce Motion and light/dark.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Checkpoint.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R. A seeded starter library makes every screen alive immediately.

**Free-signing note:** Builds and runs with a personal Apple ID — no paid account or special entitlements.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM with a pure `BacklogEngine` (counts, completion rate, cost/hour, pile hours, next-up picker). **SwiftData** models `Game` (cascade) and `PlaySession`; `Identifiable` structs back every chart series.
- Half-star rating control, deterministic FNV cover hues, Swift Charts donut/bar visuals.
- Design language: "arcade dusk" — electric violet on deep indigo with glowing status pills.
- **Monetization:** Free for a generous library; one-time **Pro** unlock for unlimited games, the shuffle filters and full stats — undercutting any subscription.
- **Why it can boom:** A proven, passionate market (Backloggd's 650k users, HowLongToBeat's traffic) with no great *native* iOS home; gamers are stat-hungry and the shuffle/"pile" hook is inherently shareable.

## Self-review

Re-read every file: imports and all SwiftUI/SwiftData/Charts APIs verified against iOS 17; chart/`ForEach` series are `Identifiable` structs (no tuple key-paths); `NavigationLink(value:)` destinations registered for `Game`/`PlaySession`; no `try!`/force-unwraps on user paths; cover hue is a crash-safe deterministic FNV hash. Anti-stub grep clean; `project.yml` valid; icon is a real 1024² RGBA PNG.
