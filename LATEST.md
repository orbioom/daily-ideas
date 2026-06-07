# Latest run — 2026-06-07_1209-UTC

**6 production-ready native iOS apps**, slots 01–06, in `runs/2026-06-07_1209-UTC/`. All built to the iOS Definition of Done (Orbioom design language; SwiftUI 5 + SwiftData; onboarding gate, empty/loading/error/success states, ≥4 feature screens, ≥3 functional Settings prefs, full Dynamic Type / VoiceOver / Reduce Motion, light & dark, designed app icons). Each ships a XcodeGen `project.yml` (run `xcodegen generate`, then open in Xcode 15+).

## The six apps
- **Chains** — built — `01-chains` — Disc-golf scorecard with a transparent SSA-based round-rating engine, courses/holes, a live hole-by-hole scorecard, and rating-trend + trouble-hole insights.
- **Ledger** — built — `02-ledger` — On-device net-worth and asset-allocation tracker: accounts net to one number, snapshots plot a trend, and an allocation engine shows drift vs targets with exact rebalance amounts.
- **Static** — built — `03-static` — Freediving apnea trainer that derives CO₂/O₂ tables from your max breath-hold and guides each session with a calm full-screen timer; logs sessions and a personal-best trend.
- **Cairn** — built — `04-cairn` — Ultralight backpacking pack-weight planner: a reusable gear catalog, pack lists, and a base/total/skin-out/big-three weight breakdown with category and cross-list insights.
- **Bench** — built — `05-bench` — A pocket electronics lab: seven maker calculators (Ohm's law, resistor colour code, LED dropper, divider, 555 astable, RC filter, battery life) with a saved-calc notebook and a parts inventory.
- **Gambit** — built — `06-gambit` — A tabletop combat manager: encounters with initiative order, HP and 5e conditions, a reusable bestiary, and a built-in dice roller with advantage/disadvantage and history.

## Top recommendation
**Ledger.** It pairs the broadest paying audience (anyone tracking money) with a genuine correctness moat the budgeting-app crowd skips — a real allocation/rebalancing engine (drift in percentage points, exact dollar moves to hit target weights) on top of an honest net-worth time series — and it's emphatically local-first, which is exactly the unmet "privacy, no bank logins" ask in the research. Strong hook, immediately demoable from seeded data.

Runners-up: **Chains** (the rating engine is the kind of math casual disc-golf apps avoid, with a clear devoted audience) and **Bench** (a sticky daily-reuse maker tool whose pure `EE` engine + notebook + parts bin is unusually substantial for a "calculator" app).

## Self-review
Anti-stub grep clean across all six (only the standard in-memory `ModelContainer` fallback uses `try!`). A focused compile-review caught and fixed a real, pervasive issue before commit: SwiftUI/Swift Charts `ForEach`/`Chart` ids using **tuple key paths** (`\.0`, `\.category`, `\.offset`, `\.element.id`), which the Swift compiler rejects — all 11 sites were converted to index-based ids or `Identifiable` structs. Remaining checks (SwiftData relationships + `@Query`, two-parameter `onChange`, `SectorMark`/iOS-17 APIs, division/`.infinity`/`isFinite` guards, optional handling on user paths) verified by hand against the iOS 17 SDK. No Xcode in the sandbox, so correctness is by inspection.

## Research signals worth following next run
- **Disc golf adjacency confirmed**: a putting-practice tracker and a bag/disc-flight catalog both surfaced as wanted but were cut for distinctness.
- **Freediving depth/Frenzel/equalisation log** (distinct from the dry-table trainer shipped here) and a **spearfishing catch + dive-conditions log** scored well.
- **Maker space**: a 3D-print cost/slice-time estimator, a Raspberry-Pi GPIO pinout reference, and a CNC feeds-and-speeds calculator all have devoted audiences.
- **TTRPG**: a loot/treasure + magic-item generator and a campaign session-notes/NPC tracker are natural companions to Gambit.
- **Finance**: an FIRE / coast-FIRE projection tool and a simple options-position P&L tracker remain open for a calm, local-first treatment.
