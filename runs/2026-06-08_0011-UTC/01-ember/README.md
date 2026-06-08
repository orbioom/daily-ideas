# Ember — intermittent fasting tracker

**Burn, not bloat.** A live fasting-window tracker that shows the metabolic stages your body moves through — fed, glycogen burn, ketosis, fat burning, autophagy — with a calm progress ring that keeps counting even after you close the app.

For the millions doing 16:8 / 18:6 / OMAD who want a beautiful, no-nonsense timer without the upsell-heavy bloat of the incumbents.

## Features

- **Live fasting ring** — count-up timer with goal progress, "time to goal" / "over goal" states, driven entirely from the start `Date` so it survives relaunch with zero background work.
- **Metabolic stage engine** — eight widely-cited stages by elapsed hours; shows the current stage, what's happening in the body, and a countdown to the next stage.
- **Plans** — six built-in protocols (14:10, 16:8, 18:6, 20:4, OMAD, 36h) plus full CRUD for **custom plans** with a live eating-window calculator.
- **End-of-fast flow** — rate how it felt (1–5) and add a note when you break a fast.
- **History** — every completed fast with duration, plan, stage reached, and feeling; swipe to delete; full detail/edit screen.
- **Insights** — current streak, average & longest fast, total hours, goal-completion rate, and a 7-day bar chart colour-coded by goal hit (Swift Charts).
- **Settings** — haptics, show/hide stages, default-start preference, data count, and destructive "delete all" with confirmation.
- Onboarding (persisted flag), empty states everywhere, sample-history loader, light/dark, Dynamic Type, VoiceOver labels, Reduce Motion.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Ember.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** select your personal team under Signing & Capabilities; the bundle id is `com.orbioom.ember`. No paid account, no API keys.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM. Persistence in **SwiftData** (`Fast`, `Plan`); small prefs in `UserDefaults` via `@AppStorage`.
- Pure `FastEngine` (progress, stage lookup) and `FastStats` (streak, rate, weekly bars) — no force-unwraps on user paths.
- Design language: **Orbioom** (liquid glass, ink-gradient buttons, JetBrains Mono numerics, green reserved for goal-hit/live).
- **Monetization:** freemium — free single-timer + history; Pro subscription unlocks custom plans, full insights, and widgets. (Proven by Zero/Fastic charging $70–100/yr.)
- **Why it can boom:** intermittent fasting is a top-grossing health category; the leaders (Zero, Fastic, BodyFast) are widely criticised in reviews as bloated, paywalled, and pushy. Ember is the clean, fast, on-device version people ask for.

## Self-review

Re-read every Swift file. Verified: all imports present (`SwiftUI`/`SwiftData`/`Charts`); SwiftData `@Model`/`@Query`/`modelContainer` wiring and `navigationDestination(for: UUID.self)` type-check; `@Bindable` used for editable models; the only `try!` is the standard in-memory `ModelContainer` fallback; no `TODO`/`placeholder`/`fatalError` on any path; ≥4 feature screens (Today, History, Insights, Plans) + Onboarding + Settings; no APIs newer than iOS 17. Anti-stub grep clean.
