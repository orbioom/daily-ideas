# Orbioom iOS build conventions (READ FULLY before writing code)

You are building **one** complete, production-ready native iOS app for the Orbioom studio.
Work ONLY inside the app folder you are given. Do NOT touch other app folders. Do NOT run
git. The sandbox has NO Xcode — **you are the compiler**; every file must be hand-verified to
compile against the **iOS 17 SDK**.

## Brand & design
Calm, considered, "Liquid Glass"-inspired but **native-first** (respect Apple HIG). Quiet
surfaces, generous spacing, one focal idea per screen, restrained/purposeful motion, green used
only as a rare luminous accent (not the whole palette). Each app must have a **cohesive,
intentional visual identity** — never leave stock SwiftUI controls unstyled. Build to feel good
on the hundredth use, not just the first.

## Tech
iOS 17, SwiftUI, MVVM. **SwiftData** for primary user data (Codable+FileManager only if SwiftData
truly cannot fit). `@AppStorage`/UserDefaults for small prefs & flags only. Swift `Charts` where it
adds value. **No external dependencies. No networking / API keys** (mock with realistic fixtures).
No audio/camera/GPS/PhotoKit unless your spec explicitly asks.

## Definition of Done (ALL required — verifiable by reading the source)
1. ≥4 distinct, substantive **feature screens** (excluding alerts/sheets, NOT counting Onboarding
   or Settings) via `NavigationStack`/`TabView`; back/dismiss always works; no dead ends; full CRUD
   where data is user-owned.
2. First-run onboarding gated by `@AppStorage("hasOnboarded")`.
3. **Empty states** everywhere data is shown. **Loading states** for async/computed work
   (`async`/`await`, `@MainActor` where needed). Calm, recoverable **error states** (never silent
   failure, `fatalError`, `try!`, or force-unwrap on user paths). **Success states**.
4. **Settings** screen with ≥3 real, persisted, functional prefs.
5. Persistence survives relaunch (SwiftData).
6. Input validation & crash-proofing: **no force-unwrap / `try!` / unchecked array index /
   unguarded division on user paths.** The ONLY allowed `try!` is the in-memory `ModelContainer`
   fallback shown below.
7. Full **accessibility**: Dynamic Type app-wide (prefer system text styles or `.dynamicTypeSize`
   friendly fonts), `accessibilityLabel`/`Hint`/`Value`, decorative images hidden
   (`.accessibilityHidden(true)`), WCAG AA contrast in both modes, Reduce Motion via
   `@Environment(\.accessibilityReduceMotion)`.
8. **Haptics** where meaningful (sparse), gated by a Settings toggle.
9. Real **AppIcon** (generate with the tool below), **AccentColor**, **LaunchBackground** launch
   screen.
10. **Light AND dark mode** first-class via the `Color.dyn(light, dark)` pattern; no hardcoded
    colors that break in either mode.
11. Tasteful animation in the app's own language; respect Reduce Motion (no large motion when on).
12. Lazy containers (`LazyVStack`/`List`/`LazyVGrid`) with stable `Identifiable` IDs; smooth at
    50+ items.
13. **Anti-stub**: NO `TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/
    `// stub` anywhere.

## Folder layout (inside `<app-folder>/ios/<App>/`)
`Models/  ViewModels/  Views/(Onboarding/  Settings/  Components/  + feature folders)  Theme/
 Persistence/ (if used)  Utilities/` — keep Models, ViewModels, Views in separate files.

## Pro unlock (honest)
If your spec mentions a Pro tier, add a tasteful `PaywallView` that explains the one-time unlock
and has an "Unlock <App> Pro" button + "Restore". Since StoreKit products are not configured in
this build, back it with `@AppStorage("isPro")` and clearly label the button as a local unlock for
this build (e.g. footnote "Demo build: unlocks locally; production wires StoreKit 2."). Gate the
Pro features behind `isPro`. Never use dark patterns; the free tier must be genuinely useful.

## EXACT scaffold files (substitute `<App>` and `<lower>`)

### `ios/project.yml`
```yaml
name: <App>
options:
  bundleIdPrefix: com.orbioom
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
targets:
  <App>:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - <App>
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.orbioom.<lower>
        INFOPLIST_FILE: <App>/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        DEVELOPMENT_ASSET_PATHS: "\"<App>/Preview Content\""
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.0"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
```

### `ios/<App>/Info.plist`
Standard plist: `CFBundleDevelopmentRegion=en`, `CFBundleDisplayName=<App>`,
`CFBundleExecutable=$(EXECUTABLE_NAME)`, `CFBundleIdentifier=$(PRODUCT_BUNDLE_IDENTIFIER)`,
`CFBundleInfoDictionaryVersion=6.0`, `CFBundleName=$(PRODUCT_NAME)`,
`CFBundlePackageType=$(PRODUCT_BUNDLE_PACKAGE_TYPE)`, `CFBundleShortVersionString=$(MARKETING_VERSION)`,
`CFBundleVersion=$(CURRENT_PROJECT_VERSION)`, `LSRequiresIPhoneOS=true`,
`UIApplicationSceneManifest`→`UIApplicationSupportsMultipleScenes=false`,
`UILaunchScreen`→`UIColorName=LaunchBackground`, `UIRequiredDeviceCapabilities=[arm64]`,
portrait for iPhone, all orientations for iPad. Add `NS...UsageDescription` keys ONLY if you use
that capability (most of these apps use none).

### `ios/<App>/<App>App.swift`
```swift
import SwiftUI
import SwiftData

@main
struct <App>App: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    let container: ModelContainer
    init() {
        do {
            container = try ModelContainer(for: <Model1>.self, <Model2>.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: <Model1>.self, <Model2>.self, configurations: config)
        }
    }
    var body: some Scene {
        WindowGroup {
            Group { if hasOnboarded { RootView() } else { OnboardingView() } }
                .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}
```

### `ios/<App>/Theme/Theme.swift` — include this EXACT extension, then a `Theme` enum
```swift
import SwiftUI
import UIKit

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >> 8) & 0xFF) / 255.0,
                  blue: Double(hex & 0xFF) / 255.0,
                  opacity: 1.0)
    }
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255.0,
                           green: CGFloat((h >> 8) & 0xFF) / 255.0,
                           blue: CGFloat(h & 0xFF) / 255.0,
                           alpha: 1.0)
        })
    }
}
```
Define a `Theme` enum with: `bg`, `surface`, `surfaceAlt`, `ink`, `inkSoft`, `inkFaint`, `accent`,
`accentSoft`, `hairline`, `good`, `bad`, plus any app-specific tints, each via `Color.dyn(light, dark)`.
Add font helpers (e.g. `rounded(_:_: )`, `serif(_:_: )` using `.system(size:weight:design:)`).
**Every token you reference in views must be defined here.**

### Assets (`ios/<App>/Assets.xcassets/`)
- `Contents.json`: `{"info":{"author":"xcode","version":1}}`
- `AppIcon.appiconset/Contents.json`:
  `{"images":[{"filename":"icon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}`
- `AppIcon.appiconset/icon-1024.png`: generate it (command below).
- `AccentColor.colorset/Contents.json`: one universal entry with your accent in srgb hex components.
- `LaunchBackground.colorset/Contents.json`: light universal + dark appearance variant:
```json
{"colors":[{"idiom":"universal","color":{"color-space":"srgb","components":{"red":"0xLL","green":"0xLL","blue":"0xLL","alpha":"1.000"}}},{"idiom":"universal","appearances":[{"appearance":"luminosity","value":"dark"}],"color":{"color-space":"srgb","components":{"red":"0xDD","green":"0xDD","blue":"0xDD","alpha":"1.000"}}}],"info":{"author":"xcode","version":1}}
```
- `ios/<App>/Preview Content/Preview Assets.xcassets/Contents.json`: `{"info":{"author":"xcode","version":1}}`

### Generate the app icon (run from repo root `/home/user/daily-ideas`)
```
python3 runs/2026-06-14_0012-UTC/_tools/make_icon.py "<ABS_PATH>/Assets.xcassets/AppIcon.appiconset/icon-1024.png" <glyph> <R,G,B>
```
Your spec gives `<glyph>` and `<R,G,B>` (the accent). Verify the PNG is 1024×1024 with `file`.

## SwiftData gotchas to respect
- `@Model final class` with a parameterless-safe `init`; relationships use `@Relationship` with an
  explicit `deleteRule` and inverse where you own children (avoid retain cycles; set inverse on one
  side). For self-referential trees, make `parent` optional and `children` the `@Relationship(inverse:)`.
- Enums stored on models must be `String`/`Int` raw values (store the raw, expose computed enum), or
  conform to `Codable` — prefer storing a raw `String`.
- `@Query` only inside Views; sort with `SortDescriptor`. Use `@Environment(\.modelContext)` for writes.
- Don't put non-persistable types on `@Model`. Arrays of value types that are `Codable` are fine.

## Self-review (MANDATORY before you finish)
Re-read EVERY Swift file and verify: each `import`; every type/initializer/enum case/modifier exists
in the iOS 17 SDK and is spelled right; protocol conformances satisfied; `@State`/`@StateObject`/
`@Binding`/`@Bindable`/`@Environment`/`@Observable`/`@Query`/`modelContainer` wiring type-checks and
ownership is hoisted correctly; `NavigationStack`/`navigationDestination`/sheet bindings type-check;
no APIs newer than iOS 17; brace/paren/bracket balance; every `Theme.` token is defined; no
force-unwrap/`try!`/`fatalError` on user paths. Then grep your folder for stub words and confirm
clean. Fix everything you find.

## README (`<app-folder>/README.md`)
Include: what it is (name, one-liner, problem + audience); full feature list (matching the shipped
app); run steps ("1) `brew install xcodegen` (one-time). 2) In `ios/`, run `xcodegen generate` (or
`./gen.sh` at repo root). 3) Open `<App>.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.");
free-signing note; Tech notes (iOS 17+, SwiftUI, MVVM, SwiftData, design language, **one-line
Monetization** note, **one-line Why it can boom** note); Self-review attestation.

## When done, report back
A concise list of the files you created, confirmation that self-review + anti-stub grep are clean,
and any single thing you could not fully verify.
