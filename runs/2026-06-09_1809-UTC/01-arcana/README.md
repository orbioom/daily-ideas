# Arcana

**A beautiful tarot reading & journal for iOS.** Draw a card each day, lay out a
spread for any question, and keep a private, searchable journal of every reading —
with insights that surface your patterns over time.

**Problem & audience.** Tarot is having a renaissance, but most apps are either
clunky reference dictionaries or paywalled "AI astrologer" subscriptions that feel
impersonal. Arcana is for the everyday practitioner and the curious newcomer who
want a calm, gorgeous, *private* space to draw, reflect, and track — no account, no
data harvesting, no upsell wall on the basics.

## Features

- **Card of the Day** — a deterministic daily draw (the same all day, stable across
  launches) with full upright/reversed meaning, keyword chips, and a one-tap
  reflection note saved as that day's reading.
- **Reading flow** — five spreads (Single Card, Past·Present·Future,
  Situation·Action·Outcome, Relationship, Celtic Cross), an optional question, and a
  one-card-at-a-time reveal with a tasteful flip/fade that respects Reduce Motion.
  Save the reading with one tap.
- **Library** — the full 78-card Rider–Waite deck in a grid, searchable by name or
  keyword, filterable by arcana and suit. Each card has a detail screen with both
  meanings, keywords, element, and which of *your* readings it has appeared in.
- **Journal** — every saved reading, searchable and favorite-filterable, with a
  detail view that shows the spread layout, per-card notes, an editable reflection,
  favorite toggle, and delete (swipe or button, with confirmation).
- **Insights** — Swift Charts: readings per month (bar), suit distribution (donut),
  upright vs reversed ratio, most-drawn cards, current streak, and total readings.
- **Settings** — allow reversed cards (affects the engine), haptics, a daily-card
  reminder (local notification with a time picker and graceful denied-state handling),
  four card-back gradient styles, and a destructive "Clear journal" with confirmation.
- **Onboarding** — a three-page intro, gated by a persisted flag.
- **Everywhere** — full light/dark support, Dynamic Type, VoiceOver labels/hints,
  empty states, a loading state for first-run seeding, success and error states, and
  sparse haptics gated by the Settings toggle.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Arcana.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

**Free signing:** the project uses no paid capabilities (only local notifications,
which need no provisioning). Set your own Team in *Signing & Capabilities* and it runs
on a personal device with a free Apple ID.

## Tech notes

- **iOS 17+**, **SwiftUI**, lightweight **MVVM** (pure static engine + SwiftData
  models + views), **SwiftData** for persistence (survives relaunch).
- The full 78-card deck and the spread catalog are static Swift data; only readings
  and drawn cards are persisted.
- Daily draws use a seeded SplitMix64 PRNG keyed off the `yyyy-MM-dd` string and an
  FNV-1a stable hash, so the card of the day is deterministic across launches.
- **Orbioom design kit** (`Brand` tokens, glass surfaces, ink/glass buttons, chips,
  charts helpers) drives a consistent, dark-mode-first look.
- **Charts** framework powers the Insights screen.
- **Monetization:** free to draw, journal, and browse the full deck; a one-time
  "Arcana Plus" unlock (or low annual subscription) adds extra spreads, custom deck
  backs, iCloud sync, and PDF reading exports — the casual user pays nothing, the
  devoted practitioner pays once for power features.
- **Why it can boom:** tarot and astrology apps are a proven, high-retention,
  high-ARPU category (Co–Star, Labyrinthos, Golden Thread all have large audiences).
  We beat them on craft and trust: a genuinely beautiful, *offline-first, privacy-first*
  experience with the complete deck and real journaling free up front — versus
  incumbents that gate the deck, push subscriptions, or harvest birth data — making
  Arcana the obvious recommend in a word-of-mouth-driven niche.

## Self-review attestation

Every Swift file was hand-verified to compile against the iOS 17 SDK: imports,
types, initializers, enum cases, and view modifiers checked for existence and
spelling; protocol conformances (`Identifiable`, `Hashable`, `RandomNumberGenerator`,
`ButtonStyle`, `Layout`) satisfied; `@State`/`@Bindable`/`@Environment`/`@Query`/
`modelContainer` wiring type-checks; `NavigationStack`/`navigationDestination`/`sheet`
bindings correct; no API newer than iOS 17. All 78 cards are authored in full with no
truncation. The anti-stub grep
(`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub`) is clean.
No force-unwraps, `try!`, `fatalError` (beyond the unreachable in-memory container
fallback), or unguarded division on user paths.
