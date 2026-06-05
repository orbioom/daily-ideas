# Meridian — find the hour

A calm iOS app for scheduling across time zones. Add the people or cities in a
meeting and Meridian shows each person's local day as a 24-hour band, shades
everyone's working hours in live green, and surfaces the **overlapping hours**
where a call is humane for all of them.

No accounts, no calendar permissions, no network. State is saved locally.

## Why it earns weekly opens

Anyone working across continents runs the same fragile mental arithmetic —
"if it's 4pm here, that's… 7am there, too early?" Meridian replaces the guessing
with a glance: a green consensus strip tells you instantly which hours work, and
tapping any cell prints everyone's clock for that moment. It correctly handles
half-hour zones (India), DST (via `secondsFromGMT(for:)`), and the case where
**no** humane overlap exists — then it tells you so.

## What's inside

- 24-column UTC grid mapped to each participant's local hours
- Per-person working-hours shading + adjustable global work window
- Consensus overlap strip and "best start" suggestion
- Half-hour & DST-correct offsets; offset labels like `UTC+5:30`
- 16-city catalog with search; add/remove participants; persisted via Codable
- Orbioom Liquid-Glass UI, mist background, restrained green

## Architecture (MVVM)

```
Models/      Participant.swift        person + IANA timezone, DST-aware offset
             (TimeZoneCatalog)        curated city list
ViewModels/  MeetingViewModel.swift   grid math, overlap, persistence
Views/       ParticipantRow.swift     a person's 24-hour band
             AddParticipantSheet.swift searchable city picker
ContentView.swift                     composition + work-hours controls
Theme/       OrbioomTheme.swift       tokens + glass
```

## Build & run

Open `ios/Meridian.xcodeproj` in Xcode 15+ on macOS, choose an iPhone
simulator, **Cmd+R**. iOS 17+, SwiftUI 5.
