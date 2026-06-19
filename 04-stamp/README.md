# Stamp — Sticker Maker

**Platform:** iOS 17+ · **Stack:** SwiftUI 5, SwiftData, PhotosUI, CoreGraphics · **Monetization:** One-time Pro IAP ($1.99)

## What it does
Stamp turns any photo into a sticker in seconds. Import a photo, automatically remove the background, customize the border and shadow, then export a PNG ready to share anywhere.

## Key Features
- PhotosPicker integration — import any image from your library
- Automatic background removal via color-distance thresholding on the pixel buffer
- Adjustable border: thickness (0–40 px) and 9 color presets
- Drop shadow toggle
- Gallery of saved stickers with swipe-to-delete
- Export to Photos (PNG with transparency) or share sheet
- Full dark/light mode, haptics, VoiceOver labels, dynamic type
- Free: unlimited stickers · Pro: batch export, custom backgrounds ($1.99 one-time)

## Architecture
- `StickerViewModel` — `@Observable`: drives photo loading, background removal (per-pixel color distance), and `UIGraphicsImageRenderer`-based sticker compositing
- `StickerEditorView` — PhotosPicker + preview canvas + tool controls
- `StampGalleryView` — `LazyVGrid` with context-menu share/delete
- `SavedSticker` + `StampPrefs` — SwiftData persistence

## Beat
Beats expensive sticker-maker apps ($4.99+/month) by offering the core workflow — import, remove BG, add border, export — for a tiny one-time price with no subscription.
