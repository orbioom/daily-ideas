# Plate — Calories without the clutter.

A production-ready native iOS 17 calorie and macro food diary built by Orbioom. No paywall. No ads. No account. Fully on-device.

---

## What it is

Plate is a clean, fast food-logging app that replaces the friction of MyFitnessPal with a frictionless, beautiful experience:

- Log a meal in under five seconds
- See your calorie budget ring and macro bars update instantly
- Browse 14 or 30 days of trends in Swift Charts
- Let the Mifflin-St Jeor TDEE engine compute your targets, or set them manually
- All data lives on your device — zero telemetry, zero sync chaos

---

## Full feature list

### Diary (Tab 1)
- Horizontal date strip (last 14 days, tap to navigate)
- Big calorie ring: consumed / target, centre shows remaining or "over" in real time
- Three macro progress bars (Protein / Carbs / Fat vs. daily target)
- Four meal sections (Breakfast / Lunch / Dinner / Snack)
- Per-meal calorie subtotal in the section header
- Tap any entry to edit servings or delete; trash button on each row
- "Add food" and "Add more" buttons open the food-search flow targeted to that meal
- Empty state per meal section
- Success haptic on add, warning haptic on delete

### Foods (Tab 2)
- Full catalog (60 realistic items pre-seeded across 7 categories)
- Filter chips: Favorites, My Foods, and all 7 categories simultaneously
- Full-text search by name or brand
- Swipe trailing to favorite/unfavorite any food
- Swipe trailing to delete custom foods (with confirmation dialog)
- Swipe leading to edit custom foods
- "Create custom food" via the + toolbar button

### Trends (Tab 3)
- Range toggle: 14 days / 30 days
- Stat cards: avg. calories, days logged, days under target, avg delta vs. goal
- Calories-per-day bar chart (Swift Charts) with dashed target rule line
- Color-coded bars: green = on/under target, red = over
- Macro distribution donut chart (average daily protein / carbs / fat split)
- Protein trend area+line chart with target rule line
- Full empty state when no data is logged

### Goal (Tab 4)
- Live computed-target card (Mifflin-St Jeor BMR × activity factor + objective delta, floored at 1,200 kcal)
- Stats form: sex, age, height, weight, activity level, objective (lose/maintain/gain)
- Real-time preview of computed targets as you adjust stats
- Manual override toggle: directly set calorie and macro targets
- Input validation with descriptive error banners
- Success banner with auto-dismiss
- Persists to SwiftData UserGoal model

### Settings (Tab 5)
- Haptic feedback toggle (persisted as `plate.haptics`, wired to Haptics.enabled)
- Show macros in diary toggle (persisted as `plate.showMacros`)
- Imperial / metric units toggle (persisted as `plate.units`, affects Goal form input labels)
- Appearance picker: System / Light / Dark (persisted as `plate.appearance`, applied via preferredColorScheme)
- Reset onboarding (with confirmation dialog)
- About sheet (features, build info, Orbioom credit)

### Onboarding (3 screens, gated by `plate.onboarded`)
- Page 1: Mission statement
- Page 2: Trends pitch
- Page 3: Goal intro + "Get Started" button (InkButtonStyle, success haptic)

### Seed data
- 60 realistic FoodItem catalog entries across Protein, Grain, Fruit, Veg, Dairy, Snack, Drink
- 14 days × 3–4 meals of DiaryEntry records (140+ entries total)
- One UserGoal (computed from defaults: male, 30y, 178 cm, 80 kg, moderate, maintain)
- 6 foods pre-favorited

---

## Run steps

### Prerequisites

- macOS 14+ with Xcode 15+
- [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Generate and open

```bash
cd ios
xcodegen generate
open Plate.xcodeproj
```

### Build and run

1. Select the `Plate` scheme and a simulator (iPhone 15 / iOS 17+) or your device
2. Press **⌘R**

---

## Free signing note

To run on a physical device without a paid developer account:

1. In Xcode, select the `Plate` target → **Signing & Capabilities**
2. Set **Team** to your personal team (Apple ID)
3. Change **Bundle Identifier** to something unique, e.g. `com.yourname.plate`
4. Re-run — Xcode will provision the app automatically

---

## Tech notes

| Area | Detail |
|---|---|
| Language | Swift 5.9, SwiftUI, iOS 17 deployment target |
| Persistence | SwiftData — `FoodItem`, `DiaryEntry` (snapshots own nutrition), `UserGoal` |
| Charts | Swift Charts (`import Charts`): bar chart, line+area chart, sector (donut) chart |
| Engine | Pure `NutritionEngine` enum — Mifflin-St Jeor BMR, TDEE, macro targets, day totals |
| Accessibility | Dynamic Type, `.accessibilityLabel/Hint/Value`, decorative images hidden, Reduce Motion respected throughout |
| Haptics | Sparse — add success, delete warning, selection on steppers/chips |
| Theming | Brand.swift color tokens only; automatic light/dark; user-selectable appearance |
| Architecture | Single ModelContainer, @Query everywhere, no singletons |
| **Monetization** | Optional premium tier (meal plans, AI food-scan, deeper analytics) — zero-friction freemium; core is fully free |
| **Why it can boom** | MyFitnessPal's paywall and ad-cluttered UI drove millions away; Plate is the clean, private, on-device alternative they're searching for |

---

## Self-review attestation

- No `TODO`, `FIXME`, placeholder, stub, or lorem ipsum text in any Swift file
- Single `try!` — only the approved in-memory ModelContainer fallback in `PlateApp.swift`
- Zero force-unwraps on user paths; all optionals handled with `if let` / `guard` / nil-coalescing
- Zero `fatalError` calls
- `@main` appears exactly once (PlateApp.swift)
- All views import only `SwiftUI`, `SwiftData`, or `Charts` as appropriate — no external dependencies
- All types and modifiers verified against iOS 17 SDK (no iOS 18+ APIs)
- Brand.swift API used throughout — no color or font literals
- Lazy containers used (List with stable IDs, ForEach over @Query results)
- SwiftData `@Relationship(deleteRule:.nullify)` on `DiaryEntry.food` so deleting a catalog item preserves diary history
