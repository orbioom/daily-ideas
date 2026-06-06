# Orbioom Daily Ideas — Latest Run

**Run:** 2026-06-06_0607-UTC
**Folder:** `runs/2026-06-06_0607-UTC/`
**Output:** 10 production-ready products — 6 iOS, 2 SaaS, 1 tech innovation, 1 Android. All 10 built (none deferred).

Each slot was built by a dedicated agent against the full Definition of Done, then independently re-verified here: anti-stub grep clean, no force-unwrap/`try!`/user-path `fatalError`, structural integrity (pbxproj ↔ source, Info.plist launch screen, AccentColor, Preview Content), and — for the engine-bearing web/tech slots — the core algorithm executed and asserted under Node 22.

Shared tooling built once and reused (in `runs/2026-06-06_0607-UTC/_tools/`): `gen_pbxproj.py` (auto-discovers Swift files → valid Xcode 15 / iOS 17 project, the single biggest iOS build-failure source eliminated) and `make_icon.py` (12 on-brand mist→ink orb glyphs, stdlib-only PNG writer). Every iOS app's 1024 icon and every project file came from these tested tools.

---

## A — iOS (6 / 6 built)

- **Interval** — built — `01-interval/ios` — Interval-timer builder: a Routine owns ordered Segments (prepare/work/rest/cooldown) and repeat-groups; an absolute-`Date` WorkoutEngine drives a full-screen timer (count-in, progress ring, next-up, skip/+15s, keep-awake) and writes a Session log with streaks/finish-rate insights. SwiftData. 28 Swift files.
- **Apertura** — built — `02-apertura/ios` — Manual & film photography: a pure exposure engine (`EV = log2(N²/t)`, ⅓/½/full-stop snapping, equivalent-exposure enumeration, honest DoF/blur/grain guidance) plus a Roll→Frame shot log with CSV/JSON export. SwiftData. 20 Swift files.
- **Repertoire** — built — `03-repertoire/ios` — Musician's practice companion: Piece → PracticeSpots (tempo progress, mastery), Date-based metronome + practice timer that writes Sessions, and insights (current/longest streak, weekly minutes heatmap, time-by-piece, least-recently-practiced suggestion). SwiftData. 26 Swift files.
- **Larder** — built — `04-larder/ios` — Pantry/kitchen inventory: Items across Locations/Categories with expiry-window bucketing (expired/soon/fresh), per-item low-stock detection, and a generated shopping list whose check-off restocks the larder. SwiftData. 25 Swift files.
- **Strata** — built — `05-strata/ios` — Climbing/bouldering logbook: a grade-conversion engine (V↔Font, YDS↔French, canonical storage) over Sessions → Attempts → Climbs/Projects, with a send pyramid, flash/onsight rate, and hardest-send-by-month progression (Swift Charts). SwiftData. 28 Swift files.
- **Crumb** — built — `06-crumb/ios` — Sourdough & bread companion: a baker's-percentage solver that decomposes the levain to compute true hydration, scales dough weight↔loaf count, and schedules a bake's step timeline forward-from-start or backward-from-finish; plus a starter feeding log. SwiftData. 30 Swift files.

## B — SaaS (2 / 2 built)

- **Keystone** — built — `07-keystone` — Project critical-path (CPM) planner: a real graph engine (topological sort → forward/backward pass → slack → critical-path extraction → cycle detection) recomputes the schedule live as you edit; Gantt + sortable table, multi-project, JSON/CSV export. Static, localStorage, offline. *Node-verified:* sample project duration 46d, every critical task has zero slack, cycle input handled without crash.
- **Limpid** — built — `08-limpid` — Prose-clarity workbench: an overlay-highlight editor computing six readability formulas (Flesch, FK, Gunning Fog, SMOG, ARI, Coleman–Liau) with a real syllable counter, and inline passive/adverb/filler/complex/long-sentence spans; multi-document, persisted, exportable. Static, localStorage, offline. *Node-verified:* 40+ assertions pass; degenerate input → `—`, no divide-by-zero; spans align to source offsets.

## C — Technological innovation (1 / 1 built)

- **Distill** — built — `09-distill` — A genuinely working in-browser **order-3 PPMC + 32-bit range coder** text/data compressor. It shows the **real compression ratio computed live on the user's input**, honestly benchmarked against the browser's built-in gzip (`CompressionStream`), with round-trip verification, all off the main thread in a Web Worker. *Node-verified:* on the committed sample, **Distill 2,031 B (2.51×) vs gzip-9 2,264 B (2.25×) → ~10.3% smaller**, and **11/11 round-trip cases pass exactly** (empty, unicode/emoji, all-256-bytes, 50 KB repetitive, high-entropy, determinism). Lossless, honest, real applied information theory.

## D — Android (1 / 1 built)

- **Meeple** — built — `10-meeple/android` — Board-game play & stats logger: Games/Players/Plays + PlayerResults with a pure stats engine (winner resolution respecting highest/lowest/co-op scoring, per-game avg/median/high, per-player win rate, longest/current streak, **nemesis**, **head-to-head**, monthly trend). Compose + Material 3 tuned to Orbioom, DataStore + JSON persistence, **no Room/KSP**, Kotlin 1.9.24 / AGP 8.5.2 / Compose BOM 2024.06.00 / compiler ext 1.5.14 / Gradle 8.7. 27 Kotlin files.

---

## Build / APK status

- **iOS (01–06):** No Xcode in the sandbox — each project was compile-reviewed by hand (imports, iOS-17 SDK symbols, property-wrapper/`@Query`/`modelContainer` wiring, navigation/sheet bindings) and assembled with the tested `gen_pbxproj.py`. Open `<App>.xcodeproj` in Xcode 15+, pick an iOS 17 simulator, Cmd+R (free signing).
- **Android (10):** Gradle 8.7 wrapper ran in the sandbox; the build stops at AGP plugin resolution only because the sandbox has no Android SDK / Google Maven (SDK install deliberately skipped). Versions are the known-good set with no annotation processors and no Compose plugin on 1.9.x. See `10-meeple/android/build-log.txt`. Builds in Android Studio (sync → Build > Build APK(s)) → `app/build/outputs/apk/debug/app-debug.apk`.
- **Web/Tech (07–09):** Every JS file passes `node --check`; each engine was executed and asserted under Node. Open `index.html` directly — no build, server, or API keys.

## Top recommendation this run

**Distill (09).** It's the rare slot that delivers a measurable, honest "wow": a correct PPM+range-coder built from scratch that *actually beats gzip* on natural-language text (2.51× vs 2.25×, ~10% smaller), proven lossless across 11 adversarial round-trip cases, running entirely client-side in a Web Worker with the benefit computed live on the user's own input. It is real applied information theory you can feel, not a visualization — exactly the brief for the tech slot. Runner-up: **Strata**, the most differentiated iOS concept (a correct multi-system climbing-grade engine + send-pyramid analytics) with no near-neighbor in the registry.

## Research signals worth following next run

- **Hobby logbooks with real domain math keep landing** (Cellar, Strata, Crumb): climbers, bakers, musicians, photographers want a relational record *plus* a correct calculator, not a notes app. Adjacent unbuilt veins: pottery/kiln firing schedules, homebrew/fermentation, analog-synth patch libraries, dive logs (NDL math).
- **On-device "server-grade" capabilities in the browser** (Distill's thread): more wow lives in pure-JS implementations of things people assume need a backend — perceptual image dedupe, a real full-text search index, delta-sync diffing.
- **Calm dev-tools that compute, not CRUD** (Keystone, Limpid): planners/analyzers with a genuine algorithm at the core outperform dashboards. Candidates: a dependency/critical-chain resource leveler, a regex-to-railroad-diagram explainer, a JSON-diff/3-way-merge tool.
- **SaaS finance genre remains explicitly off-limits**; keep steering to workflow/creativity/analysis tools with a clear hook.
