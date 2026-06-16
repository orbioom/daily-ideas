# Orbioom iOS build kit — run 2026-06-16

You are authoring the **Swift sources only** for ONE production-ready native iOS app.
The Xcode config + assets are ALREADY generated for you. **DO NOT create or modify** these
(they exist and are correct): `ios/project.yml`, `ios/<App>/Info.plist`,
`ios/<App>/Assets.xcassets/**` (AppIcon with a real designed 1024 icon, AccentColor,
LaunchBackground), `ios/<App>/Preview Content/**`. Do **NOT** create a `.xcodeproj`.

## Where code goes
All Swift files go under `ios/<App>/<App>/` (note the **doubled folder**). Subfolders:
`Models/`, `ViewModels/`, `Engine/`, `Views/` (with `Onboarding/`, `Settings/`, `Components/`,
and per-feature folders), `Theme/`, `Utilities/`, `Persistence/`. One primary type per file.

## STUDY THE REFERENCE FIRST (read before writing — mirror the STYLE, not the content)
- `/home/user/daily-ideas/runs/2026-06-15_1809-UTC/01-tetra/ios/Tetra/Tetra/` — full app:
  copy patterns for `TetraApp.swift` (@main + ModelContainer init with do/catch), `Theme/Theme.swift`
  (the `Color.dyn(light,dark)` + `Theme` enum + `cardSurface` modifier), `Utilities/Haptics.swift`
  (copy ~verbatim), `Models/AppSettings.swift` (the `@AppStorage` `ObservableObject` + `AppearanceMode`),
  `Models/Pro.swift` (local simulated unlock + `PaywallReason`), `Views/RootView.swift`,
  `Views/Onboarding/OnboardingView.swift`, `Views/Settings/SettingsView.swift`, `Views/Paywall/PaywallView.swift`,
  `Views/Components/SharedComponents.swift`.
- `/home/user/daily-ideas/runs/2026-06-14_0613-UTC/01-relish/ios/Relish/Relish/` — full SwiftData CRUD app
  with relationships, editor sheets, Swift Charts. Mirror the SwiftData + Charts + editor patterns.

## Hard requirements (the sandbox has NO Xcode — BE the compiler)
1. `<App>App.swift` `@main` exactly like Tetra: `ModelContainer` built in `init()` with do/catch; the ONLY
   `fatalError` allowed is the documented unreachable in-memory fallback. `@AppStorage("hasOnboarded")` gates
   `OnboardingView` vs `RootView`. `@StateObject private var settings = AppSettings()`,
   `.environmentObject(settings)`, `.tint(Theme.accent)`, `.preferredColorScheme(...)`, `.modelContainer(container)`.
2. **≥4 distinct substantive feature screens** via `TabView`/`NavigationStack` (NOT counting Onboarding or
   Settings). Plus a Settings screen. Back/dismiss always works (`NavigationStack` + `.navigationDestination`,
   or sheets with explicit dismiss).
3. First-run **Onboarding** (2–3 pages in the app's design language) that sets `hasOnboarded = true` on finish.
4. **Empty states** everywhere data is shown (designed, with icon + message + CTA — not blank). **Loading states**
   for async/computed work (`async`/`await`, `@MainActor`; a brief computed spinner is fine). **Error states**
   that are calm and recoverable. **Success states** (confirmations + haptics).
5. **Settings screen with ≥3 real persisted prefs** bound to `AppSettings` (`@AppStorage`) that actually change
   behavior, PLUS: About, an Export/share action, a Pro/Restore row, and a "Load sample data" action.
6. **Persistence in SwiftData** (`@Model`, `@Query`, `modelContext`, `@Relationship(deleteRule: .cascade ...)`
   on owned children). `@AppStorage` ONLY for small prefs/flags (incl. `isPro`).
7. **No force-unwrap / `try!` / `as!` / unchecked index / unguarded division on user paths.** No `fatalError`
   except the one documented in-memory container fallback. Guard all array indexing and division by zero.
8. **Accessibility**: system fonts only (Dynamic Type), `accessibilityLabel/Hint/Value` on controls & meaningful
   icons, decorative images `.accessibilityHidden(true)`, WCAG-AA contrast in BOTH modes, respect
   `@Environment(\.accessibilityReduceMotion)` to disable non-essential animation.
9. **Light AND dark mode** first-class via `Theme.dyn(light, dark)`. No hardcoded `.white`/`.black` fills that
   break in the other mode.
10. **Haptics** sparse, meaningful, gated by `settings.hapticsEnabled` — see `Utilities/Haptics.swift`.
11. **Tasteful animation** in the app's own language; gate non-essential motion behind Reduce Motion.
12. **Cohesive visual identity** — a real `Theme` palette using the app's accent (the AccentColor hex is given in
    your spec), consistent cards/typography/spacing. No unstyled stock SwiftUI.
13. **Performance**: `LazyVStack`/`LazyVGrid`/`List` with stable `Identifiable` IDs. Your "Load sample data"
    action and `#Preview`s MUST seed **50+ items** where the model implies a collection, so lists are realistic.
14. **Monetization**: a `Pro` enum (free-tier limit + `priceLabel` + unlock copy), a `PaywallView`, and real
    gating (free up to N → paywall). Gate with `@AppStorage("isPro")`. StoreKit is NOT wired; the paywall's
    "Unlock" sets `isPro = true`, "Restore" present. Note this honestly in the README.

## Anti-stub — ZERO of these anywhere
`TODO` `FIXME` `XXX` `placeholder` `lorem` `coming soon` `not implemented` `// stub` `unimplemented`.
Every screen/control/button/tab/swipe/menu does real work end-to-end. No dead ends.

## SwiftData gotchas
- `@Model final class X { ... }`. Parent: `@Relationship(deleteRule: .cascade, inverse: \Child.parent) var children: [Child] = []`. Child: `var parent: Parent?`. Many-to-many: arrays on both sides, ONE `inverse:`.
- Register ALL `@Model` types in BOTH `ModelContainer(for: Schema([A.self, B.self, ...]))` calls.
- Views: `@Query(sort: \X.field) private var items: [X]`; `@Environment(\.modelContext) private var ctx`.
- Editing a model: `@Bindable var item: X`.
- Store enums as `rawValue` (String/Int) with a computed accessor, OR make the enum `Codable`. Snapshot display
  strings where a related object may be deleted.

## API safety (iOS 17 only)
- No `NavigationView` (use `NavigationStack`). Two-arg `onChange(of:) { old, new in }` (NOT single-arg).
- Swift Charts: `import Charts`; `Chart { BarMark/LineMark/SectorMark/AreaMark/PointMark ... }`. `SectorMark`
  needs iOS 17 (ok). Use `.foregroundStyle(by:)`, `.chartXAxis`, etc.
- `@Observable` allowed for pure view-state engines used with `@State`; **never** mix `@Observable` with
  `@StateObject`/`@EnvironmentObject` on the SAME type. `AppSettings` uses `ObservableObject` + `@StateObject`.
- Date math via `Calendar.current`; guard `Calendar` optionals (`date(byAdding:)` returns optional — handle).
- No third-party packages. No network/API keys — mock with realistic in-code fixtures.

## When done (report back, do NOT git commit)
- Re-read EVERY Swift file: imports, types, initializers, enum cases, modifiers all exist in iOS 17 SDK & spelled
  right; conformances satisfied; navigation/sheet/@Query/@Bindable type-check; no API newer than iOS 17.
- Run an anti-stub grep over your sources; confirm clean. Confirm exactly one `@main` and zero `try!`.
- Write the app's `README.md` (in `0X-<slug>/README.md`) per the studio README spec (What it is; full feature
  list; Run steps; Free-signing note; Tech notes incl. one-line **Monetization** + one-line **Why it can boom**;
  Self-review attestation with file count).
- Report a short self-review summary: file count, the engine's core logic, how each DoD item is met.
