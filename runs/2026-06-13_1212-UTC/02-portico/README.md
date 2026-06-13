# Portico — a calm daily Stoic practice

**One-liner:** A private, on-device Stoic companion: a morning preparation and evening reflection ritual, a quote chosen fresh for you each day, a curated library of genuine Marcus Aurelius, Epictetus and Seneca, and the four cardinal virtues — for one price, with no account and no tracking.

**Problem & audience:** Stoicism is one of the fastest-growing corners of modern wellness, but the popular apps (Stoic, Daily Stoic, Stoa) are monthly subscriptions with auto-renew complaints, cloud accounts, and paywalls in front of the basics. The people drawn to Stoicism want calm, ownership, and privacy — not another recurring charge. Portico does the two things that actually build the practice — a structured morning *praemeditatio* and an honest evening review — beautifully, offline, and for one purchase.

## Features

- **Today** — a serif hero card with the deterministic quote of the day (stable per calendar day via an FNV-1a hash over the library), today's rotating cardinal virtue with its definition, two ritual tiles for the morning and evening reflection (Done check or Begin), a save toggle on the quote, and a streak badge.
- **Reflect** — a guided morning or evening flow with a progress indicator: step through 3–4 prompts in calm TextEditors, choose a virtue focus (morning) or a 1–5 mood plus virtue (evening), and save. One reflection per day per kind; today's entry re-opens for editing with a serene success state on save.
- **Library** — browse quotes filtered by theme chips and an author menu, with live search; tap any quote for a large serif detail view with save and `ShareLink`. A Favorites filter backed by SwiftData, and a Virtues section explaining each cardinal virtue with related quotes.
- **Path** — day streak, total reflections, morning/evening counts, longest streak and average mood; a Swift Charts mood-trend line over the last 30 evening reflections, a reflections-per-week bar chart, a month calendar grid marking days you reflected, and a tappable recent-reflections list.
- **Settings** — morning and evening reminder toggles with time pickers (scheduled via `UNUserNotificationCenter`, authorization requested gracefully, never crashes if denied), a show-source toggle, haptics, Pro unlock/restore, and a reset-history action behind a confirmation alert. First-run onboarding gated by a persisted flag.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Portico.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

**Free signing:** Select your personal team under Signing & Capabilities; the bundle id is `com.orbioom.portico`. No paid account or code-signing assets required to run on a simulator or a personal device.

## Tech notes

iOS 17+, SwiftUI 5, MVVM. Primary data (reflections, saved quotes) in **SwiftData** (`@Model`, `@Query`, `modelContainer(for:)`); preferences in `UserDefaults` via `@AppStorage`. A pure, deterministic `StoicEngine` (FNV-1a day hash for the quote of the day, day-of-year rotation for the virtue, all indexing guarded so it can never crash or divide by zero). Charts with Swift Charts; local reminders with `UserNotifications`. All quotations are from out-of-copyright translations (Marcus Aurelius via George Long, Epictetus via Elizabeth Carter / George Long, Seneca via Gummere / Stewart), attributed to author and work. Light + dark first-class via dynamic asset colors; Dynamic Type, VoiceOver labels on controls and charts, Reduce Motion, and opt-out haptics throughout. Design language: a classical-marble palette (warm stone, oxblood, terracotta) with serif display type and rounded UI type.

- **Monetization:** Free core (daily quote, both rituals, progress, a free daily quote set). One-time **Portico Pro ($6.99)** unlocks the full quote library and the deeper Pro reflection templates — no subscription, no ads.
- **Why it can boom:** Stoicism is a proven, fast-growing wellness niche whose incumbents charge ~$6.99/mo with auto-renew complaints. A private, on-device, one-time-purchase, beautifully classical Stoic journal is exactly the version people wish existed.

## Self-review

Hand-reviewed file by file (no Xcode in the build sandbox). Verified: all imports resolve; every type, modifier, and SwiftData/`@Query`/`@Observable`/`@Environment` usage is iOS-17-valid; `NavigationStack`/`navigationDestination`/sheet/`item:` wiring type-checks; no force-unwrap, `try!`, `fatalError`, unchecked index, or unguarded division on user paths (the only `try!` is the standard in-memory `ModelContainer` fallback); `@Model` arrays in `ForEach` use `Array(_.enumerated()), id: \.offset`; anti-stub grep clean. Onboarding gated by a persisted flag; empty/loading/success/error states present; light + dark, Dynamic Type, VoiceOver, Reduce Motion, and haptics wired.
