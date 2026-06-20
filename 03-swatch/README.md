# Swatch

Swatch is a production-ready iOS app that extracts beautiful color palettes from photos using on-device K-means clustering.

## Features

- **Photo Library & Camera**: Pick any photo from your library or capture one with the camera
- **K-means Color Extraction**: On-device clustering algorithm finds 4–8 dominant colors from any image
- **Color Naming**: Automatically names each extracted color using nearest-neighbor matching against CSS named colors
- **Hex & RGB Values**: Tap any swatch to copy its hex code; view RGB values in the detail view
- **Palette Collection**: Save named palettes to a local SwiftData store and browse them in a 2-column grid
- **Share**: Export any palette as plain text with color names, hex codes, and RGB values
- **Settings**: Configure default color count (4–8) and clear all saved palettes

## Tech Stack

- **Swift / SwiftUI** — 100% SwiftUI with NavigationStack, PhotosPicker, sheets
- **SwiftData** — Persistent storage for palettes and colors
- **K-means (pure Swift)** — On-device clustering with 20 iterations, no ML frameworks required
- **UIImagePickerController** — Camera capture via UIViewControllerRepresentable

## Building

Requires [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
cd ios
xcodegen generate
open Swatch.xcodeproj
```

Then build and run on an iOS 17+ device or simulator.

## Architecture

```
Swatch/
├── Models/
│   ├── SwatchModels.swift      # SwiftData @Model classes (Palette, SwatchColor)
│   ├── KMeansExtractor.swift   # Actor-based K-means implementation
│   └── ColorNamer.swift        # CSS color nearest-neighbor namer
├── Views/
│   ├── MainTabView.swift       # Root tab container
│   ├── Onboarding/             # First-launch onboarding screen
│   ├── Palettes/               # Extract, list, and detail views
│   ├── Camera/                 # UIImagePickerController wrapper
│   └── Settings/               # Preferences and data management
└── Theme/
    └── SwatchTheme.swift       # Shared colors and style constants
```
