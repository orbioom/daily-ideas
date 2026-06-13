# Epigraph

**A commonplace book for the lines worth remembering — save highlights from every book, then have them resurfaced to you daily.** For readers, students, and writers who want Readwise's magic without the $8/month.

## Features

- **Highlights under each book:** paste or type a quote, annotate it in your own words, add a page/location, mark a favorite, and tag the themes that run between books (many-to-many tags).
- **Quote of the day:** a deterministic daily pick (FNV-seeded over the date) on a letterpress card, with one-tap favorite.
- **Daily review:** a swipeable resurfacing session that favors the least-recently-seen highlights (seeded shuffle), tracks a review streak, and lets you favorite as you go.
- **Library** of spine-colored books with categories, finished flag, and highlight counts; **book detail** lists and manages its highlights.
- **Highlights browser:** searchable across quote/note/book, filterable by favorites and by theme tag.
- Full CRUD for books, highlights, and tags. Onboarding, **Settings** (cards per review, theme, haptics, restore samples), one-time **Epigraph Pro**.
- Ships with a seeded public-domain library (Aurelius, Seneca, Thoreau, Austen, Sun Tzu, Whitman) so review works immediately.
- Light & dark, Dynamic Type, VoiceOver, Reduce Motion.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Epigraph.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

**Free signing:** pick your personal team and a unique bundle id in *Signing & Capabilities*.

## Tech notes

iOS 17+, SwiftUI 5, with a pure `Resurface` engine (SplitMix64 + FNV-1a deterministic daily pick and staleness-weighted review batches) and a `ReviewStreak` helper. Persistence in **SwiftData** (`Book` → `Highlight`, `Highlight` ⇄ `Tag`); prefs in `UserDefaults`. Design language: **literary letterpress** — ivory, ink, and brass, serif throughout, quotation marks as a motif.

- **Monetization:** free core; one-time **Epigraph Pro** ($6.99) adds bulk paste-import, Markdown/text export, and a resurfacing reminder. Avid readers are a proven paying niche (Readwise sustains a subscription).
- **Why it can boom:** "save and rediscover what you read" is a beloved job held hostage by a monthly subscription and a clunky import pipeline. A private, on-device, one-time-purchase commonplace book — beautiful enough to enjoy daily — is an obvious upgrade for a large, loyal reading audience.

## Self-review

Hand-reviewed every file. Verified imports; iOS-17 APIs; SwiftData relationships (cascade/inverse) and `@Query`; `SplitMix64: RandomNumberGenerator` + `shuffled(using:)`; `FlowLayout` `Layout`; review `TabView` paging and surfaced-marking. Anti-stub grep clean. No force-unwraps/`try!` on user paths.
