# Pitch — Tuner, metronome & reference tones

A fast, honest musician's toolkit: a microphone tuner with real on-device pitch detection, a click-accurate metronome with tap-tempo and saved presets, and pure synthesized reference tones — with every tuning free. The clean answer to GuitarTuna and friends, which bombard the free tier with ads and lock basic tunings (even drop tunings) behind a subscription.

## What it is
- **One-line:** An ad-free tuner + metronome + reference-tone app with every tuning included.
- **Problem + audience:** Tuner apps are a 100M+-download proven utility, but the leader is criticized for ad bombardment, feature bloat, and paywalling basics like a seven-string drop tuning. Pitch serves the same enormous audience of guitarists, bassists, ukulele and string players with the core tools free and clean.

## Full feature list
- **Tuner:** AVAudioEngine mic capture → on-device pitch detection (normalized square-difference / autocorrelation with parabolic interpolation) → nearest note, cents offset, and frequency; a smoothed needle gauge that turns green in tune (±5¢); instrument/tuning picker that highlights the nearest string; clean microphone-permission and denied states (audio is never recorded).
- **Metronome:** 40–240 BPM with ±1/±5 steppers, a slider, and **tap tempo**; adjustable beats-per-bar with accent on beat 1; animated beat dots; Italian tempo marking; on-device synthesized click (no audio files); **save/load/delete presets** (SwiftData).
- **Reference tones:** tap any string of the selected tuning, or any chromatic note across octaves, to hear a click-free synthesized sine (with a touch of harmonic); honors the A4 calibration; clear "now playing" + stop.
- **Tunings manager:** built-in guitar (Standard, Drop D, DADGAD, Half-step, Open G), bass (4/5-string), ukulele, violin — plus full **CRUD for custom tunings** (name, instrument, per-string semitone editing).
- **Settings:** A4 calibration (415–466 Hz), appearance, haptics, delete custom tunings/presets, honest "no paywalled tunings, no ads" copy.
- Onboarding gated by a persisted flag; engines stop on tab-leave and scene background.

## Run steps
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Pitch.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

## Free-signing note
No paid account needed: select your personal team under Signing & Capabilities and run on a simulator or your own device. The tuner prompts for microphone access (declared in Info.plist); the metronome and reference tones work without it. (The mic tuner needs a real device — the simulator has no microphone input.)

## Tech notes
- iOS 17+, SwiftUI 5, MVVM with pure `NoteMath` (equal-temperament conversions, name parsing) and `PitchDetector` (NSDF), plus three `@Observable` audio engines: `TunerEngine` (input tap + background analysis), `ToneGenerator` (AVAudioSourceNode, ramped gain), and `Metronome` (synthesized click buffers scheduled by a dispatch timer).
- Persistence: **SwiftData** (`Tuning`, `MetronomePreset`) with built-ins seeded once; `@AppStorage` for A4 and prefs.
- Design language: **Orbioom**, slate-blue accent; green reserved for "in tune" / playing.
- **Monetization:** freemium — tuner, metronome, all tunings, and reference tones free; a one-time "Pitch Pro" (alternate temperaments, polyphonic/auto chromatic strobe, more click voices, setlist tempos) is the upsell. No ads, no paywalled tunings.
- **Why it can boom:** tuners are a proven, gigantic utility category; the leader is widely resented for ad overload, bloat, and paywalling basic tunings. A fast, clean, every-tuning-free tuner+metronome is the version musicians keep asking for.

## Self-review
Re-read every Swift file: imports verified; all SwiftUI/SwiftData/AVFoundation symbols exist in iOS 17 (`AVAudioApplication` permission API, `AVAudioSourceNode`, `AVAudioPlayerNode`); render blocks guard `mData`; no `didSet` on `@Observable` stored properties (tempo changes go through `setTempo`); `@Observable`/`@State`/`@Query`/`@AppStorage`/`modelContainer` wiring type-checks; no force-unwraps/`try!`/`fatalError` on user paths (container falls back to in-memory). Anti-stub grep clean. Dynamic Type, accessibility, Reduce Motion, light/dark, and `NSMicrophoneUsageDescription` handled. (`MagnificationGesture` is unused here; the deprecated-on-17 note applies only to Mosaic and is non-breaking.)
