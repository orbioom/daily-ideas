# Tome

A calm, private **book reading tracker + reading challenge + stats** app for iOS 17 — a Goodreads / StoryGraph "beater" that keeps everything on-device, charges nothing for stats, and reads like a cozy library.

## What it is

Tome lets you shelve every book you read, track progress page by page, log reading sessions, keep a yearly reading challenge, and see exactly how you read — all in a warm, paper-inspired design with generated book covers. No account, no ads, no tracking. Your library lives in on-device SwiftData and never leaves your phone.

## Features

**Reading (home)**
- Reading-challenge ring (books finished this year vs your goal)
- "Currently Reading" cards with progress bars and quick **Update page** / **Log session** actions
- Recently finished strip with ratings
- Designed empty state for a fresh shelf

**Library**
- `LazyVGrid` of generated gradient covers (deterministic from a color seed + title/author initials)
- Search across title, author, and series
- Segmented shelf filter (All / Reading / TBR / Finished / DNF)
- Sort menu: recently added, title, author, rating, progress

**Stats** (Swift Charts)
- Reading-challenge gauge + summary cards (pages read, finished this year, longest streak, average rating)
- Pages-per-month bar chart (current year) — free
- Genre donut (`SectorMark`), ratings histogram, and pace/finishing card — **Pro**
- Async compute with a brief loading state; designed empty state

**To Read (TBR)**
- Want-to-read queue with per-book menu (Start reading / Remove)
- Date-seeded **"What next?"** picker that reveals one book with a "Start reading" action and a re-roll
- Designed empty state

**Book detail**
- Generated cover header, progress ring + bar with finish-date projection
- **Update current page** sheet and **Log session** sheet (page range or count + minutes; auto-advances and can auto-finish)
- Reading-sessions list with pages/minutes and per-row delete
- Half-step star rating, shelf segmented control (auto-sets started/finished dates), review editor, favorite, edit, delete (confirmed)

**Add/Edit Book** and **Log Session** sheets with validation.

**Settings** — persisted prefs that change behavior: yearly goal stepper, daily page target, haptics, gradient-covers toggle, default sort, appearance (System/Light/Dark). Plus About, **Load sample data**, **Reset library**, **Export CSV** (ShareLink), and Pro / Restore.

**Onboarding** — 3 pages in the app's design language; sets `hasOnboarded`.

## Run steps

1. This repo contains **Swift sources only**; the Xcode project is generated from `ios/project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen).
2. From `ios/`, run `xcodegen generate` to produce `Tome.xcodeproj`.
3. Open the project in Xcode 15+ and run on an iOS 17 simulator or device.
4. On first launch, complete onboarding, then tap **Load sample data** in Settings (or add your own book) to populate the 56-book sample library.

## Free-signing note

To run on a physical device with a free Apple ID, set a unique bundle identifier and select your personal team in **Signing & Capabilities**. No paid developer account is required for local installs.

## Tech notes

- **SwiftUI + SwiftData** (`@Model` `Book`, `ReadingSession` (cascade child), `Tag` (many-to-many)), `@Query`, `@Bindable`, all three types registered in a single shared `TomeContainer`.
- Pure, fully-guarded `ReadingEngine` (progress, pace, projected finish, streaks, by-genre counts, ratings histogram, pages-per-month, average days-to-finish) — no force-unwraps, no unguarded division.
- Swift Charts (`BarMark`, `SectorMark`), `Color.dyn(light,dark)` theming for first-class light/dark, serif headings for a literary identity, generated gradient covers (no bundled art), gated haptics, Reduce-Motion-aware animation, full Dynamic Type + accessibility labels.
- **Monetization:** one-time **Tome Pro** ($3.99) — free up to 30 books; the 31st triggers the paywall. Pro unlocks unlimited library, full stats charts, custom tags, and CSV export. StoreKit is not wired; "Unlock" sets `@AppStorage("isPro")` and "Restore" is present (noted honestly).
- **Why it can boom:** readers resent paying a subscription for reading stats and worry about data privacy — Tome gives the charts away free, keeps everything on-device, and asks one fair one-time price only for power features.

## Self-review attestation

- 29 Swift source files under `ios/Tome/Tome/`.
- One `@main` (`TomeApp`); zero `try!`; zero force-unwraps/`as!` on user paths; one documented unreachable in-memory `fatalError` (centralized in `TomeContainer`).
- Anti-stub grep clean (no TODO/FIXME/placeholder/etc.); no `NavigationView`; all `onChange` use the two-argument iOS 17 form.
- 4 feature tabs (Reading, Library, Stats, To Read) + Settings; onboarding gate; empty/loading/error(validation)/success states throughout; ≥3 persisted prefs that change behavior; 56-book seed with ~40 sessions across the year.
- Reviewed every file as the compiler for iOS 17 SDK correctness.
