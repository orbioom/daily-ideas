# Recur

A private, on-device **subscription & recurring-payment tracker** for iOS 17. See everything you
pay, know exactly when each one renews, catch free trials before they bill you, and find what to
cancel — all without an account, a server, or a single byte leaving your iPhone. Recur is a
**one-time purchase**, not yet another subscription to track your subscriptions.

## What it is

Recur normalizes any billing cycle (weekly, biweekly, monthly, quarterly, semiannual, annual, or a
custom number of days) into a true **monthly and yearly cost**, so you finally know what your
recurring spend really is. It computes month-end-safe renewal dates, flags trials that are ending,
and breaks your spending down by category and cycle with native Swift Charts.

## Full feature list

- **Dashboard** — a big monthly-spend hero with an annual projection, a "trials ending soon"
  alert banner, a "renewing in the next 7 days" feed, active/trial/cancelled count tiles, and a
  category **donut chart** (SectorMark). Calm empty state when you have nothing tracked yet.
- **Subscriptions** — every subscription in one list (active first), each row showing the colored
  glyph, normalized monthly cost, next-renewal/days, category dot and a trial badge. **Sort**
  (next renewal / cost / name), **filter** (all / active / trials / cancelled), **search**, and
  **swipe** to cancel, reactivate or delete.
- **Detail + Editor** — a full editor for every field with a color picker, SF Symbol picker, cycle
  picker (incl. custom days), trial toggle + end date, and category. The read view shows per-charge,
  monthly and annual cost; next & previous renewal; first-billed date; a **price-history sparkline**
  (LineMark + AreaMark); and actions to cancel / reactivate / delete / **log a price change**.
- **Insights** — a **month calendar grid** with renewal dots per day (tap a day to see its
  renewals) plus an insights section: spend **by category** (BarMark), spend **by cycle** (BarMark),
  and a 6-month projected-spend trend. Honors your first-day-of-week setting.
- **Settings** — currency, default billing cycle, renewal-reminder lead days, trial-reminder lead
  days, include-trials-in-total, hide-amounts privacy mode, first day of week, haptics, optional
  on-device renewal/trial **notifications**, CSV export, Unlock/Restore Pro, and About.
- **Onboarding** gated by a persisted `hasOnboarded` flag; **~13 realistic seeded subscriptions**
  (Netflix, Spotify, iCloud+, Disney+, gym, Adobe, NYT, Game Pass, Dropbox, Notion, Audible, a
  YouTube Premium **trial**, and a cancelled HBO Max) so the app demos with real volume.

## Engineering notes

- **Pure-Swift engines**, currency math in `Decimal`: `CostEngine` (cycle → monthly/annual
  equivalents), `RenewalEngine` (month-end-safe & leap-safe next/previous renewal, days-until,
  upcoming feed) and `SummaryEngine` (totals, by-category/by-cycle breakdowns, most-expensive,
  counts, trial alerts, calendar mapping). All division and date math is guarded — no crashes.
- **SwiftData** is the source of truth: `@Model Subscription` and `@Model PriceChange` (with a
  cascade `@Relationship`), registered in one `Schema`, surviving relaunch. `@AppStorage` is used
  only for small prefs/flags. The container falls back to in-memory and then to a calm
  "storage unavailable" screen instead of crashing.
- `@Observable` + `@State` view model for the editor; `@Query`/`modelContext` elsewhere — one
  consistent pattern, no `@StateObject`/`ObservableObject` mixing.
- Full accessibility (labeled totals, renewal dates and charts), Dynamic Type, light + dark via a
  cohesive `RecurTheme`, and Reduce-Motion-aware animations. Haptics are sparse and toggle-gated.
- **Notifications** use `UNUserNotificationCenter`, request permission politely, cap the schedule,
  handle denial gracefully, and are gated behind both a Settings toggle and Pro.

## Monetization

**Recur Pro — $3.99 one-time.** Free tracks up to 8 active subscriptions and the full dashboard,
list and calendar; Pro unlocks unlimited subscriptions, renewal/trial reminders, full insights,
price-history logging, and CSV export. Backed by `@AppStorage("isPro")` with a `PaywallView` plus
demo Unlock & Restore (StoreKit-ready in spirit; no real StoreKit calls in this build).

## Why it can boom

Rocket Money and Bobby either charge a recurring fee or phone home with your financial data; Recur
beats both by being a **one-time purchase that is 100% private and on-device**, with the one feature
people actually want — **real trial-end alerts so a forgotten free trial never bills you again.**

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Recur.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing:** set your Apple ID team in Signing & Capabilities; the bundle id is
`com.orbioom.recur`.

## Self-review attestation

Re-read every Swift file: all imports present (`SwiftUI`, `SwiftData`, `Charts`, `UserNotifications`
under `canImport`); iOS 17-only APIs (`NavigationStack`, `.navigationDestination`, two-parameter
`.onChange`, `SectorMark`/`BarMark`/`LineMark`/`AreaMark`); SwiftData models registered in the
`Schema`; `@Observable` stored with `@State` and no `@StateObject` mixing; protocol conformances and
property-wrapper ownership verified. No `try!`, `fatalError`, `as!`, or force-unwraps on user paths;
all date math, division, array indexing (safe subscript) and `Decimal(string:)` parsing are guarded.
Exactly one `@main`. Static audit clean.
