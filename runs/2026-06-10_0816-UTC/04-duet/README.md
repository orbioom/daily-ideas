# Duet — one phone, two answers

**What it is.** A couples companion built around a daily question you answer *separately on the same phone* — write, pass, reveal — plus a filterable date-idea deck, a shared memories scrapbook, annual occasions, and a weekly three-metric relationship pulse. The job Paired charges ~$15/month for, with the dark patterns removed: no second download, no paywall after question one, no manipulative cancel flow.

**Audience.** Couples who want a small daily ritual together — the proven Paired/Agapé/Lovewick market (~$200k/mo for the leader on ~90k monthly downloads).

## Features

- **Daily question** — 72 curated questions across six decks (Fun, Deep, Memory lane, Future, Gratitude, Spark); the day's card is deterministic (FNV-1a over the date) so it never changes mid-day, skips questions you've already answered until the bank cycles, and Spark can be hidden in Settings.
- **Pass-the-phone ritual** — partner A answers privately → handoff interstitial hides the screen → partner B answers → both reveal at once; partial progress is saved and resumable all day; revealed answers can be starred into Favorites.
- **Streak & stats** — answered-together day streak (today/yesterday tolerant) and lifetime questions shared.
- **Date ideas** — 36 built-in ideas with cost ($/free/$$), setting (home/outside/out), and energy (chill/active) filters; favorite and mark-done states persist; a "Spin" button picks tonight's date from the filtered deck with a highlighted card.
- **Memories** — a month-grouped scrapbook (title, date, note, emoji mood) with full CRUD, editor validation, and delete confirmation.
- **Occasions** — anniversary plus any annual dates, Feb-29-safe roll-forward, days-away countdown in Today, context-menu delete.
- **Pulse** — weekly check-in (connection / communication / fun, 1–5 dot scales + note), once-a-week awareness, success state, three-series Swift Charts trend over the last 8 check-ins, history with averages and delete.
- **Settings** — both names, Spark toggle, haptics; About with the privacy promise.
- Onboarding (3 pages: ritual explainer + names + anniversary, validation, persisted flag), empty states everywhere, light + dark, Dynamic Type, VoiceOver labels/hints, Reduce Motion respected, sparse haptics.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Duet.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**.

*Free signing:* personal team is enough — no entitlements used.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-style: SwiftData models (`Answer`, `Memory`, `CheckIn`, `IdeaMark`, `Occasion`), pure `DuetEngine` (deterministic question-of-day, streaks, occasion roll-forward), content banks compiled in.
- Persistence: SwiftData; names/prefs in `@AppStorage`. Zero network.
- Design language: **Orbioom** (glass cards, ink-gradient buttons, mist background, rare green for "answered together").
- **Monetization:** the couples-app category is proven subscription revenue (Paired ~$200k/mo); Duet's wedge is a one-time "Duet Plus" (more question decks, idea packs, export) — one purchase covers the couple by construction, since it's one phone.
- **Why it can boom:** Paired's own reviews complain that "the only free thing is the daily question," double-charging, and cancel-flow tricks; Duet keeps the entire ritual free, needs no second install (the pass-the-phone mechanic *is* the hook), and is private by architecture.

## Self-review

Every Swift file re-read against the iOS 17 SDK: SwiftData queries, fullScreenCover flows, ViewBuilder switches, Charts multi-series line marks with `chartForegroundStyleScale`, swipe-vs-context-menu placement (swipe actions only in List), and the deterministic question logic traced by hand. Anti-stub grep clean. No force-unwraps, `try!`, or unchecked indexing on user paths.
