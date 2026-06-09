# Coffer — private home inventory & warranty tracker

**One line:** Catalog what you own, room by room, so an insurance claim is proof instead of panic — fully on-device, no subscription.
**Problem & audience:** Homeowners and renters know they should document their belongings for insurance, but doing it is tedious and the leading app (Sortly) is widely criticized for bait-and-switch pricing (free tier squeezed toward plans up to ~$299/mo) and confusing cancellation. Coffer gives anyone who wants peace of mind — before a theft, fire, or flood — a calm, fast, fairly-priced way to record value, warranties, serials and receipts that stays on their own device.

## Full feature list
- **Overview** — total inventory value as a big mono number, item count, count of warranties expiring soon, a Swift Charts value-by-category bar chart, and quick links into Warranties and Items. Empty state for a fresh start.
- **Rooms** — every room with its item count and total value; add/edit rooms with an SF Symbol icon picker; tap into a **Room Detail** listing its items (value + warranty dots), plus an **Unassigned** bucket so items are never lost when a room is deleted.
- **Items** — searchable list of everything you own (name, brand, model, serial) with a category filter menu; each row shows room, value and a warranty status dot. Full **Item Detail** with warranty status, days remaining (color-coded), value, purchase info and notes.
- **Warranties** — items grouped into Expiring soon (amber), Expired (red) and Active (green), each sorted by expiry date, with a clear "in N days / N days ago" label. Empty state.
- **Editors** — create/edit items (category, room, brand/model/serial, price, purchase date, warranty length, notes) and rooms (name, icon, notes); name validation; delete with confirmation.
- **Settings** — currency picker (formats every value via the OS), expiring-soon window (30/60/90 days), haptics toggle, **Export** via ShareLink (plain-text summary and RFC-4180 CSV), and a guarded "Clear all data" with live counts and an on-device/no-subscription footer.
- First-run onboarding (persisted), empty states everywhere, light & dark via Brand dynamic colors, Dynamic Type, VoiceOver labels/values, Reduce Motion respected, sparse gated haptics.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Coffer.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free signing:** no paid Apple Developer account needed — select your personal team under Signing & Capabilities and run on the simulator or your own device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `InventoryEngine` (warranty status + days remaining, value/count rollups by room & category, search, and CSV/text export with correct quoting). Persistence in **SwiftData** (`Room`, `Item` with a `.nullify` relationship so deleting a room keeps its items); small prefs in `UserDefaults` via `@AppStorage` (keys prefixed `coffer.`). Swift Charts for the value-by-category view. Orbioom design language (liquid glass, ink-gradient buttons, JetBrains-style mono numerals, green reserved for live/active warranties).
- **Monetization:** free up to a limited item count; Pro = unlimited items + photo attachments + backup/export.
- **Why it can boom:** home inventory for insurance is proven demand, but Sortly's bait-and-switch pricing and cancellation traps enrage users — an on-device, no-subscription, fairly-priced app is wide open.

## Self-review
Re-read every Swift file by hand: imports resolve (`SwiftUI`, `SwiftData`, `Charts`, `UIKit`); all SwiftUI/SwiftData/Charts APIs used exist in the iOS 17 SDK; `@Model` relationship (`Room.items` nullify, inverse `\Item.room`) and `@Query` sort key paths (`\Item.createdAt`, `\Room.sortIndex`) are valid; `@State`/`@Bindable`/`@Environment(\.modelContext)` wiring type-checks; `Picker` selections of `Room?` use matching `.tag(Room?.none/.some)`; `sheet`, `NavigationStack`, and `ShareLink(item:preview:)` bindings type-check; Charts `BarMark` with `Chart(_:id:)` over `Hashable` category keys is valid; all warranty date math goes through guarded `Calendar` calls (no force-unwrap). No force-unwrap/`try!`/`fatalError` on user paths (only the in-memory `ModelContainer` fallback, mirroring Chime). `WarrantyStatus` is a no-payload enum so `==` is synthesized. Currency uses the non-throwing `.formatted(.currency(code:))`. CSV escaping doubles quotes and wraps fields containing comma/quote/newline. Anti-stub grep (TODO/FIXME/XXX/placeholder/lorem/coming soon/not implemented/stub) is clean.
