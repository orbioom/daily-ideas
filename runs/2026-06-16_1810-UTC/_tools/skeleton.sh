#!/usr/bin/env bash
# Create a valid app skeleton (project.yml, Info.plist, asset catalogs + icon).
# Usage: skeleton.sh <RunDir> <App> <slug> <glyph> <accentHex> <launchLightHex> <launchDarkHex>
set -euo pipefail
RUN="$1"; APP="$2"; SLUG="$3"; GLYPH="$4"; ACCENT="$5"; LLIGHT="$6"; LDARK="$7"
LOW=$(echo "$APP" | tr '[:upper:]' '[:lower:]')
BASE="$RUN/$(printf '%s' "$SLUG")"
SRC="$BASE/ios/$APP/$APP"
mkdir -p "$SRC/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$SRC/Assets.xcassets/AccentColor.colorset"
mkdir -p "$SRC/Assets.xcassets/LaunchBackground.colorset"
mkdir -p "$BASE/ios/$APP/Preview Content/Preview Assets.xcassets"
mkdir -p "$SRC/Models" "$SRC/Views" "$SRC/Theme" "$SRC/Persistence" "$SRC/Utilities"

# project.yml
cat > "$BASE/ios/project.yml" <<YML
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
        PRODUCT_BUNDLE_IDENTIFIER: com.orbioom.$LOW
        INFOPLIST_FILE: $APP/Info.plist
        GENERATE_INFOPLIST_FILE: NO
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        DEVELOPMENT_ASSET_PATHS: "\"$APP/Preview Content\""
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.0"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
YML

# Info.plist
cat > "$BASE/ios/$APP/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key><string>en</string>
	<key>CFBundleDisplayName</key><string>$APP</string>
	<key>CFBundleExecutable</key><string>\$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key><string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
	<key>CFBundleName</key><string>\$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key><string>\$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key><string>\$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key><string>\$(CURRENT_PROJECT_VERSION)</string>
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
PLIST

# Asset catalog roots
printf '{\n  "info" : { "author" : "xcode", "version" : 1 }\n}\n' > "$SRC/Assets.xcassets/Contents.json"
printf '{\n  "info" : { "author" : "xcode", "version" : 1 }\n}\n' > "$BASE/ios/$APP/Preview Content/Preview Assets.xcassets/Contents.json"

# AppIcon Contents.json
cat > "$SRC/Assets.xcassets/AppIcon.appiconset/Contents.json" <<ICON
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
ICON

# AccentColor
AR=0x${ACCENT:0:2}; AG=0x${ACCENT:2:2}; AB=0x${ACCENT:4:2}
cat > "$SRC/Assets.xcassets/AccentColor.colorset/Contents.json" <<ACC
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "red" : "$AR", "green" : "$AG", "blue" : "$AB", "alpha" : "1.000" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
ACC

# LaunchBackground (light + dark)
LR=0x${LLIGHT:0:2}; LG=0x${LLIGHT:2:2}; LB=0x${LLIGHT:4:2}
DR=0x${LDARK:0:2}; DG=0x${LDARK:2:2}; DB=0x${LDARK:4:2}
cat > "$SRC/Assets.xcassets/LaunchBackground.colorset/Contents.json" <<LAUNCH
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "red" : "$LR", "green" : "$LG", "blue" : "$LB", "alpha" : "1.000" }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "color" : {
        "color-space" : "srgb",
        "components" : { "red" : "$DR", "green" : "$DG", "blue" : "$DB", "alpha" : "1.000" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
LAUNCH

# Icon PNG (gradient top = launch light tinted toward accent, bottom = accent-dark)
python3 "$RUN/_tools/make_icon.py" "$SRC/Assets.xcassets/AppIcon.appiconset/icon-1024.png" \
  "$GLYPH" "$8" "$9" "$ACCENT"

echo "skeleton ready: $BASE  (accent #$ACCENT)"
