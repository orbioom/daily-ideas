# Pursuit

## What it is

**Pursuit** is a private, native iOS job-application tracker. One-liner: *your entire job search — applications, interviews, contacts and insights — in one calm, native app that never leaves your device.*

**Problem & audience.** A job search is a chaotic pipeline scattered across spreadsheets, email threads and a dozen career sites. The popular trackers are web-first and lock the useful parts behind a monthly subscription. Pursuit is for anyone job-hunting who wants a fast, offline, one-time-purchase home for the whole process — from a role they've bookmarked to a signed offer.

## Features

- **Pipeline** — a sticky funnel summary card (active count, weekly cadence, response / interview / offer rates) above a `List` grouped by status with pinned section headers and live counts. Horizontal status filter chips, full-text search over company/role/location, swipe to advance a role to its next stage, swipe to withdraw or archive, tap to open detail, and a `+` add sheet. Calm empty and no-results states.
- **Application Detail** — header with company/role, a status menu (each change appends a timeline event), excitement stars, a priority menu, salary range, source, an "open posting" button via `openURL`, and tags. A vertical activity **timeline**, an **Interviews** subsection (add / edit / delete, mode, duration, outcome), a **Contacts** subsection (add / edit / delete, email link), a free-form notes editor, an inline activity-note logger, and a follow-up reminder toggle + date.
- **Upcoming** — scheduled interviews and follow-ups due, grouped into **Today / This Week / Later**, plus a "needs a nudge" section for stale applications (applied N+ days ago with no response). Empty state when the horizon is clear.
- **Insights** (Swift Charts) — weekly-goal progress ring and response/interview/offer stat tiles are always free; the full dashboard (applications-per-week bar with goal rule line, conversion-funnel bars, by-source bars, status donut via `SectorMark`, and average time-to-response) is gated behind Pro. CSV export via `ShareLink`.
- **Onboarding** — a 4-page value walkthrough that sets `hasOnboarded`.
- **Settings** — Appearance picker (System/Light/Dark), Haptics toggle, Weekly application goal stepper, Stale-after-days stepper, Default follow-up days stepper, Default currency picker, tag manager, archived-applications browser, CSV export, Unlock Pro / Restore, and an About section.
- **Pursuit Pro** — a one-time unlock paywall: unlimited applications past the free cap of 15 active, the full Insights dashboard, CSV export, and custom tags & colors.
- **Throughout** — light & dark first-class via `Color.dyn`, Dynamic Type, accessibility labels/values/hints on controls and charts, Reduce-Motion-aware animation, haptics gated by the Haptics setting, success toasts, and a brief seeding loading state. ~36 realistic sample applications (with interviews, contacts and a 10-week activity history) are seeded once on first launch.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Pursuit.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

## Free signing

No paid Apple Developer account is needed. In Xcode → target **Pursuit** → **Signing & Capabilities**, select your personal team (Automatically manage signing). The bundle id is `com.orbioom.pursuit`; change the prefix if it collides. The app uses no entitlements beyond the default sandbox, so a free Apple ID will build and run it on a device or simulator.

## Tech notes

- **iOS 17+, SwiftUI**, `NavigationStack` navigation, `TabView` with four substantive feature screens plus Onboarding, Settings and Paywall.
- **SwiftData** for all primary data (`@Model` `Application`, `Interview`, `Contact`, `ActivityEvent`, `Tag` — every model listed in the `Schema`; `@Query` + `modelContainer`), with cascade relationships and a many-to-many tag relationship. `@AppStorage` holds preferences and the Pro flag. Money is stored as `Decimal`.
- **Pure engine.** `PipelineEngine` computes funnel counts, response/interview/offer rates, average time-to-response, weekly/monthly cadence vs goal, weekly buckets, by-source breakdown, status distribution, stale applications, upcoming interviews and follow-ups due — all guarded against empty input and divide-by-zero.
- **Design language.** Indigo accent (`0x4C5BD4`, matching the `AccentColor` asset), rounded type, soft cards, a hero gradient, and a fully mirrored light/dark palette.
- **Monetization.** One-time **Pursuit Pro** unlock ($4.99, simulated/StoreKit-ready) — unlimited applications past 15 active, full Insights, CSV export and custom tags/colors; the free core is fully usable.
- **Why it can boom.** It beats the subscription, web-first incumbents on the two axes job-seekers care about most under stress: it's instant and native, and it's pay-once-and-private — no account, no recurring fee, no data leaving the phone.

## Self-review

I re-read every Swift source file and verified by hand:

- All imports present and matched to usage (`SwiftUI`, `SwiftData`, `Charts` in Insights only, `Foundation`, `UIKit` in the Haptics helper).
- Every type, initializer, enum case and modifier exists in the iOS 17 SDK and is spelled correctly; no iOS 18-only symbols; `NavigationStack`/`navigationDestination`/sheet bindings and `@Query`/`@Bindable`/`modelContainer` all type-check.
- `.onChange` is never used in its deprecated single-argument form (the app uses custom `Binding` setters and `.task` instead, avoiding the issue entirely); `NavigationView` and `@Previewable` are absent.
- No `try!`, no `as!`, no force-unwrap on user paths, no unchecked array index, no unguarded division (every ratio is guarded; the only divisors are constants or values clamped `>= 1`). The single `fatalError` is the documented-unreachable in-memory `ModelContainer` fallback.
- No `TODO`/`FIXME`/`placeholder`/`lorem`/`stub`/`coming soon`/`not implemented` strings.
- Every `@Model` (`Application`, `Interview`, `Contact`, `ActivityEvent`, `Tag`) is listed in the `Schema([...])`; relationship inverses are declared on exactly one side.
- `ObservableObject` + `@StateObject`/`@EnvironmentObject` is used consistently for app-wide state; it is never mixed with `@Observable`.
- All `.swipeActions` live inside `List` containers; detail-screen interview/contact rows (inside a `ScrollView`) use `.contextMenu` for edit/delete so no action is dead.
- Braces and parentheses balance in every file (verified per file).
- Accessibility (Dynamic Type, labels/values/hints, decorative images hidden, Reduce-Motion fallbacks), haptics gated by `settings.hapticsEnabled`, and a cohesive light/dark theme are applied on every screen.

Attestation: to the best of a careful by-hand review, the sources conform to the stated iOS 17 compile rules and Definition of Done.
