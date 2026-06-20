# Halo — Binaural Beats

> Your mind, tuned.

## What it is

Halo generates real-time binaural beats — two slightly different frequencies, one in each ear — to guide your brain into focused, meditative, or sleep-ready states. Backed by neuroscience research and powered by a custom DSP engine built with AVAudioSourceNode.

## Features

### Free
- 4 presets: Focus Flow (alpha 10 Hz), Deep Meditate (theta 6 Hz), Sleep Drift (delta 2 Hz), Study Mode (beta 18 Hz)
- Real-time binaural synthesis (carrier + binaural offset, left/right stereo channels)
- Optional ambient pink noise layer (Kellet method)
- Session timer with auto-stop
- Session history with SwiftData persistence
- Weekly insights with Swift Charts
- Full science education section

### Pro ($4.99 one-time)
- 8 additional presets: Peak Performance, Stress Relief, Creative Surge, Healing Sleep, Confidence Boost, Mindful Presence, Lucid Gateway, Memory Lock
- Session reflection notes
- Unlimited session history

## Architecture

```
Halo/
├── Engines/
│   └── BinauralEngine.swift    — @Observable, AVAudioSourceNode real-time stereo DSP
├── Models/
│   ├── HaloPreset.swift        — 12 presets (4 free, 8 Pro) with Hz values
│   ├── BrainwaveCategory.swift — Delta/Theta/Alpha/Beta/Gamma enums with descriptions
│   ├── HaloSession.swift       — @Model for SwiftData persistence
│   └── HaloSettings.swift      — @Model singleton (onboarding, Pro, defaults)
├── Views/
│   ├── Home/                   — Preset grid, PresetDetailView, PresetCard
│   ├── Player/                 — Full-screen player, animated HaloRing, ReflectionSheet
│   ├── Sessions/               — Session history list
│   ├── Insights/               — Weekly charts (Swift Charts)
│   ├── Learn/                  — Brainwave science education
│   ├── Settings/               — Audio controls, timer defaults, Pro unlock
│   ├── Onboarding/             — 3-page headphone + science intro
│   └── Components/             — NowPlayingBar (mini player over tab bar)
└── Theme/
    └── HaloTheme.swift         — Deep purple #0D0D1A palette, rounded system font
```

## DSP Design

`BinauralEngine` uses `AVAudioSourceNode` with a real-time render block:

```swift
// Left channel: carrier frequency (e.g. 200 Hz)
leftData[frame] = Float(sin(2π × carrierHz × t)) × 0.5

// Right channel: carrier + binaural offset (e.g. 200 + 10 = 210 Hz)
rightData[frame] = Float(sin(2π × (carrierHz + binauralHz) × t)) × 0.5

// Pink noise: Kellet's IIR filter method (7-state b0–b6)
```

AVAudioSession category `.playback` + `UIBackgroundModes: audio` enables audio to continue when the screen locks.

## Build

```bash
cd ios/
xcodegen generate
open Halo.xcodeproj
```

Requires XcodeGen (`brew install xcodegen`) and Xcode 15+. Use stereo headphones to hear the effect.

## Monetization

**$4.99 one-time Pro unlock** — no subscription, no ads, no tracking.

Free tier is genuinely useful (4 of the most popular presets). Pro adds depth for power users.

## Why it can boom

- Calm (top 10 grossing app for years) charges $15/mo for ambient audio
- Endel charges $7/mo
- Most binaural apps are ad-heavy or poorly designed
- Halo's one-time-purchase model and clean dark UI fills a clear gap
- Binaural beats searches: 500K+/month on Google; "best binaural beats app" is competitive but winnable with ASO
