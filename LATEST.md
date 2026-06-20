# Run 2026-06-20 — run4

**6 production-ready iOS apps shipped today (entries 316–321 in SHIPPED.md)**

| Slot | App | Category | Bundle ID | Monetization |
|------|-----|----------|-----------|--------------|
| 01-drop | **Drop** | Connect Four game | com.orbioom.drop | One-time Pro |
| 02-hunt | **Hunt** | Boggle word hunt | com.orbioom.hunt | One-time Pro |
| 03-gammon | **Gammon** | Backgammon | com.orbioom.gammon | $2.99 one-time Pro |
| 04-orb | **Orb** | Bubble shooter | com.orbioom.orb | $2.99 one-time Pro |
| 05-brief | **Brief** | Freelance invoice maker | com.orbioom.brief | $4.99 one-time Pro |
| 06-pace | **Pace** | GPS run tracker | com.orbioom.pace | $3.99 one-time Pro |

---

## Top Pick: Brief (05-brief)

**Why:** Freelancers hate FreshBooks pricing ($17+/mo). Brief offers PDF invoice generation, client management, tax/discount calculation, and overdue detection for a one-time $4.99. No subscription anxiety. The "paid invoice" status dopamine hit is real.

**Revenue signal:** r/freelance is full of "I just need a simple invoice app" posts. Honeybook costs $36/mo. There is a clear gap for a polished, offline-first native iOS invoicer.

---

## App Summaries

### Drop (01-drop) — Connect Four
- 7×6 grid, minimax α-β AI (depth 3/5/7 by difficulty), CPU delay 0.5s
- SwiftData win/draw history, Swift Charts win-rate ring
- Navy + gold + red theme

### Hunt (02-hunt) — Boggle Word Hunt
- 4×4 letter grid, 3024-word dictionary, DFS solver finds all valid words
- SplitMix64 deterministic daily seeds, DragGesture path with Canvas overlay
- 2-min countdown, daily challenge with streak badge, Swift Charts 14-day bar

### Gammon (03-gammon) — Backgammon
- Full rules: bar/bearing-off/doubles/blot-hitting/gammon detection
- 3 AI levels (random/greedy/8-heuristic evaluation)
- Canvas-rendered board, 4 color schemes, pass-and-play 2-player (Pro)

### Orb (04-orb) — Bubble Shooter
- Hex grid with odd-row offset, BFS flood-fill ≥3 match + disconnect detection
- 20 level definitions, DragGesture aim + Canvas aim line
- Labeled `outerLoop:` Swift break for nested collision detection

### Brief (05-brief) — Invoice Maker
- Client→Invoice→LineItem SwiftData cascade, all Decimal arithmetic
- UIGraphicsPDFRenderer A4 PDF, UIActivityViewController share
- InvoiceStatus (draft/sent/paid/overdue), BriefDataSeeder sample data

### Pace (06-pace) — GPS Run Tracker
- CLLocationManagerDelegate with NSObject extension, background location
- GPS noise filter (accuracy ≤30m, delta >3m), MET-based calories
- iOS 17 Map + MapPolyline route, Swift Charts 8-week chart, streak tracking

---

## Tech Notes
- All apps: iOS 17+, SwiftUI 5, `@Observable` (not ObservableObject), SwiftData `@Model`
- XcodeGen `project.yml` (no hand-written .xcodeproj)
- Build any: `brew install xcodegen && cd <app>/ios && xcodegen generate`
- App icons generated via Python stdlib (struct/zlib PNG encoding)

---

## Next-Run Signals
- **Gammon** has real revenue potential — App Store backgammon category is stale
- **Pace** privacy angle resonating on social (Strava criticism spiking)
- Avoid finance/budgeting/tax/investment (off-limits per mandate)
- Candidates for next run: Checkers AI, Cribbage, Photo editor, Habit tracker variants
