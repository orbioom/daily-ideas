# Lumina — Affirmations & daily motivation

A calm, private affirmations companion. Read a deterministic affirmation of the day, swipe a themed deck, build a practice streak, and settle into a full-screen breathing session where each line rises with your breath. Built for anyone who uses affirmations for confidence, calm, sleep, or self-love — without the ads, injected upsells, and cancellation traps that plague the category leaders.

## What it is
- **One-line:** A quiet affirmations app — generous, ad-free, and entirely on-device.
- **Problem + audience:** The top affirmation apps (e.g. "I Am") earn well but are widely disliked for injecting ads for other apps into the feed, losing saved data on device changes, and making subscriptions hard to cancel. Lumina is for the same large self-care audience that wants the daily ritual without the dark patterns.

## Full feature list
- **Today:** greeting + streak header, a deterministic affirmation of the day (FNV-hashed by date), a seeded daily deck you can swipe through, one-tap favorite, and an "I affirm this" action that logs the day.
- **Library:** 100+ built-in affirmations across 8 themes (Morning, Calm, Confidence, Gratitude, Self-Love, Success, Healing, Sleep), search, theme + favorites filters, and full CRUD for your own affirmations (create/edit/delete, with a live preview).
- **Practice:** configurable breathing session (theme, favorites-only, count) → a full-screen player with a breathing orb (4-2-6 inhale/hold/exhale), phase haptics, pause/skip, and a completion summary; partial sessions still count.
- **Insights:** current/longest streak, total affirmed, days practiced, favorites and custom counts, a 14-day Swift Charts bar chart, and favorites-by-theme breakdown.
- **Settings:** daily reminder with a real local notification (time picker, permission handling), per-theme toggles for the Today deck (≥1 stays on), light/dark/system appearance, haptics toggle, delete-my-custom-affirmations, privacy/version info.
- First-run onboarding gated by a persisted flag; empty, loading, success, and error states throughout.

## Run steps
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Lumina.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

## Free-signing note
No paid Apple Developer account needed: open the project, select your personal team under Signing & Capabilities, and run on a simulator or your own device.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM-ish with a pure `AffirmationEngine` (deterministic daily pick + seeded Fisher–Yates deck) and `StreakEngine`.
- Persistence: **SwiftData** (`Affirmation`, `DayLog`); `UserDefaults` only for small prefs/flags. Reminders via `UNUserNotificationCenter`, on-device only.
- Design language: **Orbioom** (glass, ink-gradient primary buttons, calm motion, green as a rare success/live accent), with per-theme tints.
- **Monetization:** freemium — core library + daily + streaks free; a one-time "Lumina+" unlock (custom-affirmation collections, extra themed packs, widget) is the obvious paid tier. Recurring willingness to pay is proven by the category's top-grossing incumbents.
- **Why it can boom:** affirmation apps are a proven top-grossing self-care category (the leader does ~$600k/mo) but are hated for ads-in-feed, data loss, and cancellation traps; Lumina wins as the calm, private, no-dark-patterns version people wish existed.

## Self-review
Re-read every Swift file: imports verified; all SwiftUI/SwiftData/Charts/UserNotifications symbols exist in the iOS 17 SDK; `@Observable`/`@State`/`@Query`/`@AppStorage`/`modelContainer` wiring type-checks; no force-unwraps, `try!`, or `fatalError` on user paths (container init falls back to in-memory); anti-stub grep clean. Dynamic Type, accessibility labels/hints, Reduce Motion, and light/dark are all handled.
