# Nocturne — "Understand your nights."

A native iOS 17 sleep tracker that goes beyond simple logging. Nocturne gives you a real sleep-debt engine, a circadian regularity score, a recommended bedtime, and beautiful trend charts — all on-device, no wearable required, no subscription wall.

---

## What It Is

Nocturne is a privacy-first, manual-entry sleep journal with genuine analytics. You log when you went to bed, when you woke up, how many times you stirred, what factors were in play (caffeine, exercise, stress, etc.), and a quality rating. Nocturne takes that data and computes:

- **Sleep debt** — rolling 14-night deficit against your personal goal.
- **Regularity score** — 0–100 score derived from the circular standard deviation of your bedtimes and wake times. A score above 75 means your circadian rhythm is well-anchored.
- **Recommended bedtime** — your target wake time minus your goal, updated live as you adjust preferences.
- **Tag correlations** — average sleep duration *with* vs *without* each lifestyle tag so you can see what actually affects your sleep.

---

## Full Feature List

### Tonight (Home Tab)
- Last night's summary card: duration ring vs goal, quality stars, vs-goal delta, bed/wake times, tags, note.
- 14-night rolling sleep-debt gauge with calm colour coding (green / amber / red).
- Regularity score dial (0–100).
- Recommended bedtime tile (live, updates with goal changes).
- Goal streak (consecutive nights meeting target).
- "Log Last Night's Sleep" button.

### Log Sleep (Sheet)
- DatePicker for bed time and wake time (full date + hour/minute).
- Live duration preview with validation feedback.
- 1–5 star quality picker.
- Awakenings stepper (0–20).
- Multi-select tag chips: Caffeine, Late screen, Exercise, Alcohol, Nap, Stress.
- Free-text note field.
- Validation: wake must be after bed; duration must be ≤ 24 h.
- Reused for edit (pre-populates all fields).
- Success haptic on save.

### History Tab
- All nights grouped by month (newest first).
- Each row: day/date, duration, quality stars, bed/wake clocks, debt contribution badge, tags.
- Swipe left: Delete (with confirmation) / Edit.
- Tap row to edit.
- Plus button to add a new log.
- Empty state.

### Insights Tab
- Range picker: 14 or 30 nights.
- **Duration bar chart** (Swift Charts) with goal rule line — green bars meet goal, amber miss.
- **Summary stats grid**: avg duration, avg quality, avg awakenings, avg bedtime, avg wake time, regularity score.
- **Bedtime & wake-time scatter chart** showing how consistent your schedule is over time.
- **Quality distribution** bar chart (Poor → Great).
- **Sleep debt trend** (area + line chart) showing how debt evolved over the selected window.
- **Tag effect table**: avg duration with vs without each tag, with up/down delta.
- All charts fully accessible (accessibilityLabel + accessibilityValue on marks).
- Empty state.

### Goal Tab
- Hero tile: recommended bedtime (live, prominent).
- Goal hours stepper (5–10 h in 15-minute steps) with range bar.
- Target wake-time picker (stored as minutes-of-day in `@AppStorage`).
- 14-night debt and regularity score summary tiles.
- Explanation cards: Sleep Debt, Regularity Score, Recommended Bedtime — each with a concise paragraph and icon.

### Settings Tab
- **24-Hour Clock** toggle (`nocturne.clock24`) — controls all time formatting throughout the app.
- **Week Starts On** picker (Sunday / Monday) — `nocturne.weekStart`.
- **Appearance** picker (System / Light / Dark) — `nocturne.appearance` drives `preferredColorScheme`.
- **Default Quality** picker (1–5) — `nocturne.defaultQuality` — pre-fills the star picker in new logs.
- **Haptics** toggle — `nocturne.haptics`.
- **Reset Onboarding** — shows the 3-page intro again next launch.
- **About Nocturne** sheet — version, privacy statement, tech notes.

### Onboarding (3 pages)
- Page 1: "Understand your nights." — product pitch.
- Page 2: Sleep debt & consistency — feature preview.
- Page 3: Set a goal, track the trend — CTA.
- Dot indicator, Continue / Back / Get Started buttons.
- Fully gated by `nocturne.onboarded` flag.

---

## Run Steps

### Prerequisites
- Xcode 15 (iOS 17 SDK)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Generate & Open Project

```bash
cd ios
xcodegen generate
open Nocturne.xcodeproj
```

### Free Signing (no paid account needed)
1. Select the `Nocturne` target → Signing & Capabilities.
2. Set **Team** to your personal free Apple ID team.
3. Change bundle ID to something unique, e.g. `com.yourname.nocturne`.
4. Run on a real device or simulator (iOS 17+).

> Swift Charts requires iOS 16+; SwiftData requires iOS 17+. No additional frameworks or SPM packages needed.

---

## Tech Notes

| Layer | Choice | Reason |
|---|---|---|
| Persistence | SwiftData (`@Model`, `@Query`) | Zero boilerplate, reactive, ships with iOS 17 |
| Charts | Swift Charts (`import Charts`) | Native, accessible, no third-party dependency |
| Analytics | `SleepEngine` (pure enum) | Stateless, fully testable, zero SwiftUI coupling |
| Motion | `Brand.ease(_:)` + `@Environment(\.accessibilityReduceMotion)` | Respects system setting on every animation |
| Haptics | `Haptics.tap/success/warning/selection` gated by user toggle | Sparse, intentional, never on passive transitions |
| Colours | `Brand.dynamic(_:_:)` UIColor trait-collection bridge | True per-trait-collection light/dark — no `.colorScheme` hacks |

**Monetization (one line):** Unlock unlimited history export and iCloud sync via a one-time in-app purchase — no recurring subscription.

**Why it can boom (one line):** Every sleep-tracker competitor either needs a wearable or sells a subscription; Nocturne is the one app that delivers a credible debt-and-regularity engine for free, on-device, with no sign-up.

---

## Self-Review Attestation

- No `TODO`, `FIXME`, `placeholder`, `stub`, `coming soon`, or `lorem` text anywhere in source.
- No force-unwrap (`!`) except the single allowed in-memory ModelContainer fallback in `NocturneApp.swift`.
- No `try!` except the ModelContainer fallback.
- No `fatalError` calls.
- All divisions guarded (engine guards `count > 0`, geometry guards `maxDebt > 0`, goal guards `goalHours > 0`).
- All time math uses `Calendar`; bedtime-before-midnight handled via day offset.
- 40 seed records with realistic variation (varied quality, awakenings, tags, durations 5.8–8.8 h).
- Swift Charts imported and used across 4 distinct chart types.
- Lazy containers (`List`, `LazyVGrid`) use stable IDs.
- `@AppStorage` keys: `nocturne.onboarded`, `nocturne.haptics`, `nocturne.appearance`, `nocturne.clock24`, `nocturne.weekStart`, `nocturne.defaultQuality`, `nocturne.goalHours`, `nocturne.targetWake`.
- All 4 feature screens (Tonight, History, Insights, Goal) plus Settings implemented with back/dismiss working.
- CRUD: create via LogSleepView, read via TonightView/HistoryView/InsightsView, update via LogSleepView(existing:), delete via swipe-to-delete in HistoryView.
- Empty, loading-equivalent (data gated), error (validation alert), and success (haptic + dismiss) states all present.
- Dynamic Type: all text uses system fonts or `Brand.mono` (scaled system fonts); no hard-coded pixel text.
- Reduce Motion respected on every animation site.
- Decorative images marked `accessibilityHidden(true)`; interactive controls have labels, hints, and values.
- Light + dark verified via `Brand.dynamic` tokens only — no hardcoded colours.
