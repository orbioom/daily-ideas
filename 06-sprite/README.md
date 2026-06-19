# Sprite — Pixel Art Creator

**Platform:** iOS 17+ · **Stack:** SwiftUI 5, SwiftData, CoreGraphics · **Monetization:** One-time Pro IAP ($2.99)

## What it does
Sprite is a fully-featured pixel art studio for iOS. Create retro-style sprites and icons on 8×8, 16×16, or 32×32 grids using pen, eraser, flood-fill, and eyedropper tools. Export scaled PNGs to Photos.

## Key Features
- 4 tools: Pen, Eraser, Flood Fill, Eyedropper
- 12-color default palette; add custom colors via eyedropper
- Unlimited undo/redo (30-step history)
- Toggle grid lines for precise pixel work
- Checkerboard transparent background preview
- Artworks gallery with live canvas previews
- Create multiple artworks at different sizes (8, 16, 32)
- Export as 512px PNG with transparency to Photos
- Full dark/light mode, haptics, VoiceOver, dynamic type
- Free: 8, 16, 32 sizes · Pro: 64×64 + custom palettes ($2.99 one-time)

## Architecture
- `CanvasViewModel` — `@Observable`: pixel buffer `[Int]` (ARGB ints), flood-fill BFS, undo/redo stacks, SwiftData auto-persist
- `SpriteCanvasView` — SwiftUI `Canvas` renderer with `DragGesture` for draw/erase
- `SpriteGalleryView` — artwork list with `ArtworkPreview` Canvas thumbnails
- `SpriteArtwork` + `SpritePrefs` — SwiftData models with JSON-encoded pixel/palette data

## Beat
Beats Pixelmator and complex desktop-style apps by offering a minimal, thumb-friendly mobile-first interface optimized for quick sprite creation on the go.
