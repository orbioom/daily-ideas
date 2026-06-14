# Orbioom iOS build conventions (run 2026-06-14_1212-UTC)

You are authoring the **Swift sources only** for ONE production-ready native iOS app.
The Xcode config is ALREADY generated for you — DO NOT create/modify these (they exist):
`ios/project.yml`, `ios/<App>/Info.plist`, `ios/<App>/Assets.xcassets/**` (AppIcon, AccentColor,
LaunchBackground), `ios/<App>/Preview Content/**`. Do NOT create a `.xcodeproj`.

## Where code goes
All Swift files go under `ios/<App>/<App>/` (note the doubled folder, exactly like the reference app).
Use subfolders: `Models/`, `ViewModels/`, `Engine/` (or `Logic/`), `Views/` (with `Onboarding/`,
`Settings/`, `Components/`, and per-feature folders), `Theme/`, `Utilities/`, `Persistence/` if needed.
Keep models, view models, engines, and views in SEPARATE files (one primary type per file).

## STUDY THE REFERENCE FIRST (read these before writing)
- `/home/user/daily-ideas/runs/2026-06-14_0613-UTC/01-relish/ios/Relish/Relish/` — full app: copy the
  patterns for `RelishApp.swift` (@main + ModelContainer), `Theme/Theme.swift`, `ViewModels/AppSettings.swift`,
  `ViewModels/Pro.swift`, `Views/RootView.swift`, `Views/Onboarding/OnboardingView.swift`,
  `Views/Settings/SettingsScreen.swift`, `Views/PaywallView.swift`, `Views/Components/*`,
  `Utilities/Haptics.swift`, `Utilities/SeedData.swift`.
- `/home/user/daily-ideas/runs/2026-06-14_0613-UTC/05-meeple/` and `06-nonet/` — for Swift Charts + engine
  patterns. Mirror the code style, not the content.

## Hard requirements (verifiable by reading source — the sandbox has NO Xcode, so be the compiler)
1. `<App>App.swift` `@main` exactly like Relish: a `ModelContainer` built in `init()` with do/catch where the
   ONLY `try!` in the whole app is the in-memory fallback in the catch block. `@AppStorage("hasOnboarded")`
   gates `OnboardingView` vs `RootView`. `@StateObject private var settings = AppSettings()`,
   `.environmentObject(settings)`, `.tint(Theme.accent)`, `.modelContainer(container)`.
2. **≥4 distinct substantive feature screens** reachable via `TabView`/`NavigationStack` (NOT counting
   Onboarding or Settings). Plus a Settings tab/screen. Back/dismiss always works.
3. First-run **Onboarding** (2–3 pages, app's design language) that sets `hasOnboarded = true` on finish.
4. **Empty states** everywhere data is shown (designed, not blank). **Loading states** for async/computed work
   (`async`/`await`, `@MainActor`, a brief computed-stats spinner is fine). **Error states** that are calm and
   recoverable. **Success states** (confirmations/haptics).
5. **Settings screen with ≥3 real persisted prefs** bound to `AppSettings` (`@AppStorage`) that actually change
   behavior. Include About, an Export action, a "Restore purchase"/Pro row, and a "Load sample data" action.
6. **Persistence in SwiftData** (`@Model`, `@Query`, `modelContext`, cascade `deleteRule: .cascade` on owned
   children). `@AppStorage`/`UserDefaults` ONLY for small prefs/flags (incl. `isPro`).
7. **No force-unwrap / `try!` / `as!` / `fatalError` / unchecked index / unguarded division on user paths.**
   The single allowed `try!` is the in-memory container fallback. Guard all array indexing and division.
8. **Accessibility**: system fonts only (Dynamic Type), `accessibilityLabel/Hint/Value` on controls & icons,
   decorative images `.accessibilityHidden(true)`, WCAG-AA contrast in BOTH modes, respect
   `@Environment(\.accessibilityReduceMotion)` to disable non-essential animation.
9. **Light AND dark mode** first-class via the `Theme.dyn(light, dark)` pattern (per-`colorScheme` UIColor).
   No hardcoded `.white`/`.black` backgrounds that break in the other mode.
10. **Haptics** where meaningful, sparse, gated by a Settings toggle (`settings.hapticsEnabled`) — see
    `Utilities/Haptics.swift`.
11. **Tasteful animation** in the app's own language; gate non-essential motion behind Reduce Motion.
12. **Cohesive, intentional visual identity** — a real `Theme` palette (use the app's accent), consistent cards,
    typography, spacing. No unstyled stock SwiftUI.
13. **Performance**: `LazyVStack`/`LazyVGrid`/`List` with stable `Identifiable` IDs. Seed sample data (via the
    Settings "Load sample data" action and in `#Preview`s) that exercises **50+ items** where the model implies a
    collection, so lists are smooth at realistic volume.
14. **Monetization surface**: a `Pro` enum with a free-tier limit + `priceLabel`, a `PaywallView`, and gating
    (e.g. free up to N items → paywall). Gate Pro with `@AppStorage("isPro")`. StoreKit is NOT wired (this is a
    build, not signed); the paywall's "Unlock" sets `isPro = true` and "Restore" is present. Make the honest
    note in the README.

## Anti-stub
NO `TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`// stub`/`unimplemented` anywhere.
Every screen, control, button, tab, swipe, and menu must do real work end-to-end. No dead ends.

## SwiftData gotchas (get these right)
- `@Model final class X { ... }`; relationships: parent has `@Relationship(deleteRule: .cascade, inverse: \Child.parent) var children: [Child] = []`; child has `var parent: Parent?`. Many-to-many: arrays on both sides with one `inverse:`.
- Register ALL `@Model` types in the `ModelContainer(for: A.self, B.self, ...)` call (both root and in-memory).
- In views use `@Query(sort: \X.field) private var items: [X]` and `@Environment(\.modelContext) private var ctx`.
- Use `@Bindable var item: X` for editing a model in a detail/editor view.
- Do not store non-Codable/unsupported types directly; store enums as their `rawValue` (String/Int) with a
  computed accessor, or make the enum `Codable`. Snapshot display strings where a related object may be deleted.

## Observation wiring (be consistent per app)
Use the Relish pattern: `AppSettings` is an `ObservableObject` with `@AppStorage` + `@StateObject`/`@EnvironmentObject`.
For pure non-persistent view-state engines you MAY use `@Observable` + `@State`, but DO NOT mix `@Observable`
with `@StateObject`/`@EnvironmentObject` on the SAME type. Prefer the ObservableObject pattern to match Relish.

## When done
- Re-read EVERY Swift file you wrote and verify imports, types, initializers, enum cases, view modifiers all
  exist in the iOS 17 SDK and are spelled right; protocol conformances satisfied; `NavigationStack`/
  `navigationDestination`/sheet bindings/`@Query`/`modelContainer` type-check; no API newer than iOS 17.
- Run an anti-stub grep over your sources and confirm clean.
- Confirm exactly one `@main` and exactly one `try!` (the in-memory fallback).
- Report a short self-review summary (file count, the engine's core logic, how each DoD item is met).
DO NOT git commit or push — the studio lead does that. Just write files and report.
