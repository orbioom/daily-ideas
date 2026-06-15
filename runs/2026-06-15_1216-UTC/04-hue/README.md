# Hue

A calm, private, on-device coloring book for iOS 17+. Tap regions of beautiful vector line-art to fill them with color, save your work, and build a gallery — no ads, no feed, no tracking.

## What it is

Hue is an anti-stress adult **coloring book**. You pick a curated palette, tap any region of a procedurally-generated page (mandalas, florals, geometric tilings, landscapes, whimsical art) to fill it, and your artwork autosaves continuously. There's a free-color mode and a guided **color-by-number** mode.

**The problem it solves:** the top-grossing coloring apps (Pigment, Recolor) wrap a relaxing activity in the opposite of relaxation — aggressive weekly subscriptions, ads between strokes, watermarks on everything, social feeds, and data harvesting. Hue is the calm alternative: everything is on-device, there is no account and no network, and Pro is a single fair one-time unlock.

**Audience:** anyone who colors to unwind — and specifically the large base of frustrated Recolor/Pigment users looking for a private, fairly-priced home.

## Features

- **Gallery** — pages grouped by category (Mandala, Floral, Geometric, Landscape, Whimsical) with live preview renders, Pro-lock badges, a deterministic **Page of the Day**, and a **Continue** row of in-progress works.
- **Coloring canvas** — `Canvas`-rendered page with pinch-zoom + pan, tap-to-fill via point-in-polygon hit-testing, a numbered palette bar with recently-used colors, selected-color readout, **color-by-number** toggle with gentle nudges, **undo** stack, **fill all #n** helper, live progress %, and a Reduce-Motion-aware completion celebration. Continuous autosave.
- **My Art** — grid of saved works (in-progress + completed) with thumbnails, filter, continue/edit, rename, **export image** via `ImageRenderer` + `ShareLink`, and delete. Empty state handled.
- **Palettes** — browse 8 built-in palettes, set a default, and (Pro) create/edit **custom palettes** with the system color picker.
- **Onboarding** — three calm slides, gated by a persisted `hasOnboarded` flag.
- **Settings** — appearance (System/Light/Dark), haptics on fill, color-by-number default, show region outlines, and default palette — all persisted.
- Full light/dark theming, Dynamic Type, VoiceOver (including an **accessible region list** so the visual tap-canvas is fully usable without sight), Reduce Motion, and sparse gated haptics.

## Substantive core logic (the real engine)

- **Procedural page generation** (`Utilities/PageLibrary.swift`): 10 pages are built from geometric rules so region counts land in the satisfying 40–120 range. Mandalas = N rotational wedges × M concentric rings (+ center disc); florals = radial petal layers; geometric = grid cells each split into 4 triangles; landscapes = stacked sky bands + a haloed sun + layered sinusoidal hills subdivided into segments; whimsical = a mirrored butterfly and an offset koi-scale field. Each `Region` stores normalized (0–1) polygon points plus a suggested color index.
- **Hit-testing** (`Utilities/Geometry.swift`): a crash-safe **ray-casting point-in-polygon** test maps a tap (after inverting the zoom/pan transform and the centered-square mapping) to the topmost region.
- **Coloring engine** (`ViewModels/ColoringViewModel.swift`): selection, fills, an undo stack, by-number validation, "fill all matching number", progress, and completion detection — all pure, main-thread state.
- **Rendering** (`Views/Components/PageCanvasView.swift`): a single `Canvas` fills every region, strokes outlines for the line-art look, and optionally draws by-number labels; `.drawingGroup()` keeps it smooth at 100+ regions. The same renderer powers gallery previews, thumbnails (`ThumbnailRenderer`), and watermark-aware exports (`ArtworkExporter`).
- **Persistence**: `Artwork` and `CustomPalette` are SwiftData `@Model`s; fills persist as a JSON-encoded `[regionID: hex]` map in `Data`; preferences use `@AppStorage`.

## Run

1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. `open Hue.xcodeproj` — select an iOS 17+ simulator and press **Cmd+R**.

### Free signing
The project uses no paid capabilities. In Xcode, select the Hue target → Signing & Capabilities → pick your personal team (or "Sign to Run Locally") to run on a device for free.

## Tech notes

- **iOS 17+, SwiftUI 5**, `NavigationStack`/`TabView`, MVVM (`ColoringViewModel`), **SwiftData** for primary data with `@AppStorage` for prefs.
- **Design language:** soft, gallery-like, generous whitespace, magenta-violet accent (`#C04CC8`), rounded type, pastel surfaces; artwork colors stay constant while chrome adapts to light/dark via a semantic `Theme`.
- **Monetization:** one-time **Hue Pro** (`$3.99`) simulated locally via `@AppStorage("isPro")` with a tailored `PaywallView`/`PaywallReason`; StoreKit 2 wires in for production (swap the flag flip for a `Product.purchase` + transaction listener). No ads, no subscription, no account, no network.
- **Why it can boom:** it directly out-positions Pigment/Recolor on the exact axis users complain about — privacy and fair pricing — while matching the core experience, so it converts dissatisfied top-grossing-app users at a one-time price.

## Self-review

I re-read every Swift file and verified by inspection: all imports resolve; every type, initializer, modifier, and SDK API (`Canvas`, `GraphicsContext.fill/stroke/draw`, `ImageRenderer`, `ShareLink`/`Transferable`, `ContentUnavailableView`, `ColorPicker`, SwiftData `@Model`/`@Query`/`modelContainer`, `DragGesture`/`MagnificationGesture`, `.onChange` two-param form) exists in iOS 17 and is spelled correctly; `@State`/`@StateObject`/`@Bindable`/`@Environment`/`@Query` ownership is correct; point-in-polygon and tap-coordinate math is guarded against degenerate input, empty regions, and division by zero; Codable encode/decode of fills round-trips and fails safe to empty; no `NavigationView`; no APIs newer than iOS 17. The anti-stub grep (`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`stub`) is clean, and there are no force-unwraps, `try!`, or `as!` on user paths — the only `fatalError` is the documented unreachable in-memory `ModelContainer` fallback. The app was assembled without Xcode available, so it has not been run on a simulator; the verification above is by careful inspection.
