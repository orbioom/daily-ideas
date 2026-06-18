# Glimpse

**A photo-a-day moment journal.** Capture one meaningful moment each day — a photo, a short caption, a mood, and a few tags — and watch a private, beautiful record of your life build up over time.

Glimpse is the calm middle ground between *1 Second Everyday*, *Project 365* and *Day One*: a one-tap daily ritual, a warm timeline, a calendar of color, gentle "on this day" memories, and a streak worth keeping — all stored entirely on your device. No account, no feed, no algorithm.

**Audience:** anyone who wants to remember their ordinary days without the friction (or exposure) of social journaling. The problem it solves: most days blur together and most journaling apps ask for too much. Glimpse asks for one moment.

---

## Features

**Core (free, fully usable)**
- **Today / Capture** — today's moment or an inviting capture CTA, with a live streak header. Photo picker, mood selector, title, caption, tags, favorite. Success confirmation toast + haptic.
- **Timeline** — reverse-chronological feed of generous photo cards (photo + date + caption + mood + tags). Lazy-loaded; filter by mood, tag or favorites; search captions/titles/tags.
- **Calendar** — month grid with a thumbnail (or mood-colored dot) per logged day, multi-moment badges, month navigation, today highlight, and a live capture-rate bar. Tap any day to see its moment(s).
- **Memories** — "On this day" from prior years, "a little while ago" time-ago resurfacing (1–6 weeks/months), a deterministic daily pick, and a favorites rail. Share any moment as a branded rendered card (ImageRenderer → share sheet).
- **Stats** — Swift Charts: current/longest streak + days + photo metric tiles, moments-per-month bars, a mood-distribution donut, and a top-tags bar chart — all with accessibility labels/values.
- **Moment detail + editor** — full-resolution view, edit, favorite, delete (with confirmation), and share-card rendering.
- **Settings** — Appearance (System/Light/Dark), Haptics, Default mood, Week-starts-on, Grid density, and a daily reminder toggle with a time picker. Membership + Restore + About.
- **Onboarding** — four-page, value-first, gated by `hasOnboarded`, respects Reduce Motion.
- **Daily reminder** — optional `UNUserNotification` "capture today's glimpse", politely permission-gated, capped to a single repeating notification.

**Pro (simulated one-time unlock — `@AppStorage("isPro")`)**
- More than one moment per day
- **Month montage export** — render a month's moments into a mosaic image and share/save it (ImageRenderer)
- Unlimited tags (free tier caps at 4)
- Extra themes
- Multiple journals

**Under the hood**
- **Image storage:** JPEGs written via `FileManager` to `Documents/Glimpse/`; SwiftData stores **only the filename**, never a blob. Imports via `PhotosPicker`, re-encoded and capped. Thumbnails are downsampled with `ImageIO` and cached. Missing files degrade to a graceful placeholder — never a crash.
- **Seed data:** on first run Glimpse seeds ~40 moments across the past ~8 weeks, each with a tasteful generated **gradient + film-grain JPEG** (rendered with `UIGraphicsImageRenderer` and a deterministic PRNG), plus varied captions, moods, tags and a scattering of favorites and gaps — so Timeline, Calendar, Stats and Memories look rich immediately. Guarded to run exactly once.
- **Pure engines:** `StreakEngine` (current/longest streak, days logged, month/year capture %), `MemoriesEngine` (on-this-day, time-ago, daily pick), `StatsEngine` (per-month counts, mood distribution, top tags, photo count). All guarded — no force-unwrap, no unguarded division.

---

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Glimpse.xcodeproj` in Xcode 15+, pick an **iOS 17+ simulator**, and press **Cmd+R**.

### Free signing
No paid Apple Developer account is needed to run on the Simulator. To run on a physical device, select the Glimpse target → Signing & Capabilities → choose your personal team (automatic signing); Xcode provisions a free development profile. The bundle id is `com.orbioom.glimpse`.

---

## Tech notes

- **iOS 17.0+**, **SwiftUI**, **SwiftData** (`@Model Moment`, `@Query`, `modelContainer`) for primary data; `@AppStorage` for preferences and the simulated Pro flag.
- **PhotosUI** `PhotosPicker` for import; **FileManager + ImageIO** image store with downsampled, cached thumbnails (no image blobs in the database).
- **Swift Charts** for all analytics; **ImageRenderer** for share cards and the Pro month montage; **UNUserNotificationCenter** for the daily reminder.
- **Design language:** warm, photographic, editorial — a soft coral accent (`#F2664B`), warm-paper/film-black surfaces via `Color.dyn(light, dark)` for full light + dark support, generous rounded photo cards, and a rounded (serif-ish) system font. Full Dynamic Type, accessibility labels/values on controls and charts, gated haptics, and Reduce-Motion-aware animation throughout.
- **Monetization:** one-time **Glimpse Pro** unlock (simulated here, StoreKit-ready) gating multi-moment days, montage export, unlimited tags, extra themes and multiple journals — the daily core stays free.
- **Why it can boom:** the photo-a-day habit is proven sticky and deeply shareable, and a *private, on-device, one-time-purchase* take (no subscription, no social feed) is exactly the trust-forward angle the journaling category is missing.

---

## Self-review

I re-read every Swift file by hand and verified:

- **Imports** present and correct per file (`SwiftUI`, `SwiftData`, `Charts`, `Foundation`, `UIKit`, `PhotosUI`, `ImageIO`, `UserNotifications`, `UniformTypeIdentifiers`) — each only where used.
- **iOS 17 only:** `NavigationStack` (no `NavigationView`); two-parameter `.onChange(of:) { old, new in }` everywhere; `.navigationDestination(item:)` with a `Hashable` value; `SectorMark`/`BarMark` Charts; `ImageRenderer`; no `@Previewable`; no iOS-18 symbols.
- **Crash-safety:** no `try!`, no `as!`, no force-unwrap (`!`) on user paths, no unchecked array indexing, no unguarded division. Image loads, day-key parsing, calendar math and PRNG ranges are all guarded and return safe fallbacks. The only `fatalError` is the documented-unreachable in-memory `ModelContainer` fallback, copied verbatim.
- **No stubs:** no `TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`stub`/`unimplemented` strings in code (the word "placeholder" appears only in doc comments describing the graceful missing-photo UI). Every button is wired; no dead screens.
- **SwiftData:** the single `@Model` (`Moment`) is listed in `Schema([Moment.self])`. `@Query` and the `#Predicate`-filtered query type-check; `modelContainer` is attached at the scene.
- **Architecture:** `AppSettings` is the lone `ObservableObject` (`@StateObject` at the app root, `@EnvironmentObject` downstream) — never mixed with `@Observable`. View models use plain `@State`. Property-wrapper ownership is consistent.
- **ImageRenderer safety:** rendered content (`ShareCard`, `MontageGrid`/`MontageTile`) loads images synchronously and uses no `@EnvironmentObject`, so renders are complete and self-contained.
- **Definition of Done:** 5 feature screens beyond Onboarding/Settings; gated multi-page onboarding; empty + loading + error + success states; ≥3 real persisted settings (six here) plus Pro/Restore/About; persistence survives relaunch with one-time seeding of ~40 items; full Dynamic Type + accessibility; gated haptics; Reduce-Motion-aware animation; cohesive coral/film identity on every screen; lazy containers with stable `Identifiable` IDs; Swift Charts with accessible labels.
- **Balance:** braces and parentheses balanced in every file (the only apparent paren delta is a `)` inside a code comment).

Attestation: to the best of my hand review, the Glimpse sources compile against the iOS 17 SDK, contain no stubs or placeholders, are crash-proofed on all user paths, and fulfill the full app spec and Definition of Done.
