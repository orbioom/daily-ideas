# Hush

**A sleep-sounds mixer that makes its own sound.** Stack rain over brown noise, add a slow ocean swell, dial each layer to taste, and drift off under a timer that *fades* to silence instead of cutting out. Every sound is generated on your device — no downloads, no streaming, no account, and no $60/yr paywall hiding the free sounds.

The problem: white-noise and sleep-sound apps are a top-grossing category, but their reviews are full of the same complaints — steep recurring subscriptions ($40–60/yr), free vs. paid sounds jumbled together, ads even after paying, and apps that overheat the phone streaming audio all night. Hush answers every one of those.

## What it is
- **Audience:** anyone who sleeps, focuses, or relaxes to ambient sound — light sleepers, parents, students, office workers, the noise-sensitive.
- **Core job:** blend looping ambient layers into the exact texture you want, save your blends, and fall asleep to a gentle fade-out timer.

## Features
- **Live mixer** — eight on-device sounds (white, pink, brown noise; rain, ocean, wind, fan, drone) each with an independent volume fader and a global play/pause. A soft breathing aura while playing.
- **Real synthesis, zero files** — coloured noise via standard filters (Paul Kellet's pink filter, a leaky-integrator brown), textured sounds via LFO-modulated noise, all rendered into gapless, crossfade-looped PCM buffers and mixed through one `AVAudioEngine`.
- **Saved mixes** — four curated starting blends (Deep rest, Rainy night, By the sea, Focus haze) plus save/recall/delete of your own; one tap to load a blend and play.
- **Sleep timer that fades** — presets (15–120 min) or a custom length; over the final seconds Hush ramps the master volume to silence so nothing jolts you awake. A countdown ring shows the fade.
- **Background audio** — keeps playing with the screen locked (`UIBackgroundModes: audio`).
- **Sounds library** — a reference screen describing each sound and what it's good for; tap to audition any layer.
- **Settings** — master volume, default layer volume, fade-out length, interface haptics, and delete-my-mixes.
- Onboarding (persisted flag), empty/success/guard states, light + dark, Dynamic Type, VoiceOver labels + values on every fader, Reduce Motion support.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Hush.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**. (Audio is best heard on a device or with the simulator's audio enabled.)

**Free signing:** no paid account needed — select your personal team in *Signing & Capabilities* and run. No API keys; nothing leaves the device.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. Saved mixes in **SwiftData** (`Mix`, `MixLayer`); prefs in `@AppStorage`.
- Audio: `NoiseFactory` generates seamless loop buffers; `SoundMixer` runs one `AVAudioEngine` with a looping `AVAudioPlayerNode` per active layer; `MixerEngine` (`@Observable @MainActor`) is the single source of truth for live state and the date-based fade-out sleep timer.
- **Design language:** Orbioom (glass surfaces, ink-gradient transport, JetBrains Mono numerics, slow breathing motion, green as a rare live accent).
- **Monetization:** freemium — core noises (white/pink/brown/rain) and a couple of saved mixes are free; Pro unlocks the textured sounds (ocean/wind/fan/drone), unlimited saved mixes, and the advanced timer. No ads, no streaming, no account.
- **Why it can boom:** sleep sound is proven top-grossing demand, but the incumbents are widely resented for predatory subscriptions and feature-gating the free sounds. An on-device, fair, beautiful mixer with a fade-to-silence timer is exactly what those one-star reviews are asking for.

## Self-review
Re-read every Swift file by hand against the iOS 17 SDK: verified all imports; `@Model`/relationship/`@Query` wiring; `@Observable` engine injected via `.environment()` and read with `@Environment(MixerEngine.self)`; `@State`/`@AppStorage` bindings; `AVAudioEngine`/`AVAudioPlayerNode.scheduleBuffer(_:at:options:.loops)`/`AVAudioPCMBuffer` usage; `TabView`/`NavigationStack`/`.sheet`/`confirmationDialog`. Buffer math guards all optionals; no force-unwraps, `try!`, or `fatalError` on user paths (only the unreachable in-memory container fallback). `UIBackgroundModes: audio` added to Info.plist. Anti-stub grep is clean.
