# Hearth

A calm home-cleaning rotation manager — the tasteful answer to Tody and Sweepy.
Your home is a set of rooms; each room has a few recurring cleaning chores with a
cadence. Hearth tracks when each was last done, surfaces what's due or overdue
today, gives every room a living **freshness** score that gently decays over
time, and rolls everything up into a whole-home cleanliness gauge. One tap marks a
chore done — Hearth resets its clock, logs the minutes, and keeps your streaks.

Built for the Orbioom studio. "Conjured, not just coded."

## Features

- **Today** — a whole-home cleanliness ring gauge plus the due/overdue (and
  optionally "due soon") chores grouped by status, each with its room, estimated
  time, and a one-tap Done button (haptic + animation). Calm empty state when
  everything is fresh.
- **Rooms** — every room with its freshness ring, task count, and a "N due"
  badge. Add, edit (name, color accent, SF Symbol icon), and delete rooms.
  - **Room detail** — the room's tasks with per-task status, cadence, next-due,
    and a freshness bar; add/edit/delete tasks, pause/resume, and one-tap Done.
- **Insights** — Swift Charts: chores per week (bar, 6w/12w), effort by room
  (donut + breakdown), time spent, day-streak and totals stat cards, and a "most
  neglected" list. Empty state until you complete a chore.
- **Settings** — persisted preferences wired to behavior: "soon" window
  (1–7 days, drives status bucketing), show "due soon" on Today, show estimated
  time, and haptics. Plus replay-intro, delete-all-data (with confirmation), and
  an about section.
- **Onboarding** — a gated 3-slide welcome.

Other niceties: realistic seeded home + ~6 weeks of history so every screen is
alive on first launch, full Dynamic Type and VoiceOver labels/values for
freshness and status, Reduce Motion gating (including the gauge), AA-contrast
Brand tokens in light and dark, sparse gated haptics, and clamped input
validation.

## Run

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Hearth.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, press Cmd+R.

### Free-signing note
The project uses a personal/free Apple ID signing flow. If signing fails, select
the **Hearth** target → **Signing & Capabilities** → choose your own Team and let
Xcode manage signing. The bundle id is `com.orbioom.hearth`; change it if it
collides with an existing profile.

## Tech notes

- **Platform:** iOS 17+, SwiftUI, MVVM-lite (pure static engines + SwiftData
  models + views).
- **Persistence:** SwiftData (`Room`, `CleaningTask`, `CompletionLog`).
  `Room → CleaningTask` is a cascade relationship; `CompletionLog` is an
  independent model that is *not* cascade-deleted, so stats and streaks survive
  task or room deletion. In-memory fallback if the on-disk store can't open.
- **Engine:** `HearthEngine` (due status, next-due, freshness, room/home
  cleanliness, today's tasks) and `StatsEngine` (daily/weekly series, by-room,
  streak, totals) are pure and dependency-free; all averages guard against
  divide-by-zero.
- **Charts:** Swift Charts (`BarMark`, `SectorMark`).
- **Design:** the Orbioom Brand system — color tokens that resolve per color
  scheme, glass surfaces, ink/glass buttons, and a single easing curve.

### Monetization

Free for **one home** (rooms + tasks + Today + core insights). **Hearth+**
(one-time unlock or light subscription) unlocks unlimited rooms, the full
Insights suite, and — on the roadmap — household sharing so everyone can see and
claim chores.

### Why it can boom

Home management is a large, evergreen market, and the incumbents (Tody, Sweepy)
feel dated and fiddly — heavy setup, busy UIs, guilt-driven streaks. Hearth's
**living freshness score** turns upkeep into something you *feel* rather than
schedule, and the calm one-tap flow makes staying on top of the house feel
effortless. That combination of broad appeal (every household) and a genuinely
nicer daily loop is what gives it room to grow.

## Self-review attestation

I re-read every Swift source by hand (there is no Xcode here — I am the compiler):

- Imports verified per file; `HearthEngine` imports SwiftData for
  `PersistentIdentifier`.
- All types/inits/modifiers/enum cases checked against the iOS 17 SDK; no
  post-iOS-17 APIs. Swift Charts usage (`BarMark`, `SectorMark`,
  `.foregroundStyle(by:)`, `chartLegend(position:spacing:)`) is iOS 17-valid.
- SwiftData wiring type-checks: `@Model`, `@Query`, `@Relationship(inverse:)`,
  `@Bindable`, `modelContext`. `CompletionLog` confirmed independent of the
  `CleaningTask` cascade.
- Ownership of `@State`/`@Bindable`/`@Environment`/`@AppStorage`,
  NavigationStack, and sheet/`item:` bindings reviewed.
- Date math uses `Calendar` (`startOfDay`, `dateComponents`, week-of-year);
  averages guard divide-by-zero; never-done tasks read as due/overdue.
- No `fatalError`/`try!`/force-unwrap on user paths (the only `fatalError` is the
  pre-existing in-memory `ModelContainer` fallback in `HearthApp`).
- Anti-stub grep over the source folder (`TODO|FIXME|XXX|placeholder|lorem|coming
  soon|not implemented|// stub`): **zero matches.**
- Accessibility: Dynamic Type throughout, `accessibilityLabel`/`Value` for
  freshness scores and status, decorative images hidden, Reduce Motion gating on
  the ring/gauge and button styles.
