#!/usr/bin/env bash
# scaffold.sh <RunDir> <SlugFolder> <AppName> <lowerid> <glyph> <accentR,G,B>
# Creates the shared Orbioom boilerplate for one app. Domain Swift files are written separately.
set -euo pipefail
RUN="$1"; SLUG="$2"; APP="$3"; LOWER="$4"; GLYPH="$5"; ACCENT="$6"
TOOLS="$RUN/_tools"
BASE="$RUN/$SLUG/ios/$APP"
mkdir -p "$BASE/Models" "$BASE/ViewModels" "$BASE/Views/Onboarding" "$BASE/Views/Settings" "$BASE/Views/Components" \
         "$BASE/Persistence" "$BASE/Theme" "$BASE/Utilities" \
         "$BASE/Assets.xcassets/AppIcon.appiconset" "$BASE/Assets.xcassets/AccentColor.colorset" \
         "$BASE/Assets.xcassets/LaunchBackground.colorset" "$BASE/Preview Content/Preview Assets.xcassets"

# Theme + haptics (copied verbatim, identical across apps)
cp "$TOOLS/Brand.swift" "$BASE/Theme/Brand.swift"
cp "$TOOLS/Haptics.swift" "$BASE/Utilities/Haptics.swift"

# Icon
python3 "$TOOLS/make_icon.py" "$BASE/Assets.xcassets/AppIcon.appiconset/icon-1024.png" "$GLYPH" "$ACCENT" >/dev/null

# project.yml
cat > "$RUN/$SLUG/ios/project.yml" <<YML
name: $APP
options:
  bundleIdPrefix: com.orbioom
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
targets:
  $APP:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - $APP
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.orbioom.$LOWER
        INFOPLIST_FILE: $APP/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.0"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
YML

# Info.plist
cat > "$BASE/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>\$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>$APP</string>
	<key>CFBundleExecutable</key>
	<string>\$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>\$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>\$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key>
	<string>\$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key>
	<string>\$(CURRENT_PROJECT_VERSION)</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<true/>
	</dict>
	<key>UILaunchScreen</key>
	<dict>
		<key>UIColorName</key>
		<string>LaunchBackground</string>
	</dict>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
</dict>
</plist>
PLIST

# Asset catalog roots
cat > "$BASE/Assets.xcassets/Contents.json" <<'J'
{
  "info" : { "author" : "xcode", "version" : 1 }
}
J
cat > "$BASE/Preview Content/Preview Assets.xcassets/Contents.json" <<'J'
{
  "info" : { "author" : "xcode", "version" : 1 }
}
J
cat > "$BASE/Assets.xcassets/AppIcon.appiconset/Contents.json" <<'J'
{
  "images" : [
    {
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
J
cat > "$BASE/Assets.xcassets/AccentColor.colorset/Contents.json" <<'J'
{
  "colors" : [
    {
      "idiom" : "universal",
      "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", "red" : "0x1B", "green" : "0x1D", "blue" : "0x2A" } }
    },
    {
      "idiom" : "universal",
      "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", "red" : "0xF2", "green" : "0xF3", "blue" : "0xF8" } }
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
J
cat > "$BASE/Assets.xcassets/LaunchBackground.colorset/Contents.json" <<'J'
{
  "colors" : [
    {
      "idiom" : "universal",
      "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", "red" : "0xED", "green" : "0xEE", "blue" : "0xF3" } }
    },
    {
      "idiom" : "universal",
      "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "color" : { "color-space" : "srgb", "components" : { "alpha" : "1.000", "red" : "0x14", "green" : "0x15", "blue" : "0x1B" } }
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
J

echo "scaffolded $APP at $BASE"
