# Kith — personal CRM / stay-in-touch

**One line:** A quiet personal CRM that keeps the people who matter close — private, on-device, and beautiful.
**Problem & audience:** Busy adults watch good friendships drift simply because they forget to reach out. Personal CRMs (Dex, Clay, Monica, UpHabit) prove the demand and charge $9–12/mo, but they're built for professional networking, feel dated (Monica), or hinge on cloud sync of your private relationships. Kith is for your real life — friends, family, mentors — with thoughtful reminders and nothing leaving your phone.

## Full feature list
- **Home / Today** — a "Reach out" hub of people you're due (or overdue) to contact, with one-tap contact logging, plus "Upcoming occasions" (birthdays/anniversaries within your look-ahead window, with whose-turning-what).
- **People** — searchable, relationship-filterable directory with favorites pinned and a last-contact freshness line; add unlimited people (8 relationship types, 8 colors, how-you-met, notes).
- **Person detail** — header with last-contact, a reach-out cadence card with the next due date, four quick-log buttons (called/texted/met/video) plus a noted log, **important dates** (birthday/anniversary/custom with annual roll-forward), an interaction timeline (full CRUD), and context notes; favorite, edit, delete.
- **Insights** — people, interactions this month, tracked count, occasions ≤30 days; a 6-month interactions chart; a relationship-mix donut; and a "haven't spoken in a while" list.
- **Cadence engine** — set how often you'd like to be in touch (sensible defaults per relationship); Kith computes the next reach-out from your last logged contact.
- **Settings** — reach-out reminder window, occasion look-ahead window, haptics, load sample people, reset onboarding.
- Onboarding (persisted) with a sample-people path; empty/loading/success states; light & dark; Dynamic Type; VoiceOver; Reduce Motion.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Kith.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** no paid Apple Developer account needed — personal team, simulator or your own device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `KithEngine` (reach-out due dates, next-occurrence roll-forward for annual dates, upcoming occasions, relationship & monthly stats, falling-out-of-touch). **SwiftData** models `Person → Interaction / ImportantDate` (cascade); value-based `NavigationStack` routing; prefs in `@AppStorage`. Swift Charts for insights. Orbioom design language.
- **Monetization:** subscription/one-time — proven $9–12/mo incumbents. Free for a modest number of people; Pro unlocks unlimited contacts, reach-out notifications, birthday reminders, and import/export.
- **Why it can boom:** a validated, growing "personal CRM" category whose tools are priced for professionals or feel dated; a private, on-device, genuinely lovely keep-in-touch app for ordinary friendships is the version people actually want.

## Self-review
Hand-checked every file: imports resolve; SwiftUI/SwiftData/Charts APIs iOS-17-valid; `navigationDestination(for: Person.self)` / `NavigationLink(value:)` rely on `PersistentModel` Hashable conformance; next-occurrence date math reviewed (no force-unwrap); sheets/`@Query`/`@Bindable` correct; no `try!`/`fatalError` on user paths. Anti-stub grep clean. `project.yml` valid YAML naming the `Kith` sources and `Info.plist`.
