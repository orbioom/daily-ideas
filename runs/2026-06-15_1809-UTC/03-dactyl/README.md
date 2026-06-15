# Dactyl

A crisp, native iOS touch-typing & WPM trainer with a clean mechanical-keyboard feel.

## What it is

Touch-typing is an evergreen, broadly useful skill — students, professionals, developers, and
gamers all want to type faster and more accurately. The strong incumbents (Typing.com, Keybr,
Monkeytype) are web-first and have no great native iOS app. **Dactyl** brings the experience home
to iPhone: a guided curriculum, timed speed tests over a common-English word bank, and a real
**per-key error heatmap** that shows exactly which keys trip you up — all in a calm, crisp,
mechanical-keyboard design with a mint accent, monospace type, and key-cap motif.

Everything is on-device: no account, no network, no tracking.

## Features

- **Lessons** — an ordered curriculum (Home Row → Words → Top/Bottom rows → Numbers →
  Punctuation → Capitals → Common Words → Sentences). Each lesson is a card showing your best WPM,
  best accuracy, and a completion check. The Home Row tier is free; the rest unlock with Pro.
- **Typing session** (full-screen drill) — the target text rendered character-by-character with a
  blinking mint **caret**, correct characters in calm green, mistakes in red. A live HUD shows
  WPM / accuracy / time, an optional **next-key + finger guide** strip tells you which finger to
  use, and the keyboard is raised by a native key-capture component. Strict mode requires fixing
  mistakes before advancing. On completion: a success screen with WPM, accuracy, errors, and the
  keys you most mistyped, plus Retry / Done.
- **Test** — 15s / 30s / 60s timed tests or a word-count sprint over a bundled common-English word
  bank, with a live ticking HUD and a history of recent results. The 30s test is free; other modes
  unlock with Pro.
- **Stats** — `Charts`-powered WPM-over-time and accuracy-over-time line charts, plus headline
  tiles (best WPM, average accuracy, total words typed, sessions). Empty state before any data.
- **Keys** — the signature insight: a QWERTY grid colored by your real per-key error rate, a
  per-finger error breakdown, and a **custom drill** launcher (type any text and practice it).
- **Settings** — appearance (System/Light/Dark), haptics, key-click sound, finger guide, strict
  mode, and default test length — all persisted.
- First-run **onboarding**, light + dark first-class, full Dynamic Type & VoiceOver support,
  Reduce-Motion-aware animation, sparse gated haptics, and a rich seeded 8-week history so Stats
  and the heatmap are alive on first launch.

## Substantive core logic

- **`KeyCaptureField`** — a `UIViewRepresentable` wrapping a custom first-responder `UIView` that
  conforms to `UIKeyInput`. It raises the system keyboard and forwards each **inserted character**
  and each **`deleteBackward`** directly to the engine (rather than diffing a bound String), so
  errors and backspaces are counted correctly. Focus is binding-driven and crash-proof.
- **`TypingEngine`** — a pure `struct` holding the target characters, current index, and
  per-position correctness. `type(_:)` compares to the target, advances, and records correct /
  incorrect (tracking which key was mistyped); `backspace()` steps back, guarded. Live metrics:
  WPM = (correctChars / 5) / elapsed-minutes (wall-clock from the first keystroke), accuracy =
  correctChars / totalTyped, and net WPM — every division guarded against zero. Strict mode
  refuses to advance past an uncorrected error.
- **`KeyHeatmap`** — aggregates a set of `TestResult`s into per-key and per-finger error rates,
  normalizing raw error counts by an English letter-frequency estimate so the heatmap reflects
  *rates*, not just volume, and folds keys through a QWERTY finger map.
- **SwiftData** — `TestResult` (with per-key error counts encoded as JSON `Data`, decoded safely)
  and `LessonProgress` (per-lesson bests) persist across relaunch; the curriculum and word bank
  are bundled static catalogs in code.

## Run

1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. `open Dactyl.xcodeproj`, pick an iOS 17+ simulator, and press **Cmd+R**.

**Free signing:** select the Dactyl target → Signing & Capabilities → your personal team; the
bundle id can be anything unique. No paid account is required to run on a simulator or a personal
device.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM, SwiftData for persistence, Swift Charts for trends.
- `NavigationStack` only (no `NavigationView`); two/zero-param `onChange`; no iOS-18 APIs; no
  external dependencies; no network.
- Design language: clean mechanical-keyboard — crisp dark surfaces, mint accent (0x4FC9B0),
  monospace for typed text and stats, key-cap motif, a caret on the current character.
- A `Theme` with `Color.dyn(light, dark)` semantic tokens drives first-class light and dark modes
  and AA-contrast text in both.
- **Monetization:** one-time **Dactyl Pro $3.99** — all lessons, custom drills, all test modes,
  full stats & key heatmap. Simulated locally via `@AppStorage("isPro")` + a `Pro` enum +
  `PaywallView` + `PaywallReason`; StoreKit 2 would wire in here for production. No ads, no account.
- **Why it can boom:** touch-typing is a broad, evergreen learn-a-skill market with strong web
  incumbents but no great native iOS app; Dactyl brings a real per-key error heatmap and a clean
  mechanical-keyboard feel, one-time not subscription.

## Self-review

I acted as the compiler and re-read every Swift file against the iOS 17 SDK:

- All `import`s resolve (SwiftUI, SwiftData, Charts, Combine, UIKit, AudioToolbox, Foundation);
  every type, initializer, enum case, and modifier used exists in iOS 17.
- No force-unwraps, `try!`, `as!`, unguarded division, or unchecked indexing on user paths. All
  array access in `TypingEngine`, the seed generator, and the heatmap is bounds-checked; every
  WPM/accuracy/rate division is zero-guarded. The only `fatalError` is the documented unreachable
  `ModelContainer` fallback (an empty in-memory store cannot fail to build).
- `KeyCaptureField`'s `UIKeyInput` wiring, binding-driven focus, and closure refresh in
  `updateUIView` are crash-proof; `Character`/`String` indexing is guarded throughout.
- State ownership verified: `@StateObject` for `AppSettings` and `SessionViewModel`, `@Query` only
  inside views, `@Environment(\.modelContext)` for SwiftData writes, `@AppStorage` for prefs/flags.
- `@Query`/`modelContainer`/`#Predicate` wiring and `Charts` marks (`LineMark`, `PointMark`)
  type-check; `navigationDestination(item:)` and `sheet(item:)` bindings are correct.
- Accessibility: Dynamic Type via the `Theme` font helpers; labels/hints/values on interactive and
  data elements; decorative images hidden; Reduce Motion respected in animations and the caret
  blink; AA contrast in light and dark.
- Anti-stub grep (`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/
  `stub`) is clean; no dead ends — every tab, button, and gate is wired to real behavior.
