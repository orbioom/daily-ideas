# Latest run — 2026-06-14_0613-UTC

**Folder:** `runs/2026-06-14_0613-UTC/`
**Shipped:** 6 production-ready native iOS apps (slots 01–06), all built to the Definition of Done.
174 Swift files total. Each ships a XcodeGen `project.yml` (no hand-written `.xcodeproj`), a real
distinctive 1024² on-brand icon, light + dark first-class, onboarding gated by a persisted flag, a
Settings screen with ≥3 functional persisted prefs, empty/loading/error/success states, SwiftData
persistence, Dynamic Type + VoiceOver + Reduce Motion + opt-out haptics, and an honest one-time Pro
unlock surface (StoreKit not wired in this build; gated by `@AppStorage("isPro")`). Each app was built
by a dedicated agent then audited by the studio lead (no Xcode in the sandbox): anti-stub grep clean,
single sanctioned in-memory-container `try!` per app and no other force ops, no force-unwraps on user
paths, no duplicate type declarations, RootView/Onboarding/Settings/Paywall present, observation wiring
(SwiftData `@Model`+`@Query`/`@Bindable` vs `ObservableObject`+`@StateObject`) consistent per app,
project.yml/Info.plist/asset JSON parsed, and brace/paren balance verified.

## The 6 apps

- **Relish** — *built* — `01-relish` — Personal restaurant ranker. `RankingEngine` runs a binary-search
  pairwise comparison ("which was better?") to insert a new place within its Loved/Liked/Okay sentiment
  tier, then derives a tier-banded 0–10 personal score from rank position; `Restaurant` cascade-owns
  Dishes & Visits. Screens: Your List (search/filter/sort), Add+Compare card flow, Restaurant Detail,
  Want-to-Try wishlist, Taste Stats (Charts). — *Monetization: free up to 15 ranked places; one-time
  Relish Pro ($4.99) for unlimited + full stats + export.* — *Boom: Beli is viral but invite-walled,
  social-only and cloud-bound — a private, offline personal ranker with the same addictive pairwise
  scoring is the version people wish existed.*
- **Quest** — *built* — `02-quest` — Video-game backlog & "what to play next". `BacklogEngine`: status
  pipeline (backlog→playing→completed), %-of-estimate from logged hours, seeded weighted pick-next, and
  a beat-this-year challenge with pace projection; `Game` cascade-owns PlaySessions, generated gradient
  covers. Screens: Library + Now-Playing shelf, Game Detail, slot-machine "What to Play Next", Year-in-
  Games dashboard with platform/genre/monthly Charts. — *Monetization: free up to 20 games; one-time
  Quest Pro ($4.99) unlimited + stats + export.* — *Boom: Backloggd is web/social-only and HowLongToBeat
  is a website — gamers want a private native backlog with a pick-next hook and a yearly challenge; no
  clean iOS incumbent.*
- **Bell** — *built* — `03-bell` — Unguided meditation timer with real bells. In-code `SoundEngine`
  synthesizes bells (additive sine partials × exponential decay → `AVAudioPCMBuffer`) and looping
  ambient beds, all guarded with a silent/haptic fallback; `TimerEngine` is Date-based & relaunch-safe
  (warmup → interval bells → sit). Screens: Today (goal ring + streak), immersive Session Player + mood
  reflection, Presets CRUD, Insights (minutes/time-of-day/streak Charts), History. — *Monetization: free
  timer + 3 presets + bowl bell; one-time Bell Pro ($5.99) for all bells/soundscapes + unlimited presets.*
  — *Boom: Insight Timer/Calm push subscriptions & guided content; experienced meditators beg for a
  beautiful ad-free ONE-TIME unguided timer with real bells & soundscapes.*
- **Jaunt** — *built* — `04-jaunt` — Day-by-day trip itinerary planner. `ItineraryEngine` generates a
  TripDay per calendar day (DST-safe), sorts a day's items by time, and classifies countdown/in-progress/
  past; `Trip` cascade-owns Days→ItineraryItems plus PackItems & Expenses; `BudgetEngine` planned-vs-spent;
  `PackingEngine` with 5 starter templates. Screens: Trips (countdown cards), Trip Overview, Day Itinerary
  timeline, Packing checklist, Budget (Charts). — *Monetization: free up to 2 trips; one-time Jaunt Pro
  ($4.99) unlimited + templates + budget + export.* — *Boom: Wanderlog/TripIt are account-bound,
  ad/subscription, cloud-first — a private offline itinerary + packing + budget in one calm app is what
  the "I just want to plan my trip" traveler wants.*
- **Meeple** — *built* — `05-meeple` — Board-game collection + play logger. `StatsEngine` computes
  totals, most-played, per-player win rates, weight buckets, and the BGG-beloved **H-index** (largest N
  with N games each played ≥ N times); `PlayPicker` does player-count/time/weight eligibility + a seeded
  "Surprise Me"; `BoardGame` cascade-owns Plays→PlayerResults (snapshotted names) alongside a Player
  roster. Screens: Collection, Game Detail (per-game win rates), Log Play, Play Picker, Stats (Charts),
  Players. — *Monetization: free up to 15 games; one-time Meeple Pro ($4.99) unlimited + full stats +
  export.* — *Boom: BG Stats is the paid/clunky incumbent and BGG's app is dated — passionate, spendy
  board gamers love play-logging & stats; a beautiful native logger with a "what to play tonight" hook wins.*
- **Nonet** — *built* — `06-nonet` — Clean, ad-free Sudoku with a real engine. `SudokuSolver` does
  bitmask constraint propagation, a uniqueness `solutionCount(maxToFind:)`, and a human-technique grader
  (naked/hidden singles → locked candidates → pairs); `SudokuGenerator` builds a seeded full solution
  then digs symmetric holes while uniqueness holds and the grade matches the target (attempt/time-capped),
  with a verified fallback bank; daily puzzle is SplitMix64 date-seeded. Screens: Home (daily + streak),
  Board (pencil marks/hints/mistake-check/resume), Stats (Charts), Learn techniques guide, History. —
  *Monetization: free daily + unlimited Easy/Medium; one-time Nonet Pro ($2.99) for Hard/Expert + themes;
  never ads.* — *Boom: top Sudoku apps are ad-stuffed/subscription and reviews beg for clean ad-free
  Sudoku with real hints — Nonet is exactly that, with a proper technique-graded generator.*

## Top recommendation

**Relish** is the strongest "boom" bet: the Beli-style pairwise ranking is a genuinely addictive,
share-worthy mechanic in a huge always-relevant category (where to eat), Beli's social/invite walls and
cloud lock-in leave a wide-open private/offline lane, and the one-time-purchase model fits a tool people
return to weekly. **Nonet** is the safest broad-reach hit (top-charts evergreen puzzle, cleanest engine),
and **Quest** has the most passionate underserved audience (no clean native game-backlog app exists).

## Research signals worth following next run

- The no-repeat registry is now ~165 iOS apps deep — most obvious big markets are taken. Remaining
  *uncovered* proven-demand lanes spotted but not yet built: **mileage / freelance time-tracking (Toggl)**,
  **vinyl/record collection (Discogs)**, **anime/manga tracker (AniList — keep it clearly distinct from
  Reel's TV/movie mechanic)**, **perfume/fragrance collection**, **body-measurements + progress photos**,
  **sleep tracker + smart alarm (Sleep Cycle — higher build risk: background alarm/sensors)**.
- Pattern that keeps winning here: take a viral/top-grossing app that is subscription-walled, social-only,
  cloud-bound, or ad-stuffed, and ship the **private, offline, one-time-purchase, ad-free** native version.
