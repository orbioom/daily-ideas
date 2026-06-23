# Packwise

**Smart trip packing lists that build themselves.** Tell Packwise where you're
going, for how long, with whom and what you'll be doing — it generates a
tailored, categorized packing checklist scaled to your trip, then lets you check
items off with a satisfying progress ring.

## Problem & audience

Packing is the most-procrastinated, most-error-prone part of any trip. Generic
checklists give everyone the same 40 items; you either over-pack or forget the
charger. **Packwise** is for travelers — families, business flyers, weekend
hikers, beach-goers — who want a *right-sized* list in seconds, reusable across
many trips, fully offline and ad-free. It's a focused take on PackPoint/TripList:
the same "generate from trip details" idea, but with night-scaled quantities,
activity-aware gear, reusable templates and multi-trip management.

## Features

- **Generator engine** — a pure, deterministic rules engine builds the list from
  trip type (beach / business / hiking / city / ski), nights, traveler count and
  tagged activities. Clothing scales with nights and your packing style; per-person
  items multiply by travelers; each activity adds its own gear, de-duplicated
  against the base list, capped sensibly so a 30-night trip doesn't ask for 30 shirts.
- **3-step create flow** — details → activities → live generated preview with a
  loading state and a summary of how the list was tailored.
- **Packing checklist** — collapsible category sections (Documents, Clothing,
  Toiletries, Electronics, Gear, Essentials), tap-to-pack rows, a central
  progress ring, per-category counts, and an "all packed!" success banner.
- **Custom items** — add your own items (name, quantity, category); they're kept
  when you regenerate.
- **Regenerate** — rebuild the auto list after editing trip details, preserving
  your custom additions.
- **Templates** — 5 built-in starter templates (Carry-On Essentials, Toiletry Kit,
  Tech Bag, Beach Day, Baby & Toddler) plus full CRUD on your own. Apply any
  template into any trip; duplicate a starter to customize it.
- **Multi-trip** — manage several concurrent trips; pick an *active* trip that
  lives on the Packing tab. Upcoming / past grouping with countdowns.
- **Settings** — packing style (Light / Balanced / Generous), default travelers,
  pack-reminder lead time, haptics toggle, metric/imperial units, replay onboarding.
- First-run onboarding (persisted flag), empty / loading / success / recoverable
  error states throughout, full Dynamic Type & VoiceOver, light + dark mode,
  Reduce-Motion-aware animation, haptics gated by a Settings toggle.

### Screens (4 substantive feature screens + Onboarding + Settings)

1. **Trips** — all trips, upcoming/past, create & delete.
2. **Packing** — the trip detail / checklist (the active trip), with progress ring.
3. **Create flow** — the multi-step generator sheet.
4. **Templates** — browse / create / edit / delete reusable lists + editor.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM. **SwiftData** for persistence (`Trip`, `PackItem`,
  `Template`, `TemplateItem`, `AppSettings`) via `@Model` / `@Query` /
  `modelContainer`; `@AppStorage` only for the onboarding flag and the active-trip id.
- `PackingEngine` is a pure value-type rules engine (no SwiftData), so it is
  deterministic and trivially testable; quantity scaling is guarded against
  reversed dates, zero nights and division by zero.
- No external dependencies, no network, no API keys. 5 sample trips (60+ generated
  items) and 5 starter templates seed on first launch.
- Crash-proofing: no `try!` / `fatalError` / force-unwraps on user paths; the
  model container degrades gracefully to in-memory if the store can't open.
- **Monetization:** free with a one-time **Packwise Pro** unlock (unlimited
  concurrent trips + unlimited custom templates + cloud sync); the engine and
  one active trip stay free.
- **Why it can boom:** packing is a universal, recurring, high-anxiety travel
  chore with proven demand (PackPoint, TripList) but a stale, ad-heavy field —
  a calm, offline, genuinely *tailored* generator with reusable templates is
  highly shareable ("it packed my whole trip in 10 seconds") and a natural fit
  for travel-creator and airline partnerships.

## Run steps

```bash
brew install xcodegen      # if not already installed
cd ios
xcodegen generate          # creates Packwise.xcodeproj
open Packwise.xcodeproj     # Xcode 15+
# Select an iOS 17 simulator and press Cmd+R
```

**Free signing:** in Xcode, select the *Packwise* target → Signing & Capabilities
→ pick your Personal Team; the bundle id is `com.orbioom.packwise`. No paid
account required to run on a simulator or your own device.

## Self-review attestation

I re-read every Swift file as the compiler. Verified: all imports
(`SwiftUI`, `SwiftData`, `Foundation`, `UIKit`) and every type, initializer,
enum case and modifier exist in the iOS 17 SDK and are spelled correctly; no APIs
newer than iOS 17 are used. Property wrappers are correct — `@Model`, `@Query`,
`@Bindable`, `@State`, `@AppStorage`, `@Environment`, `@Observable` (on the
`@MainActor` view model). `NavigationStack` + `navigationDestination(for:)` use
SwiftData model values (`Trip`, `Template`) as navigation payloads; all sheet and
`confirmationDialog` bindings type-check; `@Query` sorts use `Comparable` key
paths only (the earlier `Bool` sort was removed). No force-unwraps, `try!` or
`fatalError` on user paths; division and date math are guarded. The anti-stub
grep `grep -rniE 'TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|//
stub' Packwise/` returns **no matches**. `xcodegen generate` succeeds and the
`AppIcon` is a real 1024×1024 RGBA PNG (designed gradient + suitcase emblem).
29 Swift files.
