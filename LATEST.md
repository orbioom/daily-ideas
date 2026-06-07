# Latest run — 2026-06-07_0608-UTC

**6 production-ready native iOS apps**, slots 01–06, in `runs/2026-06-07_0608-UTC/`. All built to the iOS Definition of Done (Orbioom design language; SwiftUI 5 + SwiftData; onboarding gate, empty/loading/error/success states, ≥4 feature screens, ≥3 functional Settings prefs, full Dynamic Type / VoiceOver / Reduce Motion, light & dark, designed app icons). Each ships a XcodeGen `project.yml` (run `xcodegen generate`, then open in Xcode 15+).

## The six apps
- **Links** — built — `01-links` — Golf handicap & round logbook: a real World Handicap System engine (best 8 of 20, Net Double Bogey capping, chronological processing) over a hole-by-hole scorecard, courses/tees, and scoring insights.
- **Plume** — built — `02-plume` — Birdwatching life list & sightings: a 65-bird catalog, automatic lifer detection, life/year lists in checklist order, trips, and seasonal insights.
- **Capo** — built — `03-capo` — Chord transposer & setlist manager: a key-aware transposition engine (correct enharmonics, slash chords, Nashville numbers, capo-shape math), a chords-over-lyrics renderer, setlists with per-slot transpose/capo, and a swipeable performance view.
- **Cone** — built — `04-cone` — Pottery studio: percentage→grams glaze batch scaling, firing ramp schedules with time + energy-cost estimates, an Orton cone-temperature reference + shrinkage calculator, and a piece-stage workflow.
- **Cog** — built — `05-cog` — Bike maintenance & component wear: a distance+time wear engine that projects replacement dates from ride history, a cross-bike health overview, and a service/spend history.
- **Vial** — built — `06-vial` — Medication & refill tracker: a dose-schedule engine with today's checklist, supply countdown to a refill-by date, and adherence trends (overall/daily/per-med).

## Top recommendation
**Capo.** It has the deepest, most reusable domain logic (a genuine music-theory engine: pitch-class parsing, key-aware enharmonic spelling, Nashville numbers, capo math) wrapped in the most visually distinctive feature — a live chords-over-lyrics chart that transposes as you tap — and serves a large, paying audience (worship/cover/gigging musicians) underserved by clunky or paywalled apps. Strong hook, clear why-now, immediately demoable.

Runners-up: **Links** (the WHS math is the kind of correctness moat casual apps skip) and **Cog** (a sticky, genuinely useful "before it breaks" tool with daily re-use).

## Self-review
Anti-stub grep clean across all six. Three parallel by-hand compile-review passes (one per pair of apps) returned no compile errors and no crash paths — SwiftData wiring, iOS 17 API usage, `Picker` tags, `.onChange` two-parameter form, `Layout`/`Canvas`, and division/`.infinity` guards all verified. No Xcode in the sandbox, so correctness is by inspection.

## Research signals worth following next run
- **Disc golf** scorecard + rating (PDGA-style) — same appetite as ball golf, fewer good native apps.
- **Net-worth / asset-allocation snapshots** — finance is well-covered for budgeting/debt but a calm allocation+history tracker is open.
- **Pottery/maker adjacencies** validated: kiln-share scheduling, leatherworking project costing, screen-printing ink mixer all surfaced as niche-but-devoted.
- **Freediving apnea CO₂/O₂ tables** (distinct from scuba), **chess opening-repertoire trainer**, and a **gig/expense mileage log for musicians** all scored well on substance but were cut for distinctness this run.
