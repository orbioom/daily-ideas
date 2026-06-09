# Vesper — a calm prayer journal & daily devotional

Vesper is a quiet, private, on-device space to pray, reflect, and notice how
prayers unfold over time. Each day opens with a short public-domain scripture and
a gentle reflection prompt; alongside it lives a living list of prayers you can
hold, update, and one day mark answered. No accounts, no content upsell, no
feed — just you, your prayers, and a little insight into the rhythm of your
devotional life.

## Features

- **Today** — Devotion of the Day (deterministic per calendar day), with verse,
  reference, theme, and a reflection prompt. Mark it read with an optional
  reflection note; gentle success state. Activity-streak and readings stat tiles,
  a "Needs prayer" short list of long-untouched active prayers, an optional
  evening-examen prompt, and a one-tap "New prayer" button.
- **Prayers** — A searchable list filterable by status (Praying / Answered /
  Archived) and category, pinned prayers shown first. Create prayers (title,
  body, category, person, pin). Prayer Detail shows the body, a timeline of dated
  reflections you can add, and lets you mark answered (with a note and a calm
  success state), pin/unpin, archive/restore, edit, and delete-with-confirm.
  Swipe to pin or delete. Empty and no-match states.
- **Devotions** — Browse the full library of 65 public-domain readings, filter by
  theme and search by reference or text. Read-state badges. Devotion Detail shows
  the verse, reflection, theme, your personal reading history for that passage,
  and a "mark read" action. Reading streak and total surfaced at the top.
- **Insights** — Charts (Apple Charts framework): prayers added vs. answered per
  month (grouped bars), category distribution (donut), answered-rate and streak
  stat tiles, longest-standing prayers (RankBar by days held), and readings per
  month (area/line). Empty states throughout.
- **Settings** — Translation label picker (persisted), daily reminder (toggle +
  time via UNUserNotificationCenter, with an inline calm state if notifications
  are denied), evening-examen prompt toggle, show-archived toggle, haptics
  toggle, and a destructive "Clear all prayers" with confirmation. Six real
  persisted preferences.

Plus: onboarding gated by `@AppStorage("vesper.onboarded")`, full Dynamic Type
and VoiceOver support, Reduce Motion honored, light + dark via the Orbioom Brand
system, and SwiftData persistence that survives relaunch.

## Run

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate`
3. Open `Vesper.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press
   **Cmd+R**.

**Free signing:** select the `Vesper` target → Signing & Capabilities → choose
your personal team. The bundle id `com.orbioom.vesper` can be changed to anything
unique if signing complains.

## Tech notes

- **iOS 17+**, **SwiftUI**, lightweight **MVVM** (pure static `VesperEngine` for
  all stats/streaks/series; views stay thin).
- **SwiftData** models: `Prayer` (with a cascade `PrayerUpdate` timeline) and
  `ReadingLog`; a static `DevotionLibrary` of 65 entries.
- Devotion texts are the **public-domain World English Bible (WEB)**; the daily
  reading is fully deterministic via an FNV-1a hash of the `yyyy-MM-dd` day key
  (no randomized hashing, no `SystemRandomNumberGenerator` on that path).
- **Orbioom design system** (Brand tokens, GlassCard, ink/glass buttons, chips,
  stat tiles, rank bars, flow layout) shared verbatim across the studio.
- **Charts** framework powers the Insights screen.
- **Monetization:** a simple one-time "Vesper Plus" unlock (custom reminder
  schedules, themes, and export) — no subscription, no content paywall.
- **Why it can boom:** the faith market is proven and top-grossing (Hallow,
  Pray.com, YouVersion), but those lean on content and upsell; Vesper is calm,
  private, and on-device, with real answered-prayer tracking and gentle insight
  instead of a feed — a journaling-first niche that retains.

## Self-review attestation

Every Swift file was hand-verified against the iOS 17 SDK: imports, SwiftData
`@Model`/`@Query`/`@Bindable`/`modelContainer` wiring, `NavigationStack` and
sheet/destination bindings, Charts (`BarMark`/`SectorMark`/`LineMark`,
iOS-17-only marks), deterministic devotion math, and accessibility. No stubs,
no `TODO`/`FIXME`/placeholder text, no force-unwraps / `try!` / unguarded
division on user paths (the only `fatalError` is the reference in-memory
container fallback). Empty, loading, error, and success states are present
across all screens.
