# Montage — story & collage maker

Turn your photos into share-ready Instagram stories, square posts and collages. Pick a template, drop in photos, add a draggable caption and a gradient background, and export a crisp, watermark-free image in a tap.

**The problem & audience.** The enormous creator/social audience making stories and collages daily. Unfold, Mojo, StoryArt and Canva prove the demand and the money — but they paywall basic templates, stamp watermarks and push subscriptions; people want a fast, tasteful, watermark-free maker as a one-time buy.

## Features
- **Create** — 14 templates across Story (9:16), Square (1:1) and Collage layouts, each with a schematic preview.
- **Editor** — a live canvas that doubles as the export renderer: tap any frame to add a photo, pick a solid or gradient **background**, and add **text overlays** you can drag anywhere, recolor, restyle (4 weights), resize and shadow.
- **Export** — renders at 1080-wide full resolution via `ImageRenderer`, saves to your photo library, and offers a native `ShareLink` — no watermark.
- **Backgrounds** — a palette library of solids and gradients with favorites that float to the top of the editor's Style picker.
- **Creations** — a gallery of everything you've exported, with re-share and delete.
- Onboarding (persisted), Settings with default story background, start-with-caption and haptics (wired into new designs), light + dark, Dynamic Type, VoiceOver, Reduce Motion, opt-out haptics, a designed overlapping-frames icon and launch screen.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Montage.xcodeproj` in Xcode 15+, iOS 17+ simulator, Cmd+R.

**Free-signing:** personal Team in Signing & Capabilities — no paid account needed.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM with a `@Observable` `DesignVM`; one `DesignCanvas` view renders both the live preview and the export (`ImageRenderer`), so what you see is what you save.
- Persistence: **SwiftData** (`Creation` JPEG previews); static template/background libraries; `UserDefaults` for prefs/favorites.
- Photos via PhotosUI; normalized (0–1) frame & text geometry shared by preview and export.
- Design language: vibrant creator studio — warm pink, clean cards, rounded type.
- **Monetization:** free studio, never watermarked; one-time **Montage Pro ($5.99)** unlocks all premium gradients and looks. Who pays: creators and small businesses posting stories who resent watermarks and subscriptions.
- **Why it can boom:** story/collage makers (Unfold, Mojo) have tens of millions of installs and strong revenue, but they watermark and subscribe — a fast, tasteful, watermark-free, one-time maker is the version creators wish existed.

## Self-review
Audited file-by-file: anti-stub grep clean; balanced delimiters; only the in-memory `ModelContainer` `try!`, no `fatalError`, no force-unwraps; `BackgroundStyle.fill` (a View) usage fixed to layer correctly rather than be passed as a ShapeStyle; imports (SwiftUI/SwiftData/PhotosUI) present; `ImageRenderer`/`ShareLink`/`ProposedViewSize` verified for iOS 17; Theme tokens defined.
