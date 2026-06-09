# Trove — gift & occasion planner

**One line:** A calm, private way to track the people you give to, their gift ideas, and every occasion — with budgets that actually help.
**Problem & audience:** Everyone juggles gifts for birthdays and holidays in their head, scattered notes, or shared lists that cause family-group friction. The proven incumbents (Giftster, Santa's Bag) own the category but feel "stuck in 2010" — dated, glitchy, account-and-group heavy. Trove is the modern, on-device, casual version: organized people + ideas + occasions, with spend and budget rollups, and nothing to sign into.

## Full feature list
- **Home** — at-a-glance to-buy count, people count, and upcoming count; a budget-overview ring (total spent vs total budget); and a unified **Upcoming** feed combining occasions and birthdays with friendly countdowns. Quick-add a gift from the toolbar. Empty state for first run.
- **People** — every person with relation, gift count, and acquired spend. Tap into a **Person detail**: stat tiles (gifts, to-buy, spent), next-birthday countdown, sizes note, free-form notes, and their gifts grouped by status. Add a gift pre-linked to them, edit, or delete (cascades to their gifts).
- **Occasions** — list sorted by next occurrence, each with next date + countdown and a budget vs spend bar (over-budget shown in red). Tap into an **Occasion detail**: annual roll-forward date, a budget ring (over-budget in `Brand.danger`), notes, and the occasion's gifts. Add a gift, edit, or delete (gifts are nullified, not deleted).
- **Gift editor** — title (validated non-empty), price (currency-aware), status picker (Idea / Bought / Wrapped / Given), person picker, occasion picker, store, link, and notes. Destructive delete when editing.
- **Insights** — total spend vs budget ring, a **status donut** (Swift Charts `SectorMark`) with a readable legend, **spend-by-person** and **spend-by-occasion** bar charts (`BarMark`), and a full to-buy list. Empty state.
- **Settings** — currency picker (USD/EUR/GBP/JPY/CAD/AUD) with a live example, show/hide already-given gifts, haptics toggle, live library counts, and a confirmed **Clear all data** with an on-device footer.
- First-run onboarding (persisted gate), empty states everywhere, light & dark via dynamic Brand colors, Dynamic Type, VoiceOver labels/values, Reduce Motion respected, sparse gated haptics, SwiftData persistence, seeded sample data on first launch.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Trove.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free signing:** no paid Apple Developer account needed — select your personal team under Signing & Capabilities and run on the simulator or your own device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `GiftEngine` (annual date roll-forward with Feb-29 safety, birthday/occasion countdowns, spend & budget rollups, status tallies, chartable spend series). Persistence in **SwiftData** (`Person`, `Occasion`, `Gift` — cascade on `Person.gifts`, nullify on `Occasion.gifts`); small prefs in `UserDefaults` via `@AppStorage` (keys prefixed `trove.`). Swift Charts for the status donut and spend bars. Currency via `NumberFormatter` with a safe fallback. Orbioom design language (liquid glass, ink-gradient buttons, JetBrains-style mono numerals, green reserved for live/acquired, red for over-budget).
- **Monetization:** free for a modest circle; Pro = unlimited people/gifts + shareable lists + occasion reminders.
- **Why it can boom:** gift tracking is proven and seasonal, and incumbents (Giftster/Santa's Bag) are dated/glitchy with family-group friction — Trove is the modern, private, casual version people want.

## Self-review
Re-read every Swift file by hand: imports resolve (`SwiftUI`, `SwiftData`, `Charts`, `Foundation`, `UIKit`); all APIs used exist in the iOS 17 SDK; `@Model` relationships wire correctly (cascade on `Person.gifts`, nullify on `Occasion.gifts`, both with valid inverse key paths) and `@Query` sort key paths are valid; `@State`/`@Bindable`/`@Environment(\.modelContext)`/`@AppStorage` usage type-checks; `sheet`/`NavigationLink`/`confirmationDialog` bindings type-check; pickers use `PersistentIdentifier?` tags consistently; Charts `SectorMark`/`BarMark`/`AxisMarks` are valid iOS 17; date math uses `Calendar` with guards and never force-unwraps; division by budget is guarded; prices/budgets clamped non-negative; currency formatting falls back instead of crashing. Anti-stub grep (TODO/FIXME/XXX/placeholder/lorem/coming soon/not implemented/stub) is clean. Only `fatalError` is the unreachable in-memory `ModelContainer` fallback, mirroring the canonical app. `project.yml` is valid YAML naming the real `Trove` sources and `Info.plist`.
