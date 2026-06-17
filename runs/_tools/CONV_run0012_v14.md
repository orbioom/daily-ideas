# Orbioom iOS build conventions — run 2026-06-17_0012-UTC (v14)

You are authoring the **Swift sources + README** for ONE production-ready native iOS 17 app.
The folder tree, `project.yml`, `Info.plist`, and `Assets.xcassets` (AppIcon 1024 PNG, AccentColor,
LaunchBackground) are **already scaffolded — DO NOT touch or recreate them.** You only ADD
`.swift` files under the inner source dir and write the app's `README.md`.

## Where files go
- Swift sources: `<APPDIR>/ios/<App>/<App>/...` (the INNER `<App>` folder, alongside `Assets.xcassets`).
  e.g. `runs/2026-06-17_0012-UTC/01-spindle/ios/Spindle/Spindle/Models/Card.swift`
- README: `<APPDIR>/README.md` (top level of the app folder).
- Sub-folders to use under the inner source dir: `Models/`, `Engine/` (or `ViewModels/`),
  `Views/` (with `Onboarding/`, feature folders, `Settings/`, `Components/`), `Persistence/`,
  `Theme/`, `Utilities/`. Keep models, engines, and views in separate files.

## The @main App file (REQUIRED pattern — copy this shape exactly)
```swift
import SwiftUI
import SwiftData

@main
struct <App>App: App {
    private let container: ModelContainer?
    init() {
        let schema = Schema([ /* every @Model type */ ])
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [onDisk]) {
            container = c
        } else {
            let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try? ModelContainer(for: schema, configurations: [mem])
        }
    }
    var body: some Scene {
        WindowGroup {
            if let container {
                RootView().modelContainer(container)
            } else {
                StoreUnavailableView()   // calm recoverable screen, NOT fatalError
            }
        }
    }
}
```
`RootView` switches on `@AppStorage("hasOnboarded")` between Onboarding and the main `TabView`,
and seeds bundled data in `.task { SeedData.seedIfNeeded(context) }` (idempotent: check a count first).

## Definition of Done (ALL required, verifiable by reading source)
1. ≥4 distinct substantive feature screens (NOT counting Onboarding or Settings) via NavigationStack/TabView; back/dismiss always works.
2. First-run onboarding gated by the persisted `hasOnboarded` flag.
3. Empty states everywhere data is shown; Loading states for async/computed work; calm Error states; Success states.
4. A Settings screen with ≥3 real persisted, functional preferences (@AppStorage or a persisted prefs object).
5. Primary data in **SwiftData** (`@Model`, `@Query`, `modelContext`). `UserDefaults`/`@AppStorage` only for small prefs/flags. Survives relaunch.
6. Input validation & crash-proofing: NO force-unwrap (`!`) on user paths, NO `try!`, NO `as!`, NO `fatalError`, NO unchecked array index, NO unguarded division. Use `guard let`/`if let`, `.first`, safe-index helpers, guard against divide-by-zero.
7. Full accessibility: Dynamic Type (use semantic fonts / `.font(.body)` etc., never fixed huge frames that clip), `accessibilityLabel`/`Hint`/`Value` on controls & charts, decorative images `.accessibilityHidden(true)`, WCAG-AA contrast in BOTH light & dark.
8. Reduce Motion: read `@Environment(\.accessibilityReduceMotion)` and provide a still fallback for any non-trivial animation.
9. Haptics where meaningful (sparse), gated by a Settings toggle.
10. Light AND dark mode first-class — use the asset color sets / `@Environment(\.colorScheme)` via a Theme; NO hardcoded `Color(white:)`/hex that breaks in the other mode.
11. Cohesive, intentional visual identity (a Theme file with palette, typography, card styles) applied across every screen — no unstyled stock SwiftUI.
12. Lazy containers (`LazyVStack`/`List`/`LazyVGrid`) with stable `Identifiable` IDs. Seed/test realistic volumes (50+ where a collection is implied).

## API / compile-safety rules (you are the compiler)
- iOS 17 SDK ONLY. No iOS 18+ API. SwiftUI 5.
- Use `NavigationStack` (never `NavigationView`). Use `.navigationDestination` / sheet bindings correctly.
- Charts: `import Charts`; use `Chart { BarMark/LineMark/SectorMark/AreaMark ... }`. `SectorMark` IS iOS 17.
- `@Observable` (Observation framework) view models: store with `@State` (NOT `@StateObject`). Do NOT mix `@Observable` with `@StateObject`/`ObservableObject`. If you instead use `ObservableObject`, use `@StateObject`. Pick ONE pattern per app and be consistent.
- `.onChange(of:)` MUST use the iOS 17 two-parameter form: `.onChange(of: x) { _, newValue in }`.
- No `@Previewable`. Previews optional; if used, keep simple and compile-correct (or omit entirely — preferred to omit to reduce risk).
- SwiftData: every `@Model` class registered in the `Schema([...])`. Relationships with `@Relationship(deleteRule:)`. Don't store non-Codable/unsupported types; store enums as their rawValue or mark them properly (a plain `String`/`Int`-backed enum property works if the enum is `Codable`; simplest: store `rawValue` String/Int and expose a computed enum).
- Money: compute in `Decimal` where currency precision matters; you may persist as `Double` and convert. Never force-unwrap `Decimal(string:)`.
- Wall-clock timers: drive from a stored start `Date` + `TimelineView`/`Timer`, recompute on `scenePhase`, so they survive backgrounding/relaunch.
- Provide a safe array subscript helper if you index arrays from user input.

## Anti-stub (MUST be clean)
No `TODO`, `FIXME`, `XXX`, `placeholder` (except real TextField prompt strings), `lorem`, `coming soon`,
`not implemented`, `// stub`, `unimplemented`. Every screen/control/button wired to real behavior. No dead ends.

## Monetization (simulated one-time Pro)
Include a `PaywallView` and a persisted `@AppStorage("isPro")` flag with a "Restore"/"Unlock (demo)" that
sets it true (StoreKit-ready in spirit, no real StoreKit calls needed). Gate a few advanced features behind `isPro`
but keep the core app fully usable free. Put the price in the README's Monetization line.

## Self-review before finishing
Re-read EVERY Swift file: imports exist, types/initializers/modifiers exist in iOS 17, protocol conformances
satisfied, property-wrapper ownership correct, no banned APIs, no force-unwrap on user paths, balanced braces.
Then write the README (What it is; Full feature list; Run steps with xcodegen; Free-signing note; Tech notes incl.
one-line **Monetization** and one-line **Why it can boom**; Self-review attestation).

## README run-steps block (use verbatim)
1) `brew install xcodegen` (one-time). 2) In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3) Open `<App>.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.
Free-signing: set your Apple ID team in Signing & Capabilities; the bundle id is `com.orbioom.<lower>`.

A non-compiling app is a failure. Build the complete, polished app.
