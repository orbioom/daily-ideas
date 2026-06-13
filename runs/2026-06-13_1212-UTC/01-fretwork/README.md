# Fretwork — learn the guitar fretboard for real

**One-liner:** A focused, subscription-free guitar trainer: a readable chord library, a fretboard note-naming drill, and the classic one-minute chord-change game — with your progress charted over time.

**Problem & audience:** Millions of beginner and intermediate guitarists want to *internalise* the fretboard and stop fumbling chord changes. The market leaders (Yousician, Fender Play, Justin Guitar) are video-course subscriptions that auto-renew, gate the basics behind a paywall, and lean on flaky audio chord-detection. Fretwork does the two things that actually move the needle — knowing the notes under your fingers and drilling chord transitions — beautifully, offline, for one price.

## Features

- **Chord library** — 25 hand-verified shapes from open beginner chords to barre chords, grouped by difficulty, searchable, with accurate diagrams. Tap any chord for a big diagram, the notes it sounds, a string-by-string fingering breakdown, and a technique tip. Diagrams respect a left-handed toggle and a show-finger-numbers toggle.
- **Fretboard trainer** — a 12-question note-naming drill. The app lights a string and fret; you pick the note from four options. Choose your tuning (guitar standard, drop D, bass, ukulele) and fret range (3–12). Adaptive distractors, instant feedback, scored, and logged.
- **One-minute changes** — pick any two chords and count clean changes against a 30/60/90-second clock, with a live changes-per-minute readout and an alternating visual cue. Beat your CPM week over week.
- **Progressions** — eight common chord progressions (Pop I–V–vi–IV, Doo-Wop, 12-bar blues, folk, and Pro-only jazz ii–V–I, Canon, Andalusian) with a tempo-controlled play-along highlighter.
- **Progress** — day streak, total practice minutes, sessions, best CPM, best accuracy, plus Swift Charts of CPM over time and fretboard accuracy, and a recent-session list.
- **Settings** — default tuning, show finger numbers, left-handed diagrams, haptics, Pro unlock/restore, and a reset-history action. First-run onboarding gated by a persisted flag.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Fretwork.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

**Free signing:** Select your personal team under Signing & Capabilities; the bundle id is `com.orbioom.fretwork`. No paid account or code-signing assets required to run on a simulator or a personal device.

## Tech notes

iOS 17+, SwiftUI 5, MVVM. Primary data (practice sessions) in **SwiftData**; small preferences in `UserDefaults` via `@AppStorage`. Pure music-theory engine (modulo-12 pitch-class arithmetic, tuning-aware fretboard lookup, all guarded so it can never crash). Chord diagrams drawn with `Canvas`; charts with Swift Charts. Light + dark first-class via dynamic asset colors; Dynamic Type, VoiceOver labels, Reduce Motion, and opt-out haptics throughout. Design language: a warm luthier's-workbench palette (walnut, brass, honey amber) with serif display type and rounded UI type.

- **Monetization:** Free core (full chord library + both trainers + progress). One-time **Fretwork Pro ($7.99)** unlocks Pro progressions and custom drills — no subscription, no ads.
- **Why it can boom:** Guitar learning is a massive, evergreen market whose incumbents are $15–20/mo video subscriptions with auto-renew complaints and unreliable chord detection. A gorgeous, offline, one-time-purchase trainer that nails the two highest-leverage beginner skills (fretboard notes + chord changes) is exactly the tool the long tail of frustrated learners searches for.

## Self-review

Hand-reviewed file by file (no Xcode in the build sandbox). Verified: all imports resolve; every type, modifier, and SwiftData/`@Query`/`@Observable`/`@Environment` usage is iOS-17-valid; `NavigationStack`/`navigationDestination`/sheet wiring type-checks; no force-unwrap, `try!`, or `fatalError` on user paths (the only `try!` is the standard in-memory `ModelContainer` fallback); anti-stub grep clean. Onboarding gated by a persisted flag; empty/loading/success/error states present; light + dark, Dynamic Type, VoiceOver, Reduce Motion, and haptics wired.
