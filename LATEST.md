# Latest Run — 2026-06-05 1808 UTC

**Folder:** `runs/2026-06-05_1808-UTC/`
**Shipped:** 8 fully-built, production-ready products (≥1 in every category) + 2 detailed iOS specs in `BACKLOG.md`.
**No-repeat:** all 10 picks checked against `SHIPPED.md` (entries 1–27) — no repeats, paraphrases, or same-mechanic variations. New entries appended as #28–#35.

Each shipped product passed an anti-stub scan and a hand/automated verification trace (recorded in each slot's README "Self-review"). The four computational tools had their core math re-verified independently in Node before commit (results below).

---

## A — iOS (slots 01–03)

- **Split** — built — `runs/2026-06-05_1808-UTC/01-split` — Shared-expense splitter; groups own members, expenses (equal/exact/shares), and recorded settlements, with greedy min-cash-flow "who pays whom" suggestions. SwiftData persistence; Decimal-only money math with exact integer-cent reconciliation. 6 feature screens + onboarding + 5 persisted settings. Real 1024×1024 on-brand app icon (two overlapping orbs), light/dark, VoiceOver, Reduce Motion.
- **Repertoire** — spec — `BACKLOG.md` — Musician practice companion: Pieces own PracticeSpots; PracticeSessions log time; sample-accurate metronome + practice timer; streaks/tempo-progress insights. SwiftData. (Deferred for quality-floor protection — one strong iOS app shipped this run.)
- **Larder** — spec — `BACKLOG.md` — Pantry/kitchen inventory: Items across Locations/Categories with expiry windowing + low-stock detection feeding a generated shopping list; local expiry notifications. SwiftData.

## B — Web / SaaS (slots 04–06)

- **Envelope** — built — `runs/2026-06-05_1808-UTC/04-envelope` — Zero-based envelope budgeting. Accounts, envelopes (grouped, rollover), month-aware transactions; "To Be Budgeted" hero, grouped progress + overspend, reports (hand-drawn canvas donut / SVG bars). localStorage, JSON/CSV round-trip, light/dark, full a11y. _JS syntax-checked; only `placeholder=` HTML attrs (no stubs)._
- **Recall** — built — `runs/2026-06-05_1808-UTC/05-recall` — SM-2 spaced-repetition flashcards. Decks/cards, study sessions with keyboard rating, 12-week SVG heatmap + 7-day due forecast. localStorage, JSON/CSV. _SM-2 verified in Node: n=0→I=1, n=1→I=6, n=2→I=15, Easy→EF 2.6, lapse handling correct._
- **Renewal** — built — `runs/2026-06-05_1808-UTC/06-renewal` — Subscription & recurring-expense tracker. 6 billing cycles incl. custom-N-days, month-end-safe next-renewal stepping, calendar + donut, totals by category/method. localStorage, JSON/CSV. _Verified in Node: Jan-31 monthly → Feb 28 / Feb 29 (leap) / Mar 31; monthly↔yearly↔custom normalization correct._

## C — Scientific / Technological, interactive UI (slots 07–09)

- **Smooth** — built — `runs/2026-06-05_1808-UTC/07-smooth` — Savitzky–Golay smoothing & differentiation (Savitzky & Golay, *Anal. Chem.* 1964). Coefficients computed from the Vandermonde design matrix via normal equations + Gaussian elimination (no hardcoded tables); asymmetric boundary handling; live window/order/derivative; canvas chart, PNG/CSV. _Verified in Node: window-5/order-2 → [-3,12,17,12,-3]/35, smoothing sum 1, derivative sum 0, quadratic reproduced to 1e-15._
- **Axis** — built — `runs/2026-06-05_1808-UTC/08-axis` — PCA explorer (Pearson 1901; Hotelling 1933) via Jacobi eigendecomposition. Standardize toggle, scores scatter + scree + loadings biplot; bundled Iris (Fisher 1936 / UCI) + seeded synthetic; PNG/CSV. _Verified in Node: standardized Iris PC1+PC2 = 95.81% (matches sklearn), eigenvectors orthonormal, variance sums to 1._
- **Compass** — built — `runs/2026-06-05_1808-UTC/09-compass` — A* pathfinding visualizer (Hart, Nilsson & Raphael, *IEEE T-SSC* 1968) with a hand-written binary min-heap; Dijkstra & Greedy comparison; 5 heuristics; seeded maze/terrain generators; animated frontier + path; PNG export. _Verified in Node: all 5 built-in sanity checks pass (A*=Dijkstra optimal cost, admissible pruning, no-path, trivial, heap invariant)._

## D — Android (slot 10)

- **Transit** — built — `runs/2026-06-05_1808-UTC/10-transit` — Fuel & mileage log. Vehicles own fill-ups; the engine computes fuel economy *between full tanks*, folding partial fills into the fuel total and flagging untrustworthy segments; cross-vehicle insights; self-drawn Compose Canvas trend charts. MVVM, DataStore + JSON (no Room/KSP), custom Orbioom Material 3 light/dark, adaptive icon (+ monochrome + round).

---

## Build / APK status

- **iOS (Split):** No Xcode in the sandbox — hand-compiled by careful source review. All 24 Swift files referenced in every required `project.pbxproj` section with unique IDs; icon is a valid 1024×1024 RGBA PNG; no force-unwraps/`try!` on user paths. Builds in Xcode 15+ (Cmd+R, iOS 17+ simulator).
- **Android (Transit):** `./gradlew assembleDebug` ran — the wrapper fetched Gradle and started, then failed only at Android Gradle Plugin resolution (no Android SDK / no Google Maven in the sandbox; ~5 GB SDK deliberately not installed). Documented in `android/build-log.txt`. Versions are the known-good set (Kotlin 1.9.24, AGP 8.5.2, Compose BOM 2024.06.00, compiler ext 1.5.14, SDK 26/34/34); no annotation processors; Compose plugin not applied. Builds in Android Studio (sync → Build APK(s)).
- **Web & Sci (6):** open `index.html` directly — no build, no server, no keys. All JS `node --check`-clean; all core algorithms independently re-verified (above).

## Top recommendation

**Compass (A* pathfinding visualizer).** It is the most complete expression of this run's bar: a genuinely rigorous, correctly-cited algorithm (real binary-heap A* plus Dijkstra/Greedy for contrast) made *visible and manipulable* — you paint walls and weighted terrain, pick a heuristic, and watch the frontier breathe outward before the path locks in with the brand's rare green "magic" flash. Its built-in sanity suite (A* optimal cost == Dijkstra) proves correctness, and the science-as-spectacle framing is exactly the Orbioom "conjured, not just coded" feeling. Close runners-up: Axis (PCA matching sklearn to the decimal) and Split (the only slot with a non-trivial *relational* model plus settlement optimization).

## Research signals worth following next run

- **Personal-finance "calm money" tools** keep surfacing on r/SideProject and PH — debt-payoff (snowball/avalanche) planners, sinking-funds, and net-worth-over-time trackers are wanted but mostly ship as spreadsheets; strong Category-B candidates that clear the substance floor.
- **Local-first / no-account journaling & logging** (mood, symptoms, training load) remains a recurring r/androiddev + r/iosprogramming ask — good for the native slots, and the multi-entity + computed-trend angle keeps them above the floor.
- **"See the algorithm" science tools** have room beyond what's shipped: Gillespie SSA (stochastic chemical kinetics), Kalman filtering on a tracked signal, Barnes–Hut n-body, hierarchical clustering dendrograms, and wavelet transforms are all named, citable, and highly visual — natural Category-C picks that avoid the already-shipped FFT/k-means/ODE/PCA/A* space.
- **Spaced-repetition analytics** (forgetting-curve fitting, FSRS vs SM-2 comparison) came up while building Recall — a visual FSRS explorer would be a distinct, rigorous Category-C follow-up.
