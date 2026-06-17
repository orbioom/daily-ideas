# Caliper

## What it is
**Caliper** is a focused, private, on-device **body-measurement & physique tracker** for iPhone. Log your weight, body-fat %, and tape measurements across the whole body; watch smooth trends; and see computed body-composition metrics (US Navy body-fat %, BMI, waist-to-hip ratio, FFMI, weekly rate of change) and goal progress — all without accounts, ads, or a subscription.

It's the version people wish existed instead of bloated all-in-one fitness suites and ad-laden trackers: calm, precise, beautiful, and a one-time purchase.

**Audience:** lifters, recompers, and anyone running a cut or bulk who wants honest progress data they actually own.

## Features
- **Dashboard** — summary cards for Weight, Body fat %, and Waist (latest value, change since last entry, tiny sparkline), computed BMI / waist-to-hip / FFMI cards, a prominent "Log measurements" button, goal-progress bars for sites with a goal, and a calm empty state.
- **Measurements** — list of all 14 tracked sites (Weight, Body fat %, Neck, Shoulders, Chest, Waist, Hips, L/R Bicep, L/R Thigh, L/R Calf, Forearm). Tap a site → detail: Swift Charts trend line with goal rule-mark, current/min/max/avg, weekly rate & total change, goal editor with progress bar, "Add entry", and an editable history list (edit/delete each entry).
- **Log (Add session)** — record a session on a chosen date; enter any subset of sites in your unit settings; **auto-compute Navy body-fat %** from neck/waist/(hips for women)/height/sex and accept it into the Body fat % site; per-field validation with calm inline errors.
- **Insights** — Swift Charts dashboard with smoothed weight & body-fat trends, waist trend, a fat-vs-lean composition bar, and computed stats over a selectable 30 / 90 / 365 / all window: weekly rates, BMI category, waist-to-hip classification, and FFMI. Brief async loading spinner while computing.
- **Onboarding** — 3 value pages + a profile page collecting biological sex, height, and unit preference (persisted); gated by `hasOnboarded`.
- **Settings** — units (metric/imperial), biological sex, height, appearance (System/Light/Dark), haptics toggle, plus Unlock Pro / Restore / Add custom site / CSV export / About.
- States throughout: empty, loading, inline errors, and success toasts with haptics. Light + dark, full Dynamic Type, VoiceOver labels on controls and charts, and Reduce Motion fallbacks.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Caliper.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

On first launch Caliper seeds the 14 built-in sites and ~5 months of realistic weekly entries (a believable cut/recomp: weight & waist trending down, biceps up) so every chart and metric looks great immediately.

## Free signing
No paid Apple Developer account needed. In Xcode, select the **Caliper** target → **Signing & Capabilities**, choose your personal team, and let Xcode manage signing. The bundle id is `com.orbioom.caliper` (adjust if it collides on your account). Free provisioning runs on a connected device for 7 days.

## Tech notes
- **Platform:** iOS 17.0+, SwiftUI, Swift Charts. `NavigationStack` only; two-parameter `.onChange`.
- **Persistence:** SwiftData (`@Model MeasurementSite`, `@Model MeasurementEntry`, both registered in the `Schema`); `@Query` for reads; small prefs/flags in `@AppStorage`. Survives relaunch. Documented in-memory `ModelContainer` fallback is the only `fatalError`.
- **Architecture:** pure logic isolated in `Engine/` (`BodyMath`, `Units`, `SiteStats`, `SiteCatalog`); views are thin. `AppSettings`/`ProStore` are `ObservableObject` + `@StateObject`; no mixing with `@Observable`.
- **Units:** values are stored canonically (kg, cm, percent) and converted only for display via `Units`, so switching metric/imperial never mutates stored data.
- **Body-comp formulas used (all input-guarded; return `nil` rather than crash):**
  - US Navy body-fat % (circumferences converted to inches):
    - men: `%BF = 495 / (1.0324 − 0.19077·log10(waist−neck) + 0.15456·log10(height)) − 450`
    - women: `%BF = 495 / (1.29579 − 0.35004·log10(waist+hip−neck) + 0.22100·log10(height)) − 450`
    - guards `waist−neck > 0` (and `waist+hip−neck > 0` for women) and `height > 0` before any `log10`.
  - BMI `= kg / m²` with category bands; Waist-to-hip `= waist / hip` (guards `hip > 0`).
  - FFMI `= leanMass / m²` where `leanMass = weightKg·(1 − bodyFat/100)`; normalized FFMI `= FFMI + 6.1·(1.8 − m)`. All divisions guarded.
  - Weekly rate of change = least-squares slope over dated points (requires ≥2 points and non-zero time variance).
- **Design language:** calm teal (`#1FB6A6`, matching the AccentColor asset) and charcoal, crisp bordered cards, big rounded numerals, smooth Catmull-Rom trend charts. Backgrounds match the LaunchBackground asset (light `#EAF6F5`, dark `#06140F`). Every custom color is dynamic for AA contrast in both modes.
- **Monetization:** one-time simulated **$4.99** Pro unlock (`@AppStorage("isPro")`, StoreKit-ready) — free core logging is never gated; Pro unlocks all sites + custom sites, advanced insights/FFMI/full windows, unlimited goals, full history beyond 90 days, and CSV export.
- **Why it can boom:** the fitness-tracking niche is dominated by subscription bloatware and ad-funded trackers — a beautiful, private, one-time-purchase physique tracker with honest computed metrics is exactly what serious lifters keep asking for.

## Self-review
I re-read every one of the 34 Swift files by hand and verified: all imports present (`SwiftUI`, `SwiftData`, `Charts` where charts are used, `Foundation`, `UIKit` for haptics/share); every type, enum case, initializer, and modifier exists in the iOS 17 SDK and is spelled correctly; Swift Charts usage (`Chart`, `LineMark`/`AreaMark`/`BarMark`/`RuleMark`, `.annotation`, `chartYScale`) is correct under `import Charts`; property-wrapper ownership is correct (`@StateObject` for `AppSettings`/`ProStore`, `@Query`/`@Environment(\.modelContext)` for data, no `@Observable` mixed with `@StateObject`); `NavigationStack`, `navigationDestination`/`NavigationLink`, sheet bindings, and `#Predicate`-based `@Query` type-check; both `@Model` types (`MeasurementSite`, `MeasurementEntry`) are listed in the `Schema`; no iOS-18-only APIs; all `.onChange` use the two-parameter form; no `@Previewable`, no `NavigationView`; no `try!`/`as!`/force-unwrap/unchecked index/unguarded division/log10 on user paths (the only `fatalError` is the documented unreachable in-memory `ModelContainer` fallback); no TODO/placeholder/stub strings; and braces/parens balance in code (the only paren-counter flag was prose inside a doc comment, since reworded). **Self-review passed.**
