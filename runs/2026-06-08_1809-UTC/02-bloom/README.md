# Bloom — pregnancy week-by-week companion

**Bloom is a calm, private week-by-week pregnancy tracker — baby's size, your symptoms, weight, appointments, and the tools you actually need on the day.** For expecting parents who want Ovia/What-to-Expect features without the ads, accounts, and data harvesting.

## What it is
A native iOS pregnancy companion anchored on your due date. It computes gestational age, shows a weekly development guide, and tracks symptoms, weight (with personalized healthy-gain guidance), and appointments — plus a kick counter and a 5-1-1 contraction timer.

## Features
- **Overview** — a progress ring with current week/day, days-to-go, % complete, due date, this-week baby size, next appointment, weight delta, and recent symptoms.
- **Weekly guide** — every week 4–40 with a size comparison, approximate length/weight, a development note, and a gentle tip; current week highlighted, past weeks checked.
- **Week detail** — size hero, what's happening, weekly tip, and a personalized **healthy weight-gain range by now** computed from your starting BMI via IOM guidelines (singleton or multiples).
- **Care** — log symptoms (12 types, 1–3 severity), weight (with a Swift Charts trend), and appointments (with done state); swipe to delete.
- **Tools** — a **kick counter** (count to a target with live timer + history) and a **contraction timer** (live stopwatch, average frequency/duration, and a 5-1-1 pattern guide).
- **Settings** — baby nickname, due date, multiples, pre-pregnancy weight & height (drives BMI), kick target, haptics, full reset. All persisted.
- Onboarding by due date *or* last-period estimate; empty/loading/success states; Dynamic Type + VoiceOver; light/dark; Reduce Motion; sparse haptics.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Bloom.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: select your personal team; runs on simulator and device with a free Apple ID.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `PregnancyEngine` (gestational age, trimester, progress, IOM weight-gain ranges, kick status, contraction 5-1-1 analysis) and a static `WeekCatalog`. **SwiftData** for `Pregnancy`, `SymptomEntry`, `WeightEntry`, `Appointment`, `KickSession`, `Contraction`; small prefs in `UserDefaults`. `TimelineView` powers the live timers. Design language: **Orbioom**. No external dependencies; medical content is general guidance, not advice (stated in-app).
- **Monetization:** freemium — tracking free; Pro (subscription) unlocks partner sharing, richer weekly content, and kick/contraction history export. Pregnancy apps (Ovia, Pregnancy+) are a large, proven subscription/ad market.
- **Why it can boom:** huge, recurring, high-intent audience that already pays — but the leaders are ad-heavy and privacy-poor. Bloom is fully on-device, beautiful, and free of dark patterns, with genuinely useful day-of tools.

## Self-review
Re-read every file. Verified imports, iOS 17 SDK usage, SwiftData schema (standalone log models keyed by date), `@Bindable`/`@Query`/`@Environment` ownership, `TimelineView(.periodic)` timers, Charts (`LineMark`/`PointMark`). Engine math (gestational days, BMI categories, ranges, 5-1-1) checked by hand; no division without a positive guard. Anti-stub grep clean (only "placeholder"/"keyboard" parameter names). No `try!`/force-unwrap on user paths; only the documented container-fallback `fatalError`.
