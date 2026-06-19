# Stipple — Color-by-Number Pixel Art

**Platform:** iOS 17+ · **Stack:** SwiftUI 5, SwiftData · **Monetization:** One-time Pro IAP ($4.99)

## What it does
Stipple is a color-by-number pixel art app with 15 hand-crafted scenes. Tap numbered cells to fill them with the matching palette color. Complete a scene to unlock a shareable artwork.

## Key Features
- 15 pixel scenes across 5 categories (Nature, Space, Food, Animals, Seasonal)
- Flood-fill auto-fill: tap and hold to fill all connected matching cells
- Daily scene: a fresh scene every day chosen deterministically from the library
- Zoom & pan the canvas with pinch/drag gestures
- Progress saved automatically via SwiftData
- Export completed art as a PNG and share it
- Full dark/light mode, haptics, dynamic type, and VoiceOver support
- 5 free scenes · 10 Pro scenes ($4.99 one-time)

## Architecture
- `SceneLibrary` — 15 pixel scenes encoded as 20×20 grids painted from geometric shape functions
- `CanvasViewModel` — `@Observable` engine with flood-fill, progress tracking, and auto-persist
- `SceneProgress` + `StipplePrefs` — SwiftData models for state persistence
- SplitMix64 seeded RNG for deterministic daily scene selection

## Beat
Outperforms free color-by-number apps by offering zero ads, clean SwiftUI rendering, and a permanent unlock rather than per-pack purchases.
