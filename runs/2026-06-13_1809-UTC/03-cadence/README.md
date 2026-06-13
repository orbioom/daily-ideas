# Cadence — medication & supplement reminder

Never miss a dose, never run out. Cadence lays out exactly what to take and when, counts your supply down with every dose, and sends quiet on-device reminders. No account, no cloud.

**The problem & audience.** The huge population on daily prescriptions, vitamins and supplements — plus caregivers. Medisafe proves the market (tens of millions of users) but is ad-laden and pushes a subscription; people want a calm, private, beautifully simple pill reminder.

## Features
- **Today** — every due dose grouped by time with one-tap take/skip/undo, an adherence ring, a smart greeting and "next up"; an as-needed (PRN) section with per-day counts.
- **Medications** — full CRUD with 8 forms, identity colors, strengths, notes; schedules (every day / specific weekdays / as needed), multiple times per day, doses-per-time; pause/resume.
- **Schedule engine** — generates daily occurrences from schedules + logs, matches taken/skipped/missed, and computes streaks and 7-/30-day adherence.
- **History** — current streak, 7-/30-day adherence, a 14-day adherence **Swift Chart**, and a recent-dose log.
- **Refills** — supply tracked down with every dose, days-of-supply estimates, low-supply warnings and a "mark refilled" sheet (add or set total).
- **Local reminders** — optional `UNUserNotificationCenter` calendar reminders at each dose time, rescheduled on every change (capped to stay within iOS limits).
- Onboarding (persisted, requests notifications), Settings with reminders, default refill threshold and haptics, light + dark, Dynamic Type, VoiceOver, Reduce Motion, opt-out haptics, a designed capsule + clock icon and launch screen.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Cadence.xcodeproj` in Xcode 15+, iOS 17+ simulator, Cmd+R. (Allow notifications when prompted to see reminders.)

**Free-signing:** personal Team in Signing & Capabilities — no paid account needed.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM with a pure `ScheduleEngine` (occurrences, adherence, streaks) and a `NotificationScheduler`.
- Persistence: **SwiftData** (`Medication`, `DoseLog`); `UserDefaults` for reminders/threshold/haptics/onboarding.
- Design language: calm clinical — soft mint paper, teal, healthy greens; per-med color identity.
- **Monetization:** free for up to 5 medications; one-time **Cadence Pro ($6.99)** for unlimited meds, export adherence reports and more colors. Who pays: people managing multiple medications and caregivers.
- **Why it can boom:** medication adherence is a massive, proven health category (Medisafe et al.) where the incumbents lean on ads and subscriptions — a private, on-device, one-time reminder with real refill tracking is broadly wanted, especially by an aging, supplement-buying audience.

## Self-review
Audited file-by-file: anti-stub grep clean; balanced delimiters; only the standard in-memory `ModelContainer` `try!`, no `fatalError`, no force-unwraps on user paths; imports (SwiftUI/SwiftData/Charts/Combine/UserNotifications) present; Theme tokens defined; async notification calls use `await` correctly; weekday/bitmask and time math reviewed.
