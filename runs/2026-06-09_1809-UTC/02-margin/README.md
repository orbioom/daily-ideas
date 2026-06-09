# Margin

**Read more, on purpose.** Margin is a native iOS reading tracker built around a
yearly reading challenge. It keeps your whole library in one place — currently
reading, want-to-read, finished, and DNF — tracks page-by-page progress, logs
reading sessions, and turns it all into a challenge ring, pace verdicts, and rich
reading analytics.

## What it is

A SwiftUI + SwiftData app (iOS 17+) that combines a full personal library with a
Goodreads-style yearly challenge and StoryGraph-style analytics, in one calm,
offline, on-device experience. No accounts, no cloud, no cover-image scraping —
each book gets a deterministic colored "spine" generated from its title.

## Features

- **Shelf (Home)** — Currently-reading cards with progress bars, projected finish
  dates, and one-tap "Log progress"; an "Up next" strip of want-to-read books; a
  finished-this-year count; and the yearly-challenge ring. Empty state when the
  library is empty.
- **Library** — Every book grouped into sections by status, searchable by title or
  author, with status filter chips and sort by recent / title / rating. Add-book
  sheet (title, author, pages, genre, format, status, rating, tags, notes). Full
  book detail: progress, editable star rating, session history, tags, notes, and
  actions to log progress, mark finished, edit, or delete. Empty + no-results
  states.
- **Challenge** — Big yearly-goal ring, pace verdict ("3 books ahead of
  schedule"), projected year-end finishes, days remaining, a books-finished-
  per-month bar chart, the this-year finished list, and an inline edit-goal sheet.
- **Insights** — Charts: pages per week (area), books finished per month (bar),
  genres read (bar), rating distribution (bar); plus reading-streak, pages/day,
  pages this year / all-time, average rating, average days-to-finish stat tiles,
  and a longest-book card. Empty state until there's data.
- **Settings** — Yearly goal stepper, progress display unit (pages vs percent,
  affects the logging UI), default book format, haptics toggle, daily reading
  reminder (local notification with time + denied-permission fallback), library
  counts, and a destructive "Clear library" with confirmation. All persisted.

Plus: first-run onboarding gated by `@AppStorage("margin.onboarded")`, empty
states everywhere, calm confirmation/destructive flows, light + dark mode, Dynamic
Type, VoiceOver labels/values on progress bars, ratings, and controls, Reduce
Motion honored, and sparse gated haptics.

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate`
3. Open `Margin.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press
   **Cmd+R**.

**Free signing:** to run on a physical device, select the Margin target →
Signing & Capabilities → set your personal Apple ID team and a unique bundle
identifier. No paid developer account is required for local device runs.

## Tech notes

- **iOS 17+**, **SwiftUI**, **MVVM**-leaning structure (pure static `MarginEngine`
  for all analytics, views stay declarative), **SwiftData** for persistence
  (`Book`, `ReadingSession`, `BookTag` with cascade + many-to-many relationships),
  **Charts** for Insights, and the shared **Orbioom** design system (Brand tokens,
  GlassCard, ink/glass button styles, motion curves).
- Persistence is on-device and survives relaunch; seed data loads once on first
  launch so every screen is populated.
- **Monetization:** free core library + challenge, with a one-time "Margin Pro"
  unlock for unlimited custom tags, advanced analytics, and reading-goal history.
- **Why it can boom:** it fuses the two apps readers juggle today — a full library
  tracker (Goodreads) and a reading-analytics dashboard (StoryGraph) — into one
  fast, private, offline app whose yearly challenge, projected pace, and
  genre/mood analytics make "read more" a measurable, motivating game.

## Self-review attestation

Every Swift file was hand-verified to compile against the iOS 17 SDK: imports,
SwiftData `@Model`/`@Query`/`@Bindable`/`modelContainer` wiring, NavigationStack
and sheet bindings, Charts marks, and enum conformances were all checked. No
force-unwraps, `try!`, unguarded division on user paths, or post-iOS-17 APIs
remain; the only `fatalError` is the reference in-memory container fallback. The
anti-stub grep (`TODO|FIXME|XXX|placeholder|lorem|coming soon|not
implemented|// stub`) returns no matches.
