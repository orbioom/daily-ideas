# Loft

**Vision board & goal tracker for iOS**

## Problem & Audience

Vision boards are proven to boost goal achievement through visualization, yet existing apps are either clunky web tools or subscription-gated. Loft is a fast, local-first native iOS app for creating beautiful boards and tracking milestones. Audience: self-improvement and productivity users, predominantly women 18–40.

## Features

- **Vision Boards** — Create boards by life category (Career, Health, Travel, etc.)
- **Photo collage** — Add photos from library via `PhotosPicker`, with captions
- **Affirmation text** — per-board custom affirmation shown prominently
- **Goals with milestones** — linked to boards, with target dates and progress bars
- **Milestone checklist** — tap to complete; board auto-marks "complete" when all done
- **Category filtering** — filter boards by life area
- **Stats screen** — completion rates, streak, category breakdown
- **Settings** — haptics, theme accent, notification reminder

## Run Steps

```bash
cd runs/2026-06-11_0100-UTC/03-loft/ios
xcodegen generate
open Loft.xcodeproj
# Requires NSPhotoLibraryUsageDescription (already in Info.plist)
```

## Tech Notes

- `ImageStore` utility wraps `FileManager` JPEG storage in `Documents/LoftImages/`
- `PhotosPickerItem.loadTransferable(type: Data.self)` for async photo loading
- `VisionBoard` → `BoardItem` and `Goal` → `Milestone` cascade-delete relationships in SwiftData
- `LoftTheme` includes `Color(hex:)` extension for accent color picker

## Monetization

**3 boards free** → Loft Pro unlocks unlimited boards + goals for $3.99/month. Also sells "Vision Pack" photo collections as one-time IAPs ($1.99 each).

## Why It Can Hit

Vision board apps consistently rank in the top Lifestyle charts. A clean, fast native app with proper SwiftData and PhotosUI integration beats the slow web-based competitors that dominate the category.

## Self-Review Attestation

- [x] Photo library integration fully implemented
- [x] SwiftData cascade deletes on boards/goals/milestones
- [x] 4+ screens (Boards list, Board detail, Goals, Stats, Settings)
- [x] FileManager-based image store (no CoreData binary blobs)
- [x] XcodeGen project.yml, iOS 17
