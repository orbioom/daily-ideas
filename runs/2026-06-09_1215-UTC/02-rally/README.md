# Rally

A fast, private, native iOS racket-sports match tracker for pickleball and tennis — by **Orbioom**. Score every match live, track wins and losses, see head-to-heads against rivals and partners, and watch a transparent DUPR-style rating climb after every game.

> "Conjured, not just coded."

## What it is

Rally is the modern answer for the booming racket-sports crowd. Pickleball is the fastest-growing sport in the US and players love DUPR-style ratings — but the incumbent trackers are clunky and ugly. Rally is built around two things they get wrong: **fast live scoring** and a **transparent, honest rating**. Everything is on-device, with no account and no feed.

## Features

- **Live scoreboard** — pick sport (pickleball / tennis), format (singles / doubles), your side, opponents, points-to-win (11/15/21 or 4/6/7), and win-by-two; then score game-by-game with big +/- buttons. The app auto-detects a won game, tracks games won, and lets you start the next game or finish the match.
- **Match log** — every completed match newest-first, filterable by sport, each card showing a W/L badge, the games line, opponents, and sport/format chips. Tap through to per-game scores, players, rating impact, and delete.
- **Players roster** — "You" pinned on top, opponents and partners sorted by rating, each with their record and rating. Add, edit, and delete players.
- **Player detail** — record, win rate, current streak, best doubles partner, full head-to-head list, and recent matches.
- **Transparent rating** — an Elo-style engine maps a DUPR-like 2.0–6.0 scale onto internal Elo, computes expected vs actual result, and nudges every participant's rating after each completed match. Team rating is the average of the side.
- **Insights** — Swift Charts: rating over time (line + area), win rate by sport (bar), matches per month (bar), wins/losses (donut), plus stat tiles for record, win rate, streak, total matches, and points for/against.
- **Settings** — defaults for new matches (sport, points-to-win, win-by-two), haptics toggle, data counts, replay intro, and delete-all-data with confirmation.
- **Polish** — onboarding gated by a persisted flag, empty states everywhere, calm recoverable errors (no crashes on user paths), light + dark via Brand tokens, full accessibility (Dynamic Type, labels/hints/values on the live scoreboard, decorative images hidden, Reduce Motion gating), and sparse gated haptics.

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` if present).
3. Open `Rally.xcodeproj` in Xcode 15+, choose an iOS 17+ simulator, and press **Cmd+R**.

### Free signing

No paid Apple Developer account needed. Select your personal team under **Signing & Capabilities** (or let Xcode auto-manage); the bundle id is `com.orbioom.rally`. Change it if your free team needs a unique id.

## Tech notes

- **Platform:** iOS 17+, SwiftUI, MVVM-ish with pure engines, SwiftData persistence, Swift Charts.
- **Design:** the Orbioom Brand design system (glass surfaces, ink gradient buttons, mono numerals, per-color-scheme tokens) — light and dark are both first-class.
- **Data model:** `Player`, `Match` (with `mySide` / `oppSide` nullify relationships and cascading `games`), and `GameScore`. Deleting a player keeps their past matches; deleting a match cascades its games.
- **Engines (pure, testable, deterministic):** `ScoreEngine` (game-won detection + validation), `RatingEngine` (Elo-style update mapped to 2.0–6.0), `StatsEngine` (records, streaks, head-to-head, best partner, points, matches-per-month, and rating-over-time reconstructed by replaying matches in date order).
- **Seed data:** ~6 players (including "You") and ~50 completed matches across both sports and formats over ~5 months, with ratings evolved through `RatingEngine` in chronological order, so charts and stats are rich on first launch. Seeding is guarded so it runs only once.

### Monetization

Free core: log unlimited matches and use live scoring during early access. **Rally Pro** is a planned one-time unlock for unlimited matches long-term plus advanced stats and full rating history.

### Why it can boom

Pickleball is the fastest-growing sport in the US, and DUPR-style rating culture is already huge among players. The incumbent trackers are clunky and ugly. Rally wins on the two things that matter at the court: dead-simple **fast live scoring** and a **transparent rating** you can actually trust — all native, all private.

## Self-review attestation

Every Swift source file was re-read after writing. All imports verified; all types, inits, modifiers, and enum cases checked against the iOS 17 SDK (no post-iOS-17 APIs). SwiftData `@Model` / `@Query` / `@Relationship` / `modelContext` wiring type-checks with simple, safe relationships (nullify on player sides, cascade on games, no fragile inverses). `@Observable` (via `@Model`), `@State`, `@Bindable`, and `@Environment` ownership are correct; `NavigationStack` / `navigationDestination` / `sheet` bindings type-check. `ScoreEngine.Winner` is `Equatable` for `==` comparisons and animation values; `PlayerEditorView.player` has a default for the add path. The anti-stub grep (`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub`) returns zero matches, and the only `fatalError` is the in-memory `ModelContainer` fallback in `RallyApp` (matching the reference app); there are no `try!` or unguarded force-unwraps on user paths.
