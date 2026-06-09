# Cache — goal-based savings tracker

**One line:** Turn vague money intentions into clear goals and know exactly when you'll reach them.
**Problem & audience:** Plenty of people want to save for a trip, a fund, or a big purchase but have no feel for whether they're on pace. Goal-savings apps (Qapital and friends) prove the demand, but they push bank linking, fees, and accounts. Cache is the private, on-device version: just goals, contributions, and honest projections.

## Full feature list
- **Goals** — a total-saved overview plus goal cards with a progress ring, amount saved/target, and a live on-track / behind / no-deadline status.
- **Goal detail** — big progress ring, remaining amount, **projected finish date** from your real contribution pace (or a monthly plan you set), the **required-per-month** to hit a target date, full contribution history, and deposit/withdrawal logging.
- **Add contribution** — deposits or withdrawals with quick-amount chips, date and note.
- **Activity** — a unified savings ledger across all goals, grouped by month with net totals; add a contribution to any goal from here.
- **Insights** — total saved, this-month deposits, active/completed counts, a cumulative savings curve, net deposits per month (bar), and a where-your-savings-sit donut by goal.
- **Goal editor** — name, target, optional deadline, optional monthly plan, 12 icons, 8 colors, notes.
- **Settings** — currency symbol (10 options), hide completed goals, haptics, load sample goals, reset onboarding.
- Onboarding (persisted) with a sample-data path; empty/loading/success states; light & dark; Dynamic Type; VoiceOver; Reduce Motion.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Cache.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** no paid Apple Developer account needed — personal team, simulator or your own device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `SavingsEngine` (pace from history, projection, required monthly, on-track classification, cumulative/monthly trends, milestones). **SwiftData** models `Goal → Contribution` (cascade); prefs in `@AppStorage`. Swift Charts for trends. "Saved" is always the sum of contributions, never a stored number, so the math can't drift. Orbioom design language.
- **Monetization:** freemium — free for a few goals; Pro unlocks unlimited goals, recurring auto-contributions, widgets, and iCloud sync/export.
- **Why it can boom:** goal-based saving is a proven money category, and millions distrust bank-linking finance apps; Cache offers the same motivating progress + projection magic with zero account, zero ads, fully private.

## Self-review
Re-read every file: imports resolve; SwiftUI/SwiftData/Charts APIs valid for iOS 17 (`SectorMark`, `AreaMark`, etc.); `@Model`/`@Query`/`@Bindable` wiring type-checks; sheets and `confirmationDialog` correct; no force-unwrap/`try!`/`fatalError` on user paths (the one guarded dictionary access was made nil-safe). Anti-stub grep clean. `project.yml` valid YAML naming the `Cache` sources and `Info.plist`.
