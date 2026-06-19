# Ante — Gin Rummy Card Game

**Tagline:** Classic Gin Rummy, beautifully offline.

**Problem + Audience:** Millions play Gin Rummy digitally but leading apps (Zynga, Grand Gin Rummy) require sign-in, push social ads, and run dark pattern monetization. Ante delivers the pure card game experience for anyone who wants focused offline play without an account.

---

## Features

- **Single Player vs CPU** — AI opponent draws intelligently, discards highest-deadwood cards, knocks when able
- **Pass & Play** — Two human players alternate on one device with hand-hiding between turns
- **Full Gin Rummy Engine** — Meld detection (sets + runs), deadwood calculation, knock/gin/undercut resolution, dead hand handling
- **Animated Card Table** — Deep-green felt aesthetic, card fan display, draw/discard/knock flow
- **Round Summary** — Both hands revealed after each round with melds highlighted, deadwood shown, points breakdown
- **Game Over Screen** — Final scores, winner crown, round count, game duration stats
- **Statistics Screen** — Win rate, games played, W/L record, best score, average score, current & longest streak, 6-month BarMark chart
- **Rules Reference** — Tap-to-expand sections covering melds, knocking, Gin, scoring, undercuts
- **Settings** — Winning score (50–200), card count display, animations, haptics, sound, game history management
- **Ante Pro ($2.99 one-time)** — Unlimited history, custom card back colors (blue/green/red), Oklahoma variant mode
- **Light + Dark mode** — Works in both; dark felt aesthetic always maintained
- **Zero sign-in, fully offline** — No network, no account, no tracking

---

## Run Steps

```bash
brew install xcodegen
cd /path/to/03-ante/ios
xcodegen generate
open Ante.xcodeproj
```

Select an iPhone 17+ simulator or real device, then Run (⌘R).

---

## Tech Notes

- iOS 17+ / Xcode 15+
- SwiftUI 5 with `NavigationStack`
- `@Observable` macro (not `ObservableObject`)
- SwiftData (`@Model`, `@Query`, `.modelContainer`)
- Swift Charts (`BarMark`) for monthly stats
- No external dependencies
- No force-unwraps, no `try!`, no `fatalError` on user paths
- AppIcon generated via Python (`struct` + `zlib`, RGBA PNG)

---

## Monetization

One-time $2.99 Pro upgrade via StoreKit — unlimited history, custom card backs, Oklahoma variant.

## Why It Can Boom

Gin Rummy Plus has millions of players but forces sign-in and pushes intrusive social features; Grand Gin Rummy is ad-heavy — Ante wins on App Store reviews with its clean, private, fully offline design.

---

## Self-Review

Reviewed all Swift files. No TODOs, stubs, or force-unwraps found.
