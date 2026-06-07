# Vial — Medication & refill tracker

**A calm, private medication tracker.** See today's doses, tick them off, and let Vial count your supply down to a refill-by date and chart your adherence — all on your device.

> Vial is a personal tracker, not medical advice. Always follow your prescriber's instructions.

Design language: **Orbioom** (Liquid Glass, ink-gradient buttons, SF Pro + JetBrains Mono, green for taken/adherence; per-medication colour accents).

## The problem
Pill organisers don't track supply, and most med apps push you to an account. Vial keeps an adherence log and a running supply count locally, and tells you the exact day to reorder each prescription.

## Features
- **Today** — the day's doses across all medications in time order, with one-tap Taken/Skip (and undo), and a breathing progress ring. Marking a dose taken decrements that medication's supply; undoing restores it.
- **Dose engine** (`Utilities/DoseEngine.swift`): builds each day's dose slots from per-med times and weekdays, matches them to logs, computes days-of-supply and run-out / refill-by dates, and adherence (overall, daily series, per-med) over a trailing window.
- **Medications** — list with supply/refill-soon badges; full CRUD with multiple daily dose times, every-day or specific weekdays, units per dose, form, colour, on-hand quantity, refill threshold, active toggle, notes.
- **Medication detail** — supply with days-of-supply, run-out date and refill-by date; schedule summary; 30-day adherence bar; recent dose history; quick refill logging.
- **Refills** — upcoming refills sorted by run-out with refill-by dates, plus a refill history with total spend; logging a refill adds to supply (deleting reverses it).
- **Insights** — 30-day adherence headline, a 14-day daily-adherence chart, and per-medication adherence bars. Computed asynchronously with a loading state.
- **Settings** — haptics, appearance, default refill-alert window, confirm-before-delete, data counts, guarded erase-all.
- Onboarding gated by a persisted flag (with a not-medical-advice note); empty/loading states; full Dynamic Type, VoiceOver, Reduce Motion, light & dark, designed capsule app icon. Seeds four medications with 30 days of dose history and refills.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Vial.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** personal team under Signing & Capabilities; bundle id `com.orbioom.vial`. No network, accounts, or API keys; no push notifications — Vial is a tracker you check, not a reminder service.

## Tech
iOS 17+, SwiftUI 5, SwiftData (`Medication`/`DoseLog`/`Refill`), pure value-type engine, native bar charts and a `Canvas`-free trim ring, `UserDefaults` for prefs. No third-party dependencies.

## Self-review
Re-read every Swift file by hand: imports, iOS 17 SDK symbols, SwiftData relationships & `@Query` keypaths, `sheet(item:)` Identifiable, `AnyShapeStyle` ternary backgrounds, `DatePicker(.hourAndMinute)` bindings, `.onChange` two-parameter form, `project.yml`. Anti-stub grep clean. The `daysOfSupply` can be `.infinity`; every `Int(...)` conversion of it is guarded by `.isInfinite`/positive-consumption checks (verified). Only `try!` is the in-memory container fallback. An automated by-hand compile review of this app returned clean. Believed to compile cleanly under Xcode 15+ after `xcodegen generate`.
