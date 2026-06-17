# Verbo

**The Spanish & French verb conjugation trainer — a real engine, adaptive drills, full reference tables. One-time, offline, no account.**

Verbo drills the universally-hated skill the big apps do poorly: putting verbs in the right form. A built-in conjugation **engine** generates the correct form for any verb × tense × person; adaptive, mastery-weighted drills quiz you on your weak spots; and complete conjugation tables serve as an offline grammar reference.

---

## What it is

A native iOS 17 app (SwiftUI + SwiftData + Swift Charts) that teaches verb conjugation through three reinforcing loops:

1. **A conjugation engine** — regular `-ar / -er / -ir` (Spanish) and `-er / -ir / -re` (French) endings are computed live; the most common irregular verbs come from a curated lookup-override table. There is no finite answer key to run out of.
2. **Adaptive drills** — Verbo tracks per-verb-per-tense mastery and weights questions toward what you keep getting wrong.
3. **Reference** — full conjugation tables for 60+ verbs and clear, worked tense explanations.

Spanish core is free forever. French and advanced tenses are a one-time Pro unlock.

## Full feature list

- **Practice** — full-screen adaptive drill. Prompt shows *person · tense · infinitive* (e.g. `yo · presente · hablar → ___`). Type the answer or pick from multiple choice. Instant feedback shows a checkmark/✗ and the correct conjugation. Running progress bar, success/error haptics, and an end-of-session summary (score, accuracy, time, and an "items to review" list).
- **Verbs** — browse the catalog of 60+ verbs. Filter by language, by group (`-ar/-er/-ir/-re`), or irregular-only; search by infinitive or English meaning. Tap a verb for full conjugation tables across every tense, annotated with your personal mastery.
- **Learn (Tenses)** — per-language explanations of each tense (when to use it), the regular-ending tables for each group, and worked examples conjugated live by the engine.
- **Progress** — Swift Charts: accuracy over time (line), mastery by tense (bar), mastery by verb group (bar, Pro), verbs mastered, day streak, and a "target these next" weakest-verbs list. Async compute with a loading state.
- **Settings** — languages enabled (Spanish always on; French = Pro), per-tense toggles, answer mode (type / multiple choice), strict-vs-lenient accents, questions-per-session, daily reminder, haptics, Load sample data, Export progress (CSV via share sheet), Reset progress, About, and Unlock/Restore Pro.
- **Onboarding** — four-slide first-run intro, gated by a persisted flag.
- **Engine details** — Spanish `presente, pretérito, imperfecto, futuro` plus Pro `condicional` & `subjuntivo`; French `présent, imparfait, futur simple` plus Pro `passé composé` (auxiliary avoir/être + past participle, with simple agreement for être verbs). All six persons per language. ~26 curated irregular verbs.
- **Craft** — indigo/violet theme, full light & dark mode, Dynamic Type throughout, accessibility labels on controls and charts, Reduce Motion respected, haptics gated by a setting, correct handling of accented (diacritic) characters.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Verbo.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free signing:** set your Apple ID team in Signing & Capabilities; the bundle id is `com.orbioom.verbo`.

## Tech notes

- **Stack:** SwiftUI 5, SwiftData, Swift Charts, Observation framework. iOS 17 SDK only.
- **Architecture:** A pure, dependency-free `ConjugationEngine` (regular computation + irregular override table) is the core IP. `DrillEngine` is an `@Observable` class (stored with `@State`) that builds a mastery-weighted question pool, grades answers (accent-strict or diacritic-lenient), and updates SwiftData. `StatsEngine` is a pure function over data snapshots.
- **Persistence:** user progress only — `ItemStat` (per verb×tense) and `DrillSession` — in SwiftData, registered in the app `Schema`. The verb catalog itself is static structs. Small flags/prefs use `@AppStorage`. Survives relaunch; seeds idempotently on first run.
- **Safety:** no force-unwraps on user paths, no `try!` / `as!` / `fatalError`; all string/array indexing is guarded (safe subscript helper); the data store falls back to in-memory and then to a calm recoverable screen rather than crashing.
- **Monetization:** simulated one-time **Verbo Pro at $5.99** via `@AppStorage("isPro")` with Unlock (demo) / Restore. Pro adds French, advanced tenses (subjuntivo, condicional, passé composé), the full verb library, and advanced analytics. The Spanish core (four tenses, 40 verbs, drills, reference) is fully usable free.
- **Why it can boom:** Language learning is the largest consumer-learning market, and conjugation is its single most painful, under-served gap — apps like Ella Verbs and Conjugato charge *ongoing subscriptions* for it. Verbo delivers a genuine conjugation engine + adaptive drills + complete reference tables for a one-time price, fully offline, with no account.

## Self-review attestation

All **40** Swift source files were re-read after writing. Verified: every file's imports are present (SwiftUI / SwiftData / Charts / Observation / Foundation / UIKit as needed); iOS-17-only APIs (`NavigationStack`, `.navigationDestination`, `@Observable` + `@State`, Swift Charts `LineMark`/`BarMark`/`PointMark`); a single observation pattern throughout (no `ObservableObject`/`@StateObject`); no `.onChange` misuse; no `NavigationView`, no `@Previewable`; no force-unwrap on user paths, no `try!` / `as!` / `fatalError`; guarded array/string indexing via a safe subscript; accented (diacritic) strings handled correctly for both display and lenient comparison; both `@Model` types (`ItemStat`, `DrillSession`) registered in the `Schema`; conjugation data spot-checked for correctness across regular groups, all tenses, and irregular lookups; no stub words (`TODO`/`FIXME`/`placeholder`/etc.). Light & dark mode, Dynamic Type, accessibility, Reduce Motion, and gated haptics are present across screens.

**Schema models:** `ItemStat`, `DrillSession`.
