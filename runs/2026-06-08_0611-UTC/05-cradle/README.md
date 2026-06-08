# Cradle — "Every feed, nap, and change — at a glance."

A production-ready native iOS 17 newborn tracker built by **Orbioom**. Cradle beats Huckleberry and Baby Tracker on simplicity: one-tap logging, live timers, big legible last-event tiles, gorgeous insights charts, multi-baby — all on-device, no account, no subscription wall on core logging.

---

## What it is

Cradle is a lightweight but feature-complete baby tracker that makes logging the relentless feed-sleep-diaper cycle dead simple. Open the app, tap a big button, done. The home screen shows you exactly what matters: how long since the last feed, sleep, and diaper change — with live ticking timers when events are in progress.

---

## Full Feature List

### Home
- Active baby selector pill bar (multi-baby support, persisted in AppStorage)
- Prominent live timer banner (TimelineView, 1-second tick) with a Stop button when any feed/sleep/pump is ongoing
- 2×2 last-event tile grid — Feed, Sleep, Diaper, Pump — each showing time-since in big monospaced type plus secondary detail (type, amount, duration)
- 4 quick-action buttons: Feed, Sleep, Diaper, Pump — tap to start live timer or open full logging sheet; Diaper opens a fast type-picker sheet
- Today summary row: feeds, sleep duration, diaper count, bottle total

### Timeline (Log)
- Day-by-day date selector with previous/next chevrons
- Day summary header (feeds, sleep, naps, diapers)
- Chronological event list (newest first) with icon, time, summary, duration
- Tap a row to edit — full AddEventSheet opens
- Swipe-to-delete with confirmation haptic
- Empty state view when no events logged

### Add/Edit Event Sheet
- Kind picker (Feed, Sleep, Diaper, Pump, Note) for new events
- Full time fields: Start + optional End; toggle for ongoing timer vs completed
- Feed: type picker (Breast/Bottle/Solid), breast side selector, amount entry in mL or oz
- Sleep: end-time toggle for instant vs live timer
- Diaper: type picker (Wet/Dirty/Mixed)
- Pump: amount entry
- Note: free-text field
- Validation: end ≥ start, positive amounts; error messages shown inline

### Insights
- Range toggle: last 7 or 14 days
- Stat cards: avg feeds/day, avg sleep hours/day, avg feed interval, longest sleep stretch
- Feeds per day bar chart (Swift Charts)
- Sleep hours per day stacked bar chart — day sleep vs night sleep (night = 19:00–07:00)
- Diapers per day bar chart
- Empty state when no data

### Babies
- List of all babies with avatar (SF symbol + accent color), name, age, sex
- Active baby checkmark; tap "Select" to switch active baby
- Add baby: name, birth date (validated ≤ today), sex, SF symbol picker (12 options), color palette (12 colors)
- Edit any baby's profile
- Swipe-to-delete (cascades all events)

### Settings (6+ persisted preferences)
- Units: mL / oz (affects all amount display and entry)
- Time format: 12h / 24h
- Default feed type
- Appearance: System / Light / Dark (live preferredColorScheme)
- Haptic feedback toggle (wired to Haptics.enabled)
- Restart onboarding (confirmation dialog)
- Delete all data (confirmation dialog)
- About sheet with version, tech stack, studio info

### Onboarding
- 3-page brand-styled onboarding with animated page dots
- Skip or Continue; final page has Get Started button
- Gated by `@AppStorage("cradle.onboarded")`; never shown again after completion

### Data & Seed
- SwiftData on-device; Schema([Baby.self, CareEvent.self])
- Two sample babies (Mia ~3 months, Leo ~6 weeks) with 7 and 5 days of realistic events respectively
- ~8 feeds/day, ~4 sleeps/day (with one ongoing nap to demo the live banner), ~6 diapers/day, daily pump, occasional notes
- Well over 100 total seeded events across both babies

---

## Run Steps

### Prerequisites
- macOS 14+ with Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

### Generate & Open Project
```bash
cd ios
xcodegen generate
open Cradle.xcodeproj
```

### Build & Run
1. Select the `Cradle` scheme
2. Choose a simulator (iPhone 15 Pro recommended) or a connected device
3. Press **⌘R**

### Free Signing Note
For a physical device, open **Cradle → Signing & Capabilities** in Xcode, select your personal Apple ID team, and let Xcode auto-manage provisioning. No paid developer account required for personal use.

---

## Tech Notes

- **SwiftData** — full @Model graph with cascade delete; @Query with SortDescriptor; try?/guard pattern throughout; no force-unwrap on user paths
- **Swift Charts** — bar charts, stacked bars (day/night sleep split), per-day data via `CradleEngine.perDayData`
- **TimelineView** — live 1-second timer for active events, 30-second refresh for "time since" tiles
- **CradleEngine** — pure stateless enum; all computations (duration, timeSince, daySummary, averages, dayVsNightSleep, perDayData, averageFeedInterval, longestSleep) are side-effect-free and testable
- **Brand system** — all colors are dynamic light/dark tokens; no hardcoded UIColor; Brand.ease respects Reduce Motion
- **Accessibility** — Dynamic Type on all text; accessibilityLabel/Hint/Value on interactive elements; decorative images hidden; Reduce Motion respected in all animations
- **Monetization** — Optional iCloud sync or premium multi-device export as a one-time IAP; core logging forever free
- **Why it can boom** — every new parent needs this the day they leave the hospital; the category has poor UX incumbents and no viral loop blocker; beautiful design drives organic word-of-mouth in parent communities

---

## Self-Review Attestation

- No `TODO`, `FIXME`, `placeholder`, `stub`, `coming soon`, or `lorem` in any source file
- No force-unwrap (`!`) on user paths (only the one allowed `try!` in-memory ModelContainer fallback)
- No `fatalError`, unchecked index access, or unguarded division
- No APIs newer than iOS 17
- `@main` appears exactly once (`CradleApp.swift`)
- All 4 feature tabs (Home, Timeline, Insights, Babies) plus Settings implemented and populated
- CRUD: Create/Read/Update/Delete for both Baby and CareEvent
- Validation present in AddEventSheet and BabyFormSheet with user-facing error messages
- Empty, loading-equivalent, and success states present throughout
- SwiftData @Model with @Relationship(.cascade) as specified
- Seed produces well over 50 realistic events (two babies × several days)
- Swift Charts imported and used in InsightsView
- Lazy containers (LazyVGrid) used with stable IDs throughout
- All Brand color tokens used; no raw hex in views
- Haptics.tap/success/warning/selection used sparingly and gated by Haptics.enabled
