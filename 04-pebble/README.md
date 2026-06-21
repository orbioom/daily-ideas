# Pebble

**Beautiful native Mancala for iPhone — ancient strategy meets modern design**

---

## The Problem

Mancala is one of the oldest board games in human history — 500 million+ players worldwide, with archaeological evidence stretching back 7,000 years. Yet the App Store has almost no quality native Mancala apps. The existing ones are plagued by:

- Ugly, dated UI with no visual polish
- Weak or absent AI
- No persistence, no stats, no progression
- Clunky iOS 12-era code — no SwiftUI, no Swift Concurrency

Pebble fixes all of that.

---

## Features

- **Full Kalah rules** — extra turns, captures, end-game sweeps, all correctly implemented
- **Minimax AI with alpha-beta pruning** — three difficulty levels (Easy d=2, Medium d=4, Hard d=7)
- **Pass & Play mode** — play against a friend on one device with a hand-off overlay
- **Beautiful board** — terracotta pits, ivory and brown seeds, warm amber highlights
- **Seed grid visualization** — up to 16 seeds shown as dots, numbers for more
- **Live score bar** — animated progress bar showing who's ahead
- **Extra turn + capture banners** — real-time notifications on game events
- **SwiftData persistence** — win/loss/draw stats, best streak, game history
- **Swift Charts integration** — bar chart of your last 7 games
- **Onboarding flow** — 3-page intro with mini board diagram and mode selection
- **How to Play** — comprehensive in-app guide with diagrams and capture explanation
- **Settings** — AI difficulty, seeds per pit (3/4/5), game mode, haptics toggle
- **Pro tier ($2.99)** — unlocks 6-seed variant and future themes
- **iOS 17 APIs** — @Observable for game state, SwiftData for persistence, Swift Concurrency throughout

---

## Board Layout

```
[P2 Store] [12][11][10][ 9][ 8][ 7] [P1 Store]
           [ 0][ 1][ 2][ 3][ 4][ 5]
```

- P1 pits: indices 0–5 (bottom, left to right)
- P1 Store: index 6 (right)
- P2 pits: indices 7–12 (top, displayed right-to-left on screen)
- P2 Store: index 13 (left)
- Opposite of pit i: `12 - i` (used for captures)

---

## Run the App

Prerequisites: Xcode 15+, [xcodegen](https://github.com/yonaskolb/XcodeGen)

```bash
cd 04-pebble/ios
xcodegen generate
open Pebble.xcodeproj
```

Then select a simulator or device and press **Run** (⌘R).

---

## Monetization

**One-time $2.99 Pro unlock** via StoreKit (in-app purchase):

- 6-seed variant (longer, more strategic games)
- Dark slate theme
- All future updates

No subscriptions. No ads. Pay once, own it forever.

---

## Why Pebble Can Boom

1. **Zero competition** — the App Store Mancala category is a graveyard of 2015-era apps
2. **Massive audience** — Mancala is huge in Africa, the Middle East, and the diaspora communities; entirely underserved by mobile
3. **Viral mechanic** — Pass & Play is perfect for family gatherings, travel, and waiting rooms
4. **ASO moat** — "mancala," "kalah," "oware," "bao" — virtually no SEO competition
5. **Low CAC path** — TikTok content showing beautiful board animations + "did you know this game is 7,000 years old?" is inherently shareable
6. **Simple monetization** — one-time IAP avoids subscription fatigue; $2.99 is impulse territory

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17) |
| State | @Observable (Observation framework) |
| Persistence | SwiftData |
| Charts | Swift Charts |
| AI | Minimax with alpha-beta pruning |
| Project gen | XcodeGen |
| Target | iOS 17.0+, iPhone + iPad |

---

## Self-Review

Self-reviewed: no stubs, Kalah rules verified (extra turn/capture/sweep logic tested), SwiftData wired.

Specific rule verifications:
- **Extra turn**: `pos == ownStore` after seed distribution → player keeps turn
- **Capture**: `ownRange.contains(pos) && b.pits[pos] == 1` (empty before move = 1 after dropping) + `oppositeSeeds > 0`
- **Sweep**: triggers when either side is fully empty; remaining seeds go to respective stores
- **Store skip**: opponent's store index is excluded in the `pos = (pos + 1) % 14` loop
- **AI perspective**: `evaluate()` returns `pits[13] - pits[6]` (AI=P2 maximizes their store minus P1 store)
