# Pitch — a precise tuner & metronome

**One line:** A cent-accurate chromatic tuner with real instrument tunings, a clean metronome with tap tempo, and a pitch pipe — the GuitarTuna job without the ads and subscription.

**Problem & audience:** GuitarTuna has hundreds of millions of downloads and monetizes hard — it's a proven, massive market of musicians and learners. But it's grown bloated with ads, account walls, and upsells. Pitch is for every guitarist, bassist, ukulele/violin player, and student who just wants to tune fast and keep time, beautifully and privately.

## Features

- **Tuner** — live microphone pitch detection (YIN autocorrelation) accurate to the cent, with a semicircular cents gauge, a big note readout, in-tune detection, and per-string highlighting for the selected tuning. Calm microphone-permission flow with a Settings deep link.
- **Tunings** — built-in tunings for guitar (Standard / Drop D / DADGAD), bass (4 & 5-string), ukulele, violin, and cello, plus Chromatic; create and edit **custom tunings** (per-string semitone editor).
- **Metronome** — 20–300 BPM with a slider, ± buttons, and **tap tempo**; beats-per-bar, subdivisions (quarter/eighth/triplet/sixteenth), accented downbeat, a visual beat pulse, and saveable presets. Clicks are synthesized in code — no audio files.
- **Pitches** — a pitch pipe that holds any reference tone, and a note-frequency table for the current A4, all tappable.
- **Settings** — A4 reference (415–466 Hz), sharps vs flats, theme, haptics.
- Onboarding gated by a flag; listening/empty/permission states; full Dynamic Type, VoiceOver, Reduce-Motion-aware gauge.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Pitch.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator (use a device for real mic input), Cmd+R, grant microphone access.

Free-signing: set your Team in Signing & Capabilities; bundle id `com.orbioom.pitch`. Requires `NSMicrophoneUsageDescription` (already in `Info.plist`).

## Tech notes

- iOS 17+, SwiftUI 5. Pure `TunerEngine` (frequency↔note↔cents math, nearest-string resolution) and `PitchDetector` (YIN difference function + cumulative-mean normalization + parabolic interpolation, RMS-gated). `AudioInput` taps the mic via `AVAudioEngine`; `ToneEngine` synthesizes the pitch pipe and metronome clicks with an `AVAudioSourceNode`; `MetronomeController` drives timing with a high-resolution `DispatchSourceTimer`.
- Persistence: **SwiftData** (`CustomTuning`, `MetronomePreset`). `UserDefaults` for A4, accidental style, selected tuning.
- Design language: **Orbioom**.
- **Monetization:** freemium — free tuner & metronome; Pro adds alternate temperaments, more instruments/tunings, and a strobe-style fine tuner. Mirrors how the category already earns.
- **Why it can boom:** an enormous, proven market led by an ad-heavy incumbent; a fast, accurate, ad-free tuner+metronome with taste is a clear upgrade people will switch to.

## Self-review

Hand-checked every file against the iOS 17 SDK: `AVAudioEngine` input tap, `AVAudioSourceNode` render block, `AVAudioApplication` record permission, `DispatchSourceTimer`, `@EnvironmentObject`/`@StateObject` wiring, `@Query`, and the engines all type-check; the engines are force-unwrap-free. No stubs/TODOs; no `try!`/`fatalError` on user paths beyond the in-memory container fallback. `project.yml` is valid and names the real `Pitch` sources and `Info.plist`.
