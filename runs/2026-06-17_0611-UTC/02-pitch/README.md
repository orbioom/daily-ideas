# Pitch

**An instrument tuner + metronome that does the DSP on-device — no ads, one-time unlock.**
A GuitarTuna-beater built natively for iOS 17 with SwiftUI 5: accurate microphone
pitch detection, a sample-accurate metronome, a reference tone pipe, and a studio-dark
visual identity with precise gauges and monospaced numerals.

## What it is

Pitch turns your phone into a precise, calm tuning workstation. The tuner listens
through the mic and estimates the fundamental frequency with **normalized
autocorrelation + parabolic peak interpolation**, then maps it to the nearest
12-TET note and a signed cents offset. A glowing needle and big note readout make
"in tune" obvious; per-string highlighting guides you through any tuning. The
metronome synthesizes its clicks in code and schedules them sample-accurately off
a wall-clock so the tempo never drifts. A tone generator gives you a sustained
reference pitch for any note. Everything runs on-device — no network, no ads.

## Full feature list

**Tuner**
- Live microphone pitch detection (normalized autocorrelation, parabolic
  interpolation, RMS silence gate, median + EMA smoothing).
- Big note name + octave, frequency in Hz, and a −50…+50 cents gauge with a
  glowing green in-tune confirmation + sparse haptic.
- Per-string row highlight for the active tuning (nearest target by cents).
- Configurable A4 reference (415–446 Hz) and in-tune tolerance (±1–15 cents).
- Calm states: microphone-permission-denied (with a deep link to Settings),
  "Listening…" loading, no-signal empty, and audio-error recovery.

**Metronome**
- 30–300 BPM with a large monospaced readout, slider, fine steppers, and **tap
  tempo** (averages the last taps).
- Time signatures 2/4, 3/4, 4/4 (free) plus 6/8, 5/4, 7/8, 9/8, 12/8 (Pro).
- Subdivisions: quarter & eighth (free), triplet & sixteenth (Pro).
- Accent on beat 1 (distinct pitch/volume), three click timbres synthesized in code.
- Animated beat indicator with a discrete-fill fallback under Reduce Motion.
- Save / load / delete presets (SwiftData), with a free-tier preset cap.
- Practice-minutes weekly bar chart (Swift Charts) logged automatically per session.

**Tunings**
- Built-in presets: Guitar Standard/Drop D/DADGAD/Half-step Down, Bass 4 & 5
  string, Ukulele GCEA, Violin GDAE, Cello CGDA, and Chromatic.
- Select the active tuning; it drives the tuner's string highlighting.
- Custom tuning builder (Pro): name, instrument, add/remove/retune string slots.

**Tone**
- Reference pitch pipe: tap a note to play a sustained sine; tap again to stop;
  tap another to retune seamlessly.
- Quick chromatic grid per octave; free tier covers octaves 3–5, Pro the full range.
- Shows the A4 reference and exact target Hz.

**Settings** (persisted): A4 reference, in-tune tolerance, metronome click sound,
haptic-on-beat, keep-screen-awake, plus the Pro entitlement and a demo reset.

**Onboarding** gated by a persisted flag, and a **Paywall** for the one-time unlock.

## Run steps

1) `brew install xcodegen` (one-time). 2) In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3) Open `Pitch.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: set your Apple ID team in Signing & Capabilities; the bundle id is `com.orbioom.pitch`.

> The tuner needs a real microphone. The Simulator has no mic input, so for live
> tuning run on a physical device; the metronome, tone generator, tunings, and
> all UI work fully in the Simulator.

## Tech notes

- **iOS 17+ / SwiftUI 5**, `NavigationStack`, `TabView`, two-parameter `.onChange`.
- **AVFoundation DSP**: `AVAudioEngine` input tap → pure, testable `PitchDetector`
  using **normalized autocorrelation with parabolic interpolation** (guarded RMS
  gate, bounds-checked lags, zero-guarded divisions). iOS 17 mic permission via
  `AVAudioApplication.requestRecordPermission`.
- **On-device synthesis**: metronome clicks are sine + exponential-decay PCM
  buffers built in code and scheduled sample-accurately on an `AVAudioPlayerNode`
  off a wall-clock; the tone pipe runs a continuous-phase oscillator in an
  `AVAudioSourceNode`. No audio files ship with the app.
- **MVVM**: `@MainActor @Observable` engines (`TunerEngine`, `MetronomeEngine`,
  `ToneGenerator`) shared via the environment and stored with `@State`; real-time
  render/analysis state is kept off the main actor (`Sendable` value-type detector,
  a dedicated render-state box) so the audio thread never touches UI state.
- **SwiftData** for primary data: `CustomTuning`, `MetronomePreset`, `PracticeLog`
  (all registered in the schema); small prefs/flags via `@AppStorage`. **Swift
  Charts** for the practice summary.
- **Design language**: dark-studio aesthetic, indigo `#5B6CF0` accent, monospaced
  numerals for cents/BPM/Hz, glowing in-tune indicator, cohesive `PitchTheme` with
  first-class light + dark and WCAG-AA contrast.
- **Accessibility**: Dynamic Type throughout; the tuner readout exposes a spoken
  value like "A4, 3 cents sharp"; controls, beat indicator, and chart bars have
  labels/values; decorative imagery is hidden; Reduce Motion swaps the needle
  spring and beat pulse for still fallbacks; haptics are sparse and toggle-gated.
- Crash-proofing: no force-unwrap on user paths, no `try!`/`as!`/`fatalError`, no
  unchecked indices, no unguarded divisions; a safe `subscript(safe:)` helper.

**Monetization:** one-time **$4.99** Pitch Pro unlock (custom tunings, advanced
metronome subdivisions & odd meters, unlimited presets, full-range tone pipe,
themes) — core tuner, metronome, and tones stay free forever.

**Why it can boom:** the leading tuners bury accurate, simple tuning under ads and
subscriptions — Pitch ships genuinely good on-device pitch detection plus a
rock-steady metronome in one calm, ad-free app you buy once.

## Self-review

Every Swift source was re-read after writing. Verified: all imports exist;
AVFoundation/AVFAudio APIs used are iOS 17 (`AVAudioEngine`, `AVAudioPlayerNode`,
`AVAudioSourceNode`, `AVAudioPCMBuffer`, `AVAudioSession`,
`AVAudioApplication.requestRecordPermission`, `floatChannelData`); a single
property-wrapper pattern (`@MainActor @Observable` + `@State`/environment) is used
app-wide with no `ObservableObject`/`@StateObject` mixing; `NavigationStack` only;
two-parameter `.onChange`; every `@Model` registered in the `Schema`. The DSP
guards its RMS gate, lag bounds, array indices, and every division. An anti-stub
grep (`TODO`/`FIXME`/`XXX`/`placeholder`/`fatalError`/`try!`/`as!`/`coming soon`/
`not implemented`/`unimplemented`) is **clean**, and a force-unwrap grep over the
sources is clean. I added the **`NSMicrophoneUsageDescription`** key to
`ios/Pitch/Info.plist` (the only change to that file) so the mic-permission prompt
shows a clear reason.
