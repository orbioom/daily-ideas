# Shared build spec — Orbioom iOS run 2026-06-15_0610-UTC

You are building ONE complete, production-ready native iOS app. Read this fully.
The app's design assets are ALREADY GENERATED — do not touch them.

## What already exists (DO NOT CREATE OR MODIFY)
Under `ios/<App>/<App>/Assets.xcassets/`:
- `AppIcon.appiconset/` (real 1024 icon + Contents.json) ✅
- `AccentColor.colorset/` ✅
- `LaunchBackground.colorset/` (light+dark) ✅
- `Contents.json` ✅
And `ios/<App>/Preview Content/Preview Assets.xcassets/Contents.json` ✅

You write everything else: `ios/project.yml`, `ios/<App>/Info.plist`, all Swift under
`ios/<App>/<App>/...`, and `README.md` at the app folder root (`0X-<slug>/README.md`).

## Folder layout (exact)
```
0X-<slug>/
  README.md
  ios/
    project.yml
    <App>/
      Info.plist
      Assets.xcassets/            (ALREADY DONE)
      Preview Content/...         (ALREADY DONE)
      <App>/
        <App>App.swift            # @main
        Models/  ViewModels/  Views/(Onboarding|Settings|Components|<feature folders>)/
        Theme/  Persistence/  Utilities/
```

## project.yml (copy exactly, replace <App> and <lower>)
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

## Info.plist (copy exactly, replace <App>; add usage strings ONLY if the app uses that capability)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key><string>en</string>
	<key>CFBundleDisplayName</key><string><App></string>
	<key>CFBundleExecutable</key><string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key><string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
	<key>CFBundleName</key><string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key><string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key><string>$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key><string>$(CURRENT_PROJECT_VERSION)</string>
	<key>LSRequiresIPhoneOS</key><true/>
	<key>UIApplicationSceneManifest</key>
	<dict><key>UIApplicationSupportsMultipleScenes</key><false/></dict>
	<key>UILaunchScreen</key>
	<dict><key>UIColorName</key><string>LaunchBackground</string></dict>
	<key>UIRequiredDeviceCapabilities</key><array><string>arm64</string></array>
	<key>UISupportedInterfaceOrientations</key>
	<array><string>UIInterfaceOrientationPortrait</string></array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
</dict>
</plist>
```

## Definition of Done (ALL required, verifiable by reading source)
1. Complete feature set — every screen/control/tab/button/swipe wired to real behavior; full CRUD where data is user-owned.
2. >= 4 distinct substantive feature screens (NOT counting Onboarding or Settings) via NavigationStack/TabView; back/dismiss always works.
3. First-run onboarding gated by a persisted `@AppStorage("hasOnboarded")` flag.
4. Empty states everywhere data is shown.
5. Loading states for any async/computed work (`async`/`await`, `@MainActor`).
6. Error states — calm, recoverable; NEVER `fatalError`, `try!`, or force-unwrap on user paths.
7. Success states.
8. Settings screen with >= 3 real persisted, functional preferences.
9. Persistence surviving relaunch: primary data in **SwiftData** (iOS 17, `@Model`/`@Query`/`modelContainer`). `UserDefaults`/`@AppStorage` only for small prefs/flags.
10. Input validation & crash-proofing (no force-unwrap/`try!`/unchecked index/unguarded division on user paths). Guard divisions.
11. Accessibility: Dynamic Type everywhere; `accessibilityLabel`/`Hint`/`Value`; decorative images `.accessibilityHidden(true)`; WCAG AA contrast in both modes; honor `@Environment(\.accessibilityReduceMotion)`.
12. Haptics where meaningful (sparse; gated by a Settings toggle).
13. AppIcon/AccentColor/launch screen — ALREADY DONE, just reference them.
14. Light AND dark mode first-class. Define colors per-`colorScheme` in a `Theme` (use `Color(.sRGB...)` literals or `Color("AccentColor")`). NO hardcoded colors that break in the other mode.
15. Tasteful animation in the app's own design language; respect Reduce Motion (skip/!shorten animations when set).
16. Cohesive, intentional visual identity applied consistently across every screen. No naked default SwiftUI.
17. Performance: lazy containers, stable `Identifiable` IDs; seed/test with 50+ items where a collection is implied.

## Crash-proofing rules (the compiler is YOU — there is no Xcode here)
- Re-read EVERY Swift file before finishing. Verify each `import`, every type/initializer/enum case/modifier exists in the iOS 17 SDK and is spelled right, every protocol conformance is satisfied, property wrappers used correctly with ownership hoisted right, NavigationStack/navigationDestination/sheet bindings + `@Query`/`modelContainer` wiring type-checks. No APIs newer than iOS 17.
- Anti-stub grep MUST be clean: no `TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`// stub`.
- SwiftData gotchas: `@Model` classes need an initializer; relationships use `@Relationship(deleteRule:)`; enums stored in models must be `Codable` (raw-value enums are fine). Don't put computed-only values in `@Query` filters that SwiftData can't evaluate — fetch then compute in Swift. Avoid `#Predicate` referencing enum raw values in ways SwiftData can't translate; if unsure, fetch all + filter in memory.
- Use `Decimal` for money. Guard against divide-by-zero. Use `Calendar`/`DateComponents` for date math (leap-safe).
- For charts use Swift `Charts` (`import Charts`). For lists use `List`/`LazyVStack`/`LazyVGrid`.

## Design
Each app has a chosen accent (already in AccentColor). Build a real visual identity: a `Theme.swift` with semantic colors (background, surface/card, primary text, secondary text, accent, success/warn) defined for light AND dark, consistent corner radii, typography scale, and reusable styled components (cards, buttons, pills, section headers). Make first launch feel intentional.

## README.md (per app)
Sections: **What it is** (name, one-liner, problem + audience); **Features** (full list matching shipped app); **Run** ("1) `brew install xcodegen` (one-time). 2) In `ios/`, run `xcodegen generate` (or `./gen.sh` at repo root). 3) Open `<App>.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R."); **Free signing** (works with a personal Apple ID, no paid account; code-signing only needed for device install); **Tech notes** (iOS 17+, SwiftUI 5, MVVM, SwiftData persistence, design language; one-line **Monetization** note; one-line **Why it can boom** note); **Self-review** (attest: compiles by inspection, anti-stub grep clean, DoD met).

Deliver a complete, compiling, stub-free app. No placeholders. No half-built screens.
