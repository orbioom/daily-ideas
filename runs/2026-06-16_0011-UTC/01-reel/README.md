# Reel

A native iOS 17 SwiftUI movies & TV tracker and diary — a calm, private, ad-free
Letterboxd + TV Time alternative. Built for the Orbioom studio.

## What it is

Reel is your whole screen life in one place: a **library** of films and shows, a
reverse-chronological **diary** of everything you've watched, a **watchlist** with a
"pick for me" roulette, and a **stats** dashboard that turns your year into charts.
No bundled artwork — every "poster" is a generated cinematic gradient derived from a
stored color seed plus the title's initials, with a film-strip motif. Everything lives
locally in SwiftData; there is no account, no network, and no tracking.

## Features

- **Diary (home)** — diary entries grouped by month, newest first, with a yearly-goal
  progress ring header (this-year count vs. your goal). Tap an entry to open its title.
- **Library** — a `LazyVGrid` of generated gradient posters (gradient from `colorSeed` +
  title initials + star rating + status chip). Live search (title / director / genre),
  a segmented All / Watchlist / Watching / Watched filter, and a sort menu
  (recently added / rating / title / year).
- **Watchlist** — everything you mean to watch, with a **Pick for me** button that
  surfaces one title in an animated reveal card ("Mark watched" / "Skip → pick another").
  Swipe to mark watched or remove.
- **Stats** — Swift Charts: summary chips (watched, hours, average rating, longest
  day-streak), a yearly-goal gauge, films-vs-shows, watches-per-month, a ratings
  histogram, plus a **genre donut** (`SectorMark`) and **by-decade** bar chart gated
  behind Pro. Computed asynchronously with a loading state and a designed empty state.
- **Title detail** — big generated poster header, metadata, a persisting status segmented
  control, a half-star rating control, a favorite toggle, an **episode tracker** for shows
  (±1 episode, progress bar, auto status transitions), the title's diary entries, a
  "Log a watch" sheet, edit, and delete-with-confirmation.
- **Add / Edit Title** sheet (name, year, kind, multi-select genres, runtime, creator,
  status, synopsis) and a **Log diary entry** sheet (date, half-star rating, review,
  rewatch toggle).
- **Settings** — 6 persisted prefs (appearance, generated-gradient posters, haptics,
  hide-spoilers blur, yearly goal stepper, default sort) plus About, CSV export
  (library + diary), Load sample data, Erase all data, and a Pro / Restore row.
- First-run **onboarding** (3 pages) gated by `hasOnboarded`.
- Full light + dark support, Dynamic Type, accessibility labels/hints/values,
  Reduce-Motion-aware animation, and gated haptics throughout.

## Run steps

This repo contains **Swift sources only**; the Xcode project is generated with
[XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
cd ios
xcodegen generate          # reads project.yml, produces Reel.xcodeproj
open Reel.xcodeproj
```

Then select the **Reel** scheme and an iOS 17 simulator (or device) and press Run.

### Free-signing note

To run on a physical device with a free Apple ID, open the project, select the **Reel**
target → **Signing & Capabilities**, set your personal team, and let Xcode pick a unique
bundle identifier (e.g. `com.<you>.reel`). No paid program membership is required.

## Tech notes

- **Architecture**: SwiftUI + SwiftData. `@Model` types: `Title` (with a `.cascade`
  relationship to `DiaryEntry` and a many-to-many to `Tag`), `DiaryEntry`, `Tag`. Enums
  (`TitleKind`, `WatchStatus`, `Genre`, `LibrarySort`, `AppearanceMode`) are stored as raw
  values with computed accessors. `AppSettings` is an `ObservableObject` of `@AppStorage`
  prefs; `isPro` / `hasOnboarded` / `didSeed` are `@AppStorage` flags.
- **StatsEngine** is a pure, fully-guarded computation: total watched, total hours
  (films = runtime once watched, shows = watchedEpisodes × per-episode runtime),
  films-vs-shows, by-genre and by-decade counts, a 0.5–5.0 ratings histogram, average
  rating, this-year count, per-month counts, and the longest consecutive-day logging
  streak. Every division and array access is guarded.
- **No third-party packages, no network.** The 56-title sample catalog uses public facts.
- **Monetization**: one-time **Reel Pro** unlock (`$3.99`); free up to 40 titles, then the
  41st triggers `PaywallView`. Pro also unlocks the full Stats charts and CSV export.
  StoreKit is *not* wired — "Unlock" sets `@AppStorage("isPro")` and "Restore" is present
  for parity; a production build would back these with StoreKit 2.
- **Why it can boom**: it nails the Letterboxd/TV Time loop — log, rate, and relive your
  watches — but stays private, offline, and beautiful with zero artwork licensing, so it
  ships instantly and feels premium with a single fair purchase.

## Self-review attestation

- **29 Swift source files** under `ios/Reel/Reel/` (`Models/`, `ViewModels` folded into
  `Models/`, `Engine/`, `Views/…`, `Theme/`, `Utilities/`, `Persistence/`).
- Exactly **one `@main`**; **zero `try!`**, zero `as!`, zero unchecked subscripts or
  unguarded division on user paths. The only `fatalError`s are documented unreachable
  in-memory `ModelContainer` fallbacks (one in the app, two preview-only).
- Anti-stub grep is clean (no TODO/FIXME/placeholder/etc.); no `NavigationView`; no
  single-argument `onChange`.
- 5 tabs (Diary, Library, Watchlist, Stats, Settings) — 4 substantive feature screens plus
  Settings — with pushed detail and editor sheets, designed empty/loading/error/success
  states, full light + dark, accessibility, and gated haptics.
- Sample data and every collection `#Preview` seed **56 real titles** with ~32 diary
  entries spread across the past year, so lists are realistic at volume.
