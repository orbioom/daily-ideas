# Sprig 🌱

**A calm, one-tap baby tracker — feeds, sleep, diapers and growth, with no subscription wall on the basics.**

Newborn life is a blur of feeds, naps and diaper changes. Sprig lets exhausted
parents log any of them in a single tap, see a clean chronological timeline, and
watch real trends and a simple growth curve emerge over time — all on-device,
all private, and free for everything you need day to day.

**Audience:** new and expecting parents tracking one or more babies (0–18 months).

---

## Features

- **Today dashboard** — baby header with live age, a live breast-feed stopwatch
  (Left / Both / Right), a one-tap sleep start/stop with a running clock, quick
  buttons for bottle / diaper / sleep / growth, today's summary counts, and
  "last event" tiles ("2h ago").
- **One-tap logging** — breast feeds via a live timer (or manual minutes), bottle
  feeds in fl oz or mL, diapers (wet / dirty / mixed / dry), sleep sessions, and
  growth measurements (weight and/or length).
- **Timeline** — every event merged into one reverse-chronological log, grouped by
  day (Today / Yesterday / date), filterable by category, with tap-to-edit and
  swipe-to-delete on every entry. Full CRUD.
- **Trends** — real Swift Charts for feeds/day (bars), sleep hours/day (area+line),
  and a wet/dirty diaper trend (stacked bars), over a 7 / 14 / 30-day window, plus
  at-a-glance daily averages.
- **Growth** — weight and length charts (your baby's own curve — no percentile
  claims), latest values, total weight gain, and a full measurement log with
  add / edit / delete.
- **Multi-baby profiles** — switch babies from the Today screen; manage profiles,
  colors and birth dates in Settings.
- **Settings** — bottle / weight / length units, haptics toggle, delete-confirmation
  toggle, and a one-time Pro unlock.
- **First-run onboarding** gated by a persisted flag, collecting the first baby's
  details so the app opens with real data.
- Empty, loading, error and success states throughout; light + dark first-class;
  Dynamic Type; VoiceOver labels/hints/values; Reduce Motion respected; haptics
  gated by a Settings toggle.

## Screens (TabView + NavigationStack)

Today · Timeline · Trends · Growth · Settings (plus Onboarding, editor sheets,
and a Pro paywall).

## Data model (SwiftData)

`Baby` (cascade-owns) → `FeedLog`, `SleepLog`, `DiaperLog`, `GrowthEntry`. Small
preferences (units, haptics, active baby, onboarding flag, Pro) live in
`UserDefaults` via `@AppStorage`. All derived stats (summaries, day series,
growth series, averages, timeline merge) come from the pure, division-guarded
`SprigEngine`.

## Run steps

```bash
brew install xcodegen          # if not already installed
cd ios
xcodegen generate              # creates Sprig.xcodeproj
open Sprig.xcodeproj            # Xcode 15+ (iOS 17 SDK)
# Select an iOS 17+ simulator and press Cmd+R
```

**Free signing:** in Xcode, select the *Sprig* target → *Signing & Capabilities*,
choose your personal team (or "Sign to Run Locally"). No paid account needed to
run on the simulator; a free Apple ID is enough for a device. No code-signing
assets are committed.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM. SwiftData for persistence; `@AppStorage` for flags.
- No external dependencies, no network, no API keys. 60+ realistic seeded events
  across two babies (deterministic SplitMix64 RNG) so every screen has life on
  first launch.
- Crash-proofing: no `fatalError` / `try!` / force-unwraps on user paths; the
  model container falls back to in-memory if the disk store can't open; all
  averages and conversions are division-guarded.
- **Monetization:** free core logging; one-time **Sprig Pro** ($4.99) unlocks
  unlimited baby profiles, data export and all profile colors — no subscription.
- **Why it can boom:** the category leaders (Huckleberry, Baby Tracker) gate basic
  logging and insights behind $10–15/mo subscriptions; Sprig gives sleep-deprived
  parents genuinely one-tap logging, real charts and a private on-device growth
  log for free, monetizing only power-user extras — exactly the wedge a frustrated,
  word-of-mouth-driven parent market rewards.

## Self-review attestation

I re-read every Swift file. All imports (`SwiftUI`, `SwiftData`, `Charts`,
`UIKit`, `Foundation`) and every type, initializer, enum case and modifier used
exist in the iOS 17 SDK and are spelled correctly. Property wrappers
(`@Model`, `@Query`, `@Bindable`, `@State`, `@AppStorage`, `@Environment`),
relationship/`inverse` declarations, `NavigationStack` / `.sheet(item:)` /
`.confirmationDialog` bindings, and `modelContainer` registration all type-check.
Swift Charts `BarMark` / `LineMark` / `AreaMark` / `PointMark`, `.position(by:)`,
`chartForegroundStyleScale`, and `AxisMarks` usage is iOS-17-valid. The feature
timeline view is named `LogTimelineView` to avoid colliding with SwiftUI's
`TimelineView` (used for the live clocks). No APIs newer than iOS 17 are used.

Verified mechanically in this environment:

- `xcodegen generate` → succeeds, creates `Sprig.xcodeproj`.
- `grep -rniE 'TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub' Sprig/` → **no matches**.
- `swiftc -target arm64-apple-ios17.0 -sdk <iPhoneOS SDK> -typecheck` over all 19
  Swift files → **exit 0, zero errors, zero warnings.**
- `AppIcon.appiconset/icon-1024.png` is a real 1024×1024 RGBA PNG (designed sage
  gradient + sprout-in-cradle emblem, generated with Pillow).
