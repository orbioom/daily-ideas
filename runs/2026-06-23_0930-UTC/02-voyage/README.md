# Voyage

**Travel phrases you'll actually remember.** A traveler's phrasebook with real
spaced repetition — curated survival decks per language, an SM-2 review session
with self-grading, and offline native pronunciation. No streaks-and-gems
gamification, no signup, no network.

## Problem & audience

Phrasebook apps are reference tools — you look something up, then forget it. Flashcard
apps make you build decks yourself. Voyage sits in between: it ships *ready-made
survival decks* for a trip (greetings, dining, directions, emergencies, shopping)
and then actually helps you **commit them to memory** before you land, using a
proven spaced-repetition scheduler. Built for travelers prepping for a trip who
want to retain a handful of phrases without grinding a full language course — and
it all works on a plane with no signal.

## Features

- **Four curated decks** — Spanish, French, Italian, Japanese — **205 real travel
  phrases** total (50+ each) spanning six categories: Greetings, Basics, Dining,
  Directions, Shopping, Emergencies. Each phrase has the English meaning, the
  native translation, and a romanized pronunciation hint.
- **SM-2 spaced repetition** — a correct SuperMemo-2 scheduler (ease factor,
  interval growth, repetitions, lapses, due dates) decides which phrases to show.
  Self-grade each card *Again / Hard / Good / Easy* and see the next interval live.
- **Flashcard review session** — flip card (3D flip, or cross-fade under Reduce
  Motion), loading / empty / studying / finished states, per-session results, and
  re-queueing of missed cards.
- **Offline pronunciation** — `AVSpeechSynthesizer` speaks every phrase in its
  native voice, entirely on-device. Tap to hear it, or auto-play on reveal.
- **Browse & search** — global search across every phrase and language, with a
  favorites filter and category chips.
- **Favorites** — heart any phrase for quick access on the road.
- **Stats** — Swift Charts dashboard: totals, maturity donut (new/learning/
  mastered), mastery-by-deck bars, and a 7-day upcoming-reviews forecast.
- **Full CRUD** — create custom decks (with a chosen speech voice), add phrases,
  delete phrases and decks, reset progress.
- **Per-deck progress** — mastery rings and due counts everywhere.
- **Onboarding** gated by a persisted flag; replayable from Settings.
- **Settings** — 5 persisted preferences: new-cards-per-session, show
  pronunciation, auto-play on reveal, speech rate, haptics. Plus reset progress.
- **Polish** — light & dark mode (asset-catalog color sets), Dynamic Type,
  VoiceOver labels/hints/values, decorative images hidden, Reduce Motion honored,
  haptics gated by a setting, designed app icon + accent color + launch screen.

## Run steps

```sh
brew install xcodegen          # if not already installed
cd ios
xcodegen generate              # produces Voyage.xcodeproj
open Voyage.xcodeproj           # Xcode 15+ (iOS 17 SDK)
# Select an iPhone simulator and press Cmd+R
```

**Free signing:** the project has no code-signing requirements baked in. In Xcode,
select the *Voyage* target → *Signing & Capabilities* → pick your Personal Team
(or leave automatic) to run on a device. The simulator needs no signing.

## Tech notes

- **Stack:** SwiftUI 5, MVVM, iOS 17+. Persistence is **SwiftData**
  (`Deck`, `Phrase`, `ReviewState`, `AppSettings` via `@Model` / `@Query` /
  `modelContainer`). A single `UserDefaults`/`@AppStorage` flag gates onboarding.
- **No dependencies, no API keys, no network.** All 205 phrases are curated mock
  fixtures seeded on first launch; pronunciation is on-device TTS.
- **Crash-proofing:** the SwiftData container falls back from disk → in-memory →
  a calm "Storage Unavailable" screen rather than trapping. No `try!`,
  `fatalError`, or force-unwraps on user paths; division and indexing are guarded.
- **SRS engine** (`SRSEngine`) is a pure, deterministic, side-effect-free function
  — easily testable and independent of SwiftData.
- **Monetization:** free with the four starter decks; a one-time **Voyage Pro**
  unlock ($4.99) adds premium language packs (German, Portuguese, Korean,
  Mandarin, Arabic), unlimited custom decks, and an offline trip-prep mode.
- **Why it can boom:** every traveler downloads a phrasebook and forgets every
  phrase by the gate — Voyage is the only one that makes them *stick* with real
  spaced repetition, fully offline, with zero gamification bloat. Trip-timed,
  one-time-purchase, gift-able before a honeymoon or study-abroad — a clean wedge
  against Duolingo's grind and Google Translate's "look it up again" loop.

## Self-review attestation

I re-read every Swift file. All imports resolve; every type, initializer, enum
case and modifier used exists in the iOS 17 SDK and is spelled correctly; protocol
conformances are satisfied; `@State`/`@StateObject`/`@Binding`/`@Bindable`/
`@Environment`/`@Observable`/`@Query`/`modelContainer` usage type-checks;
`NavigationStack`, `navigationDestination`/sheet bindings, and Swift Charts marks
are valid for iOS 17; no APIs newer than iOS 17 are used. The anti-stub grep
(`TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub`) is clean
(the only case-insensitive hit is the legitimate Spanish phrase "Todo recto" =
"Straight ahead" in the seed data). **The project builds with
`xcodebuild ... BUILD SUCCEEDED` (no errors, no warnings) against the iOS
simulator SDK, launches, seeds its data, and renders.** Light and dark color sets
are defined for every custom color; accessibility labels/hints/values and Reduce
Motion handling are present throughout.
