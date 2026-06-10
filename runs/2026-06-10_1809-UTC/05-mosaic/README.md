# Mosaic — Photo collage & grid maker

Build a beautiful photo collage in seconds: pick from nine layouts, drop in your photos, pan/zoom each one, tune spacing/corners/borders/background, apply tasteful per-photo filters, and export in high resolution — with **no watermark, ever**. The clean, fair answer to PicCollage-style apps that slap watermarks on free exports and lock basics behind a $36/yr VIP.

## What it is
- **One-line:** A fast, watermark-free photo collage maker that keeps your photos on-device.
- **Problem + audience:** Collage apps are a massive, evergreen photo category (the leader has 1.8M+ ratings), but free exports carry watermarks and ads, and customization is paywalled. Layout-style "no watermark, no ads" apps are loved precisely for being clean — Mosaic is that, with more layouts, filters, and control.

## Full feature list
- **Projects gallery:** saved collages with rendered thumbnails, photo counts, create/delete (with image-file cleanup).
- **New collage:** pick one of **9 layouts** (single, grids, big+two, rows, six-grid, etc.) and a **canvas aspect** (1:1, 4:5, 9:16, 16:9, Story).
- **Editor** (4 tool panels):
  - **Photo:** import per cell via PhotosUI; replace/remove; **drag to reposition, pinch to zoom** inside any cell.
  - **Layout:** switch templates live (cells added/removed, images preserved where possible).
  - **Filter:** 8 Core Image filters (Original, Mono, Noir, Sepia, Vivid, Cool, Warm, Fade) applied **per photo**, with live filtered thumbnails.
  - **Adjust:** spacing, corner radius, and border-width sliders; aspect picker; background-color swatches.
- **Export:** render to a high-resolution `UIImage` (2000/3000/4000px) via `ImageRenderer`, **Share** or **Save to Photos** — no watermark; a thumbnail is saved back to the gallery.
- **Settings:** export resolution, appearance, haptics, delete-all-collages, privacy/version.
- Onboarding gated by a persisted flag; empty/loading/success/error states (render failure and save-permission errors surface calmly).

## Run steps
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Mosaic.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

## Free-signing note
No paid account needed: select your personal team under Signing & Capabilities and run on a simulator or your own device. Saving to Photos prompts for add-only access (declared in Info.plist).

## Tech notes
- iOS 17+, SwiftUI 5, MVVM with an `@Observable` `EditorModel` (image + filtered caches keyed by file|filter), a pure `FilterEngine` (Core Image), `Templates` (unit-space layouts), and an `ImageRenderer`-based `Exporter`.
- Persistence: layout + per-cell settings in **SwiftData** (`CollageProject` ⟶ cascade `CollageCell`); photo bytes live on disk via `ImageStore` (Documents), never in SwiftData or the cloud; `@AppStorage` for prefs.
- Design language: **Orbioom** with a warm terracotta accent (a justified, cohesive standout for a creative photo tool).
- **Monetization:** freemium — all 9 layouts, filters, and watermark-free export free; a one-time "Mosaic Pro" (sticker/text layers, more templates, batch export) is the upsell. Never a watermark on free exports — the core differentiator.
- **Why it can boom:** photo collage is a proven, high-volume category whose leaders are resented for watermarks, ads, and paywalled basics; a clean, private, no-watermark maker is exactly what the loved-but-limited alternatives prove people want.

## Self-review
Re-read every Swift file: imports verified; all SwiftUI/SwiftData/PhotosUI/CoreImage/ImageRenderer symbols exist in iOS 17; the cell pan/zoom uses `@GestureState` correctly within its owning view (no cross-view binding); `@Observable`/`@State`/`@Query`/`navigationDestination(item:)`/`modelContainer` wiring type-checks; no force-unwraps/`try!`/`fatalError` on user paths (container falls back to in-memory; audio/photo failures handled); anti-stub grep clean. Dynamic Type, accessibility, light/dark, and `NSPhotoLibraryAddUsageDescription` all handled.
