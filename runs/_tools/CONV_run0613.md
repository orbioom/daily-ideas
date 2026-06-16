# Orbioom iOS build conventions — run 2026-06-16_0613 (READ FULLY before writing any Swift)

You are authoring the **Swift sources + README** for ONE production-ready native iOS app.
The boilerplate is ALREADY created for you (do NOT touch or recreate it):
- `…/ios/project.yml` (XcodeGen spec — already correct)
- `…/ios/<App>/Info.plist` (already correct, has UILaunchScreen → LaunchBackground)
- `…/ios/<App>/<App>/Assets.xcassets/` — AppIcon (real 1024 PNG), AccentColor.colorset, LaunchBackground.colorset, Contents.json (already created)
- `…/ios/<App>/Preview Content/Preview Assets.xcassets/` (already created)

**Write your Swift files into `…/ios/<App>/<App>/`** in these subfolders:
`<App>App.swift` (@main, at the source root), `Models/`, `ViewModels/` (only if you use ObservableObject VMs), `Engine/` (pure logic), `Views/` (with `Onboarding/`, feature folders, `Settings/`, `Components/`, `Paywall/`), `Persistence/` (SeedData), `Theme/`, `Utilities/`.
Keep models, engines, and views in **separate files**. One type per concept; no giant files.

## NON-NEGOTIABLE compile rules (you are the compiler — there is no Xcode here)
- Target **iOS 17.0**. Never use any API newer than iOS 17 (NO `onChange` single-arg-deprecated form — use the **two-parameter** `.onChange(of:) { oldValue, newValue in }`; NO `@Previewable`; NO iOS 18 SwiftData/SwiftUI symbols; NO `NavigationView` — use `NavigationStack`).
- Persist primary user data in **SwiftData** (`@Model`, `@Query`, `modelContainer`). Small prefs/flags in `@AppStorage`.
- **Every `@Model` class** you define MUST be listed in the `Schema([...])` in `<App>App.swift`.
- NO `try!`, NO `as!`, NO force-unwrap (`!`) on user paths, NO unchecked array index, NO unguarded division. The ONLY allowed `fatalError` is the documented-unreachable in-memory ModelContainer fallback (copy the pattern below verbatim).
- NO `TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`// stub`/`unimplemented`. Everything must be real and wired.
- Use `@Observable` (Observation) OR `ObservableObject`+`@StateObject` — do NOT mix `@Observable` with `@StateObject`. For app-wide settings use the `ObservableObject` pattern below. For view-models prefer `@Observable` + `@State`.
- Balanced braces/parens. Every `import` needed (`SwiftUI`, `SwiftData`, `Charts`, `Foundation`, `AVFoundation`/`CoreMotion`/`CoreLocation` only if actually used).
- Decimal money uses `Decimal`; never `Double` for currency math.

## REQUIRED `<App>App.swift` pattern (copy, adapt names)
```swift
import SwiftUI
import SwiftData

@main
struct <App>App: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @StateObject private var settings = AppSettings()
    let container: ModelContainer
    init() {
        let schema = Schema([/* every @Model type */])
        if let onDisk = try? ModelContainer(for: schema) {
            container = onDisk
        } else if let mem = try? ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) {
            container = mem
        } else {
            fatalError("Unable to initialize ModelContainer.") // Unreachable: empty in-memory store cannot fail.
        }
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded { RootView() } else { OnboardingView() }
            }
            .environmentObject(settings)
            .tint(Theme.accent)
            .preferredColorScheme(AppearanceMode(rawValue: appearanceRaw)?.colorScheme)
        }
        .modelContainer(container)
    }
}
```

## REQUIRED settings + appearance pattern (`Models/AppSettings.swift`)
```swift
import SwiftUI
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? { self == .system ? nil : (self == .light ? .light : .dark) }
}
@MainActor final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    // …plus ≥1 more app-specific persisted prefs so Settings has ≥3 real toggles total…
    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }
}
```
Settings screen must expose **≥3 real persisted, functional preferences** (one is Appearance picker, one Haptics toggle, plus app-specific ones), plus an "Unlock Pro" / "Restore" row and an About section.

## REQUIRED Theme pattern (`Theme/Theme.swift`) — give the app a DISTINCT identity
```swift
import SwiftUI
extension Color {
    init(hex: UInt) { self.init(.sRGB, red: Double((hex>>16)&0xFF)/255, green: Double((hex>>8)&0xFF)/255, blue: Double(hex&0xFF)/255, opacity: 1) }
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h>>16)&0xFF)/255, green: CGFloat((h>>8)&0xFF)/255, blue: CGFloat(h&0xFF)/255, alpha: 1) })
    }
}
enum Theme {
    static let accent = Color(hex: 0x……)   // MUST equal the AccentColor in Assets (given per app)
    static let bg = Color.dyn(0x……, 0x……)
    // …surface, ink, inkSoft, hairline, good/warn/bad, heroGradient, fonts, corner radii…
    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font { .system(size: s, weight: w, design: .rounded) }
}
```
Use `Color.dyn(light,dark)` (or asset color sets) for EVERY custom color so light AND dark mode both read well (WCAG AA). Never hardcode a single color that breaks in the other mode. Apply the theme on EVERY screen — no unstyled stock SwiftUI.

## REQUIRED simulated Pro (`Models/Pro.swift` + `Views/Paywall/PaywallView.swift`)
One-time unlock stored as `@AppStorage("isPro")`. PaywallView lists 4–5 real unlocks, a price label, an "Unlock <App> Pro" button that sets `isPro = true` and dismisses, and a "Restore" + "Maybe later". No real StoreKit (note it's simulated/StoreKit-ready). Gate a genuinely premium-but-non-essential surface (e.g. unlimited items past a free cap, advanced stats, export). The FREE core must be fully usable and satisfying.

## DEFINITION OF DONE (every item verifiable by reading your source)
1. ≥4 distinct substantive feature screens (NOT counting Onboarding/Settings) via TabView/NavigationStack; back/dismiss always works.
2. Onboarding gated by `hasOnboarded` (multi-page, explains value, sets the flag on finish).
3. Empty states everywhere data is shown (calm, with an icon + helpful line + a CTA).
4. Loading state for any async/computed work (`async`/`await`, `@MainActor`), even if brief (e.g. a generating/seeding spinner).
5. Error states — calm, recoverable; never silent, never crash.
6. Success states (confirmation toasts/overlays/haptics).
7. Settings screen with ≥3 real persisted prefs (above).
8. Persistence survives relaunch (SwiftData primary; @AppStorage prefs). Seed realistic sample data (≥30–50 items where the model implies a collection) on first run via `SeedData.seedIfNeeded`, guarded so it runs once.
9. Input validation & crash-proofing on all user paths.
10. Full accessibility: Dynamic Type everywhere (use semantic/scalable fonts; no fixed tiny text), `.accessibilityLabel/.accessibilityValue/.accessibilityHint` on controls and charts, decorative images `.accessibilityHidden(true)`, AA contrast both modes, honor `@Environment(\.accessibilityReduceMotion)` (provide a still fallback for any looping/large animation).
11. Haptics where meaningful, gated by `settings.hapticsEnabled` (use a small `Haptics` helper with `UIImpactFeedbackGenerator`/`UINotificationFeedbackGenerator`).
12. Tasteful animation in the app's design language; respects Reduce Motion.
13. Cohesive, intentional visual identity applied consistently.
14. Lazy containers (`LazyVStack`/`List`/`LazyVGrid`) with stable `Identifiable` IDs; smooth at 50+ items.
15. Swift Charts for any analytics/insights screen, with accessible labels.

## SELF-REVIEW (do this before finishing, write the result into the README "Self-review" section)
Re-read EVERY Swift file and verify by hand: imports; every type/initializer/enum case/modifier exists in iOS 17 SDK & spelled right; protocol conformances satisfied; property-wrapper ownership correct; `NavigationStack`/`navigationDestination`/sheet bindings & `@Query`/`modelContainer` type-check; no iOS-18 APIs; no force-unwrap/`try!`/`as!` on user paths; no TODO/placeholder/stub strings; every `@Model` in the `Schema`; braces balanced. State the attestation explicitly.

## README (write `…/0X-slug/README.md`)
Sections: **What it is** (name, one-liner, problem + audience); **Features** (full list matching what you actually built); **Run** ("1) `brew install xcodegen` (one-time). 2) In `ios/`, run `xcodegen generate` (or `./gen.sh` at repo root). 3) Open `<App>.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R."); **Free signing** note; **Tech notes** (iOS 17+, SwiftUI, SwiftData, design language, a one-line **Monetization** note, a one-line **Why it can boom** note); **Self-review** attestation.

Build the COMPLETE app. No stubs, no half-screens, no dead buttons. Make it feel premium.
