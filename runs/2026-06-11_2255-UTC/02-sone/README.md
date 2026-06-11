# Sone — sound level meter & hearing-safety dosimeter

**What it is.** A precision-instrument-styled sound meter for concert-goers, parents, commuters, musicians and shop workers. The category leader (Decibel X) charges **$4.99/month** for fixed functionality behind a hostile paywall; Sone is the fair version: live meter, NIOSH dose tracking, saved measurements with full traces — all on device, nothing recorded.

## Features

- **Live meter** — AVAudioEngine mic tap → RMS → smoothed dB estimate at ~10 Hz with a 96 pt animated readout, color-coded classification ladder (very quiet → painful) with plain-language advice, linear gauge, 60-second live sparkline (Swift Charts) with the 85 dB limit line, running MIN / AVG (energy-averaged Leq) / MAX tiles with reset, and a live "safe exposure at this level" readout (NIOSH 85 dB/8 h, 3 dB exchange rate).
- **Measurements** — explicit start/stop capture with live elapsed time and accumulating daily-dose percentage; save sheet (label + summary, discard option) with success toast; sessions persist a downsampled level trace.
- **History** — summary header (count, loudest peak), measurement list (avg/peak/dose per row, swipe to delete), and a **detail screen** with the full area-chart trace, 85 dB rule line, stat table, and classification verdict.
- **Guide** — interactive exposure calculator (level × hours → % daily dose + safe maximum, with over-limit warning), 15-step everyday-sounds ladder, honest "how Sone measures" explainer.
- **Settings** — calibration offset (±20 dB with reset), keep-screen-awake, haptics; privacy statement.
- Permission flow handled as first-class states: requesting (loading), denied (link to Settings), failed (retry), running. Meter pauses in background, resumes on activation. Onboarding gated by persisted flag; Dynamic Type; Reduce Motion respected on the numeric readout; light & dark.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Sone.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R. (Simulator uses the Mac microphone.)

Free Apple ID signing works for device installs.

## Tech notes

- iOS 17+, SwiftUI 5; `@Observable AudioMeter` (AVAudioEngine input tap, energy-averaged Leq, NIOSH dose accumulation at 5 Hz), pure `NoiseMath` engine, SwiftData for `MeasureSession` (incl. `[Double]` trace attribute), `@AppStorage` prefs; `AVAudioApplication` permission API (iOS 17).
- Design language: "precision instrument" — cyan on graphite, monospaced numerals, hairline gauges.
- **Monetization:** one-time Pro unlock (history + dosimeter) for people who monitor noise for work/health — against Decibel X's $60/yr.
- **Why it can boom:** Decibel X's own reviews complain about subscription pricing and trial traps; noise-dose anxiety (concerts, kids' ear protection, workplace) is mainstream and growing.

## Self-review

Re-read every Swift file: AVAudioEngine/AVAudioSession/AVAudioApplication API spelled per iOS 17 SDK, tap thread → main-actor hop via DispatchQueue, no force-unwraps on user paths, SwiftData macros and `@Query` wiring checked, charts compile against Swift Charts API, anti-stub grep clean.
