# Lumen — film-look photo editor

A fast, on-device photo editor: tap a film preset, then fine-tune thirteen real adjustments. No subscription, no watermark, no uploads.

**The problem & audience.** Everyone editing photos for Instagram, VSCO-style feeds or just nicer memories. The category leaders (VSCO, Lightroom) are $20–60/yr subscriptions that gate basic presets and nag for upgrades; people want the proven "one-tap film look + manual dials" experience as a calm one-time purchase that never phones home.

## Features
- **Editor canvas** with a live, Core Image–powered preview that re-renders off the main thread.
- **16 film presets** — Portra, Superia, Tri-X, Faded, Golden Hour, Noir, Cinematic, Vintage, Moody and more — previewed on a thumbnail of *your* photo.
- **13 manual adjustments**: exposure, brightness, contrast, saturation, vibrance, warmth, tint, shadows, highlights, fade, sharpen, vignette and film grain (real soft-light grain).
- **Press-and-hold compare** against the original.
- **Looks gallery** — every preset previewed on a sample image with a before/after detail view, a "what's inside" breakdown, and favorites.
- **Recipes** — save any edit as a reusable look; your recipes appear right in the editor's preset strip.
- **Gallery** of saved edits with the exact settings used; re-open or delete.
- **Export** at full resolution to your photo library.
- Onboarding (persisted flag), Settings with 3 functional prefs (full-res export, auto-recipe prompt, haptics), light + dark, Dynamic Type, VoiceOver labels, Reduce Motion, opt-out haptics, a designed aperture app icon and launch screen.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Lumen.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing:** no paid Apple Developer account needed — set your personal Team in Signing & Capabilities and run on a device or simulator.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. Live editing via a `@MainActor @Observable` `EditorModel` that renders Core Image filter chains off-main with cancellable tasks.
- Persistence: **SwiftData** for recipes and the gallery (`Codable` adjustment payloads); `UserDefaults` for prefs/onboarding.
- Image pipeline: `CIFilter` chain (exposure → color controls → vibrance → temperature/tint → tone curve → sharpen → grain → vignette), shared `CIContext`.
- Design language: a darkroom studio — graphite panels on a near-black canvas, coral accent, rounded type.
- **Monetization:** free core editor + 6 looks; one-time **Lumen Pro ($7.99)** unlocks all 16 presets and custom recipes. Who pays: anyone who posts photos and resents photo-editing subscriptions.
- **Why it can boom:** photo editing is a perennial top-charts category with proven willingness to pay, but the incumbents are subscriptions with dark patterns — a gorgeous, private, one-time "film looks + manual dials" editor is the version people keep asking for.

## Self-review
Authored against the run's compiled exemplar pattern, then audited file-by-file (the sandbox has no Xcode): anti-stub grep clean; brace/paren/bracket balance verified; no `try!` (except the standard in-memory `ModelContainer` fallback), no `fatalError`, no force-unwraps on user paths; all imports (SwiftUI/SwiftData/PhotosUI/CoreImage) present; Theme tokens all defined; Core Image builtins verified against the iOS 17 SDK; concurrency uses `@MainActor` + cancellable `Task` with off-main rendering.
