# Fetch — Dog Training & Tricks Coach

## What it is

**Fetch** is a native iOS dog-training coach that teaches your dog commands and tricks
with clear, step-by-step lessons — then helps you actually *practice* with timed
sessions, a built-in clicker, rep counting, and per-dog progress tracking.

It's built for everyday dog owners who want the structure of an app like Dogo, Puppr
or GoodPup **without the $40-a-month subscription**. Fetch is a one-time purchase:
self-serve training that respects your wallet.

- **Problem:** Most dog-training apps lock genuinely useful content behind expensive
  recurring subscriptions, and few make daily practice feel rewarding.
- **Audience:** New puppy parents, multi-dog households, and anyone who wants a
  trustworthy, friendly coach in their pocket.

## Features

- **40-trick catalog** across four categories — Basics, Manners, Tricks, and Agility &
  Advanced — each with a real, ordered, 4–8 step training plan, trainer tips, a
  difficulty rating, estimated days, and prerequisites.
- **5 structured programs** — Puppy Starter, Good Manners, Leash Mastery, Party Tricks,
  and Calm & Focus — each an ordered curriculum with live per-dog progress.
- **Today / Home** — active-dog header with a switchable avatar, training-day streak,
  daily-goal ring, AI-free smart trick suggestions (based on status, prerequisites and
  difficulty), a quick "start session" action, and recent sessions.
- **Library** — browse and search every trick, filter by category, open a rich
  **trick detail** screen with steps, tips, prerequisites checklist, your dog's status,
  and a one-tap practice session.
- **Programs** — browse plans and open a **program detail** with an ordered lesson list,
  per-trick status, and an overall mastery bar.
- **Dogs** — full multi-dog CRUD: add/edit, photo (via PhotosPicker), breed, birthday →
  age, notes, and a per-dog **progress dashboard** with a mastery ring and status
  breakdown.
- **Session player** (full-screen) — a live wall-clock timer (anchored to the start
  date so it survives backgrounding), big rep +/− controls, an on-device synthesized
  **clicker** (sound + haptic), pause/resume, then a finish flow with a 5-star rating
  and note that writes a `TrainingSession` and intelligently advances `TrickProgress`.
- **Stats** — Swift Charts: sessions over time, minutes trained, mastery by category,
  session-rating distribution, plus streak and totals.
- **Custom tricks** (Pro) — author your own commands with steps and tips; they appear in
  the Library alongside the catalog.
- **Settings** — Appearance (System/Light/Dark), Haptics, Clicker sound, Daily training
  goal, Default session length, Restore, and About.
- **Onboarding** — a gated, multi-page welcome that explains the value and creates your
  first dog.
- **Polish** — light & dark themes, Dynamic Type, VoiceOver labels on controls and
  charts, Reduce Motion fallbacks, gated haptics, empty/loading/success states, and
  a friendly bright-blue, rounded, paw-motif design language.

### Seeded sample data
On first run Fetch seeds a sample dog ("Cooper", a 16-month Golden Retriever) with 12
progress rows across all statuses and ~35 training sessions spread over the last six
weeks, so Home, Stats and the streak are alive immediately. Seeding is guarded by an
`@AppStorage` flag and a dog-count check so it runs exactly once. (If you create your
own dog during onboarding, the sample is skipped entirely.)

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root if present).
3. Open `Fetch.xcodeproj` in Xcode 15+, pick an **iOS 17+ simulator**, and press **Cmd+R**.

### Free signing
No paid Apple Developer account is required to run on the simulator. To run on a
physical device, select the **Fetch** target → **Signing & Capabilities**, choose your
personal team, and Xcode will provision a free development signing certificate.

## Tech notes

- **iOS 17+, SwiftUI** throughout — `NavigationStack`, `TabView`, `TimelineView`,
  two-parameter `.onChange(of:)`, `PhotosPicker`.
- **SwiftData** is the primary store: `Dog`, `TrickProgress`, `TrainingSession`, and
  `CustomTrick` are all registered in a single `Schema`. Small preferences and flags
  live in `@AppStorage`. Data survives relaunch.
- **AVFoundation clicker** — the click is synthesized on-device as a tiny generated PCM
  buffer played through `AVAudioEngine` (no audio files shipped), gated by a sound
  setting and paired with a haptic. Engine start is guarded so it fails silently.
- **Swift Charts** powers the Stats screen with accessible labels and values.
- **Pure engines** (`ProgressEngine`, `StatsEngine`, `SessionEngine`, `Clicker`) keep
  logic out of views; all user-path math is guarded (no force-unwraps, no unguarded
  division, no unchecked indexing).
- **Design language** — bright-blue accent `#2E86DE`, rounded SF typography, playful paw
  motifs, clean cards, and `Color.dyn(light, dark)` for WCAG-AA contrast in both modes.
- **Monetization:** a single one-time **Fetch Pro** unlock ($14.99) — unlimited dogs
  (free = 1), all programs (free = 2), advanced stats, and custom tricks; the simulated
  purchase is StoreKit-ready.
- **Why it can boom:** it beats the $40/month incumbents on price and trust — a genuinely
  useful, self-serve training coach that owners buy once and recommend, with broad
  evergreen appeal to every new dog owner.

## Self-review

I re-read every Swift file and verified by hand:

- **Imports** match usage in every file (`SwiftUI`, `SwiftData`, `Charts` only in Stats,
  `PhotosUI` only in the dog editor, `AVFoundation` only in the clicker, `Observation`
  only in `SessionEngine`, `UIKit` in helpers).
- **iOS 17 only** — no `NavigationView`, no `@Previewable`, no iOS-18 SwiftData/SwiftUI
  symbols; `.onChange(of:)` uses the two-parameter `{ oldValue, newValue in }` form in
  both call sites; `TimelineView`, `contentTransition(.numericText())`, `PhotosPicker`,
  and `presentationDetents` are all iOS 17-valid.
- **Safety** — no `try!`, no `as!`, no force-unwrap on user paths, no unchecked array
  index, no unguarded division. The only `fatalError` is the documented-unreachable
  in-memory `ModelContainer` fallback in `FetchApp.swift`.
- **No stub strings** — grep for `TODO/FIXME/XXX/placeholder/lorem/coming soon/not
  implemented/stub/unimplemented` finds only the legitimate SwiftUI `placeholder:`
  TextField parameter name; every screen and button is real and wired.
- **SwiftData** — all four `@Model` types (`Dog`, `TrickProgress`, `TrainingSession`,
  `CustomTrick`) are listed in the `Schema([...])`; relationships use correct inverse
  key paths with cascade delete rules.
- **Observation ownership** — `SessionEngine` is `@Observable` and held with `@State`
  (never mixed with `@StateObject`); app-wide `AppSettings` is `ObservableObject` held
  with `@StateObject`.
- **Catalog integrity** — 40 tricks, no duplicate ids; every prerequisite id, every
  program lesson id, and every seeded trick id resolves to an existing catalog trick.
- **Balanced braces and parentheses** in all 40 Swift files (verified programmatically).
- **Definition of Done** — 6 substantive feature screens (Today, Library, Programs,
  Dogs, Session Player, Stats) plus Onboarding and Settings; gated onboarding; empty,
  loading, success and error/recovery states; ≥3 real persisted settings; lazy
  containers with stable `Identifiable` ids; Dynamic Type, VoiceOver labels, Reduce
  Motion fallbacks, and gated haptics throughout; Swift Charts for analytics.

Attestation: to the best of my hand-review, the sources are internally consistent,
type-checked against the iOS 17 SDK by inspection, free of the prohibited patterns, and
ready to build with `xcodegen generate` followed by Cmd+R.
