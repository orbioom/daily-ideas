# Hark

## What it is

**Hark** is a native iOS hearing self-screening and audiogram tracker. It plays real, on-device pure tones at standard audiometric frequencies, finds the quietest tones you can hear in each ear, and plots them on an audiogram you can track over time.

**The problem:** Hearing loss is common, gradual, and easy to ignore. Clinics gate-keep audiograms behind appointments, and most consumer hearing apps push subscriptions. People want a private, low-friction way to spot a change early — before it becomes a problem.

**Audience:** Anyone curious about their hearing — people who work or play in loud environments, those who suspect a slow decline, tinnitus sufferers, and folks who just want a baseline they can re-check now and then.

> **Not a medical device.** Hark is an *uncalibrated screening tool*. It does not know your exact headphone output or room conditions, and it **cannot diagnose hearing loss**. Its job is to track *relative changes over time* and nudge you to see a professional when something looks off. For sudden hearing loss, one-sided symptoms, pain, drainage, dizziness, or ringing that starts abruptly, see a professional promptly.

## Features

- **Home** — last-result summary card with a mini audiogram, PTA + plain-language classification per ear, headphone/quiet-room setup checklist, a big *Start Hearing Check* button, and the always-present screening disclaimer.
- **Test runner** — full-screen, calm screening that plays real synthesized tones. Shows current ear + frequency, a large *I hear a tone* button, auto-advances on the no-response (timeout) path, supports pause/quit, and shows reassuring progress. Slightly randomized inter-stimulus timing defeats rhythm-gaming.
- **Results / Audiogram** — a Swift Charts audiogram with a log-spaced frequency x-axis, an inverted dB y-axis (softer = higher, per convention), a line + points per ear, normal-range band shading, PTA, left/right asymmetry, and plain-language classification with caveats.
- **History** — list of past tests plus a PTA-over-time trend chart per ear with written trend summaries.
- **Tools**
  - *High-frequency limit finder* — sweep a tone upward to find the highest pitch you can still hear.
  - *Tinnitus tone matcher* — dial a tone to match your ringing, add a note, and save the frequency to track shifts over time.
- **Learn** — four authored hearing-health reads (how a pure-tone screening works, why headphones matter, screening vs. diagnosis, protecting your hearing).
- **Onboarding** — four-page intro explaining value and conditions, gated by `hasOnboarded`.
- **Settings** — Appearance, Haptics, test ear order, tone duration, response timeout, max test level, Pro/restore, erase-all-data, and an About section.
- **Accessibility** — full VoiceOver labels (including the *I hear a tone* button and charts described as data), Dynamic Type throughout, AA-tuned contrast in both light and dark, and Reduce-Motion-first visuals.

### Tone synthesis approach

Tones are generated **live, sample-by-sample** — there are no audio files. `AudioEngine` (`Engine/AudioEngine.swift`) wires an `AVAudioSourceNode` into an `AVAudioEngine` and renders a sine wave per buffer: it advances a phase accumulator at `2π·f/sampleRate`, applies a smoothed gain to avoid clicks, and uses constant-power panning to route the tone to the left or right channel for the ear under test. A relative dB-HL-ish level is mapped to linear gain as `gain = clamp(pow(10, (level − maxLevel)/20), 0...1)`. All audio session/engine setup is wrapped in `do/catch` and surfaces a **calm error state** (with a *Try again*) instead of ever crashing; the engine is torn down cleanly on dismiss.

### Threshold procedure approach

`ThresholdProcedure` (`Engine/ThresholdProcedure.swift`) is a **pure state machine** implementing a modified **Hughson–Westlake** up-down search per ear at `[250, 500, 1000, 2000, 4000, 8000]` Hz. Present a tone: a response (*I hear a tone*) lowers the level **10 dB**; a timeout (no response) raises it **5 dB**. A threshold is recorded as the lowest level with **responses on ≥2 of 3 ascending presentations**. Inter-stimulus delays are jittered via an **injected RNG** (`RandomProvider`) so the cadence can't be gamed; the same protocol allows deterministic seeding. Floor/ceiling and a presentation cap make it terminate safely. The `TestRunnerModel` view-model owns timing and the `AudioEngine`; the engine itself touches no UI or audio.

### Analysis approach

`AnalysisEngine` + `HearingClassification` (pure) compute PTA (average of 500/1k/2k/4k), classify into relative bands (normal / mild / moderate / moderately-severe / severe), report left/right asymmetry, and build a PTA-over-time trend.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Hark.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

> Tones play through the simulator, but for an honest screening run on a real device with headphones in a quiet room.

### Free signing

The project uses no paid capabilities. Select your personal team under *Signing & Capabilities* (automatic signing) to run on a device for free; the simulator needs no signing.

## Tech notes

- **iOS 17+**, **SwiftUI**, **SwiftData** (`@Model` `HearingTest` + child `Threshold`, and `TinnitusMatch`, all registered in the app `Schema`), **Swift Charts** for the audiogram and trend, and **AVFoundation** for real tone synthesis.
- **Design language:** calm, clinical-but-warm indigo (`#5B6CF0`, matching `AccentColor`), soft surfaces, generous spacing, rounded type, conventional red-right / blue-left ear coloring. Reduce-Motion-first — no spinny visuals; the only animation is a gentle, suppressible pulse on the response button.
- **Persistence:** SwiftData survives relaunch; small prefs/flags in `@AppStorage`. First launch seeds four realistic past tests (with a gentle high-frequency drift to make the trend tell a story) and a saved tinnitus match, guarded to run once.
- **Monetization:** one-time **Hark Pro** unlock at **$3.99** (simulated via `@AppStorage`, StoreKit-ready) — gates full history/trends, both Tools, audiogram export (CSV/text via `ShareLink`), and per-ear frequency detail. The free core (run a screening + see the current audiogram) is fully usable.
- **Why it can boom:** hearing health is a large, aging, underserved market; clinics gate-keep audiograms and apps like Mimi push subscriptions — Hark is a private, one-time self-screening + trend tracker that lives entirely on the user's device.

## Self-review

I re-read every Swift file by hand and verified:

- **Imports** are present and minimal per file (`SwiftUI`, `SwiftData`, `Charts`, `Foundation`, `AVFoundation`, `UIKit` only where used).
- **iOS 17 only** — no iOS 18 SwiftUI/SwiftData APIs; every `.onChange(of:)` uses the two-parameter `{ oldValue, newValue in }` form; `NavigationStack` + `navigationDestination` throughout (no `NavigationView`); no `@Previewable`. `navigationDestination(item:)` is fed a `HearingTest` (a `@Model`, which conforms to `Hashable`/`Identifiable` via `PersistentModel`).
- **Crash-proofing** — no `try!`, `as!`, or force-unwraps on user paths (verified by search); the only `fatalError` is the documented-unreachable in-memory `ModelContainer` fallback, copied verbatim. Audio setup is `do/catch` with a calm error state. No unchecked array indexing (clamped) and no unguarded division (PTA guards for empty input; gain clamps `maxLevel`).
- **No banned strings** — searched for and found zero `TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`stub`/`unimplemented`.
- **Schema** — `HearingTest`, `Threshold`, and `TinnitusMatch` are all listed in `Schema([...])` in `HarkApp.swift`.
- **Property-wrapper ownership** — `AppSettings` is `ObservableObject` injected via `@StateObject`/`@EnvironmentObject`; view-models (`TestRunnerModel`) are `@Observable` held in `@State`; the two patterns are never mixed on one object.
- **State coverage** — empty states (Home/History/Tools), loading states (test "Preparing tones…", async seeding), calm recoverable error states (audio failure, save failure), and success states (toasts + gated haptics) are all present.
- **Accessibility** — Dynamic Type via scalable rounded fonts; `.accessibilityLabel/Value/Hint` on controls and both charts (described as data); decorative images `.accessibilityHidden(true)`; the screening is operable under VoiceOver; AA-tuned dynamic colors for light and dark.
- **Charts** — the audiogram inverts the dB axis by plotting negated values and re-negating the axis labels (no reliance on any unavailable reversed-scale API), with a single `chartYScale`/`chartYAxis`; the trend chart is per-ear.
- **Balanced braces/parens** and one-type-per-concept file organization confirmed across all 33 Swift files.

**Attestation:** To the best of a careful by-hand review (there is no Xcode in this environment), the sources are internally consistent, use only iOS 17 SDK APIs, satisfy the stated conventions and Definition of Done, and contain no stubs, dead buttons, or half-screens. Every feature described above is implemented and wired.
