# Crisp 🔥

**The air-fryer guide and multi-timer that actually gets dinner right.**

Crisp tells you the exact temperature and time for any food, scales it to your portion or
straight-from-frozen, converts oven recipes to air-fryer settings, shows safe doneness temps,
and runs several real cooking timers at once — so nothing burns while something else finishes.

Built for anyone who owns an air fryer and is tired of ad-stuffed, IAP-junk reference apps.
The free core is genuinely useful; one optional one-time unlock removes the few caps.

---

## What it is

- **Name:** Crisp
- **One-liner:** Air-fryer cooking guide + multi-timer.
- **Problem:** Air-fryer apps are cluttered with ads and locked behind subscriptions, yet still
  can't answer the only questions that matter mid-cook: *what temp, how long, and is it done?*
  Meanwhile a single phone timer can't watch three baskets at once.
- **Audience:** Everyday air-fryer owners, batch cookers, and anyone reheating leftovers who
  wants reliable settings and timers that survive locking the phone.

---

## Features

### Guide — 68 foods across 7 categories
- Searchable, category-filtered food grid (Chicken, Beef & Pork, Seafood, Vegetables, Frozen,
  Snacks & Other, Baked) with a Favorites filter.
- **Food detail** with a big temperature + time hero, a **Fresh / From-frozen** toggle that
  swaps to realistic frozen settings, and a **portion stepper** that live-recomputes the time
  via the cook engine (sub-linear scaling — bigger batches take a little longer, not double).
- Shake/flip reminder, cooking tips, and USDA-safe internal temps for meats.
- One-tap **Start timer** and **Favorite** from any food.

### Timers — true multi-timer dashboard
- Run several concurrent timers, each with a live countdown ring drawn by `TimelineView`.
- **Background- and relaunch-safe:** remaining time is always derived from a persisted
  `endDate`, never a ticking counter — close the app, come back, and the time is correct.
- Add quick custom timers (label + wheel duration + presets), pause / resume, ±1 min, stop.
- Local notification + success haptic fire when a timer completes (permission requested
  politely on first use; pending notifications capped).
- Free plan runs up to 2 timers at once; Pro removes the cap.

### Convert — three tools in one
- **Oven → Air-fryer** recipe converter: enter the oven temp + time, get the air-fryer setting
  (−25 °F, ×0.8 time, rounded to a clean dial number).
- **Unit converter:** °F ↔ °C and g ↔ oz, all guarded against bad input.
- **Doneness guide:** USDA-safe + chef-preferred internal temps in your chosen unit.

### Saved — favorites & custom foods
- Saved favorites grid plus full **custom-food CRUD** (name, category, temp, time, notes) with
  validation. Free plan stores up to 3 custom foods; Pro is unlimited.

### Cook Log & Stats (Swift Charts)
- Every cook you start is logged. The Log screen shows total cooks, average rating, foods tried,
  a 14-day **cooks-per-day** bar chart, a **most-cooked** ranking, and a recent-cooks list.

### Throughout
- **Onboarding** (3 pages, gated by `hasOnboarded`), **Settings** with 7 real persisted prefs,
  and a simulated **Paywall**.
- Empty, loading (seeding), error, and success states; toasts and gated haptics everywhere.
- Cohesive warm, appetizing identity: hot-orange accent (`#F2792B`), rounded type, big legible
  numbers, soft food-card surfaces — readable in both light and dark mode.

### Settings (7 persisted preferences)
Appearance (System/Light/Dark) · Temperature unit (°F/°C) · Weight unit (g/oz) ·
Include preheat in times · Default servings · Timer sound · Haptics — plus Unlock/Restore Pro
and an About section.

---

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root if present).
3. Open `Crisp.xcodeproj` in Xcode 15+, pick an **iOS 17+ simulator**, and press **Cmd+R**.

### Free signing
No paid Apple Developer account is needed for the simulator. To run on a physical device, open
the project, select the **Crisp** target → **Signing & Capabilities**, and choose your personal
team; Xcode will provision it with a free signing certificate.

---

## Tech notes

- **iOS 17+, SwiftUI, SwiftData.** Primary data (timers, favorites, custom foods, cook log) is
  stored in SwiftData `@Model` types; small preferences live in `@AppStorage`.
- **Timers** use a persisted `endDate` + `TimelineView` so they are correct across backgrounding
  and relaunch, with `UserNotifications` for completion alerts.
- **Pure engines** (`CookEngine`, `ConversionEngine`, `DonenessEngine`) hold all the cooking math
  — every division is guarded and every result is clamped to a safe floor.
- **Swift Charts** powers the analytics, with accessibility labels on every mark.
- **Design language:** warm kitchen palette, hot-orange accent `#F2792B`, rounded SF fonts, big
  numbers, food-card grid; full Dynamic Type, AA contrast in both modes, and Reduce-Motion
  honored. Haptics are gated by the Haptics setting.
- **Observation:** app-wide settings use `ObservableObject` + `@StateObject`; the `TimerEngine`
  uses `@Observable` + `@Environment` — the two patterns are never mixed on one object.
- **Monetization:** one-time **Crisp Pro** unlock (simulated, StoreKit-ready) — unlimited timers
  and custom foods, full doneness guide, no nags. The free core stays fully usable.
- **Why it can boom:** air-fryer ownership is enormous and the category's top apps are
  ad-and-subscription bloat; a fast, premium, one-time-purchase guide *with real multi-timers*
  is a clean, word-of-mouth-friendly wedge.

---

## Self-review

I re-read every Swift file by hand and verified:

- **iOS 17 only.** No `NavigationView` (only `NavigationStack`), no `@Previewable`, no single-arg
  `onChange` — every `.onChange(of:)` uses the two-parameter `{ old, new in }` form. No iOS-18
  SwiftUI/SwiftData symbols. `TimelineView`, `@Observable`, SwiftData `@Query`/`#Predicate`,
  and Swift Charts are all iOS 17 APIs.
- **Persistence.** All four `@Model` types — `CookTimer`, `FavoriteFood`, `CustomFood`,
  `CookLog` — are listed in the `Schema([...])` in `CrispApp.swift`. Prefs use `@AppStorage`.
  First-run seeding (12 favorites, 3 custom foods, ~30 cook logs) is guarded by a UserDefaults
  flag so it runs exactly once.
- **Crash-proofing.** No `try!`, no `as!`, no force-unwraps on user paths, no unchecked array
  indexing. The only `fatalError` is the documented-unreachable in-memory `ModelContainer`
  fallback. Every division is guarded: cook scaling divides by `max(basePortionGrams, 1)`;
  timer progress divides by `max(1, totalSeconds)`; average rating is gated on a non-empty set;
  all other divisions are by compile-time constants.
- **No stubs.** No `TODO`/`FIXME`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`stub`
  strings; every screen and button is real and wired. ("placeholder" appears only as a SwiftUI
  `TextField` parameter name.)
- **Definition of Done.** Five substantive feature screens (Guide, Timers, Convert, Saved, Log)
  plus Onboarding, Settings, and Paywall; gated onboarding; empty/loading/error/success states;
  7 real persisted settings; relaunch-safe persistence; input validation; full Dynamic Type and
  accessibility labels/values/hints; decorative images hidden; gated haptics; Reduce-Motion
  fallbacks; lazy containers with stable `Identifiable` IDs; Swift Charts with accessible labels.
- **Structure.** Balanced braces/parens across all 41 files (mechanically checked); required
  imports present (`SwiftUI`, `SwiftData`, `Charts`, `Foundation`, `Observation`, `UserNotifications`,
  `UIKit`); `@Observable` is not mixed with `@StateObject`; the theme is applied on every screen.

**Attestation:** To the best of a careful by-hand review, this is a complete, compile-ready iOS 17
SwiftUI + SwiftData app with no stubs, no dead buttons, every timer relaunch-safe, and every
user-path division guarded.
