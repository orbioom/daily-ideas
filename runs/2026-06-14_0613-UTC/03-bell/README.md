# Bell

A beautiful, ad-free, **one-time-purchase** unguided meditation **sit timer** with real, in-code-synthesized bells. Not a breathing-pattern app, not a guided-audio course — just you, your breath, and a gentle bell. Dark-first jade identity, built for iOS 17 in SwiftUI + SwiftData + Swift Charts.

## What it is

Configure a sit (duration or open-ended, warmup, interval bells, bell tone, optional soundscape), sit, and save the session with a mood and an optional note. Stickiness comes from a daily minutes goal ring, a day streak, lifetime minutes, reusable presets, and rich insights — never from ads or a subscription.

## Full feature list

- **Today / Home** — today's minutes ring vs. daily goal, current streak, lifetime minutes, total sessions, horizontal quick-start preset chips, and a big *Begin a sit* button into a setup sheet.
- **Session player** (full-screen, immersive) — a calm breathing jade halo (static when *Reduce Motion* is on), big remaining/elapsed clock, current phase (settling in → sitting → complete), pause/resume, end-early with confirmation. Interval bells ring on schedule; a gentle ending bell plays on completion, then a reflection sheet (pick mood + optional note) saves the `MeditationSession`.
- **Presets** — built-in + custom presets; create/edit (duration, warmup, interval, ambient, bell) with a *Preview bell* button; swipe to edit/delete custom presets. Pro-gates: >3 custom presets, Pro ambients, Pro bells.
- **Insights** — Swift Charts: minutes per day (last 30), sessions by time-of-day, mood distribution donut, a 5-week streak heatmap, plus totals (sessions, minutes, average length, longest streak). Shows a loading state while stats are computed off the main thread.
- **History** — month-grouped chronological log with mood, note, duration, and an *ended early* badge; tap into a detail screen to view and edit the note. Empty state when there are no sits.
- **Onboarding** (gated by `hasOnboarded`) — explains the timer, the bells, and the honest one-time-purchase model.
- **Settings** — Sound, Haptics, Keep-screen-awake toggles; daily minutes goal; default soundscape; reset sample data; About.
- **Bell Pro** — honest one-time *Unlock Bell Pro ($5.99)* with a Restore action and a clear demo-build note. Free tier is genuinely usable.

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Bell.xcodeproj` in Xcode 15+, choose an iOS 17+ simulator, and press **Cmd+R**.

## Free signing

The project ships unsigned. In Xcode: select the **Bell** target → **Signing & Capabilities** → check **Automatically manage signing** and pick your personal team. No paid Apple Developer account is required to run on a simulator or a personal device.

## Tech notes

- **In-code audio synthesis.** `Audio/SoundEngine.swift` builds bells with `AVAudioEngine` + `AVAudioPlayerNode`: additive sine partials shaped by `exp(-t·decay)` rendered into an `AVAudioPCMBuffer`, scheduled with no file assets. Ambient soundscapes are a separate low-volume looping buffer (`.loops`) — brown noise, rain, a filtered drone, ocean swell — with a volume fade for endings.
- **Graceful silent fallback.** Every audio setup path is wrapped in `do`/`catch` and every optional (`AVAudioFormat`, `floatChannelData`) is `guard let`-ed — there is **no force-unwrap anywhere in the audio code**. If anything fails, `isAvailable` stays false, the timer runs silently, and bells degrade to a soft haptic cue.
- **Relaunch-safe timer.** `Engine/TimerEngine.swift` is a `final class: ObservableObject` (owned via `@StateObject`) that stores `sessionStartDate` and computes elapsed from `Date()`, so backgrounding/lock never drifts the clock. On each tick it reconciles which interval bells *should* have rung. A `Timer` on the common run-loop mode ticks the UI; screen-awake is toggled via `UIApplication.shared.isIdleTimerDisabled` and always reset on exit.
- **Data.** SwiftData is the primary store (`@Model` `MeditationSession` & `Preset`, `@Query`, `modelContext`). UserDefaults (`@AppStorage`) holds only preferences and the `isPro` / `hasOnboarded` / `didSeed` flags. First launch seeds 4 built-in presets and ~60 historical sessions across the last 8 weeks so streaks and insights look alive; Settings offers a reset-and-reseed.
- **Accessibility.** Dynamic Type throughout, labels/values/hints on stat tiles, controls, and every chart, decorative imagery hidden, AA-contrast jade palette in both light and dark, and the breathing halo collapses to a static state under `@Environment(\.accessibilityReduceMotion)`.

## Monetization

Free: full timer + insights, 3 built-in presets, the singing-bowl bell, and silence/brown-noise soundscapes. One-time **Bell Pro ($5.99)** unlocks all bells (chime, gong), all soundscapes (rain, drone, ocean), and unlimited custom presets. No subscriptions, no ads.

## Why it can boom

Insight Timer, Calm, and Headspace all push subscriptions and guided content. Experienced meditators repeatedly ask for the opposite: a *beautiful, ad-free, one-time-purchase* unguided timer with real bells and soundscapes — and nothing more in the way. That's Bell.

## Self-review attestation

- Re-read every Swift file; verified AVFoundation / SwiftUI / SwiftData / Charts API spelling and iOS-17 availability (`SectorMark`, `AVAudioPCMBuffer`, `ModelContext.delete(model:)`, two-parameter `onChange`).
- **No force-unwrap, no `as!`, no `fatalError`** on any user path. The only force operation is the single sanctioned `try!` in the in-memory `ModelContainer` fallback in `BellApp`. Audio formats and channel data are all `guard let`.
- Observation ownership is consistent: `TimerEngine`/`AppSettings` are `ObservableObject` via `@StateObject`/`@EnvironmentObject`; SwiftData via `@Query`/`@Bindable`/`modelContext`. No `@Observable` macro mixed with `@StateObject`.
- No duplicate types; Charts series are `Identifiable` structs; Theme tokens defined; brace/paren balance verified across all files.
- `grep -rniE "TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub"` over `ios/Bell` → **zero matches**. No stubs.
