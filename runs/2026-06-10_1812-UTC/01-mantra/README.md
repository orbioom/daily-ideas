# Mantra — a calmer daily affirmations practice

**One line:** A quiet, ad-free space to read, write, and keep daily affirmations — the version of "I Am" people wish existed.

**Problem & audience:** Daily-affirmation apps are a proven, large self-care market, but the category leaders bury a 10-second ritual under aggressive paywalls, mid-thought interstitial ads, and pushy upsells. Mantra is for anyone who wants a calm, beautiful affirmation habit without the noise — and to write their own.

## Features

- **Today** — a deterministic, hand-written daily set (3–10 affirmations, your choice) presented as a swipeable, breathing card. Tap **I affirm this** to log a practice; favorite the lines that land. A live streak sits in the corner.
- **Browse** — ten categories (Morning, Calm, Confidence, Self-Love, Gratitude, Success, Abundance, Healing, Focus, Sleep) with ~90 curated affirmations; favorite any.
- **Mine** — your Favorites and your own written mantras in one place, with a full composer (text + category, validated) and delete for your own entries.
- **Insights** — streak, total affirmations practiced, distinct days, the category you return to, and a 14-day practice chart (Swift Charts).
- **Settings** — affirmations-per-day, an optional daily reminder (real local notification at a chosen time), light/dark/system theme, and haptics.
- First-run onboarding gated by a persisted flag; empty, loading, and success states throughout; full Dynamic Type, VoiceOver labels, Reduce-Motion-aware breathing animation.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Mantra.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: set your own Team in Signing & Capabilities; the bundle id is `com.orbioom.mantra`.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-ish with a pure `MantraEngine` (deterministic daily set via SplitMix64, streak/stat math).
- Persistence: **SwiftData** (`Affirmation`, `PracticeLog`); library seeded once behind a flag. `UserDefaults` for small prefs. Local notifications via `UNUserNotificationCenter`.
- Design language: **Orbioom** (glass, ink-gradient buttons, SF Pro + JetBrains Mono, slow breathing motion, green as a rare accent).
- **Monetization:** freemium — free core practice; a Pro subscription unlocks unlimited custom mantras, extra theme packs, and widgets. Proven willingness to pay in this category.
- **Why it can boom:** affirmation apps already gross millions, but their 1–3★ reviews are full of "too many ads," "paywall everything," "feels manipulative." Mantra wins on calm, taste, and a generous free tier.

## Self-review

Re-read every Swift file by hand against the iOS 17 SDK: imports, types, modifiers, `@Model`/`@Query`/`modelContainer` wiring, `@AppStorage`, Charts, and notification APIs check out. No `TODO`/stub/placeholder markers; no force-unwraps, `try!`, or `fatalError` on user paths (only the standard in-memory `ModelContainer` fallback). `project.yml` is valid YAML naming the real `Mantra` sources and `Info.plist`.
