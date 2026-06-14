# Lancet — glucose & diabetes manager

**One-liner:** A private, on-device glucose logbook that turns your readings into the numbers that matter — estimated A1C, GMI, and Time-in-Range — without a subscription wall.

**The problem + audience:** People with diabetes or prediabetes log blood sugar every day, but the category leader (mySugr) paywalls its best insights and reports behind a recurring "Pro" subscription, and most apps bury the one view clinicians and patients actually use — the classic meal-slot logbook. Lancet is for anyone managing glucose (T1, T2, gestational, prediabetes) who wants a fast, beautiful logbook and free analytics that live only on their phone.

## Full feature list
- **Today dashboard** — latest reading as a big, color-coded number (low / in-range / elevated / high) with "x min ago", a Time-in-Range ring for today, an estimated-A1C / GMI / average mini-card, today's readings list, and a prominent **Log reading** button. Designed empty state before any readings.
- **Logbook** — the classic diabetes grid: rows = recent days, columns = meal slots (Breakfast / Lunch / Dinner / Bedtime), cells show color-coded values; tap a cell to edit that reading.
- **History** — all readings grouped by day with a per-day average, a context filter, full add/edit/delete (swipe), reusing the validated entry sheet.
- **Insights** — estimated A1C `(avg + 46.7)/28.7`, GMI `3.31 + 0.02392·avg`, average, Time-in-Range stacked bar, glucose variability (CV%), hypo/hyper excursion counts, by-context averages, and Swift Charts: glucose-over-time scatter with a shaded target band, a TIR donut (SectorMark), and a readings-by-hour view. Loading state while stats compute.
- **Add / Edit reading** — unit-aware numeric entry with live band classification, context picker (fasting / before-meal / after-meal / bedtime / exercise / random), optional carbs & insulin, note, and date; rejects empty / non-numeric / ≤ 0 / > 800 with an inline error.
- **Settings** — units (mg/dL ↔ mmol/L, changes every display and chart axis), target range low & high steppers (drive the engine and all color coding), show-A1C-on-Today toggle, haptics; plus Pro, CSV export, Load sample data, reset, and About.
- **Onboarding** (3 pages), first-run gated; ~120 realistic seeded readings across ~21 days so every screen is alive on first launch.

## Run steps
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Lancet.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing note:** No paid account needed — in Xcode set a Personal Team on the target and use the `com.orbioom.lancet` bundle id (or your own) to run on a device. No entitlements or capabilities are required.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. Primary data in **SwiftData** (`Reading`), small prefs in `@AppStorage`. Canonical mg/dL stored; mmol/L computed at display.
- Pure `GlucoseEngine` (A1C / GMI / TIR / variability / by-context / hourly) with every division and array access guarded; no force-unwrap, `as!`, `fatalError`, or `try!` on user paths (the one `try!` is the in-memory `ModelContainer` fallback).
- Design language: clinical-calm, crimson/coral accent with a green in-range band; first-class light & dark via `Theme.dyn`; Dynamic Type, VoiceOver labels on values/rings/charts, Reduce Motion respected.
- **Monetization:** logging is always free; **Insights charts + CSV export** are a one-time **$4.99** Pro unlock (StoreKit not wired in this build — the demo "Unlock" flips a flag; "Restore" present). Who pays: daily glucose loggers who want analytics without mySugr's subscription.
- **Why it can boom:** glucose tracking is a proven, high-retention health category with millions of daily users; the incumbent (mySugr) is widely disliked for paywalling reports. Lancet ships the beloved logbook + free A1C/TIR insights with a one-time price and on-device privacy — exactly the version reviewers keep asking for.

## Self-review
29 Swift files. Static audit clean: exactly one `@main`, exactly one `try!` (in-memory fallback), anti-stub grep clean, all asset JSON valid, real 1024² icon, balanced delimiters, no `@Observable`/`@StateObject` mixing. Engine divisions/indices guarded; all `Reading` registered in both `ModelContainer` calls; ≥4 substantive feature screens + Settings; empty/loading/error/success states throughout. A dedicated compile-review pass read every file for cross-file type/API correctness against the iOS 17 SDK.
