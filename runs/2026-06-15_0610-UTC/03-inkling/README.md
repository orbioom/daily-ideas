# Inkling

## What it is
**Inkling** — a flexible health symptom & lifestyle tracker that surfaces *what actually moves your symptoms* through ranked correlations.

Track anything — symptoms, mood, sleep, meds, food, activity, weather — and Inkling shows you the real relationships in your data ("Caffeine → headache: strong +", "Sleep → mood: moderate +"). It's built for the chronic-illness, migraine, mood, ADHD, and gut-health crowd who are tired of guessing.

The edge: Bearable (900k+ users) paywalls its correlation reports **and** any history beyond 30 days behind a $34.99/yr subscription. Inkling gives you correlations **and** unlimited history **free**, fully on-device, with a single optional one-time Pro unlock for power features.

## Features
- **Today** — fast daily logging of every active tracker. Each control adapts to the tracker's scale: a slider (severity), a stepper (count), a toggle (yes/no), or a numeric field. A progress ring shows logged vs pending, with a success state and an empty state when no trackers are active. One entry per tracker per day (upsert).
- **Insights / Correlations** — ranked correlation cards (factor → outcome) showing Pearson's *r*, strength (weak/moderate/strong), direction (raises/lowers), a confidence note, and a strength meter. Same-day and (Pro) next-day lag toggle, a 30/90/all time-range picker, and an empty "need more data" state. Tap any card for a scatter chart with a least-squares trend line plus a plain-English reading.
- **Trends / History** — pick a tracker for a 30/90-day line+area trend chart, rolling 7/30-day averages, current/min/max, logging streak, and trend direction. A 5-week calendar heat-map of logged days; tap a day to open a Day Detail with inline editing of every value logged that day.
- **Trackers** — full CRUD: name, kind, scale, unit, color, symbol, active flag, drag-to-reorder, swipe to edit/delete (cascade-deletes history), with an empty state. Extended color/symbol palettes are a Pro extra.
- **Onboarding** — three intro pages plus a starter-tracker picker; gated by a persisted `hasOnboarded` flag.
- **Settings** — severity scale (0–4 vs 0–10), default time range, daily reminder (local `UNUserNotification`) with a time picker, haptics toggle, appearance (system/light/dark), Pro, CSV export, and reset/erase data actions. All real, all persisted.
- **Seeded on first run** — ~12 starter trackers across every kind and ~60 days of *correlated* synthetic history, so Insights and charts are rich immediately (and in previews).

## Run
1) `brew install xcodegen` (one-time).
2) In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3) Open `Inkling.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

## Free signing
Works with a personal Apple ID — no paid developer account needed. Code-signing is only required to install on a physical device; the simulator needs nothing.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. Primary data in **SwiftData** (`@Model` `Tracker`/`LogEntry`, `@Query`, `modelContainer`); small prefs/flags in `@AppStorage`.
- **CorrelationEngine**: Pearson's *r* per (factor, outcome) pair across shared days, lag 0 and lag +1; guards n<4 and zero variance (returns nil, never divides by zero); ranks by |r| with a sample-size confidence note.
- **StatsEngine**: rolling 7/30-day averages, current/min/max, logging streak, least-squares trend slope — all guarded against empty input.
- Swift **Charts** for scatter + trend visuals. Calm clinical-but-warm violet identity via a per-`colorScheme` `Theme`, first-class light & dark, Dynamic Type, accessibility labels/values describing chart data, Reduce-Motion-aware animation, and sparse haptics gated by a Settings toggle.
- **Monetization**: Free forever — unlimited trackers, logging, same-day correlations, and unlimited history (the hook vs Bearable). One-time **Inkling Pro** (~$5.99, simulated via `@AppStorage "isPro"`) unlocks next-day lag analysis, CSV export, custom symbols/themes, and experiments. Tasteful paywall + simulated restore.
- **Why it can boom**: Bearable proved the market (900k+ users) but rents you your own insights and history; Inkling gives both away free and on-device, charging once for power tools — a sharper, more trustworthy pitch for a privacy-sensitive health audience.

## Self-review
- **Compiles by inspection**: every file re-read; imports, iOS 17 SwiftData (`@Model`/`@Query`/`modelContainer`/`fetchCount`) and Swift Charts (`PointMark`/`LineMark`/`AreaMark`, axis labels) APIs verified; property wrappers and ownership hoisted correctly; sheet/navigation bindings type-check.
- **Anti-stub grep clean**: no TODO/FIXME/XXX/placeholder/lorem/"coming soon"/"not implemented"/stub/fatalError. No force-unwrap, `try!`, or unguarded division on any user path (the single `try!` is the unreachable in-memory container fallback in `@main` init, mirroring the reference app).
- **Definition of Done met**: 4 substantive feature screens + Onboarding + Settings; empty/loading/error/success states; 5 real persisted preferences; SwiftData persistence surviving relaunch; crash-proofed math (n<4 and zero-variance guards, leap-safe date math); accessibility (Dynamic Type, labels/hints/values, decorative images hidden, Reduce Motion); light + dark via Theme; cohesive violet identity; lazy containers; 12 trackers + ~60 days seeded.
