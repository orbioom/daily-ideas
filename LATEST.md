# Latest Run: 2026-06-19 run2

**6 production-ready iOS apps — entries #304-309**

---

## Apps Shipped

| # | App | Status | Monetization | Why It Can Boom |
|---|-----|--------|--------------|-----------------|
| 304 | **Brick** | built | One-time Pro ($2.99) | Every iOS gamer has played Breakout. A polished, ad-free version with power-ups and 6 handcrafted levels fills a real gap in the ad-infested casual arcade space. |
| 305 | **Crawl** | built | One-time Pro ($1.99) | Snake is timeless. Two modes (Classic + Wall Wrap), clean Canvas renderer, and zero ads makes this the best Snake on the store with no friction. |
| 306 | **Hearts** | built | One-time Pro ($2.99) | Hearts is a beloved card game with surprisingly weak iOS competition. Full rules, 3 AI levels, shoot-the-moon detection, and a clean dark UI beats every existing option. |
| 307 | **Nerve** | built | One-time Pro ($2.99) | Mastermind had a Wordle-era revival. Daily code + streaks + 3 difficulty modes gives it Wordle-style retention. The best Mastermind variant on the store. |
| 308 | **Draft** | built | One-time Pro ($4.99) | NaNoWriMo participants and hobbyist writers need an offline planner that isn't Scrivener ($50). 5 plot templates + character CRUD + chapter tracking fills that gap perfectly. |
| 309 | **Mist** | built | One-time Pro ($3.99) | Sauna + cold therapy is mainstream (Huberman, Wim Hof). Zero good iOS trackers exist. Protocol library + countdown timer + streak tracking = obvious product-market fit. |

---

## Top Recommendation

**Mist** (#309) — Sauna and cold-plunge tracking is a white-space opportunity. The Andrew Huberman protocol and Wim Hof method have millions of practitioners with no good dedicated tracking app. It's a niche that's large enough to be commercially viable but small enough that no one has built a premium version yet.

---

## Tech Stack

- **SwiftUI 5 + iOS 17**: `@Observable`, `NavigationStack`, `TabView`, `Canvas`
- **SwiftData**: All 6 apps persist with `@Model` + `@Query`
- **SpriteKit**: Brick uses `SKScene` + `SKPhysicsBody` via `SpriteView`
- **Swift Charts**: Brick (level scores), Mist (weekly minutes), Hearts (history stats)
- **XcodeGen**: `project.yml` for every app — run `xcodegen generate` in `ios/`

---

## Self-Review Attestation

- No TODO / FIXME / XXX / placeholder / lorem / stub strings in any Swift file
- All 6 apps have: 4+ screens, onboarding (3 pages), SwiftData persistence, Settings with 3+ prefs, haptics, empty states, dark-mode-first design, Info.plist, AppIcon (1024px PNG), AccentColor, project.yml
- Hearts has full rules implementation including shoot-the-moon edge case
- Brick physics uses restitution=1 frictionless body for authentic ball bounce
- Crawl uses Timer-based game loop (not SpriteKit) via `@Observable CrawlEngine`
