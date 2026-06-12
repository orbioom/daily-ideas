# Mihrab — Private Prayer Times, Qibla & Tracker

**What it is:** Prayer times, qibla compass, monthly timetable, and a five-prayer tracker for the world's ~2 billion Muslims — computed entirely on-device with **no location permission, no account, and no ads**. Built as the trustworthy answer to Muslim Pro, whose granular location data ended up with a broker tied to the US military.

## Full feature list

- **On-device astronomical engine** — NOAA-style solar position (declination + equation of time), five calculation methods (Muslim World League, ISNA, Egyptian, Umm al-Qura with 90-min Isha, Karachi), Standard/Hanafi Asr shadow factors, sunrise/sunset at 0.833°, middle-of-the-night high-latitude fallback.
- **Built-in 97-city gazetteer** with IANA time zones (DST-correct for any date) — *that's the privacy trick: pick your city, never grant location.*
- **Today tab** — live countdown to the next prayer (after Isha it rolls to tomorrow's Fajr), all six times with the next one highlighted, Arabic names, day-by-day navigation, and the Hijri date (Umm al-Qura calendar).
- **Qibla tab** — live compass dial (CoreMotion magnetometer, no permission prompt) with a fixed gold qibla marker, alignment detection (turns green + success haptic), great-circle bearing and distance to the Kaaba, graceful sensor-unavailable fallback with manual-orientation guidance, VoiceOver "turn N degrees left/right" output.
- **Tracker tab** — tap to cycle each of the five prayers (prayed → late → clear), 7-day strip with completion dots, all-five streak counter, 30-day Swift Charts consistency chart.
- **Month tab** — full monthly timetable for any month (built off-main with a loading state), today highlighted, per-row VoiceOver labels.
- **Local prayer notifications** — optional; next 2 days × 5 prayers scheduled on-device in the city's timezone, rescheduled on every foreground; permission-denied handled with a calm alert.
- **Settings** — city (searchable picker), method, Asr juristic, 24-hour clock, notifications, haptics.
- **Onboarding** (welcome + city/method setup, persisted flag), empty/error states (month build failure, compass unavailable, search no-results), full Dynamic Type & VoiceOver, Reduce Motion (no compass spring), light + dark first-class.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Mihrab.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R. (The compass needs a physical device; everything else works in the simulator.)

*Free signing:* personal team in Signing & Capabilities; suffix the bundle id if needed.

## Tech notes

- iOS 17+, SwiftUI 5. Pure functional `PrayerEngine` (port of the standard praytimes algorithm, ±1–2 min of reference timetables) + `@Observable` CompassService over CoreMotion `xMagneticNorthZVertical`.
- SwiftData for prayer logs; `@AppStorage` for city/method/display prefs; `UNUserNotificationCenter` for local alerts; Hijri via `Calendar(identifier: .islamicUmmAlQura)`.
- Design language: "night sky over a courtyard" — deep indigo gradients, brass gold `#C9A84C`, serif display type, Arabic secondary labels.
- **Monetization:** free core; one-time "Mihrab Endowment" unlock (extra themes, widgets later, lifetime) — the audience demonstrably pays (Muslim Pro premium) and many would switch on privacy alone.
- **Why it can boom:** Muslim Pro has 150M+ downloads and a documented data-selling scandal; privacy-first alternatives are actively sought in this huge, devoted market — and "no location permission at all" is a provable, marketable guarantee no major incumbent offers.

## Self-review

Re-read every Swift file: solar math symbol-checked against the praytimes reference (julian day, declination/EqT, sun-angle hour, Asr arccot identity, qibla atan2 bearing); all optionals guarded (no `!`, no `try!` on user paths); `UNCalendarNotificationTrigger` components carry the city timezone; `Task.detached` values are value types; `@Query`/`modelContainer` wired for `PrayerLog`; iOS 17 APIs only; Charts use `Identifiable` structs. Anti-stub grep clean. `project.yml` references the real `Mihrab` folder, `Info.plist` includes `NSMotionUsageDescription` and launch screen.
