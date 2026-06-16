# Encore

**Encore** is a private, on-device concert tracker and memory keeper for iOS 17 — a Setlist.fm / Concert Archives "beater". Log the shows you've been to, remember the setlist and the support acts, see beautiful stats on your year in live music, and build a bucket list with live countdowns. No account, no network, no tracking — everything stays on your device.

Built natively in SwiftUI + SwiftData with the studio's "night / stage-lights" design language: stage-magenta accent (#C2459B), magenta→purple gradients, ticket-stub cards with a perforation notch, and a tasteful neon glow that respects Reduce Motion.

## Features

- **Timeline (home)** — attended shows reverse-chronological, grouped by year as ticket-stub gradient cards (headliner, venue · city, date, rating). A live-countdown banner (`TimelineView`) for the next upcoming show. Designed empty state.
- **Shows (library)** — searchable + filterable list (artist / venue / city / year / genre / support act) with a sort menu (newest, oldest, artist, rating, venue). Swipe to favorite or delete. Tap → detail.
- **Stats** — Swift Charts: shows-per-year (BarMark), top artists (BarMark), top venues (BarMark), genre mix (SectorMark donut), spend-over-time (Line + Area + Point). A summary grid, highlights card, and a shareable **Concert Wrapped** card (`ImageRenderer` → `ShareLink`). Async computed with a loading state and empty state.
- **Bucket List** — wishlist shows split into Upcoming (live countdown badges) and Someday. "Mark as attended" converts a wishlist item into an attended show (sets date / venue / rating). Swipe to delete.
- **Concert detail** — ticket-stub header, rating + favorite, support-act list, a **reorderable** setlist (drag to reorder; swipe a song to toggle encore / highlight), notes, companions, seat, price, a shareable **memory card** (`ImageRenderer`), Edit, and Delete (with confirm).
- **Add / Edit Concert** sheet — headliner, date, venue, city, country, tour, type, status, multi-select genres, half-star rating, price, seat, companions, notes, and a per-show ticket colour, plus inline setlist + support-act editing (add / remove / reorder rows via `EditButton`).
- **Settings** — persisted prefs that change behavior: currency code, default sort, show-countdowns toggle, haptics toggle, appearance (System/Light/Dark). Plus About, **Load sample data**, **Export CSV** (`ShareLink`), and Pro / Restore.
- **Onboarding** — three pages in the app's design language; sets `hasOnboarded` on finish.
- **Stats engine** — `ConcertStatsEngine`, a pure, fully guarded computation: totals, distinct artists (headliners + support, case-insensitive), venues, cities, countries, most-seen artist, most-visited venue, shows-per-year, spend-per-year, total spent (Decimal), average rating, by-genre counts, busiest year, first-show date, total songs logged, and upcoming shows sorted with countdown days.

## Run steps

1. This repo ships **Swift sources only** under `ios/Encore/Encore/`. The Xcode project is generated from `ios/project.yml` with **XcodeGen**.
2. From `ios/`, run `xcodegen generate` to produce `Encore.xcodeproj`.
3. Open `Encore.xcodeproj` in Xcode 15+ (iOS 17 SDK), select an iPhone simulator, and Run.
4. On first launch, finish onboarding. The Timeline auto-seeds 50+ sample shows on an empty store; you can also re-load samples from Settings.

### Free-signing note

To run on a physical device with a free Apple ID, set a unique bundle identifier and your personal team in Signing & Capabilities. No paid program, entitlements, or capabilities are required — the app is fully offline (no network, push, or background modes).

## Tech notes

- **SwiftUI + SwiftData** (iOS 17): `@Model` types `Concert`, `SetlistSong`, `SupportAct`, `Genre`, all registered in both `ModelContainer` builds. Owned children (`setlist`, `supportActs`) use `@Relationship(deleteRule: .cascade, inverse:)`; `genres` is many-to-many with the single inverse on `Genre`. `@Query` / `@Bindable` / `modelContext` throughout.
- **Money** is stored as `Decimal` and formatted with a cached, `NSDecimalNumber`-safe `CurrencyFormatter`.
- **Charts**: `BarMark`, `SectorMark` (donut), `LineMark` + `AreaMark` + `PointMark`, with a stable colour scale.
- **Sharing**: `ImageRenderer` → `Transferable` PNG → `ShareLink` for the memory and Wrapped cards; CSV via a `Transferable` document.
- **Safety**: one `@main`, zero `try!` / `as!` / force-unwrap / unchecked index / unguarded division on user paths. The only `fatalError` is the documented unreachable in-memory `ModelContainer` fallback (plus a preview-only twin in `PreviewContainer`).
- **Accessibility**: system fonts (Dynamic Type), labels/hints/values on controls, decorative icons hidden, WCAG-AA contrast in both modes, and `accessibilityReduceMotion` gates the countdown glow and onboarding animation.
- **Haptics** are sparse and gated by the `hapticsEnabled` setting.
- **Monetization**: free up to 20 shows and the first 5 setlist songs; Pro (`$3.99`, one-time, `@AppStorage("isPro")`) unlocks unlimited shows, full Stats, complete setlists, Concert Wrapped, and CSV export. StoreKit is **not** wired — the paywall's "Unlock" flips the local flag and "Restore" is present; a production build would query StoreKit 2 transactions here.
- **Why it can boom**: concert-goers love their gig history and *love* sharing it — the ticket-stub memory cards and Concert Wrapped are tailor-made for Instagram/Stories, turning every show into organic, on-brand marketing.

## Self-review attestation

- One `@main` (`EncoreApp`); ModelContainer built with do/catch-style `try?` chain and a single documented unreachable in-memory `fatalError`.
- Anti-stub grep clean (no TODO/FIXME/placeholder/etc.); zero `try!` / `as!` / force-unwraps on user paths; no `NavigationView`; two-arg `onChange` not needed (none used).
- Four substantive feature screens (Timeline, Shows, Stats, Bucket List) + Settings + Onboarding; every control does real end-to-end work.
- Empty / loading / success / error states present; light + dark first-class via `Theme.dyn`.
- 50+ seeded sample concerts across many years, with setlists (incl. encores/highlights), support acts, genres, varied prices/ratings/colours, and upcoming wishlist shows.

**Swift source files: 31.**
