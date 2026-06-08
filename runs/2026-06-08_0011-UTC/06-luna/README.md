# Luna — private cycle tracker

**Your cycle, understood — and yours alone.** Log your period in a tap and Luna learns your rhythm, predicting your next period, fertile window, and ovulation. No account, no cloud, no data sales — the opposite of the big period apps.

For the enormous women's-health audience that wants Flo/Clue-style tracking but is uneasy about period data being sold or subpoenaed.

## Features

- **Prediction engine** — learns average cycle and period length from your history (recent-6 window, implausible values discarded), then derives next-period date, ovulation (≈14 days before next period), and the fertile window, plus your current cycle day and phase (menstrual / follicular / fertile / ovulation / luteal).
- **Today** — a cycle-day ring coloured by phase, a phase explainer, predictions list, today's quick-log card, and one-tap "period started / end period today".
- **Day logging** — flow (spotting → heavy), mood, a 12-item symptom catalogue, and a note; auto-creates/cleans the day's record.
- **Calendar** — month grid marking logged periods, predicted periods (dashed), fertile window, and ovulation, with per-day flow dots and tap-to-log; fertility overlay can be hidden.
- **Cycles** — period history with each cycle's length and a stats summary; add/edit/delete past periods with validation.
- **Insights** — average cycle/period, regularity (std-dev) with a plain-language read, a cycle-length-over-time chart vs your average, and most-logged symptoms (Swift Charts).
- **Settings** — default cycle & period length, show/hide fertility, haptics, and delete-all with confirmation; clear privacy statement.
- Onboarding (persisted, sets default cycle), empty states, sample-history loader, light/dark, Dynamic Type, VoiceOver, Reduce Motion.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Luna.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** personal team; bundle id `com.orbioom.luna`. No paid account, no keys.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM. **SwiftData** (`Period`, `DayLog`); prefs in `@AppStorage`. All data on-device — no networking code at all.
- Pure `CyclePredictor` (averages, regularity, phase classification, calendar day-kind) guarded against implausible/empty data; reusable month-grid calendar.
- Design language: **Orbioom** (glass + ink, lunar accent palette; period/fertile/ovulation colours tuned for AA contrast in both schemes).
- **Monetization:** freemium — free tracking & predictions; Pro unlocks symptom analytics, partner/cycle export, and reminders. Privacy itself is the headline selling point.
- **Why it can boom:** period tracking is one of the largest, most monetised health categories (Flo, Clue, Stardust) — and post-2022 the #1 complaint in reviews and press is data privacy. An on-device, no-account tracker with real predictions is exactly the trusted alternative millions are actively switching to.

*Predictions are estimates for awareness only — not contraception or medical advice.*

## Self-review

Re-read every file. Verified imports; `CyclePredictor` date maths and phase logic compile; the `IdentifiableDate` sheet binding, month-grid calendar, and Charts (cycle length + symptoms, `chartYScale`) type-check; `Period`/`DayLog` `@Query` and edit/validation paths are safe; only `try!` is the in-memory fallback; ≥4 feature screens (Today, Calendar, Cycles, Insights) + Onboarding + Settings; no stubs, no iOS-18 APIs. Anti-stub grep clean.
