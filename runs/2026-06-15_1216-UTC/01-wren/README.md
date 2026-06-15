# Wren

A calm, grown-up self-care companion. Nurture a small bird by doing real self-care — it grows, thrives, and goes on little journeys.

## What it is

Wren is a self-care companion app for adults who want gentle structure without the noise. You set small self-care goals (Move, Rest, Mind, Connect, Tidy, Nourish), and completing them feeds a little bird companion that levels up, builds energy, and sets off on quiet illustrated journeys that earn collectible postcards and cosmetics.

**The problem:** most self-care pets are dense, cluttered, and childish, and they monetize through daily-pressure dark patterns and steep subscriptions.

**The audience:** grown-ups who find streak-shaming and gamified guilt counterproductive, and who want a warm, low-pressure ritual.

**The incumbent it beats:** Finch (a ~$4M/mo, top-charts self-care pet). Wren wins by being *calm and adult* instead of busy and cute, with a *fair one-time unlock* (~$4.99) instead of a ~$70/yr subscription, and no daily-pressure mechanics — energy decays gently and recovers the moment you show up, never punishing you.

## Features

- **Today (Home)** — an animated Wren drawn entirely with SwiftUI `Canvas` (soft idle breathing/bob that respects Reduce Motion), a derived mood line, an energy ring around the bird, level/XP, a daily-goal progress ring vs. your target, and the day's due goals as a quick-complete checklist with a satisfying fill animation and pebble/energy reward toast. Empty states when nothing is due.
- **Goals** — full CRUD of self-care goals: add / edit / delete / archive / restore, grouped by category with color chips, a schedule editor (every day / pick weekdays / times-per-week), per-goal pebble + energy reward preview, and a "Due today" indicator. Free tier caps active goals at 5 → calm paywall.
- **Journeys** — an active-journey card with progress, a list of journeys to start (energy cost, acts of care, and reward shown; some are Pro), a detail sheet, and a **Collection gallery** of earned postcards/cosmetics drawn as shape-based art. Empty states throughout.
- **Insights** — Swift Charts: 14-day completions bar, mood trend line (from check-ins), category-balance donut (`SectorMark`), a Pro growth/XP area chart, plus streak, longest-streak, and completion-rate stat tiles.
- **Reflections** — a daily mood (1–5, calm drawn faces) + optional note + gratitude check-in (one per day, editable), a scrollable history with swipe-to-delete, and Pro reflection export via the share sheet.
- **Onboarding** — name your companion, pick a couple of starter goals; gated by a persisted `hasOnboarded` flag.
- **Settings** — appearance (System/Light/Dark), haptics toggle, gentle-reminders toggle, daily-goal target stepper, companion rename, equipped-accessory picker, and the Pro unlock.

## Substantive core logic

A pure, testable engine drives everything (no SwiftUI/SwiftData coupling):

- **`CareEngine`** — lazy energy decay computed from days since last tended (clamped 0–100); level/XP thresholds (level *n* needs *n×100* XP, overflow-guarded); 7-day completion rate; companion mood derived from rate + energy (thriving / content / sleepy / needs-you); current + longest streaks from the set of completion days; daily-target progress with guarded division; per-goal reward calculation.
- **`InsightsEngine`** — aggregates completions, check-ins and XP into chart-ready structs (per-day buckets, mood points, category slices, cumulative XP/level over time, completion rate).
- **`CareStore`** — a `@MainActor` wrapper over `ModelContext` that performs all mutations with guards and recoverable thrown errors: completing a goal (double-completion guard, applies pebbles/energy/XP, advances the active journey and finishes it when full), undo, starting/cancelling journeys (energy guard, one active at a time, reward payout into a `Postcard` or cosmetic or pebbles), and one-per-day check-in upsert.

Data is modeled in SwiftData with six `@Model` entities — `Companion`, `SelfCareGoal` (cascade to `GoalCompletion`), `GoalCompletion`, `CheckIn`, `Journey`, `Postcard` — and seeded on first launch with a companion, six starter goals, ~45 days of backdated completions and check-ins (deterministic RNG), and a previously earned postcard so Insights and the collection look alive immediately.

## Run

1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. `open Wren.xcodeproj` — select an iOS 17+ simulator and press **Cmd+R**.

**Free signing:** the project uses no paid capabilities; select your personal team in Signing & Capabilities (or run on the simulator) and it builds and runs with a free Apple ID.

## Tech notes

- **iOS 17+**, SwiftUI 5, MVVM with a pure engine layer.
- **SwiftData** for all primary data (`@Model` / `@Query` / `modelContainer`); `@AppStorage` only for small prefs/flags (`hasOnboarded`, `appearance`, `hapticsEnabled`, `dailyGoalTarget`, `remindersEnabled`, `isPro`).
- **Swift Charts** for Insights (`BarMark`, `LineMark`, `PointMark`, `AreaMark`, `SectorMark`).
- **Design language:** warm, "lived-in" identity — cream/warm-paper light, deep warm-charcoal dark, terracotta-coral accent, soft sage "good" green; rounded + serif typography; a centralized `Theme` with semantic `Color.dyn` tokens so light and dark are first-class. The companion and all postcard art are drawn with `Canvas`/shapes, not bitmaps.
- **Accessibility:** Dynamic Type throughout, VoiceOver labels/values/hints on interactive elements, decorative canvases hidden, and animation gated by Reduce Motion.
- **Monetization:** one-time **Wren Pro** (~$4.99) simulated locally via `@AppStorage("isPro")` with a tailored `PaywallView` (`PaywallReason` copy) — no ads, no subscription, no account; StoreKit 2 wires in for production at the `unlock()`/`restore()` seams.
- **Why it can boom:** it takes a proven, ~$4M/mo category (self-care pets) and removes the two things adults resent most — childish clutter and predatory subscriptions — making the calm, fair, one-time-purchase version the obvious recommendation.

## Self-review

I acted as the compiler (no Xcode in the sandbox) and re-read every Swift file against the iOS 17 SDK:

- Verified all `import`s, types, initializers, enum cases, and modifiers exist and are spelled correctly for iOS 17; no APIs newer than iOS 17 are used (`grep` for iOS 18+ symbols was clean).
- Checked SwiftData wiring: six `@Model` types, a cascade relationship with explicit inverse, `@Query` (incl. `#Predicate` + KeyPath sort) used only in views, `modelContext` passed via environment, and the robust two-tier `ModelContainer` init from the spec.
- Verified `@State`/`@StateObject`/`@Binding`/`@EnvironmentObject`/`@Environment`/`@Query` ownership, sheet/alert bindings, and `NavigationStack`/`TabView` flow; no `NavigationView`, no single-arg `onChange`.
- Confirmed Swift Charts marks/axes type-check.
- **Anti-stub grep** (`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`stub`) — clean.
- **Crash-proofing:** no `try!`, no `as!`, no force-unwraps on user paths; the only `fatalError` is the documented unreachable in-memory-container fallback. Divisions and array indexing are guarded; currency/energy/XP are clamped to non-negative.
- Confirmed all 22 source types are uniquely named and the Definition of Done is met (onboarding gate, empty/loading/error/success states, 5+ persisted Settings prefs, SwiftData persistence, full accessibility, Reduce-Motion-aware animation, gated haptics, light+dark Theme, lazy lists with stable IDs, 50+ seeded records).
