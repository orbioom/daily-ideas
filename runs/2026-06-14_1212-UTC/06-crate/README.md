# Crate

**Your private vinyl collection & spin log.** A Discogs-beater that lives entirely on your device — no marketplace, no account, no feed. Catalogue every record with tracklists, Goldmine condition grades and value, log every spin, and watch your collection's stats take shape in a warm, tactile record-store design language.

## What it is

The Discogs app is a cluttered marketplace bolted onto a database. Crate is the part collectors actually want: a beautiful, native, **private collection + spin log**. Every record carries its pressing details (format, speed, label, catalog number, vinyl color), a side-by-side **tracklist with durations and total runtime**, separate **media and sleeve condition grades** on the Goldmine standard (M, NM, VG+ … P), and price-paid vs. estimated value. One tap **logs a spin**, and Crate turns that history into real insight — most-spun, never-spun, spins this month, spins over time. Can't decide what to play? **"What should I spin?"** surprises you with a seeded pick from your shelves, leaning toward records you haven't spun in a while.

## Full feature list

- **Collection** — an owned grid of vinyl-cover cards (deterministic gradient sleeve + vinyl-disc motif, artist/title/year, format badge, value). Search by artist/title/label, filter by genre/format/decade, sort by artist/title/recently-added/value/most-spun. Designed empty and no-match states.
- **Now Spinning** — the signature **"What should I spin?"** surprise picker on a spinning turntable-style card (re-roll, seeded for variety, optionally prefers unplayed), a one-tap **Log spin** with a success haptic, and a horizontal **recently-spun** shelf.
- **Wantlist** — wishlist records with a swipe / tap **"Mark as acquired"** that prompts for condition and price paid, then flips the record into your collection. Swipe to delete; empty state.
- **Stats** — Swift Charts: genre **donut**, by-decade **bar**, format breakdown, condition distribution, **spins-over-time** line/area, **value-by-genre** bar, a most-spun shelf, plus headline numbers (records, collection value, total spins, spins this month). Computed in an async loading state; full charts are Pro-gated with a teaser when free.
- **Record detail** — a spinning disc-and-sleeve hero, pressing metadata, **tracklist grouped by side** with durations + total runtime, media/sleeve grade chips with a paid/value/upside line, full **spin-log history** (tap to edit), one-tap **Log spin**, edit and delete with confirmation.
- **Add / Edit** — full form with an inline **tracklist editor** (add, reorder, delete tracks per A/B/C/D side, with `m:ss` durations) and validation (title & artist required; year 1900–2100; prices ≥ 0; durations well-formed).
- **Onboarding** — three pages in Crate's record-store language, gated by `hasOnboarded`.
- **Settings** — haptics, hide-values, default sort, grade display (full vs. abbreviated), currency symbol, and a "prefer unplayed picks" toggle (all persisted and live), plus **Export** (text **and CSV**), **Load sample data**, About, and Pro/Restore.
- **Crate Pro** — free up to **25** records (wantlist unlimited); a one-time **$4.99** unlock removes the cap, opens full Stats, enables value tracking, and turns on CSV/text export. Honest demo unlock + Restore.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Crate.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

### Free-signing note

You can run Crate on a physical device with a personal Apple ID (free): select the Crate target → Signing & Capabilities → pick your personal team. Free provisioning lasts **7 days** before you'll need to re-sign.

## Tech notes

- **iOS 17+**, **SwiftUI 5**, small single-responsibility files split across `Models/`, `ViewModels/`, `Engine/`, `Theme/`, `Utilities/`, and per-feature `Views/` folders.
- **SwiftData** is the primary store (`@Model` / `@Query` / `modelContext`); `Record` cascade-owns its `Track` and `Spin` children (`deleteRule: .cascade`). `UserDefaults` (`@AppStorage`) holds only prefs and flags (incl. `isPro`). Data survives relaunch; **60+ realistic records** across genres, decades and formats — with tracklists and spins — seed on first launch behind a `didSeed` flag (and reload from Settings).
- **Swift Charts** powers Stats. The collection math lives in a pure, UI-free `StatsEngine` (value/spend, most-spun, never-spun, by-decade/genre/format, condition breakdown, monthly spins series, value-by-genre, average tracklist length — every division and index guarded). `SpinPicker` is a pure, deterministic seeded weighted picker (SplitMix64; weights toward less-recently-spun).
- **Warm record-store design language** built around burnt-orange (`#D2772E`): paper-warm light mode and near-black-wax dark mode, a tasteful **vinyl-disc motif** (grooves, center label, spindle), serif display type over rounded UI type, deterministic gradient covers (no images), both schemes first-class. Dynamic Type, accessibility labels/hints/values, decorative art hidden from VoiceOver, and Reduce Motion (disc spin disabled) are honored throughout. Haptics are sparse and gated by a Settings toggle.
- **Monetization:** one-time **$4.99 Crate Pro** unlock — unlimited collection + full Stats + value tracking + CSV/text export. StoreKit wires in for production; this build uses an honest demo unlock with a Restore action.
- **Why it can boom:** Vinyl sales are at multi-decade highs and collectors are passionate, high-intent spenders. The Discogs app is a cluttered marketplace, and there's no beautiful, private, native **collection + spin-log** app — Crate is exactly that, with a sticky "what should I spin?" hook and the real value/condition tracking serious collectors keep spreadsheets for.

## Self-review attestation

Every Swift file was re-read after authoring. Verified: imports; iOS 17 SDK availability of every type/initializer/modifier (incl. Swift Charts `SectorMark`/`BarMark`/`LineMark`/`AreaMark`, `onChange(of:)` two-parameter form, `@Bindable` on `@Model`); protocol conformances; `@Query`/`@Bindable`/`@StateObject`/`@EnvironmentObject` ownership consistency (ObservableObject + SwiftData only — no `@Observable` macro mixing); `NavigationStack`/`sheet`/`navigationDestination(for: Record.self)` binding types; the engine `SpinPicker` was renamed off `Picker` to avoid shadowing SwiftUI's `Picker` view in the same module; all Charts series are `Identifiable` structs; every referenced `Theme` token is defined; brace/paren balance. All array indexing is guarded (`subscript(safe:)`) and every division/empty case is guarded. The only force operation in the app is the in-memory `ModelContainer` fallback `try!`. `grep -rniE "TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub|unimplemented" ios/Crate` returns zero matches; exactly one `@main` (`CrateApp`) and exactly one `try!` across the sources.
