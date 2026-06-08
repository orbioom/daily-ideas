# Lustre — skincare routine & shelf

**Lustre keeps your skincare routine, your product shelf, and your skin in one calm place — and warns you before products expire.** For skincare enthusiasts who want a beautiful routine tracker and shelf manager without the social-feed noise or paywalled basics.

## What it is
A native iOS skincare companion. Build morning/evening/weekly routines from products on your shelf, check them off daily (with streaks and adherence), track period-after-opening freshness, and keep a photo-free skin journal.

## Features
- **Today** — switch between Morning/Evening/Weekly, check off each step (state persisted per day), a completion ring, streak, an expiry banner, and a one-tap skin check-in.
- **Routines** — build and reorder the steps of each routine; steps reference shelf products or custom actions, with optional instructions.
- **Shelf** — your products with category, freshness status (unopened / good / use-soon / expired) computed from opened date + period-after-opening, shelf value, and "needs attention" surfacing.
- **Journal** — a 30-day skin-feeling trend (Swift Charts), 14-day routine adherence bars per routine, most-noted concerns, and a list of check-ins (1–5 rating + concern tags + note).
- **Settings** — currency, expiry warning window (wired into shelf status), haptics, full reset. All persisted.
- Onboarding (optional sample shelf, persisted flag); empty/loading/success states; Dynamic Type + VoiceOver; light/dark; Reduce Motion; sparse haptics.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Lustre.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: personal team, free Apple ID, simulator or device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `SkincareEngine` (PAO expiry states, shelf stats, routine completion, streaks, adherence, skin trend, concern frequency). **SwiftData** for `Product`, `RoutineStep` (relationship to product, stable UUID key), `RoutineLog` (per-day completed step UUIDs), `SkinLog`; small prefs in `UserDefaults`. Swift Charts for trends. Design language: **Orbioom** (soft mauve accent). No external dependencies; seeded shelf, routines, and history.
- **Monetization:** freemium — routines + shelf free; Pro (subscription) for unlimited products, expiry notifications, multiple routine variants, and ingredient/conflict insights. Beauty/skincare apps convert well and skew toward high engagement.
- **Why it can boom:** skincare is a massive, high-spend consumer category; the popular trackers are either social-feed apps or paywall the basics. Lustre is private, fast, genuinely useful (real PAO expiry + adherence), and beautifully calm.

## Self-review
Re-read every file. Verified imports, iOS 17 SDK usage, SwiftData relationship (`Product.steps` inverse `RoutineStep.product`) and `[String]` properties, per-day `RoutineLog` toggling, `EditButton`-driven reorder with `onMove`/`onDelete`, Charts (`LineMark`). Expiry/streak/adherence math checked by hand; `soonDays` pref wired into shelf status; divisions guarded. Anti-stub grep clean. No `try!`/force-unwrap on user paths; only the documented container-fallback `fatalError`.
