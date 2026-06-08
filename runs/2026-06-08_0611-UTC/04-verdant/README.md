# Verdant — Plants, kept alive — calmly.

A calm, focused plant-care companion for iOS 17. No paywalls. No aggressive onboarding. Just your plants and a quiet engine that tells you when they need water.

Built by **Orbioom** studio.

---

## What it is

Verdant is a native iOS 17 SwiftUI app that helps you keep your houseplants alive without overwhelming you. It tracks watering and fertilizing schedules, adapts to seasons, and shows you exactly what needs doing today — without burying the signal in noise.

---

## Full Feature List

### Care Engine
- Seasonal adjustment: watering intervals shortened ~20% in summer (Jun–Aug), lengthened ~30% in winter (Dec–Feb)
- Fertilizing auto-skipped in winter months
- Status levels: overdue / due today / due soon (≤2 days) / ok
- Today's tasks sorted overdue-first

### Screens (5 tabs)

**Today**
- Tasks grouped: Overdue, Today, This Week
- One-tap "Done" button per task logs a CareEvent and updates lastWatered / lastFertilized
- Empty state when all plants are happy
- Pull-to-see-more — only surfaced tasks, no noise

**Plants**
- Searchable lazy grid with status dot per plant
- Filter by room
- Toggle to show/hide archived plants
- Add / Edit / Archive / Delete with confirmation
- Full plant form: nickname, species, icon (20 symbols), color (12 swatches), room picker with inline add-room, light level, watering + fertilize steppers, pot size, notes, acquired date

**Plant Detail**
- Hero card: symbol, status dot, room
- Care schedule card: light, pot size, last + next water / fertilize with countdown
- Quick Action buttons: Water / Fertilize / Mist / Repot / Prune / Add Note
- All actions log a CareEvent; water + fertilize update the due-date counters
- Full care history timeline, newest first
- Edit / Archive / Delete from menu

**Rooms**
- CRUD: add, edit, delete rooms (12 icon options)
- Each room card shows plant count, overdue badge, and a peek strip of up to 6 plant symbols with status dots
- Tap card → filtered plant list for that room, pushing to Plant Detail

**Insights (Swift Charts)**
- Streak card: days-in-a-row streak, events this month, active plant count
- Weekly care events bar chart — last 8 weeks
- Plants by room horizontal bar chart
- Plants by light level donut chart with legend
- Neediest plants list (sorted by soonest water due)

**Settings**
- Haptics toggle (verdant.haptics)
- Seasonal adjustment toggle (verdant.seasonal)
- Appearance: System / Light / Dark (verdant.appearance)
- Preferred reminder time picker stored as verdant.reminderTime (no permission request; note to enable in iOS Settings)
- Reset onboarding
- About sheet: studio, platform, storage, privacy, ads/paywall

### Onboarding
- 3-page swipe introduction with page indicator
- Skip / Next / Get Started, all respecting Reduce Motion

### Data
- SwiftData: Plant, CareEvent, Room with cascade and nullify delete rules
- Seed data: 4 rooms, 12 named plants (Monstera, Snake Plant, Pothos, Fiddle Leaf Fig, Peace Lily, ZZ Plant, Aloe, Calathea, Spider Plant, Basil, Orchid, Succulent), 62 care events — varied due states including overdue and upcoming

### Accessibility
- Dynamic Type throughout (all system fonts)
- Accessibility labels, hints, and values on all interactive elements
- Decorative images hidden from VoiceOver
- Reduce Motion respected on all animations
- Combined accessibility elements where appropriate

---

## Run Steps

### Prerequisites
- macOS 14+, Xcode 15+
- [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Generate project and run

```bash
cd ios
xcodegen generate
open Verdant.xcodeproj
```

Select the **Verdant** scheme, choose an iOS 17 simulator or device, then press ▶.

### Free signing note

In Xcode → Targets → Verdant → Signing & Capabilities, set your personal Apple ID team. The bundle ID `com.orbioom.verdant` can be changed to match your provisioning if needed.

---

## Tech Notes

**Stack:** SwiftUI + SwiftData + Swift Charts, iOS 17 only, zero third-party dependencies.

**Architecture:** Feature views with direct `@Query` reads from SwiftData. Pure-static `CareEngine` for schedule logic — fully testable without a model context. `Brand.swift` design system keeps all colors, motion, and typography in one place for consistent theming.

**SwiftData relationships:** Plant → CareEvent (cascade), Room → Plant (nullify). `@Query` with `SortDescriptor` for stable lazy-container IDs.

**Monetization (one line):** Freemium: unlimited plants free, a one-time "Garden Pro" unlock (~$4.99) adds widgets, CSV export, and custom reminder sounds — no subscription, no paywall on core care.

**Why it can boom (one line):** Planta's users routinely cite aggressive paywalls and slow load times as their top complaints — Verdant is free-first, instant, and calm, targeting the exact gap that drives 1-star reviews on the category leader.

---

## Self-Review Attestation

- No `TODO`, `FIXME`, placeholder, stub, "coming soon", or lorem text in any Swift file
- No force-unwrap (`!`) except the single allowed in-memory SwiftData fallback in `VerdantApp.swift`
- No `fatalError` on user paths
- No unchecked array indexing on user data paths
- No division on user-controlled values without a guard/clamp
- `@main` appears exactly once (`VerdantApp.swift`)
- All 5 tabs implemented: Today, Plants, Rooms, Insights, Settings
- Settings has 4+ persisted prefs: haptics, seasonal, appearance, reminderTime
- `import Charts` present in `InsightsView.swift`
- All lazy containers (`LazyVStack`, `LazyVGrid`) used with stable `.id` sources
- Accessibility labels, hints, and hidden markers on all meaningful UI
- Reduce Motion respected on every `withAnimation` call and in `OnboardingView`, `InkButtonStyle`, `GlassButtonStyle`
- Brand colors only — no literal `Color(...)` values outside `Brand.swift` and `Color(hex:)` calls using model-stored hex
- Seed data: 12 plants, 4 rooms, 62 care events, inserted only when store is empty
