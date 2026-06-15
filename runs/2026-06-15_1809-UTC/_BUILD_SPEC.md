# Shared build spec — Orbioom iOS run 2026-06-15_1809-UTC

You are building ONE complete, production-ready native iOS app. Read this fully.
The app's design assets, `project.yml`, and `Info.plist` are ALREADY GENERATED — do NOT touch them.

## What already exists (DO NOT CREATE OR MODIFY)
- `ios/project.yml` ✅ (valid XcodeGen spec, names the `<App>` source folder)
- `ios/<App>/Info.plist` ✅ (includes `UILaunchScreen` → `LaunchBackground`)
- `ios/<App>/<App>/Assets.xcassets/AppIcon.appiconset/` (real 1024 icon + Contents.json) ✅
- `ios/<App>/<App>/Assets.xcassets/AccentColor.colorset/` ✅
- `ios/<App>/<App>/Assets.xcassets/LaunchBackground.colorset/` (light+dark) ✅
- `ios/<App>/<App>/Assets.xcassets/Contents.json` ✅
- `ios/<App>/Preview Content/Preview Assets.xcassets/Contents.json` ✅

You write everything else: all Swift under `ios/<App>/<App>/...`, and `README.md` at the app
folder root (`0X-<slug>/README.md`).

## Folder layout (exact — note the double-nested `<App>/<App>/`)
```
0X-<slug>/
  README.md                          # you write
  ios/
    project.yml                      # EXISTS — don't touch
    <App>/
      Info.plist                     # EXISTS — don't touch
      Assets.xcassets/               # EXISTS — don't touch
      Preview Content/...            # EXISTS — don't touch
      <App>/                         # <-- all your Swift goes here
        <App>App.swift               # @main
        Models/  ViewModels/  Views/(Onboarding|Settings|Components|<feature folders>)/
        Theme/  Persistence/  Utilities/
```

## iOS DEFINITION OF DONE (every requirement is mandatory)
1. Complete feature set, no dead ends — every screen/control/tab/button/swipe wired to real behavior; full CRUD where data is user-owned.
2. ≥ 4 distinct, substantive feature screens (NOT counting Onboarding or Settings) via `NavigationStack`/`TabView`; back/dismiss always works.
3. First-run onboarding gated by a persisted `@AppStorage("hasOnboarded")` flag.
4. Empty states everywhere data is shown.
5. Loading states for async/computed work (`async`/`await`, `@MainActor`) where applicable.
6. Error states — calm, recoverable; never a silent failure, `fatalError`, `try!`, or force-unwrap on user paths.
7. Success states.
8. A Settings screen with ≥ 3 real persisted, functional preferences (`@AppStorage`).
9. Persistence that survives relaunch — primary data in **SwiftData** (`@Model`/`@Query`/`modelContainer`); `@AppStorage`/UserDefaults only for small prefs/flags. (For drawing/binary data, store `Data` in SwiftData or FileManager.)
10. Input validation & crash-proofing (no force-unwrap/`try!`/unchecked index/unguarded division on user paths).
11. Full accessibility — Dynamic Type app-wide; `accessibilityLabel`/`Hint`/`Value`; decorative images hidden (`.accessibilityHidden(true)` or `decorative:`); WCAG AA contrast both modes; Reduce Motion via `@Environment(\.accessibilityReduceMotion)`.
12. Haptics where meaningful (sparse; gated by a Settings toggle).
13. AppIcon/AccentColor/launch screen — ALREADY DONE, don't touch.
14. Light AND dark mode first-class (use the `Theme` with `Color.dyn` semantic colors; no hardcoded colors that break in the other mode).
15. Tasteful animation in the app's own design language; respects Reduce Motion.
16. Cohesive design — a clear, intentional visual identity applied consistently across every screen.
17. Sensible performance — lazy containers with stable `Identifiable` IDs; no main-thread blocking; smooth at realistic volumes (seed/test with 50+ items where the model implies a collection).

## project.yml (already written — for reference only)
`sources: [<App>]`, `INFOPLIST_FILE: <App>/Info.plist`, `GENERATE_INFOPLIST_FILE: NO`,
`DEVELOPMENT_ASSET_PATHS: "<App>/Preview Content"`, deployment iOS 17.0.

## Theme convention (create `Theme/Theme.swift` like this)
Provide `Color(hex:)`, `Color.dyn(light, dark)` (resolves per `UITraitCollection.userInterfaceStyle`),
and an `enum Theme` with semantic tokens (bg, surface, surfaceAlt, ink, inkSoft, inkFaint, accent,
accentSoft, hairline, good, warn, bad) plus rounded/mono font helpers and corner constants.
Reference implementation (adapt colors to your app's identity):

```swift
import SwiftUI
extension Color {
    init(hex: UInt) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF)/255, green: Double((hex >> 8) & 0xFF)/255,
                  blue: Double(hex & 0xFF)/255, opacity: 1)
    }
    static func dyn(_ l: UInt, _ d: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? d : l
            return UIColor(red: CGFloat((h >> 16) & 0xFF)/255, green: CGFloat((h >> 8) & 0xFF)/255,
                           blue: CGFloat(h & 0xFF)/255, alpha: 1)
        })
    }
}
enum Theme {
    static let bg = Color.dyn(0xF6F1EC, 0x15120F)   // adapt per app
    // ... surface, ink, accent, etc.
    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font { .system(size: s, weight: w, design: .rounded) }
    static let corner: CGFloat = 18
}
```
Match the AccentColor in the asset catalog (each app has a distinct accent — see your prompt).

## @main App entry pattern (robust container, no crash)
```swift
@main
struct <App>App: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @StateObject private var settings = AppSettings()
    let container: ModelContainer
    init() {
        let schema = Schema([/* your @Model types */])
        if let onDisk = try? ModelContainer(for: schema) { container = onDisk }
        else if let mem = try? ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) { container = mem }
        else { fatalError("Unable to initialize ModelContainer.") } // unreachable; in-memory empty store cannot fail
    }
    var body: some Scene {
        WindowGroup {
            Group { if hasOnboarded { RootView() } else { OnboardingView() } }
                .environmentObject(settings)
                .tint(Theme.accent)
                .preferredColorScheme(AppearanceMode(rawValue: appearanceRaw)?.colorScheme)
        }
        .modelContainer(container)
    }
}
```
(The `fatalError` here is the documented unreachable fallback — an empty in-memory store cannot
fail to build. Never use `fatalError`/`try!`/force-unwrap anywhere on real user paths.)

## Monetization (simulated, local) — REQUIRED
Each app has a one-time **Pro** unlock simulated locally via `@AppStorage("isPro")`. Provide a
`Pro` enum (price label, free-tier limits, gating helpers), a `PaywallView` (calm, lists what Pro
unlocks, a "Restore" + "Unlock" button that flips `isPro`), and a `PaywallReason` enum with
tailored copy. NO real StoreKit, NO ads, NO account, NO network for monetization. Note in README
that StoreKit 2 wires in for production.

## AppSettings pattern
`@MainActor final class AppSettings: ObservableObject` exposing `@AppStorage` prefs incl.
`hapticsEnabled`, `appearance` (System/Light/Dark via `AppearanceMode`), plus ≥1 app-specific pref.

## Self-review mandate (the sandbox has NO Xcode — you are the compiler)
Before finishing, re-read EVERY Swift file and verify by hand: every `import`; every
type/initializer/enum case/modifier exists in the iOS 17 SDK and is spelled correctly; protocol
conformances satisfied; `@State`/`@StateObject`/`@Binding`/`@Bindable`/`@Environment`/`@Observable`
ownership correct; `NavigationStack`/`navigationDestination`/sheet bindings and `@Query`/
`modelContainer` wiring type-check; no APIs newer than iOS 17. Run an anti-stub grep
(`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`stub`) and confirm
clean (the words may appear in normal UI copy only if genuinely functional — avoid them). Record
the result in the README "Self-review" section.

## Common SwiftData / SwiftUI gotchas to avoid
- `@Model` classes need `import SwiftData`; relationships use `@Relationship(deleteRule:)`.
- Use `@Query` only inside Views; pass `modelContext` via `@Environment(\.modelContext)`.
- For computed/aggregated stats, compute in a plain struct/enum "engine" (pure functions) — keep it testable and off the main-thread-blocking path.
- `Charts` requires `import Charts`. Use `BarMark`/`LineMark`/`SectorMark`/`PointMark` (all iOS 17 OK).
- Avoid `NavigationView` (deprecated) — use `NavigationStack`.
- Avoid `.onChange(of:)` single-arg closure if targeting strict; use the iOS 17 two-param form `.onChange(of: x) { old, new in }` or zero-param `{ }`.
- Guard all divisions and array index access. Use `Decimal` for money.

## README (write `0X-<slug>/README.md`)
Sections: title + one-line; **What it is** (problem + audience + the incumbent it beats);
**Features** (full list matching the shipped app); **Substantive core logic** (the real engine);
**Run** (`1) brew install xcodegen` … `2) cd ios && xcodegen generate` … `3) open <App>.xcodeproj`,
iOS 17+ sim, Cmd+R); **Free signing** note; **Tech notes** (iOS 17+, SwiftUI 5, MVVM, SwiftData,
design language, one-line **Monetization** note, one-line **Why it can boom** note);
**Self-review** attestation.
