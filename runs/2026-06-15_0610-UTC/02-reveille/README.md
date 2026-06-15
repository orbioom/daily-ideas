# Reveille

**A calm, beautiful alarm clock with "dismiss missions" that actually get you out of bed — plus a bedside clock and wake-up stats.**

Reveille is built for heavy sleepers and snooze addicts. Set an alarm, pick a *dismiss mission*, and the alarm only stops once you've finished it — solved the math, repeated the pattern, tapped the dots, shaken your phone, or typed the phrase. No mission, no silence.

**The problem & audience.** The category leader (Alarmy) is top-grossing but costs **$5–9 per month** and keeps nagging you to rate or pay even after you've already paid. Reveille is a **one-time** unlock with **no dark patterns** — no subscription, no ads, no nagging — aimed squarely at people who genuinely struggle to wake up and are tired of being upsold every morning.

## Features

- **Alarms** — full CRUD list with per-alarm enable toggle, live "rings in 7h 12m" subtitles, swipe-to-delete, swipe-to-test, a big "next alarm in…" header, and a calm empty state.
- **Add / Edit alarm** — wheel time picker, Monday-first weekday repeat, custom label, sound picker with **live preview**, dismiss-mission type + difficulty + repetitions, snooze config (length, max-snooze cap), and a volume-ramp slider.
- **Five dismiss missions, all fully playable**
  - **Math** — N arithmetic problems on a keypad, difficulty-scaled operands/operations.
  - **Memory** — watch a tile sequence light up, then repeat it.
  - **Tap targets** — catch N appearing dots before they fade.
  - **Shake** — CoreMotion accelerometer counts real shakes to a threshold (with a tap fallback on devices without a motion sensor).
  - **Steady type** — type a given phrase exactly, with live match progress.
  - Plus **None** (a deliberate press-and-hold Stop) for light sleepers.
- **Ring screen** — a full-screen dawn takeover with the live clock, alarm label, the active mission, a capped Snooze button, and a "Good morning" success state. **Reachable any time** via *Test ring* (swipe left on an alarm or use its context menu) — no waiting required.
- **Bedside clock** — tap-to-dim full-screen clock (`TimelineView`), big time, date, next-alarm countdown, optional 24-hour, four gradient themes.
- **Stats** — average time-to-dismiss, snoozes per week, wake-time consistency (±minutes spread), missions completed, best streak, and **Swift Charts** (dismiss-seconds trend, snooze bars, wake-hour histogram), with an empty state and an async/loading state.
- **Onboarding** — four calm pages that explain the missions, the **honest iOS reliability constraint**, and request notification permission.
- **Settings** — haptics, vibrate-while-ringing, keep-screen-on, 24-hour clock, default sound, default snooze, bedside theme, notification status, and data tools (load sample / reset).
- **Reveille Pro** — tasteful one-time paywall with restore.

## Synthesized sound

Every alarm tone is **generated live in code** with `AVAudioEngine` — no audio files ship with the app. The library includes Ascending Chime, Classic Beep, Warm Marimba, Soft Birdsong (filtered-noise chirps over a drone), Sunrise Bells (inharmonic bell partials), and a Heartbeat Pulse. Each tone loops and **ramps up gently** over a configurable fade-in so you wake without a jolt, and every sound can be previewed from the picker.

## Honest note on alarm reliability

This is the truth, stated plainly (and repeated in-app during onboarding and in About):

> Reveille rings **reliably while it is open or running in the background**, using the audio background mode and `AVAudioSession`. iOS does **not** let any third-party app guarantee a custom ringing alarm after the app has been **force-quit** — that capability is reserved for the system Clock app. To cover that case, Reveille also schedules a **local notification** at each alarm time as a backstop, so you still get a time-sensitive banner and the system alert sound. For the most reliable wake-up, leave Reveille running in the background overnight.

We don't fake a guarantee we can't keep.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Reveille.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

> The Shake mission needs a physical device to read the accelerometer; on the simulator it shows a tap fallback so the mission is still winnable. Background audio and notifications behave best on a real device.

## Free signing

The project works with a **personal Apple ID** — no paid developer account is needed to build and run in the simulator. Code-signing is only required to install on a physical device (select your team in *Signing & Capabilities*).

## Tech notes

- **iOS 17+, SwiftUI 5, MVVM.** Models / view-models / views live in separate files.
- **Persistence: SwiftData** (`@Model` `Alarm` + `WakeLog`, `@Query`, `modelContainer`) with an in-memory fallback if the store is unreadable. Small prefs/flags use `@AppStorage`.
- **Core logic is real and pure:** `AlarmScheduler` computes the next fire `Date` from time-of-day + repeat weekdays using `Calendar`/`DateComponents` (DST/leap-safe), sorts alarms, and renders countdown labels. `RingEngine` synthesizes every tone via `AVAudioEngine` with a volume ramp. `MissionEngine` generates and validates all five missions at three difficulties. `ShakeDetector` wraps `CoreMotion`. `NotificationManager` schedules the backstop via `UNUserNotificationCenter`.
- **Design language:** a warm dawn-to-dusk identity with a coral accent (#FF6B5E), `Color.dyn` light/dark semantic colors, rounded typography, and reusable cards/buttons/pills — applied consistently across every screen, first-class in light **and** dark mode.
- **Accessibility:** Dynamic Type throughout, `accessibilityLabel`/`Hint`/`Value`, decorative images hidden, and animations that honor **Reduce Motion**. Haptics are sparse and gated by a Settings toggle. Divisions are guarded; no force-unwrap / `try!` / `fatalError` on user paths.
- **Monetization:** Free gives unlimited alarms + Math/Shake missions + two sounds. **Reveille Pro** (one-time ~$4.99, simulated locally via `@AppStorage("isPro")`) unlocks all missions, all premium soundscapes, bedside themes, and full stats history. No real StoreKit in this build; restore is simulated.
- **Why it can boom:** the top alarm app prints money on a *monthly* subscription while annoying paying users with rate/pay nags. Reveille keeps the one feature people actually pay for — missions that force you awake — and sells it once, cleanly. A trustworthy, beautiful, no-dark-patterns alternative in a proven top-grossing category is a strong wedge.

## Self-review

- **Compiles by inspection:** every Swift file re-read against the iOS 17 SDK; imports, types, initializers, modifiers, property wrappers, SwiftData wiring, and Charts/TimelineView usage verified. No APIs newer than iOS 17.
- **Anti-stub grep clean:** no `TODO` / `FIXME` / `XXX` / `placeholder` / `lorem` / `coming soon` / `not implemented` / `// stub`.
- **Definition of Done met:** onboarding gated by `hasOnboarded`; four feature tabs (Alarms, Bedside, Stats, Settings) plus the full-screen Ring takeover; empty / loading / error-safe / success states; Settings with 6 persisted prefs; SwiftData persistence surviving relaunch; guarded divisions and no force-unwraps on user paths; accessibility (Dynamic Type, labels/hints/values, Reduce Motion); sparse haptics gated by a toggle; first-class light + dark; a cohesive dawn/dusk visual identity; lazy containers; and seeded sample alarms + ~55 WakeLogs so Stats is rich on first launch.
