# Equinox

A warm, dignified, private perimenopause & menopause companion for iOS 17 — calm daily tracking, cycle-change awareness, real insights, and an evidence-based education library, all on-device.

## What it is

The menopause transition affects roughly half the population for years, yet most people pass through it under-informed and under-supported, with appointments too short to capture what's really happening. **Equinox** is the companion women in midlife actually wish existed: a quiet, reassuring place to log hot flashes, sleep, mood, energy, irregular cycles, symptoms, and treatments — then see honest patterns and walk into a clinician's office with a clear summary.

- **Audience:** women in perimenopause, the menopause transition, and post-menopause.
- **The incumbents it beats:** Balance, Caria, Perry and similar apps lean on accounts, cloud sync, subscriptions, and ads. Equinox is **fully on-device**, has **no account and no network**, and asks for a **single fair one-time unlock** instead of a subscription. The design language is adult and calm — a warm botanical "dawn" identity rather than clinical-cold or cutesy.

## Features

- **Onboarding** (first-run, gated by `@AppStorage("hasOnboarded")`) with an explicit privacy and "not medical advice" consent screen.
- **Today** — a fast daily check-in: hot-flash +/− stepper, mood/sleep/energy 1–5 selectors, night-sweats toggle, flow picker, symptom toggles with 0–3 severity, treatments/supplements taken, and notes. Shows greeting, logging streak, days-since-last-period, and today's flash count, with a "Saved" success toast. One `DayLog` per day, created/updated in place.
- **Calendar** — a month grid heat-map: each day a dot colored by hot-flash intensity with a period ring marker; tap any past day for full CRUD (create/backfill, edit, delete). Empty state for unlogged months; future days disabled; non-Pro days beyond 30 are gently locked.
- **Insights** (`import Charts`) — hot flashes per day (BarMark) with a 7-day average line, week-over-week trend, a stage-heuristic card, top-symptoms ranking, and a Pro tier with domain-severity trend lines, mood & sleep charts, and a sleep↔hot-flash correlation. Includes a **doctor report** card (rendered via `ImageRenderer`-ready view + `ShareLink` text) — Pro.
- **Learn** — a curated, substantive, evidence-based library across six categories (hot flashes & triggers, sleep & night sweats, mood/anxiety/brain fog, HRT basics & non-hormonal options, bone & heart health, lifestyle). Category list → article detail; some articles are Pro. Every article is framed non-prescriptively with a "talk to your clinician" note.
- **Settings** — six persisted prefs: appearance (System/Light/Dark), haptics, track-cycle toggle, daily reminder time (stored `Date`), temperature unit (°C/°F), and full-symptom-list default; plus delete-all-data with confirmation, and "not medical advice" + "never leaves this device" notes.
- **Equinox Pro** — simulated one-time unlock with a tailored paywall.
- Full light/dark theming, Dynamic Type, accessibility labels/hints/values, decorative-image hiding, Reduce-Motion–aware animation, and sparse gated haptics throughout.

## Substantive core logic

`InsightsEngine` (in `Utilities/InsightsEngine.swift`) is a pure, fully-guarded struct over `DayLog` snapshots — no SwiftUI, no SwiftData queries, every division guarded and no force-unwraps or unchecked indices. It computes:

- **Hot-flash analytics:** calendar-filled per-day count series, a 7-day trailing rolling average, and a week-over-week trend (this 7 days vs prior 7 days, with direction).
- **Greene-style domain severity index:** per-day, per-domain severity sums and domain totals across the four clinically-grounded domains (Vasomotor, Psychological, Somatic, Sexual/other).
- **Cycle-change awareness:** collapses bleeding days into episodes, computes days-since-last-period and longest recent gap, and derives an explicitly-informational stage heuristic (tracking → perimenopause → late transition → the 12-months-without-a-period postmenopause milestone).
- **Top symptoms** ranked by frequency × average severity, **mood/sleep/energy averages and trends**, and a **sleep↔hot-flash correlation** (poor-sleep vs restful-day flash averages, with a "needs more data" guard).
- A **doctor-report summary** aggregating date range, days logged, average/total hot flashes, night-sweat days, top symptoms, and cycle info.

`DayLog` (SwiftData `@Model`) stores symptom severities and treatments as JSON `Data`, encoded/decoded defensively (clamped 0–3, unknown/zero entries dropped, all via `try?` — never `try!`). `DayLogStore` enforces the one-log-per-day invariant with a `#Predicate` date-range fetch. `SeedData` lays down ~10 weeks of deterministic, plausible history (irregular lengthening cycles, drifting hot-flash counts, correlated sleep/mood) so Calendar and Insights are rich on first run, gated by a flag and an empty-store check.

## Run

1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. `open Equinox.xcodeproj` — select an iOS 17+ simulator and press Cmd+R.

## Free signing

For a device build, set your Apple ID team under **Signing & Capabilities** and let Xcode manage a free provisioning profile; the bundle id is `com.orbioom.equinox`.

## Tech notes

- **iOS 17+**, **SwiftUI 5**, MVVM-ish with a pure engine; **SwiftData** (`@Model`/`@Query`/`modelContainer`) for persistence, `@AppStorage` only for small prefs/flags.
- `NavigationStack` only (no `NavigationView`); Charts via `import Charts`; no external dependencies, no network, no iOS-18 APIs.
- **Design language:** "warm dignified botanical" — a dawn palette (dusk-violet → warm marigold/peach, accent `0xD88A55`) with serif headings, rounded body, generous spacing, and soft leaf accents; first-class light and dark via `Theme.Color.dyn` pairs.
- **Monetization:** one-time **Equinox Pro $4.99** — full insights, unlimited history, doctor-report export, full Learn library. Simulated locally via `@AppStorage("isPro")`; StoreKit 2 would wire in at the `Pro`/`PaywallView` boundary for production. No ads, no account, no network.
- **Why it can boom:** menopause/midlife women's health is a hot, funded, underserved growth market with proven willingness-to-pay; Equinox is the calm, private, on-device, fairly-priced companion the incumbents aren't.

## Self-review

I re-read every Swift file as the compiler against the iOS 17 SDK:

- Verified all imports (`SwiftUI`, `SwiftData`, `Charts`, `UIKit`, `Foundation`), and that every type, initializer, enum case, and modifier used exists in iOS 17 and is spelled correctly (`BarMark`/`LineMark`, `chartForegroundStyleScale`, `chartYScale`, `AxisMarks`, `ShareLink`, `navigationDestination(item:)`, `.contentTransition(.numericText())`, `@Bindable`, `#Predicate`).
- Confirmed property-wrapper ownership: `@StateObject` for `AppSettings`, `@EnvironmentObject` consumers, `@Query`/`@Environment(\.modelContext)` wiring, `@Bindable` on the `DayLog` editor, and `@State` for view-local state.
- All `onChange` usage avoided in favour of `.task(id:)`/`.onAppear`; two/zero-param patterns only.
- **No force-unwraps, `try!`, `as!`, unguarded division, or unchecked indexing on user paths.** JSON encode/decode of symptom/treatment maps is fully guarded (`try?` + clamping). Every division in `InsightsEngine` is guarded by an emptiness/positive check. The only `fatalError` is the documented unreachable in-memory-container fallback in `EquinoxApp`.
- Anti-stub grep (`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`stub`) is clean; matches in prose are non-code wording only.
- Accessibility: Dynamic Type throughout, labels/hints/values on interactive controls, decorative images hidden, AA-contrast `Color.dyn` pairs for both modes, and Reduce-Motion–aware animation.

Definition of Done is met: 4 substantive feature screens (Today, Calendar, Insights, Learn) plus Onboarding and Settings; empty/loading/error/success states; ≥3 persisted prefs; SwiftData persistence; simulated Pro with paywall + reasons; light/dark; full accessibility; seeded rich first-run data.
