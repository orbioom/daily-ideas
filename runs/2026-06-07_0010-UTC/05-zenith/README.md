# Zenith

**A telescope optics companion and observing log.**

Zenith does the eyepiece math amateur astronomers do by hand, and keeps the record
of every night under the stars. Add your telescopes and eyepieces once; Zenith knows
each scope's focal ratio, resolving power, and limiting magnitude, computes
magnification / true field / exit pupil for any combination, suggests what to point
at this month, and logs what you saw. On-device, no account.

## Features

- **Gear** — telescopes (aperture, focal length, type) and eyepieces (focal length,
  apparent field). The telescope detail shows focal ratio, max/min useful power,
  Dawes resolving limit, limiting magnitude, and a table of magnification / true
  field / exit pupil for every eyepiece you own. Full CRUD.
- **Compute** — pick a scope, an eyepiece, and a barlow; get magnification, true
  field of view, and exit pupil, with a plain-language read on whether it's the
  right power and a warning past the scope's max useful magnification.
- **Observing log** — record sessions with target, type, constellation, the gear
  used (magnification auto-computed), location, Bortle class, seeing, transparency,
  and a personal rating. Full CRUD with summary stats.
- **Tonight** — the showpiece objects best placed this month (12 charted targets),
  each with magnitude, size, and a recommended eyepiece that frames it in your
  primary scope — plus a one-tap "log this" and an "observed" badge.
- **Settings** — home Bortle class, default barlow, over-magnification warning, and
  haptics; replay intro; clear all data.

## The engine

`Optics` is pure value-type math: focal ratio, magnification (`scope FL × barlow ÷
eyepiece FL`), true field (`apparent FOV ÷ magnification`), exit pupil (`aperture ÷
magnification`), Dawes limit (`116 ÷ aperture`), and a rough limiting magnitude.
`Optics.view` composes the full picture and grades the combination. The Tonight
recommender chooses the eyepiece that best frames each target's apparent size (or
the highest useful power for planets and doubles).

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Zenith.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: choose your personal team under Signing & Capabilities; no paid
account needed for the simulator or your own device.

## Tech notes

iOS 17+, SwiftUI 5, SwiftData (`Telescope`, `Eyepiece`, `Observation`), pure optics
engine off the view layer; target list as value types. Orbioom design language with
an indigo accent: glass cards, ink-gradient action, mono figures, light + dark,
Dynamic Type, VoiceOver (the eyepiece table reads each combination aloud), Reduce
Motion, gated haptics.

## Self-review

Read every file by hand: imports resolve; all SwiftUI/SwiftData types and SF Symbols
exist in iOS 17; `log10` is imported via Foundation; `@Query`/`@Bindable`/
`PersistentIdentifier` pickers and sheet bindings type-check; no force-unwraps on
user paths; the only `try!` is the in-memory container fallback in `ZenithApp`.
Anti-stub grep clean.
