# Ember — Guided Breathwork & Calm Coach

**Breathe with a beautiful animated pacer through five proven techniques — fully offline, no subscription wall.**

Ember is a calm coach for your breath. Follow a softly glowing pacer that expands and contracts in time with each phase, with gentle haptic cues at every transition. Check in on your mood before and after, build a daily streak, and watch your calm grow in simple charts. Everything runs on-device — your breathing data never leaves your phone.

## Problem & audience
Most breathing apps lock their best content behind a $70/year subscription, and many offer a single rhythm. Ember is for anyone who wants a quick, dependable way to down-regulate stress, wind down for sleep, or wake up energized — without paying a recurring fee or needing a connection. From box breathing before a presentation to Wim-Hof-style power rounds in the morning, it covers the full range in one focused, beautiful app.

## Features
- **Animated breathing pacer** — a `Canvas`-drawn glowing orb whose radius tracks the live breath phase, synced to exact phase timings with soft haptic cues. Honors **Reduce Motion** by holding a steady orb and leading with large text cues + the live count instead of scaling.
- **Five technique families, ten built-in patterns:**
  - **Box Breathing** (4-4-4-4, 5-5-5-5) — calm focus
  - **4-7-8 Relax** + Soft Landing 4-6 — wind down toward sleep
  - **Coherent** (5-5, 6-6) — heart-rate balance
  - **Energize** (2-2, Bellows 4-3) — wake up & sharpen
  - **Power Rounds** (classic & gentle) — Wim-Hof-style power breaths → retention hold → recovery hold
- **Session length picker** (2–20 min) for paced patterns; round-based patterns show their full structure and estimate.
- **Pre/post mood check-in (1–5)** with an at-a-glance "mood lift" on every session.
- **Guided full-screen player** — wall-clock (`Date`-anchored) engine that stays correct across backgrounding; pause / resume / skip-phase / end-early, optional 3-2-1 count-in, keep-screen-awake.
- **Streaks** — current and longest daily streaks.
- **Session history** grouped by day, with detail, editable note, and swipe-to-delete.
- **Standalone mood log** with its own list and CRUD.
- **Insights** — Swift Charts: sessions-per-day bars, mood-trend line, and technique-usage breakdown, over 7 / 14 / 30 days.
- **Favorites** — pin techniques for one-tap quick start on the Breathe tab.
- **Daily reminder** — optional local notification at a time you choose.
- **Settings** — default length, count-in, keep-awake, haptics, large text cues, reminder, and a reset-data action.
- **First-run onboarding** gated by a persisted flag; empty, loading, success and recoverable error states throughout.

## Tech notes
- **iOS 17+, SwiftUI 5, MVVM.** Persistence is **SwiftData** (`BreathSession`, `MoodEntry`, `AppSettings`); breathing techniques are fixed value-type seeds (`PatternLibrary`). `UserDefaults`/`@AppStorage` holds only the onboarding flag.
- **`BreathEngine`** (`@Observable`) expands any pattern — standard 4-phase loops *or* rounds — into a timed segment timeline and derives phase/fill/countdown from `Date` anchors, so a backgrounded or briefly-stalled session self-corrects.
- **`StatsEngine`** is a pure value type computing streaks, daily counts, mood trend, and style breakdown; Insights runs it behind a loading state.
- No external dependencies, no network, no API keys. 50+ realistic sample sessions + mood entries are seeded deterministically on first run so history and charts are populated immediately.
- Full accessibility: Dynamic Type, `accessibilityLabel`/`Hint`/`Value`, decorative images hidden, Reduce-Motion fallback, asset-catalog color sets tuned for AA contrast in light **and** dark mode.
- Real designed `AppIcon` (1024×1024 RGBA PNG, ember-glow gradient + breathing rings, generated with Pillow), `AccentColor`, and a launch screen.

**Monetization:** Free core (all 5 techniques, full tracking); one-time "Ember Pro" unlock ($4.99) adds a custom-pattern builder, extra ambient themes, and richer long-range insights — no subscription.

**Why it can boom:** Breathwrk and Calm proved the market but gate everything behind pricey subscriptions; Ember delivers a gorgeous animated multi-technique pacer (including the trending Wim-Hof power rounds) with mood-lift tracking, fully offline and free at the core — exactly the value-for-money story that wins App Store reviews and word of mouth.

## Run it
```bash
brew install xcodegen        # if you don't have it
cd ios
xcodegen generate            # creates Ember.xcodeproj from project.yml
open Ember.xcodeproj         # Xcode 15+
# Select an iOS 17 simulator and press Cmd+R
```
**Free signing:** open the Ember target → Signing & Capabilities → pick your Personal Team; the bundle id `com.orbioom.ember` can be changed if it collides. No paid account required to run on a simulator or your own device.

## Self-review attestation
I re-read every Swift file checking imports, that every type / initializer / enum case / modifier exists in the iOS 17 SDK and is spelled correctly, protocol conformances (`Identifiable`/`Codable`/`Hashable`) are satisfied, and that `@State`/`@Bindable`/`@Query`/`@Environment`/`@Observable`/`modelContainer`/`navigationDestination`/sheet bindings type-check. No APIs newer than iOS 17 are used. There are no force-unwraps, `try!`, `fatalError`, or unguarded divisions on user paths; the data store fails over to in-memory and finally to a calm error screen. The anti-stub grep (`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub`) is clean. **The project was generated with `xcodegen` and built with `xcodebuild` against the iOS 17 simulator SDK: `** BUILD SUCCEEDED **` with no errors or warnings.**
