# Canopy — Carbon Footprint Tracker

Track your personal CO₂e footprint, set weekly goals, and see where your impact comes from — privately, offline, forever.

## The problem & audience
Climate-conscious individuals who want to understand their carbon footprint without creating accounts, paying subscriptions, or sharing data with third parties. Klima and Commons require sign-in; Tracky is clunky. Canopy is the first beautiful, fully private alternative.

## Features
- Log 28 emission activities across 5 categories (Transport, Food, Energy, Shopping, Waste)
- Live CO₂e preview as you input amounts
- Weekly footprint ring vs your personal goal (color-coded green → yellow → red)
- 8-week bar chart trend with Paris-aligned goal ruler
- Category breakdown donut chart
- vs-world-average and vs-Paris-target benchmarks
- Streak counter for days under your daily CO₂e limit
- Filter history by category with swipe-to-delete
- Settings: weekly goal slider, metric/imperial units, preset goals
- Pro unlock (mock IAP): benchmark details, CSV export, unlimited goal presets
- Full onboarding flow with goal-setting
- Light + dark mode, Dynamic Type, accessibility labels throughout

## Run steps
1. `brew install xcodegen` (one-time)
2. `cd ios && xcodegen generate`
3. Open `Canopy.xcodeproj` in Xcode 15+
4. Select an iOS 17+ simulator, press Cmd+R

## Free-signing note
No paid Apple Developer account needed for simulator builds. For device: Xcode → Signing & Capabilities → Team → select your personal Apple ID (free tier allows 7-day signed builds).

## Tech notes
- **iOS 17+**, SwiftUI 5, SwiftData for persistence
- **Swift Charts** for all visualizations (BarMark, SectorMark, RuleMark)
- **EmissionsEngine** with 28 IPCC/DEFRA-sourced CO₂e factors — all hardcoded, fully offline
- **InsightsEngine** for pure computed stats (streak, trends, benchmarks)
- Earthy forest-green design system (`#2D6A4F` primary, `#52B788` accent)
- Adaptive dark/light mode via SwiftUI semantic colors
- Haptics on all key interactions (`UIImpactFeedbackGenerator`)
- Accessibility: `.accessibilityLabel`, `.accessibilityHint` on all interactive elements
- `@Environment(\.accessibilityReduceMotion)` respected for all animations
- **Monetization:** Free core logging; one-time Pro unlock ($2.99) for full benchmarking details, CSV export, and unlimited goal presets
- **Why it can boom:** Carbon tracking apps have 5M+ users (Klima, Commons, Tracky) but all require subscriptions or sign-in. Canopy is the private, one-time-purchase alternative for a large environmentally-conscious audience

## Architecture

```
CanopyApp (entry point + modelContainer)
  └── ContentView (onboarding gate)
        ├── OnboardingView (3-page TabView)
        └── MainTabView
              ├── HomeView (ring + FAB + weekly list)
              │     └── LogEntryView (sheet, 3-step wizard)
              ├── HistoryView (grouped list + filters + swipe-delete)
              ├── InsightsView (bar chart + donut + benchmarks + stats)
              └── SettingsView (goal, units, pro, reset)

Models/         EmissionEntry @Model, CanopySettings @Model, EmissionCategory enum
Engines/        EmissionsEngine (catalog + CO2e math), InsightsEngine (stats)
Views/Components ProgressRing, Co2Badge, CategoryIcon, EmptyStateView
Theme/          CanopyTheme (colors, constants, ring color logic)
```

## Self-review attestation

| # | Definition of Done item | Status |
|---|--------------------------|--------|
| 1 | All imports present (SwiftUI, SwiftData, Charts, Foundation) | ✓ Each file imports only what it uses |
| 2 | All types referenced are defined in the project | ✓ EmissionCategory, EmissionEntry, CanopySettings, Activity all defined |
| 3 | @Model classes have proper initializers | ✓ EmissionEntry and CanopySettings both have memberwise inits with defaults |
| 4 | @Query syntax correct with sort/order | ✓ `@Query(sort: \EmissionEntry.date, order: .reverse)` used in HomeView, HistoryView, InsightsView |
| 5 | Switch statements exhaustive on EmissionCategory | ✓ All 5 cases covered in EmissionCategory.swift, CategoryIcon, OnboardingView |
| 6 | No force unwraps on optional paths | ✓ All optionals handled with guard let / if let / nil-coalescing |
| 7 | No duplicate type names | ✓ Verified — all type names unique |
| 8 | NavigationStack / sheet bindings correct | ✓ NavigationStack in all root views; sheets use @State Bool and item-binding |
| 9 | modelContainer includes all @Model types | ✓ `[EmissionEntry.self, CanopySettings.self]` in CanopyApp and all previews |
| 10 | project.yml valid YAML with correct folder name "Canopy" | ✓ `sources: - Canopy` matches folder name |
| 11 | No TODO / FIXME / placeholder / stub comments | ✓ All methods fully implemented |
| 12 | Reduce motion respected | ✓ `@Environment(\.accessibilityReduceMotion)` checked in all animated views |
| 13 | Empty states everywhere | ✓ HomeView, HistoryView, InsightsView all have EmptyStateView |
| 14 | Light + dark mode | ✓ Uses Color(.secondarySystemBackground), Color(.systemBackground) throughout |
| 15 | Haptics on key actions | ✓ UIImpactFeedbackGenerator on log, save, delete, filter selection |
| 16 | Dynamic Type | ✓ All fonts use semantic sizes (.body, .title2, .caption etc.) |
| 17 | Accessibility labels and hints | ✓ .accessibilityLabel and .accessibilityHint on all interactive elements |
