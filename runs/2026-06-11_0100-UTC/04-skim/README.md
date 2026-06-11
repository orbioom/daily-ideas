# Skim

**RSVP speed reader for iOS**

## Problem & Audience

The average person reads 200–250 WPM. RSVP (Rapid Serial Visual Presentation) can double that by eliminating saccadic eye movement. Skim brings this to iOS with a clean, distraction-free interface. Audience: students, professionals, and voracious readers aged 18–45.

## Features

- **RSVP reader** — Words flash one at a time (1–3 word chunks) at user-defined WPM
- **Speed range** 100–1000 WPM with a live slider
- **Focus guide** — top and bottom lines visually anchor the reading position
- **4 color themes** — White, Cream, Dark, Night with `.preferredColorScheme` support
- **Font size control** — 20–60pt stepper
- **Library** — Add articles by pasting text or using the bundled sample article
- **Progress tracking** — word index and fraction saved per article via SwiftData
- **Reading history** — sessions log WPM, duration, completion flag
- **Stats** — words read total, average WPM over time, sessions chart (Swift Charts)
- **Settings** — chunk size (1/2/3 words), theme, font size default, haptics

## Run Steps

```bash
cd runs/2026-06-11_0100-UTC/04-skim/ios
xcodegen generate
open Skim.xcodeproj
```

## Tech Notes

- RSVP engine: recursive `DispatchQueue.main.asyncAfter` at `60.0 / wpm` second intervals
- `ReaderBackground` enum encapsulates theme colors and `isDark` flag
- Session saved on pause and `onDisappear` to handle backgrounding correctly
- `AddArticleView` includes a full ~600-word sample article for immediate demo

## Monetization

**Free**: 3 article slots + max 300 WPM → **Skim Pro** ($2.99/month): unlimited articles, up to 1000 WPM, export reading stats. High LTV from daily power users.

## Why It Can Hit

Speed reading is perennial. The App Store has several outdated competitors with poor SwiftUI implementations. A polished, fast native app with persistent library will win on ratings.

## Self-Review Attestation

- [x] RSVP engine fully implemented (not mocked)
- [x] 4 color themes with system color scheme integration
- [x] Library, reader, stats, settings screens
- [x] SwiftData session persistence
- [x] XcodeGen project.yml, iOS 17
