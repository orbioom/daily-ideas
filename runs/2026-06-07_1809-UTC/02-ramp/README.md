# Ramp

A native iOS 17 SwiftUI cycling **training-load tracker** for the Orbioom studio.
Ramp turns every ride into a Training Stress Score (TSS) and tracks your
**Fitness (CTL)**, **Fatigue (ATL)** and **Form (TSB)** over time — the
TrainingPeaks-style Performance Management Chart — entirely on-device. No
account, no cloud, no Strava.

Built for data-driven road, gravel and indoor cyclists and triathletes. Ramp
also manages your FTP history and computes Coggan power zones in watts and W/kg.

## What it does

- **Today** — a dashboard of today's Fitness, Fatigue and Form with a form-status
  label, the 7-day ramp rate, a 90-day mini Performance Management Chart, your
  five most recent rides, and a focal "Log ride" action.
- **Rides** — the full ride log grouped by week (newest first) with weekly TSS
  totals, search, full create/edit/delete, and swipe-to-delete. The ride form
  supports both **power mode** (enter normalized power; see the snapshot FTP,
  intensity factor and live TSS) and **manual mode** (enter TSS directly).
- **Trends** — the full Performance Management Chart over a selectable 42 / 90 /
  180-day window, a weekly-TSS bar chart for the last 12 weeks, and a
  time-in-zone distribution. Every chart carries an accessibility summary.
- **FTP** — your current FTP and W/kg, full FTP-history CRUD, an FTP-over-time
  line chart, the seven Coggan power zones in watts, and a standalone zone
  calculator for any FTP value.
- **Settings** — appearance (system / light / dark), haptics, rider weight with
  a kg/lb preference, fallback FTP, live data counts, erase-all, and an about
  section with a "replay intro" action.

## The engine (`Utilities/LoadEngine.swift`)

Pure functions, no SwiftData or SwiftUI state, so the math is testable and never
crashes on edge cases (zero FTP, no rides, zero weight all guarded).

- **TSS from power:** `IF = NP / FTP` (FTP guarded), `TSS = (min/60) · IF² · 100`.
  Manual rides use the entered TSS directly.
- **FTP on a date:** the latest recorded `FTPEntry` with `date ≤ that date`,
  else the user's fallback FTP.
- **Daily series:** TSS summed per day from the earliest ride (or today−90)
  through today; rest days contribute 0.
- **CTL / ATL / TSB:** exponential moving averages with 42-day and 7-day time
  constants; TSB (form) is yesterday's `CTL − ATL`. Both EMAs start at 0.
- **Ramp rate:** `CTL(today) − CTL(7 days ago)`.
- **Form status:** maps TSB onto five named bands with brand colors.
- **Power zones:** Coggan 7-zone model from FTP, returning rounded watt ranges;
  `W/kg = FTP / weight` (weight guarded).
- **Weekly TSS** and **time-in-zone** aggregations for the Trends charts.

Heavy series/aggregation work runs off the main actor (`Task.detached`) with a
calm loading state, so the UI stays smooth at 50+ rides.

## Data & persistence

- **SwiftData** models: `Ride` and `FTPEntry` (`@Model final class`, every stored
  property defaulted, enums stored as `String` rawValue with computed accessors).
- **`@AppStorage`** holds preferences only: `ramp.hasOnboarded`,
  `ramp.appearance`, `ramp.hapticsEnabled`, `ramp.weightKg`,
  `ramp.fallbackFTP`, `ramp.useImperialWeight`.
- First launch seeds a realistic sample season — improving FTP (248 → 270 W) and
  60+ rides over ~95 days with build weeks, a recovery week, races and rest days
  — so the charts come alive immediately.

## Design & accessibility

- Orbioom brand tokens only; light and dark are both first-class.
- Dynamic Type, accessibility labels/values on controls and chart summaries,
  decorative images hidden, and motion that respects Reduce Motion.
- Sparse, meaningful haptics gated by the Settings toggle.

## Project layout

```
ios/Ramp/
  RampApp.swift                 @main, ModelContainer
  Models/Ride.swift, FTPEntry.swift
  Utilities/LoadEngine.swift, SampleData.swift, Format.swift, Haptics.swift
  Theme/Brand.swift
  Views/
    RootView.swift              onboarding gate + TabView + global prefs
    Onboarding/OnboardingView.swift
    Today/TodayView.swift
    Rides/RidesView.swift, RideEditView.swift
    Trends/TrendsView.swift
    FTP/FTPView.swift, FTPEditView.swift
    Settings/SettingsView.swift
    Components/Components.swift, Charts.swift
```

Generate the Xcode project with `xcodegen` from `ios/project.yml`, then build for
an iOS 17 simulator or device.
