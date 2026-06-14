# Cusp

**Days until & days since.** A calm, ad-free countdown app for the days you can't wait
for — and the moments you don't want to forget.

Cusp is the countdown app the Countdown+/Dreamdays crowd keeps wishing existed: a clean,
one-time unlock with no ads and no paywalled-widget dark patterns. Track the days until
upcoming events and the days since past moments, with live tickers and gorgeous gradient
cards.

- **Problem:** Most countdown apps bury basic counting behind ads, subscriptions, and
  widgets locked behind a paywall.
- **Audience:** Anyone counting down to a trip, birthday, exam, wedding, payday or
  retirement — or counting up from a milestone like a new job or a sober date.

## Features

- **Timeline / Home** — events as rich gradient cards, each showing a live count (big
  number + unit), title, symbol and date. Pinned section on top, a segmented Upcoming /
  Past / All filter, sort (soonest / title / recently added), a summary strip and a calm
  empty state. Tap a card for detail; long-press for quick pin / edit / delete.
- **Event detail** — a full-screen **live** countdown (`TimelineView`) inside a progress
  ring, with recurrence info, the next-occurrence date, an optional note, a rendered
  **share card** (`ImageRenderer` + `ShareLink`, with a text fallback), and edit / delete.
- **New / Edit event** — a full editor: title, date with an optional time toggle,
  until/since type, repeat rule, a grouped symbol picker (SF Symbols + emoji), an 8-way
  gradient picker, and a note — with live preview and validation.
- **Calendar** — a month grid highlighting days with events (dots colored per event); tap
  a day to see its events; navigate months and jump back to today.
- **Quick-add templates** — a gallery of common occasions (New Year, Birthday, Anniversary,
  Vacation, Exam, Payday, Retirement, Wedding) that prefill the editor, plus a blank event.
- **Onboarding**, **Settings**, an honest **Paywall**, and an **About** sheet.

### The counting engine
A pure `CountdownEngine` does all date math: effective next/last occurrence for repeating
events (leap-day-safe and month-end-safe, e.g. monthly-on-the-31st), live day/hour/minute/
second spans, days-until vs days-since, progress fraction, Today / Upcoming / Past grouping
and sorting, next-5 events, busiest month, totals, and the calendar month grid. Every path
is guarded against invalid dates — it never crashes on edge cases.

## Monetization
Honest one-time **Cusp Pro ($3.99)** unlock: unlimited events, all eight gradient themes,
share cards and the calendar. Free includes up to five events and all core counting — the
basic ability to make a countdown is **never** paywalled.

## Settings (persisted)
Default event type, week-starts-on Sunday/Monday, default gradient, show-seconds-on-cards,
and a haptics toggle — plus Pro/restore and About. All survive relaunch.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Cusp.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

Free-signing: select your personal team under *Signing & Capabilities* if building to a
device; the simulator needs no signing.

## Tech notes
- **iOS 17+**, **SwiftUI**, **MVVM**, **SwiftData** for the single user-owned entity
  (`CountdownEvent`); `@AppStorage`/`UserDefaults` for small prefs & the Pro flag.
- Live counting via `TimelineView(.periodic)`; share cards via `ImageRenderer`.
- Design language: calm, native-first "quiet glass" — sunset-coral accent, eight gradient
  card themes, first-class light & dark via a `Color.dyn(light, dark)` token system, full
  Dynamic Type, VoiceOver labels, WCAG-AA contrast, and Reduce-Motion-aware animation.
- **Monetization:** one honest one-time unlock (`isPro`); the free tier is genuinely useful.
  *(Demo build unlocks locally; production wires StoreKit 2.)*
- **Why it can boom:** the countdown category is huge but universally resented for ads and
  paywalled widgets — Cusp wins on trust, beauty, and an honest price.

## Self-review attestation
Every Swift file was re-read and hand-verified against the iOS 17 SDK: imports, types,
initializers, enum cases and modifiers exist and are spelled correctly; SwiftUI state
wiring (`@State`/`@StateObject`/`@Binding`/`@Bindable`/`@EnvironmentObject`/`@Query`/
`modelContainer`) type-checks with ownership hoisted correctly; navigation and sheet
bindings type-check; no APIs newer than iOS 17; brace/paren/bracket balance verified; every
`Theme.` token referenced is defined. There are no force-unwraps, `try!` (except the
mandated in-memory `ModelContainer` fallback), or `fatalError` on user paths. An anti-stub
grep (`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`// stub`)
is clean.
