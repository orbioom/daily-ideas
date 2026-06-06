# Larder

A calm, premium pantry & kitchen-inventory app for iOS, built for Orbioom. Track what
you have, where it lives, and what's about to go off — then turn "running low" into a
shopping list without re-typing anything.

## What it is

Larder is a native SwiftUI app with a genuine relational model. An **Item** has a name,
category, quantity + unit, the **Location** it lives in (Pantry / Fridge / Freezer /
custom), a purchase date, an expiry / best-before date, a low-stock threshold, and
notes. **Locations** and **Categories** are managed entities referenced by items, so a
rename flows everywhere and the inventory groups cleanly. A **shopping list** is
generated from items at or below their low-stock threshold and merged with manual
entries; checking an auto entry off restocks its item back into the larder.

## Features

- **Inventory** grouped by location, with live search (name/category), a category
  filter bar, and per-item expiry + low-stock badges. Tap through to a detail view.
- **Item detail** with unit-aware quantity stepping (never below zero), status, dates,
  placement, and notes — plus an **editor** to create/edit with validation.
- **Dashboard**: a summary strip (expired / use-soon / low / fresh counts) plus
  "Expiring & expired" and "Running low" sections. Includes the calm
  "Nothing's about to go off" empty state.
- **Shopping list**: low-stock items appear automatically and merge (de-duped by name)
  with hand-typed entries. Check off to mark bought; auto entries **restock** their
  source item. Clear-done and per-item delete for manual rows.
- **Settings** with persisted preferences that each change behavior:
  expiring-soon window (days), default location for new items, appearance
  (system/light/dark), haptics toggle, and an optional notifications toggle.
- **Export** the full inventory as **CSV or JSON** via the system share sheet.
- **Manage locations**: add (validated — non-empty, no duplicate names), rename,
  reorder, and delete (items survive as "Unassigned").
- **First-run onboarding** (persisted flag) and a **reset** path that erases all data
  and restores first-run defaults + the sample larder.
- **Optional local notifications** for items nearing their date, with a clean
  permission request and graceful denial — the app is fully functional without them.
- Seeded with **26 sample items** across four locations and eight categories, with
  realistic dates (some expired, some expiring soon, some fresh) and a few at/below
  their low-stock threshold so the dashboard and list are alive on first launch.

## Design

Orbioom's calm, premium system: layered **mist** backgrounds (never pure white),
`.ultraThinMaterial` glass cards, a single ink-gradient primary action per screen,
ink text tokens, and a restrained green reserved for fresh/success. Expiring status
uses **amber/red paired with an icon and text — never color alone** — for accessibility.
SF Pro UI with **monospaced digits** for quantities and day counts. Motion is slow and
purposeful and honors **Reduce Motion**. Full light + dark support.

## Run steps

1. Open `Larder.xcodeproj` in Xcode 15 or later (iOS 17 SDK).
2. Select an iOS 17+ simulator or device.
3. Build & run (Cmd-R).

### Free-signing note

The project uses automatic signing with a placeholder team. For a personal device,
select the **Larder** target → **Signing & Capabilities**, choose your personal
(free) Apple ID team, and let Xcode manage the provisioning profile. No paid account
is needed to run on your own device. The bundle id is `com.orbioom.larder`.

## Tech notes

- **iOS 17+, SwiftUI 5, MVVM**, no external dependencies.
- **SwiftData** is the source of truth for `Item`, `Location`, `Category`, and
  `ShoppingListEntry` (with relationships; locations/categories nullify on delete so
  items survive). `UserDefaults` (via `SettingsStore`, `@Observable`) holds only
  onboarding/seed flags and preferences.
- Core logic lives in pure, UI-free helpers (`ExpiryLogic` for day-bucketing,
  low-stock detection, and shopping-list merge/de-dupe; `InventoryExport` for CSV/JSON;
  `NotificationManager` for guarded local reminders), keeping models as plain data.
- The data store degrades to in-memory if the on-disk store can't open, and shows a
  calm error screen rather than crashing.
- No networking anywhere.

## Self-review

- **Anti-stub grep** — clean:
  `grep -rniE 'todo|fixme|xxx|placeholder|lorem|coming soon|not implemented|// stub' Larder`
  returns no matches.
- **No unsafe constructs on user paths** — no `try!`, no `fatalError`, no force-unwraps,
  no unguarded array indexing (all index access is bounds-checked), and no division on
  user input. All `try` calls are `try?`/`do-catch`.
- **Compile / data-flow review** — verified imports, iOS-17-only APIs
  (`@Observable`, `Bindable`, `.scrollContentBackground`, `contentTransition`,
  `NavigationStack`, `.searchable`), property-wrapper wiring (`@Query`,
  `@Environment(\.modelContext)`, `modelContainer`), and sheet/binding plumbing.
  Traced the full lifecycle: create an item in the editor → `context.insert` + save →
  relaunch reads it via `@Query` → grouped, badged, and counted on the dashboard.
  Traced the shopping flow: low-stock detection → merged/de-duped list → check-off →
  restock writes back to the item and removes it from the active list.
- **Accessibility** — Dynamic Type throughout; expiry conveyed by icon + text + color
  (never color alone) with descriptive VoiceOver labels; decorative glyphs hidden;
  light/dark contrast; Reduce Motion honored in onboarding and animations.
- **#Preview** blocks compile against an in-memory, sample-seeded preview container.
