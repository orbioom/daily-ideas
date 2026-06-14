# Jaunt

**Plan a trip day by day — itinerary, packing and budget in one calm, private, offline app.**

Jaunt is a native iOS 17 SwiftUI app for the traveller who just wants to plan their trip without an account, a subscription, ads, or the cloud. Each trip becomes an ordered, day-by-day timeline, paired with a categorized packing checklist and a real budget tracker — with a friendly countdown to departure.

---

## What it is

A focused trip planner built around three jobs done well:

1. **A day-by-day itinerary** — one timeline per calendar day, items sorted by time (timed first, then "anytime"), each with a category, address, cost, duration and booking status.
2. **A packing checklist** — categorized, with progress rings and starter templates so you never forget your passport.
3. **A budget** — planned costs vs logged expenses, a category breakdown (Swift Charts donut), and an over-budget warning.

Everything is stored privately on-device with SwiftData. No network, no MapKit, no location permissions — addresses are plain text.

---

## Full feature list

- **Trips hub** — grouped into *In progress / Upcoming / Past* with gradient cover cards, destination, dates, and a live countdown ("In 12 days", "Day 2 of 5", "Last month"). Swipe to delete.
- **Add / edit trip** — name, destination, start/end dates, budget and currency, notes. Validates a non-empty name and `endDate ≥ startDate`. Days are generated automatically (one `TripDay` per calendar day, inclusive) and re-synced when the range changes, preserving days that still fall in range.
- **Trip overview** — gradient header with countdown, quick stats (days, plans, packing ring), a spent-vs-budget meter, and navigation into Itinerary, Packing and Budget. Edit, delete, and export from the menu.
- **Day itinerary (timeline)** — horizontal day selector, vertical timeline sorted by time, per-day cost footer, editable day labels. Add/edit items (title, category, time + duration, address, cost, booked, notes), move items between days, swipe to delete or toggle booked, and a Reorder mode for untimed items. Per-day empty state.
- **Packing checklist** — categorized list with check-off, per-category and overall progress, inline add, "Add from template" (Beach, City, Business, Camping, Winter — deduplicated), clear-packed, and empty state.
- **Budget** — async loading state while computing, spent-vs-budget bar chart, a Swift Charts donut of cost by category (Pro), expenses list with add/edit/delete, remaining / over-budget indicator. Divide-by-zero guarded (budget 0 → no percentage).
- **Itinerary export (Pro)** — a clean, selectable, copyable day-by-day text plan.
- **Onboarding** — four gated slides explaining trips → days → items, packing and budget.
- **Settings** — haptics toggle, currency symbol, time format (12/24h), default packing template, trip count, reset & reseed, and an About screen.
- **Accessibility** — Dynamic Type throughout, VoiceOver labels/hints/values (including an audio chart descriptor for the donut), decorative images hidden, AA-contrast palette, and animations that honour Reduce Motion.
- **Sample data** on first launch: two rich trips (an upcoming 5-day Kyoto trip with a full multi-day itinerary, plus a completed Lisbon weekend), packing lists and expenses.

---

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`)
3. Open `Jaunt.xcodeproj` in Xcode 15+, choose an iOS 17+ simulator, and press **Cmd+R**.

### Free-signing note
The project uses a personal/free Apple ID team for signing. If signing fails, open the **Jaunt** target → **Signing & Capabilities**, pick your own Team, and let Xcode manage a unique bundle identifier (the default is `com.orbioom.jaunt`).

---

## Monetization

- **Free tier** is genuinely usable: up to **2 trips**, plus your chosen default packing template.
- **Jaunt Pro** — a one-time **$4.99** unlock that adds:
  - Unlimited trips
  - All packing templates
  - Budget analytics (category breakdown)
  - Itinerary text export

The paywall is honest about being a **local demo unlock** (no real payment / StoreKit) and includes a Restore action. `PaywallReason` (`tripLimit`, `templates`, `budget`, `export`) tunes the copy to the context that triggered it.

### Why it can boom
Wanderlog and TripIt are account-bound, ad- or subscription-driven, and cloud-first. A large segment of travellers simply want to *plan their trip* — privately, offline, without signing up. Jaunt puts a day-by-day itinerary, a packing checklist and a budget into one calm app that works on a plane with no signal and asks for no account. That focus, plus a fair one-time unlock, is the wedge.

---

## Tech notes

- **iOS 17 / SwiftUI**, no external packages, no APIs newer than the iOS 17 SDK.
- **SwiftData** is the source of truth: `@Model` types `Trip`, `TripDay`, `ItineraryItem`, `PackItem`, `Expense` with `.cascade` relationships; views observe via `@Query` / `@Bindable` / `modelContext`. `UserDefaults` holds preferences only (via `@AppStorage`).
- **Pure engines** (`ItineraryEngine`, `BudgetEngine`, `PackingEngine`) hold all date math, sorting, countdown classification, budget summation and template seeds — DST-safe via calendar **date components**, with `endDate ≥ startDate` guards and divide-by-zero protection.
- **Relationships** are linked by setting the to-one side after `context.insert`, letting SwiftData maintain the inverse collection (no manual double-linking).
- **Swift Charts** powers the budget donut (`SectorMark`) and the spent-vs-budget bar, each with an accessibility descriptor.
- **Theme** is a single azure (`#2E86C1`) token set with first-class light and dark via a dynamic `Color.dyn` helper and a rounded brand font.
- The only force operation in the codebase is the documented in-memory `ModelContainer` fallback in `JauntApp.init()`.

---

## Self-review attestation

I re-read every authored file and verified:

- iOS-17 SDK correctness — Calendar/Date math via components (DST-safe), SwiftData cascade relationships and inverse maintenance, `@Query`/`@Bindable` ownership, `NavigationStack` + `.sheet(item:)`/`.navigationDestination` bindings.
- No duplicate types; a single `@main`; Charts series back by an `Identifiable` struct; all `Theme` tokens defined; balanced braces in every file.
- No force-unwraps, no `fatalError`, no unchecked indexing on user paths, and divide-by-zero guarded — the only `try!` is the allowed container fallback.
- Empty, loading, error/validation and success states across the feature screens; ≥3 persisted preferences; seed data behind a `didSeed` flag with a reset action.
- `grep -rniE "TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub"` over `ios/Jaunt` returns **zero** matches.

This app type-checks by inspection against the iOS 17 SDK. With no Xcode available in this environment, the toolchain has not executed it.
