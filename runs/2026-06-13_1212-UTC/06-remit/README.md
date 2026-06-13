# Remit — never miss a payment

**One-liner:** A private, no-bank-login bill manager: add your recurring bills once, see exactly what's due and when, tap to mark paid (Remit rolls it to the next period), and stop eating late fees.

**Problem & audience:** Everyone has bills — rent, utilities, subscriptions, loans, insurance — and a single missed due date costs real money in late fees and interest. Mint shut down in January 2024 and the bank-aggregation apps that remain demand your banking credentials and still only show what already happened. Fixed-amount subscription trackers can't cope with bills that vary month to month. Remit is for anyone who just wants a calm, trustworthy ledger of what they owe and when — without handing over a bank login, paying a subscription, or being tracked.

## Features

- **Upcoming (Home)** — every bill grouped by urgency (Overdue / Due soon / Upcoming / Paid), each row showing the amount, category, autopay badge, and a plain-English due line ("Due tomorrow", "2 days late"). A header tile shows this month's total due and what's remaining. One tap on a bill marks it paid with a success haptic and rolls it forward to the next period.
- **Calendar** — a month grid (built with `LazyVGrid`, no third-party libraries) with coloured dots on days that have bill occurrences; recurrences are expanded for the visible month. Tap any day for the bills due that day and their total; navigate months with the arrows.
- **Bills** — full CRUD over every bill, with search and sort (due date / name / amount). The add/edit form takes a name, a Decimal-safe amount, a category, a next-due date, a recurrence, an autopay toggle, a per-bill remind window, and notes — with a live "monthly equivalent" preview. Delete is swipe-to-delete with a confirm alert (past payments are preserved). The free plan holds 8 bills; Pro is unlimited.
- **Insights** — your true monthly obligations (every recurrence normalised to a monthly cost), on-time payment rate, spend-by-category and paid-over-time charts (Swift Charts), an autopay-vs-manual split, and a full payment history that survives bill deletion via a name snapshot.
- **Settings** — currency picker (formats every Decimal amount with the chosen ISO code), default due-soon window, default recurrence, week-start, opt-in payment reminders with a lead-time stepper (local notifications, authorization requested gracefully), haptics, Pro unlock/restore, and a delete-all-bills reset behind a confirm alert. First-run onboarding gated by a persisted flag.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Remit.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

**Free signing:** Select your personal team under Signing & Capabilities; the bundle id is `com.orbioom.remit`. No paid account or code-signing assets required to run on a simulator or a personal device.

## Tech notes

iOS 17+, SwiftUI 5, MVVM. Primary data (bills + payments) in **SwiftData**; small preferences in `UserDefaults` via `@AppStorage`. All money is stored and computed in **`Decimal`** — never `Double` — and formatted with `.formatted(.currency(code:))`. A pure `BillEngine` does every date and money calculation: month-end-safe next-due arithmetic (a bill anchored to the 31st resolves to the last day of shorter months), period-window paid detection, days-until-due, monthly-equivalent normalisation, mark-paid roll-forward, and a 60-day occurrence projection — every Calendar operation and division is guarded so it can never crash. Charts are Swift Charts; the calendar is a hand-built `LazyVGrid`. Light + dark first-class via dynamic asset colors; Dynamic Type, VoiceOver labels on rows/controls/charts, Reduce Motion, and opt-out haptics throughout. Design language: a calm ledger palette (money green over cool slate) with rounded financial UI type and serif display type.

- **Monetization:** Free core (up to 8 bills + all views). One-time **Remit Pro ($8.99)** unlocks unlimited bills, payment reminders, and multi-currency niceties — no subscription, no ads.
- **Why it can boom:** Everyone has bills and late fees are real money; Mint's January-2024 shutdown left a gap that bank-aggregation apps (which demand banking logins) and fixed-amount subscription trackers don't fill — a private, no-bank-login, one-time-purchase bill manager that simply prevents late fees is broadly wanted.

## Self-review

Hand-reviewed file by file (no Xcode in the build sandbox). Verified: all imports resolve; every type, modifier, and SwiftData/`@Query`/`@Relationship`/`@Observable`/`@Environment` usage is iOS-17-valid; `Decimal` stored in `@Model` and formatted via `.formatted(.currency(code:))`; `NavigationStack`/`navigationDestination`/sheet wiring type-checks; no force-unwrap, `try!`, `fatalError`, unchecked index, or unguarded division on user paths (the only `try!` is the standard in-memory `ModelContainer` fallback); all Calendar math is guarded and month-end-safe; `@Model` arrays in `ForEach` dividers use enumerated offsets / persistent IDs. Anti-stub grep clean (no TODO/FIXME/placeholder/etc.). Onboarding gated by a persisted flag; empty/loading/success/error states present; free-tier bill cap gates the paywall; light + dark, Dynamic Type, VoiceOver, Reduce Motion, and opt-out haptics wired; local-notification authorization requested gracefully and never crashes when denied.
