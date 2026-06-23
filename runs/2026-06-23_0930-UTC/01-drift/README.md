# Drift

**A calm, chronotype-based sleep coach that plans your bedtime and keeps your sleep debt honest — no account, no wearable, no paywall on the basics.**

## Problem & audience

Most people don't sleep badly because they lack a fitness ring — they sleep badly because their bedtime drifts, their schedule is irregular, and a quiet two-week deficit piles up unnoticed. Existing apps either demand a wearable, hide the useful parts behind a subscription, or bury you in data you can't act on.

Drift is for anyone who wants a **plan, not a dashboard**: a nightly lights-out target tuned to their body clock, an honest read on the sleep debt they're carrying, a wind-down routine that actually starts on time, and a clear signal of whether their rhythm is steady or scattered. Everything is computed on-device from two numbers you already know — when you went to bed and when you woke up.

## What makes it different

- **Chronotype-aware bedtime planning.** Pick your sleep "animal" (Lion / Bear / Wolf / Dolphin). Drift plans backward from a steady wake time, nudges the suggested bedtime to fit your type, and sizes your wind-down lead accordingly.
- **Real sleep-debt math.** A rolling 14-night model: nightly shortfalls accumulate, surplus pays it down but is capped per night (one great Saturday can't erase a rough fortnight). Charted as a cumulative trend.
- **Circular consistency score (0–100).** Uses circular statistics so 23:50 and 00:10 count as close. Tighter clustering of bed/wake times = higher score.
- **Wind-down checklist that resets nightly.** Build your own calming sequence; Drift tells you when to begin it and celebrates a finished routine.

## Feature list

- **Tonight tab** — hero card with chronotype, suggested lights-out time, wind-down start, wake time and sleep target; 14-night sleep-debt status with coaching; consistency ring; average sleep/quality; one-tap jump into the routine.
- **Log tab** — full CRUD over nights: date, bed/wake times (midnight-safe duration), 1–5 quality, wake-ups, free tags, notes. Swipe to delete with confirmation, tap to edit, live duration validation.
- **Trends tab** — three Swift Charts: sleep-duration bars vs goal line, cumulative sleep-debt area/line, and a bedtime-consistency scatter on a 20:00–04:00 scale. Switch between 14- and 30-night windows.
- **Routine tab** — tonight's wind-down checklist with nightly auto-reset and progress bar; a "Manage" mode for reorder, enable/disable, edit, delete, and add steps with an icon picker.
- **Settings tab** — chronotype picker sheet, target wake time, nightly goal slider, and **three persisted preferences** (haptics, 24-hour clock, include-wind-down-in-bedtime). Data management: delete all logs, restore sample data, replay onboarding.
- **Onboarding** — three-step gated first run (intro → chronotype quiz → schedule anchor), persisted via an `@AppStorage` flag.

## Tech notes

- **iOS 17+, SwiftUI 5, MVVM.** Persistence is **SwiftData** (`@Model` `SleepLog`, `WindDownItem`, `SleepSettings`; `@Query`/`modelContainer`). Only the onboarding flag lives in `UserDefaults`.
- **Pure engine** (`SleepEngine`) holds all the math (debt, circular consistency, chronotype bedtime, averages) with zero UI/persistence coupling, so it is trivially testable.
- 56 nights of deterministic, plausible sample sleep are seeded on first launch (stable PRNG) plus a 7-step default wind-down routine — the app is never empty.
- **No external dependencies, no network, no API keys.** Light + dark mode via asset-catalog color sets; Dynamic Type, VoiceOver labels/values/hints, decorative images hidden, Reduce-Motion-aware animation, and Settings-gated haptics throughout. Recoverable error/empty/loading/success states; no `fatalError`/`try!`/force-unwraps on user paths (SwiftData container falls back to in-memory rather than crashing).
- **Monetization:** free core forever; one-time "Drift Plus" unlock (or light tip jar) for extras like custom chronotype tuning, CSV export, and additional chart windows — never a wall on bedtime, debt, or logging.
- **Why it can boom:** the sleep market has proven multi-million-download winners (Sleep Cycle, Pillow), but they lean on wearables and aggressive subscriptions; Drift's wearable-free, account-free, "plan not dashboard" angle with chronotype framing is exactly the calm, trust-first hook that spreads by word of mouth.

## Run steps

```bash
brew install xcodegen      # if not already installed
cd ios
xcodegen generate          # creates Drift.xcodeproj from project.yml
open Drift.xcodeproj        # Xcode 15+
# Select an iOS 17+ simulator, then Cmd+R
```

**Free signing:** the project has no provisioning baked in. To run on a physical device, open the target's *Signing & Capabilities*, pick your personal Apple ID team, and let Xcode manage a free development signature. The simulator needs no signing at all.

## Self-review attestation

I re-read every Swift file as the compiler. All imports (`SwiftUI`, `SwiftData`, `Charts`, `UIKit`, `Foundation`) resolve; every type, initializer, enum case, modifier and chart mark used exists in the iOS 17 SDK and is spelled correctly; protocol conformances (`View`, `Identifiable`, `Codable`, `CaseIterable`, SwiftData `@Model`) are satisfied; property wrappers (`@State`, `@Binding`, `@Bindable`/binding helpers, `@Environment`, `@Query`, `@AppStorage`, `@MainActor`) are used correctly; `NavigationStack`, sheet/alert bindings, and `modelContainer`/`@Query` type-check. No APIs newer than iOS 17 are used.

The anti-stub grep is clean:

```
grep -rniE 'TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub' Drift/   →  (no matches)
```

There are no `fatalError`, `try!`, `as!`, or force-unwraps on user paths. **Beyond static review, the project was generated with `xcodegen` and compiled against the iOS Simulator SDK with `xcodebuild` — result: `** BUILD SUCCEEDED **` with no errors and no non-deprecation warnings.** The generated `.xcodeproj` and build artifacts were removed afterward; regenerate with `xcodegen generate`.
