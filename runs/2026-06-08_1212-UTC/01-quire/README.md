# Quire

**A calm, private journal — write freely or follow a gentle prompt.**

The problem: people want a daily journaling habit, but the category leader (Day One) locks the free tier to one journal and one photo per entry, has no lifetime option, and recently raised prices — long-time users are actively looking to leave. Quire is the version they wish existed: generous, fully on-device, prompt-driven, and quiet. Audience: anyone building a reflection, gratitude, or diary habit.

## Features

- **Journal timeline** grouped by day, with a daily prompt card, pinned entries, and an "On this day" surface that resurfaces past years.
- **Rich entry editor** — title + free body, live word count, date/time, a 1–5 mood, many-to-many tags (create on the fly), favorite and pin.
- **Prompt deck** — a curated library across Reflection, Gratitude, Growth, Creativity, Relationships, and Evening, with a deterministic "prompt of the day" and one-tap "write from this".
- **Calendar** — month grid colored by each day's dominant mood, tap a day to read or add entries.
- **Insights** — current/longest journaling streak, total words, average mood, a 30-day mood trend (Swift Charts), entries-per-month, and most-used tags.
- **Search** across titles, bodies, and tags.
- **Settings** — theme (system/light/dark), newest-first toggle, week-starts-Monday, a stored daily reminder time, haptics, and erase-all.
- First-run onboarding (persisted), empty/loading/success states, full Dynamic Type + VoiceOver, light & dark, Reduce-Motion-aware animation, on-brand app icon.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Quire.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: select your personal team under Signing & Capabilities; the bundle id is `com.orbioom.quire`.

## Tech notes

iOS 17+, SwiftUI 5, MVVM with a pure `JournalEngine` (streaks, word/mood stats, on-this-day, tag counts) and a `PromptLibrary`. Persistence in **SwiftData** (`JournalEntry` ⇄ `Tag` many-to-many). Design language: **Orbioom** (liquid glass, ink gradient, JetBrains Mono numerals). No account, no network.

- **Monetization:** freemium — core journaling is free forever; a one-time Pro unlock (or low annual) adds export/print, themes, and prompt packs. Who pays: habitual journalers burned by Day One's pricing.
- **Why it can boom:** Day One is a proven, top-grossing category with loud pricing/free-tier complaints; Quire keeps the loved parts (prompts, photos-of-the-mind, calendar) and removes the friction.

## Self-review

Re-read every Swift file by hand. All imports resolve; SwiftData `@Model`/`@Query`/`@Relationship` wiring and `modelContainer` type-check; `NavigationStack`/sheet bindings correct; no APIs newer than iOS 17; no force-unwraps/`try!`/`fatalError` on user paths (only the container bootstrap fallback). Anti-stub grep clean. Fixed two issues before commit: a tuple key-path in a Chart `ForEach` and weekday symbols sourced from `DateFormatter` rather than `Calendar`.
