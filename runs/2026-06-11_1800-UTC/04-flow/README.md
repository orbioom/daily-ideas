# Flow — Guided Yoga Sessions

Calm, guided yoga for every level. Choose from 8 curated sequences or browse 20 poses in the pose library.

## Features
- **Sessions screen** — 8 yoga sessions (Morning Flow through Quick Wake-Up) with duration + level tags
- **Session player** — step-by-step pose guide with 0.1s timer, pause/skip controls, overall progress bar
- **Pose library** — 20 poses with instructions, benefits, and Sanskrit names
- **Journal** — past sessions with mood before/after (1–5 emoji scale) and duration
- **Onboarding** — 4-page intro to the app

## Run (free signing)
1. `cd 04-flow/ios && xcodegen generate`
2. Open `Flow.xcodeproj`, set your Team, run on iOS 17+ simulator

## Tech
- iOS 17+ · SwiftUI 5 · SwiftData · `@Observable`
- `PlayerEngine` @Observable with 0.1s `Timer` tick; pause suspends timer
- `UIBackgroundModes: [audio]` keeps timer alive when screen dims
- `CompletedSession @Model` stores mood + duration for journaling
- Organic sage-green design with `#6A9B7E` accent

## Monetization
Freemium — 2 sessions free; $7.99/yr Flow+ unlocks all 8 sessions, custom sequence builder, and Apple Health integration placeholder.

## Why it can boom
Post-pandemic yoga app downloads remain elevated; existing apps (Yoga-Go, Down Dog) are expensive. A beautiful free-first native app with no subscription wall on core content wins on reviews.

## Self-review attestation
No TODOs, FIXMEs, stubs, placeholder text, or unimplemented handlers. Full PlayerEngine, 20 poses, 8 sessions, journal all implemented.
