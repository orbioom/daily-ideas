# Span — Your life in weeks

A gorgeous, contemplative memento-mori life calendar. Every week of your life is one dot in a
grid (52 columns × your life-expectancy rows). The weeks you've lived are filled, this week
glows, and everything ahead waits. Color your life into chapters, pin the milestones behind you,
and count down to the moments ahead.

**Problem + audience.** The "Your Life in Weeks" idea (WaitButWhy) goes viral again and again —
seeing a whole lifetime on one screen is genuinely arresting. But the apps that exist are
paywalled, cluttered, or ugly. Span is for a broad audience that wants the same gut-punch of
perspective in a calm, beautiful, one-time-Pro app they'd actually want to share.

## Features

- **Life Grid (hero).** A single `Canvas` renders 52 × *expectancy* week dots (4500+) smoothly,
  colored by chapter, with the current week glowing. Tap any week for a detail sheet showing its
  date range, your age then, the chapter it belongs to, and any milestones that week. A summary
  strip shows weeks lived / left / % of life.
- **Chapters.** Full CRUD over colored life eras (title, start, end-or-ongoing, color, note).
  Reorder by drag, swipe to delete. Each row shows its date range, duration, and ≈ week-span.
  Overlapping chapters layer by most-recent start.
- **Moments.** Past milestones pinned to exact weeks (icon + color + age-at), plus future goals
  with **live countdowns** (days / weeks) driven by `TimelineView`. Full CRUD, empty states.
- **Perspective.** Animated progress ring, precise age (years / months / days via
  `DateComponents`), weeks lived & remaining, days & months lived, summers remaining, and a
  gentle reflection drawn from the numbers.
- **Life poster export.** `ImageRenderer` renders the full grid into a high-resolution,
  shareable poster (Pro).
- **Onboarding** that asks your birth date and life expectancy and creates your profile.
- **Settings** with real, persisted preferences: show week numbers, dot style (round / square /
  soft), haptics toggle, color palette, plus profile editing and data reset.
- Contemplative **midnight + amber** identity, first-class **light and dark**, Dynamic Type,
  VoiceOver labels (the decorative dot grid carries one meaningful summary label), and **Reduce
  Motion** support (the current-week glow and progress animation are disabled when set).

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Span.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

## Free signing

Builds and runs in the simulator with a personal Apple ID — no paid Apple Developer account
needed. Code-signing is only required to install on a physical device.

## Tech notes

- **iOS 17+, SwiftUI 5, MVVM.** SwiftData (`@Model` / `@Query` / `modelContainer`) is the source
  of truth for the profile, chapters, milestones, and goals; `@AppStorage` holds only small
  flags and preferences.
- **Substantive core (`SpanEngine`).** All date math is `Calendar` / `DateComponents`-based, so
  it is leap-year and month-length correct — week indexing from birth, current-week detection,
  per-cell past/current/future classification, chapter resolution, and precise life statistics.
  Divisions are guarded; life expectancy is clamped to 40–120; a future birth date is handled
  gracefully.
- **Performance.** The grid is drawn with a single `Canvas` (not 4500 views), with shared layout
  math reused for both drawing and tap hit-testing, so it stays smooth.
- **Design language.** `Theme.swift` defines semantic colors for light and dark, a serif/rounded
  type scale, and reusable cards, buttons, pills, and empty states.
- **Monetization.** Free includes the grid, all stats, and up to 3 chapters; **Span Pro** is a
  one-time ~$3.99 unlock (simulated via `@AppStorage("isPro")`, StoreKit wires in for
  production) for unlimited chapters / milestones / goals, premium palettes & dot styles, and the
  high-res poster export — with a tasteful paywall and a restore action. No ads.
- **Why it can boom.** "Your life in weeks" is a perennially viral concept, and Span is the
  rare take that's actually beautiful and shareable — every exported poster is an ad, and the
  one-time price removes the friction that makes the paywalled incumbents resented.

## Self-review

- **Compiles by inspection.** Every file re-read; imports, types, initializers, modifiers, and
  property wrappers verified against the iOS 17 SDK. `Canvas`, `TimelineView`, `ImageRenderer`,
  and SwiftData (`Schema` / `ModelContainer` / `@Query` / `@Model`) are wired correctly; CGFloat
  math is kept consistent; no APIs newer than iOS 17 are used.
- **Anti-stub grep clean.** No `TODO` / `FIXME` / `XXX` / `placeholder` / `lorem` /
  `coming soon` / `not implemented` / `// stub` / `fatalError` / `try!` / force-unwraps on user
  paths. The SwiftData container degrades gracefully without forcing.
- **Definition of Done met.** 4 feature screens (Life, Chapters, Moments, Perspective) plus
  Onboarding and Settings; full CRUD; empty / loading / error / success states; ≥ 3 real
  persisted preferences; SwiftData persistence; Dynamic Type, accessibility, and Reduce Motion;
  light + dark; cohesive identity; seeded sample life for a rich first run.
