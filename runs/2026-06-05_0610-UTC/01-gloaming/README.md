# Gloaming — the light of your day

A calm iOS app that shows every threshold of daylight for where you are:
astronomical / nautical / civil twilight, sunrise and sunset, the golden hours,
the blue hours, and solar noon — with a live sky band that shifts color and
moves the sun as the real sun does.

Everything is computed **on-device** with the NOAA solar algorithm. No API, no
network, no tracking. It works on an airplane.

## Why it earns a place on the home screen

Walkers, photographers, and anyone who loves the quality of late light keep
asking the same question — *when exactly is golden hour today?* Most answers
come from ad-filled websites that want your location and your attention.
Gloaming answers instantly, beautifully, and privately, and it's just as happy
telling you the sun never sets in Tromsø in June.

## What's inside

- **NOAA / Meeus solar equations** in pure Swift (`SolarCalculator.swift`) —
  Julian day, equation of time, declination, hour angle for any elevation
  angle, plus a live solar-elevation readout.
- Twilight phases at the standard −18° / −12° / −6° angles, golden hour to +6°.
- Live sky gradient + sun disk that animates with the current elevation.
- Eight built-in places spanning the latitudes (incl. an Arctic city to show
  polar day/night), or **Use current location** via CoreLocation.
- Orbioom Liquid-Glass UI: `.ultraThinMaterial` cards, mist background,
  restrained live-green "now" dot, SF Rounded + monospaced times.

## Architecture (MVVM)

```
Models/      SolarCalculator.swift   NOAA math
             SunMoment.swift         phase definitions
             Place.swift             location + timezone
ViewModels/  SkyViewModel.swift      computes moments, live elevation, day length
Views/       SkyBandView.swift       animated sky + sun
             MomentRow.swift         a single event row
ContentView.swift                    composition + place picker
Theme/       OrbioomTheme.swift      color tokens + glass modifiers
```

## Build & run

Open `ios/Gloaming.xcodeproj` in Xcode 15+ on macOS, select an iPhone
simulator, and press **Cmd+R**. iOS 17+, SwiftUI 5.

## Reference

- NOAA Global Monitoring Laboratory, *Solar Calculation Details.*
- Meeus, J. (1998). *Astronomical Algorithms*, 2nd ed. Willmann-Bell.
