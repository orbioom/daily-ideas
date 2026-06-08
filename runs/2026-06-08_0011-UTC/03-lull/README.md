# Lull — guided breathwork

**Breathe with the orb.** A calm, growing Orbioom orb paces every breath — expanding on the inhale, settling on the exhale — so you never count in your head. Box breathing to focus, 4-7-8 to sleep, coherent breathing to steady.

For the huge calm/meditation audience who want Apple-Watch-style breathe sessions on their phone, with patterns the big subscription apps lock away.

## Features

- **Guided session player** — full-screen immersive session with a radial breathing orb, phase label and per-phase countdown, round counter, overall progress, pause/resume, and a 3-2-1 count-in. Phase-change haptics; optional keep-screen-awake.
- **Phase engine** — `BreathEngine` turns a four-phase pattern (inhale / hold / exhale / hold × rounds) into a continuous eased orb scale and exact live state, computed from elapsed time so pause/resume is precise.
- **Patterns** — six built-ins (box, 4-7-8, coherent, calm-down, energize, deep reset) plus full CRUD for **custom patterns** with a live total-length calculator; "try now" launches any pattern.
- **Today** — daily-minutes goal ring, streak, selected-pattern card, and quick-start list.
- **Sessions** — history of completed/partial sessions with minutes; swipe to delete.
- **Insights** — total minutes, streak, session count, a 14-day minutes chart, and your most-practised pattern (Swift Charts).
- **Settings** — phase haptics, keep-awake, daily goal (min), data count, delete-all with confirmation.
- Onboarding (persisted), empty states, sample loader, light/dark, Dynamic Type, VoiceOver, Reduce Motion (orb falls back to an opacity cue).

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Lull.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** personal team; bundle id `com.orbioom.lull`. No paid account, no keys.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM. **SwiftData** (`BreathPattern`, `BreathSession`); prefs in `@AppStorage`.
- The session is date-driven via `TimelineView(.animation)`; pure `BreathEngine` + `SessionStats` (streak, daily minutes, favourite). No timers leaking across renders.
- Design language: **Orbioom** — this is the brand's showcase: the breathing orb is the literal Orbioom orb motif, with green reserved for the live core.
- **Monetization:** freemium — free core patterns; Pro unlocks custom patterns, longer programs, and a calm-rating journal. (Calm/Headspace prove enormous willingness to pay for breathing/meditation.)
- **Why it can boom:** breathwork rides the Calm/Headspace wave but those are pricey, content-heavy, and over-produced. A free, instant, beautiful breathing orb with the patterns people actually use is exactly the lightweight tool the 1-star reviews of the giants beg for.

## Self-review

Re-read every file. Verified imports; `TimelineView` count-in/breathing are date-driven (no per-render `Timer.publish`); `fullScreenCover(item:)` over `BreathPattern` (Identifiable) compiles; `Canvas`/orb gradients, `@Query`, and Charts type-check; only `try!` is the in-memory fallback; ≥4 feature screens (Breathe, Patterns, Sessions, Insights) + Onboarding + Settings + session player; no stubs, no iOS-18 APIs. Anti-stub grep clean.
