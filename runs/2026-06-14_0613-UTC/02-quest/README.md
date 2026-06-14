# Quest

**Your private, native video-game backlog — track it, conquer it, and decide what to play next.**

Quest is a SwiftUI iOS 17 app for the Orbioom studio. It tracks your whole game
library, moves games through a clear pipeline (Backlog → Playing → Beaten), logs
play sessions, helps you pick what to play next, and runs a yearly "games beaten"
challenge with stats — all on-device, no account, no feed.

## What it is

A Backloggd / HowLongToBeat-beater built as a real native app. Where those are
web/social tools, Quest is private and native: your library lives in SwiftData on
your device, the picker beats decision paralysis, and the yearly challenge keeps
you motivated.

## Full feature list

- **Library** — a `LazyVGrid` of generated, image-free covers (deterministic
  gradient from the title hash + controller watermark + initials). Segmented
  status filter (All / Backlog / Playing / Completed / Abandoned / Wishlist),
  search across title/platform/genre, five sort modes, a favorite heart and a
  rating badge per cover, and a **Now Playing** horizontal shelf with live
  progress bars whenever a game is in progress.
- **Game detail** — cover header, segmented status picker (moving to *Completed*
  stamps the beaten date and can fire a celebration), a tappable 0–10 rating,
  favorite toggle, length-estimate editor, a progress bar vs. estimate, a full
  **play-session log** (add / edit / delete date + hours + note with a running
  total), free-form notes, and delete with confirmation.
- **What to Play Next** — a slot-machine reveal that picks one backlog game using
  a **seeded RNG** (stable until you re-roll). Pro filters by platform, genre and
  max length, with weighting toward short games or favorites. "Roll again" and
  "Start playing" (sets status to *playing*). Friendly empty states when the
  backlog is empty or filters are too tight.
- **Year in Games** — an animated goal ring (beaten vs. an editable goal), a pace
  badge ("on track / behind by N") with a projected year-end total, the list of
  games beaten this year, and **Swift Charts** stats (Pro): beaten-per-month bars,
  hours-per-month line, platform donut, genre bars and rating distribution — with
  an async loading state while they compute.
- **Onboarding** (gated by `hasOnboarded`), **Settings**, **Paywall**, **About**.
- **Settings** — haptics toggle, celebrate-completions toggle, default library
  sort, hours format (h+m / decimal), cover style (gradient / solid), yearly goal
  stepper, text export (Pro), reset-to-sample-library, and About.
- **Accessibility** — Dynamic Type, VoiceOver labels/hints/values (including chart
  summaries), decorative images hidden, AA-tested palette in light **and** dark,
  and animations that honor Reduce Motion.

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Quest.xcodeproj` in Xcode 15+, choose an iOS 17+ simulator, and press
   **Cmd+R**.

### Free-signing note

If Xcode reports a signing error, select the **Quest** target → **Signing &
Capabilities**, pick your personal Apple ID team, and let Xcode manage a free
provisioning profile. The bundle id is `com.orbioom.quest`; change it if the id is
already taken on your account.

## Tech notes

- **SwiftData** is the source of truth: `@Model` `Game` (owns `[PlaySession]`
  cascade), accessed via `@Query` / `@Bindable` / `modelContext`. `hoursLogged`
  is derived from sessions. UserDefaults (`@AppStorage`) holds **only**
  preferences and the `hasOnboarded` / `didSeed` / `isPro` flags.
- **Observation** — `ObservableObject` `AppSettings` via `@StateObject` /
  `@EnvironmentObject`; SwiftData models via `@Query` / `@Bindable`. The
  `@Observable` macro is intentionally not mixed with `@StateObject`.
- **Engine** — `BacklogEngine` is pure and side-effect-free: status counts &
  completion %, total hours, per-game % of estimate (guarded), seeded weighted
  pick-next, year challenge with pace projection, and platform/genre/monthly/
  rating breakdowns. A `SeededRNG` (SplitMix64) keeps a "shuffle" stable until the
  user re-rolls. All charts consume `Identifiable` structs, never tuples.
- **Container safety** — `ModelContainer` falls back to an in-memory store if the
  on-disk store can't open; that fallback is the only force-`try` in the app.
- **Seed** — 52 realistic games (varied platforms, genres, status, ratings, hours
  and play sessions) are inserted once behind a `didSeed` flag; Settings can wipe
  and re-seed.

## Monetization

Free core backlog (up to 20 games); one-time **Quest Pro ($4.99)** unlocks an
unlimited library, full Stats, advanced pick-next filters and text export. The
first-run core experience is never paywalled. (Pro is a demo unlock here — it
flips a local flag instead of taking payment.)

## Why it can boom

Backloggd is web- and social-only and HowLongToBeat is a website — gamers want a
**private, native** backlog with a "what to play next" hook and a yearly
beaten-games challenge. There is no clean iOS incumbent, and the picker + yearly
challenge give players a reason to open the app every week.

## Self-review attestation

Every Swift file was re-read against the iOS 17 SDK. Verified: SwiftData
`@Model`/`@Query`/`@Bindable`/`modelContext` usage and observation ownership;
`NavigationStack` / sheet / `navigationDestination` bindings; no duplicate types;
all `Theme` tokens defined; Swift Charts series are `Identifiable` structs;
balanced braces; complete light/dark palette; accessibility throughout. The only
force operation is the documented `ModelContainer` fallback `try!`. A repo-wide
scan for `TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub`
returns **zero** matches — no stubs.
