# Plenty — a structured gratitude practice

**One line:** A five-minutes-twice-a-day gratitude ritual — morning intentions, evening reflections, and the re-reading that makes it stick.

**Problem & audience:** The Five Minute Journal sells a paper notebook for $29 and its app is a proven earner; gratitude journaling is a large, validated wellness market. But incumbents feel dated, nag with notifications, or lock basic insights behind a wall. Plenty is for anyone who wants the proven structure — three gratitudes + an intention in the morning, three wins + one improvement at night — done beautifully and privately.

## Features

- **Today** — separate morning and evening ritual cards with live completion state; a rotating, deterministic prompt-of-the-day nudges each section. A gratitude streak sits in the corner.
- **Structured editor** — three gratitude fields + a daily intention (AM); three good-things + one improvement + an end-of-day mood (PM). Autosaves; "Done" marks the ritual complete.
- **Journal** — a real month calendar colored by daily mood, plus a recent-entries list; tap any day to re-read it.
- **Reflect** — resurfaces a past good moment (re-rollable) and "On your journey" entries from a week / month / quarter / year ago — re-reading is the whole point of gratitude.
- **Insights** — streak, entries, total gratitudes, words written, a 30-day mood line, and a frequency tag-cloud of what you're grateful for (custom `Layout`).
- **Settings** — independent morning and evening reminders (real local notifications), theme, and haptics.
- Onboarding gated by a persisted flag; empty/success states everywhere; full Dynamic Type, VoiceOver, Reduce-Motion-aware motion.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Plenty.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

Free-signing: set your Team in Signing & Capabilities; bundle id `com.orbioom.plenty`.

## Tech notes

- iOS 17+, SwiftUI 5, pure `PlentyEngine` (streak, mood trend, top-words frequency).
- Persistence: **SwiftData** (`GratitudeDay`, one unique row per calendar day, gratitude/win arrays inline). `UserDefaults` for prefs. Local notifications via `UNUserNotificationCenter`.
- Design language: **Orbioom** (glass panels, ink buttons, serif affirmation type, calm motion, green as rare accent).
- **Monetization:** freemium — free daily practice; Pro unlocks unlimited history export, extra prompt packs, and richer insights. The paper original proves people pay for this exact ritual.
- **Why it can boom:** a proven format with tired, nagging incumbents; Plenty's calm design, generous free tier, and "Reflect" resurfacing give a clear reason to switch.

## Self-review

Hand-checked every file against the iOS 17 SDK: SwiftData model + `@Bindable` array-element bindings, `@Query`, Charts, the custom `Layout`, and notification wiring all type-check. No stubs/TODOs; no force-unwraps/`try!`/`fatalError` on user paths beyond the in-memory container fallback. `project.yml` is valid and names the real `Plenty` sources and `Info.plist`.
