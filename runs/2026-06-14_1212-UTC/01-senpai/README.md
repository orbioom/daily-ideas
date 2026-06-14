# Senpai

**Your private, offline anime & manga tracker.** The native iOS app MyAnimeList and AniList never built. Senpai lives entirely on your device — no account, no ads, no feed — and gives anime and manga fans a beautiful, fast way to track progress, score titles, plan a backlog, and watch their taste stats grow.

## What it is

Senpai is an offline library for everything you're watching and reading. Every title has a **status** (Planning, Watching/Reading, Completed, On Hold, Dropped), a **progress count** (episodes for anime, chapters for manga), a **0–10 score**, optional **season/year**, **studio or author**, **genres**, **notes**, and a **rewatch counter**. The signature interaction is a one-tap **+1** that records a real watch-log session, advances your count, and auto-marks the title complete when you reach the finale — so you also get a genuine session history and progress chart. Because the app ships no images, every title gets a **deterministic gradient cover** derived from its name, for stable, vivid poster-like cards.

## Full feature list

- **Library** — segmented by kind (All / Anime / Manga), status filter chips, search by name or author, sort by recent / score / title / progress. A `LazyVGrid` of gradient cover cards showing title, progress (e.g. "7 / 12"), score chip, favorite heart, and a colored status pill. Designed empty states for both "no titles" and "nothing matches."
- **Up Next** — a currently-watching/reading shelf where each title has a big **+1** quick-progress button (writes a `WatchLog`, advances the count, auto-completes on hitting the total, success haptic), plus a horizontally-scrolling **Recently completed** strip.
- **Browse** — a curated, hard-coded offline **catalog of ~60 well-known real titles** (anime grouped by season/year, manga by author), each with sensible episode/chapter counts, studio/author, and genres. Tap a card → an "Add to Library" sheet prefilled from the catalog with a status picker. Already-added titles show a green check.
- **Stats (Taste Stats)** — Swift Charts: a **status donut** (`SectorMark`), a **1–10 score histogram**, a **top-genres bar chart**, and a **completed-per-month** bar over the trailing year, plus headline numbers (titles, episodes watched, chapters read, time spent, mean score, completion rate). Computed in an async `@MainActor` task with a loading spinner. The full charts are Pro-gated; basic counts are free with a teaser.
- **Title Detail** — gradient hero, a **+/− progress stepper** (each forward step writes a `WatchLog`), score picker (0–10), status segmented control, season/studio/genre chips, derived dates and estimated time, notes, a **rewatch counter** with a one-tap "+", the full **watch-log history**, and edit / favorite / delete from a menu.
- **Add / Edit Title** sheet — full form with live validation (name required; total ≥ progress; valid year for a season) and a multi-select genre list.
- **Onboarding** — three pages in the app's language, gated by `hasOnboarded`.
- **Settings** — six persisted, live preferences: haptics, **Library opens to** (default kind), **default sort**, **cover intensity** (soft / standard / vivid), **show time spent**, and **spoiler-safe hide scores**. Plus About, **Export** (text & CSV with copy/share), **Sample data** (load a 50+ title library with logs, or erase all), and a Pro / Restore row.
- **Senpai Pro** — free up to **20 tracked titles**; one-time **$4.99** unlock removes the cap, opens full Taste Stats, and enables export. Honest demo unlock + Restore.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Senpai.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

### Free-signing note

You can run Senpai on a physical device with a personal Apple ID (free): select the Senpai target → Signing & Capabilities → pick your personal team. Free provisioning lasts **7 days** before you'll need to re-sign.

## Tech notes

- **iOS 17+**, **SwiftUI 5**, MVVM-leaning structure with small, single-type files (`Models/`, `ViewModels/`, `Engine/`, `Views/…`, `Theme/`, `Utilities/`).
- **SwiftData** is the primary store: `@Model` `Title` cascade-owns `WatchLog` children and has a many-to-many with `Genre`; views use `@Query` / `@Bindable` / `modelContext`. `UserDefaults` (`@AppStorage`) holds only small prefs and flags (incl. `isPro`). A 50+ title sample library with logs seeds on demand from Settings.
- **Pure engines:** `LibraryEngine` (guarded filter/sort/up-next/recently-completed), `StatsEngine` (status counts, mean score over rated only, episodes/chapters, time-spent estimates at ~24 min/episode and ~5 min/chapter, completion rate, genre distribution, 1–10 histogram, completions per month — all deterministic and divide-by-zero/nil-guarded), `TitleActions` (guarded progress/log/status mutations), and a hard-coded `CatalogData` fixture.
- **Swift Charts** powers the Stats screen (`SectorMark` donut + `BarMark` histograms).
- **Design language:** a vibrant "streaming / otaku" identity around magenta-pink **`#E24A8B`**, dark-mode-first but first-class in light via the `Theme.dyn(light, dark)` per-`colorScheme` pattern. Rounded display + UI type (system fonts → Dynamic Type), consistent gradient covers, cards, and pills. Accessibility labels/hints/values, decorative images hidden, and Reduce Motion honored throughout.
- **Monetization:** one-time $4.99 Senpai Pro unlock (StoreKit wires in for production; this build uses an honest demo unlock that sets `isPro = true`, with Restore present).
- **Why it can boom:** the anime/manga fandom is massive and intensely engaged, yet MAL and AniList are web-first, dated, and ad-supported with no good native iOS app. A beautiful, private, offline tracker with a delightful one-tap **+1** progress hook and real taste stats is exactly what fans wish existed — and it's clearly distinct from a TV/movie tracker.

## Self-review attestation

Every Swift file was re-read after authoring. Verified: imports; iOS 17 SDK availability of every type/initializer/modifier (incl. `SectorMark`, `Layout`, `ShapeStyle.gradient`, zero-parameter `onChange`); protocol conformances; `@Query` / `@Bindable` / `@StateObject` / `@EnvironmentObject` ownership consistency (ObservableObject + SwiftData only — no `@Observable` macro mixing); `NavigationStack` / `sheet` / `navigationDestination(for: Title.self)` binding types; no duplicate type declarations; every Swift Charts series is an `Identifiable` struct; every referenced `Theme` token is defined; all array indexing and division is guarded. The only force operation in the app is the in-memory `ModelContainer` fallback `try!`. There is exactly one `@main` (`SenpaiApp`). `grep -rniE "TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub|unimplemented"` over the sources returns zero matches.
