# Tonic

A calm, beautiful ear-training trainer for iOS — the modern answer to Functional
Ear Trainer, Tenuto, and EarMaster. Tonic synthesizes every tone on-device (no
audio files, no downloads), plays intervals, chords, and scales, and you identify
them by ear. Configurable drills, adaptive practice that revisits your weak spots,
and per-item mastery tracking with charts. Built for the Orbioom studio.

## Features

- **On-device tone synthesis** — sine or soft triangle waveforms rendered into PCM
  buffers with click-free attack/release envelopes via AVAudioEngine. No bundled audio.
- **Three drill families** — intervals (unison → octave), chord qualities
  (triads + sevenths), and scales (major, minor, modes, pentatonic, harmonic minor).
- **Configurable drills** — choose which items are in play, the direction
  (ascending / descending / harmonic), and the root (fixed C or random). Built-in
  drills plus user-created custom drills, with validation (at least one item enabled).
- **Adaptive practice** — question selection is weighted toward items you're weak on
  or haven't seen recently; brand-new items are prioritized.
- **Practice loop** — big Play / Replay button, answer grid, immediate correct /
  incorrect feedback with the right answer revealed, running session score, Next, and
  End (which saves a session and updates per-item stats). Loading state while a tone
  plays; calm recoverable error if audio can't start.
- **Progress dashboard** — overall accuracy, current streak, per-item mastery bars,
  and Swift Charts for accuracy over time and sessions per week, plus recent history.
- **Settings** — persisted prefs wired to behavior: volume, note length, waveform,
  default root mode, interface haptics; replay onboarding; delete-all-data (confirmed).
- **Polish** — onboarding gate, empty states, success/error states, Dynamic Type,
  full VoiceOver labels/hints/values, AA contrast, Reduce Motion gating, sparse gated
  haptics, light + dark via Orbioom brand tokens, lazy lists with stable IDs.

## Run

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` if present).
3. Open `Tonic.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

**Free signing:** select the Tonic target → Signing & Capabilities → set your personal
team. The bundle id is `com.orbioom.tonic`; change the prefix if it collides. No paid
account is needed to run on a simulator or a personal device.

## Tech notes

- iOS 17+, SwiftUI, MVVM-ish view models with `@State`/`@Observable` patterns.
- **SwiftData** for persistence (`Drill`, `DrillSession`, `ItemStat`), seeded once
  on first launch so charts and lists are never empty.
- **AVAudioEngine** on-device tone synthesis: a shared `ToneSynth` renders sine /
  soft-triangle PCM buffers with enveloped notes and schedules them on a player node
  through the `.playback` session. Degrades to a calm no-op (never crashes) if audio
  is unavailable; no force-unwraps on any audio API.
- **Swift Charts** for accuracy-over-time (line) and sessions-per-week (bar).
- **Orbioom design system** (`Brand`): color tokens that resolve per color scheme,
  glass surfaces, ink buttons, motion curves — light and dark are both first-class.

## Monetization

Free core: the interval drills and basic progress. **Tonic Pro** (subscription or a
one-time unlock) opens all chord and scale drills, custom drill creation beyond a small
free allotment, and advanced progress analytics (per-item mastery, weekly trends).
Musicians have a long, proven willingness to pay for practice tools.

## Why it can boom

Every music student — instrumentalists, vocalists, producers, theory classes — needs
ear training, and the proven incumbents (Functional Ear Trainer, Tenuto, EarMaster)
are dated and clunky. Tonic is beautiful, adaptive, and synthesizes its audio with no
downloads, so it installs tiny and works offline forever. A calm, modern UI plus
genuine pedagogy (adaptive weak-spot practice, mastery tracking) is a clear wedge into
a large, paying audience.

## Self-review attestation

Every Swift source was re-read after writing. Verified: AVFoundation imports and
correct AVAudioEngine / AVAudioPlayerNode / AVAudioPCMBuffer / AVAudioFormat usage
(`standardFormatWithSampleRate`, `frameCapacity`, `frameLength`, `floatChannelData`)
with `guard let` everywhere and no force-unwraps; `scheduleBuffer(_:at:options:completionHandler:)`
used correctly; AVAudioSession category set inside `do/catch`; envelope applied to avoid
clicks; chord summation gain-scaled to avoid clipping. SwiftData wiring type-checks
(`[String]` property, `@Attribute(.unique)`, `#Predicate`). Accuracy computations guard
divide-by-zero. The only `fatalError` is the in-memory `ModelContainer` fallback, exactly
mirroring the reference app. Anti-stub grep (`TODO|FIXME|XXX|placeholder|lorem|coming
soon|not implemented|// stub`) returns zero matches. No post-iOS-17 APIs used.
