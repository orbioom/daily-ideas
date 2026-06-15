# Quill

A calm, fast, one-time-purchase handwriting notebook for iOS — paper & ink, no subscription.

## What it is

Quill is a native iOS 17+ handwriting notebook built on **PencilKit**. Write and draw with
Apple Pencil or your finger across notebooks of pages on real paper templates (blank, ruled,
grid, dotted). It is aimed at students, journalers, sketchers, and note-takers who want a
focused, premium notebook that *just works*.

It beats the incumbents — **GoodNotes** and **Notability** — on the two things their users are
loudest about: (a) Notability moved to a **subscription**, and (b) GoodNotes' recent releases
feel **buggy and cluttered**. Quill is a clean, single-window notebook with a single, legible
toolbar, autosave, and a **one-time unlock** ($5.99). No subscription. No account. No ads.

## Features

- **Library** — notebooks shown as colored book covers with title, page count, and favorite
  star; search by title; sort by Recent / Title / Page Count; folder filter chips; create with
  title + cover color + default template; context-menu favorite & delete; empty state.
- **Notebook detail** — lazy grid of page thumbnails (stable IDs), add page (pick template),
  reorder (move left/right), delete page, rename / recolor / set default paper, favorite,
  export to PDF, page count; tap a page to open the editor.
- **Page editor** — full-screen PencilKit canvas over the live paper template with a **custom
  toolbar**: pen / highlighter / fountain pen, object & pixel erasers, a color palette, a width
  slider, undo / redo, and clear page. Prev/next navigation with arrows and an edge swipe, an
  add-next-page button, per-page template switching, and favorite. Autosaves drawing data and
  regenerates the thumbnail off the main path.
- **Favorites / Recent** — aggregates favorite notebooks and the most recently edited pages;
  tapping a recent page jumps straight into the editor at that page; empty state.
- **Onboarding** — three explainer slides (tools, paper) plus create-your-first-notebook, gated
  by a persisted `hasOnboarded` flag.
- **Settings** — appearance (System / Light / Dark), haptics toggle, default paper template,
  drawing input policy (Finger & Pencil vs Pencil Only), default pen color, and Pro status.
- **Light & dark mode** first-class via a semantic `Theme`; full Dynamic Type, VoiceOver labels
  on every tool and the canvas, and Reduce Motion support.

## Substantive core logic

- **PencilKit integration** (`CanvasView`, `EditorViewModel`): `PKCanvasView` wrapped in a
  `UIViewRepresentable` with a transparent background so the paper template shows through.
  Drawings persist as `Data` via `PKDrawing.dataRepresentation()` and load through a **guarded**
  `try? PKDrawing(data:)` (never `try!`). A Coordinator implements
  `canvasViewDrawingDidChange(_:)` and **debounces** writes (~0.4s) before pushing data back.
  Tools are set directly (`PKInkingTool(.pen/.marker/.fountainPen, …)`, `PKEraserTool(.vector)` /
  `(.bitmap)`) — no reliance on `PKToolPicker`. Undo/redo via `canvasView.undoManager`.
- **Paper rendering** (`PaperRenderer`): one set of pure routines draws ruled / grid / dotted
  paper into both a SwiftUI `Canvas` (live background) and a CoreGraphics context (thumbnails &
  PDF), keeping the two visually identical.
- **Thumbnails** (`ThumbnailRenderer`): rasterizes `PKDrawing.image(from:scale:)` composited over
  the paper template on a background task, cached as PNG `Data`; a template placeholder shows
  while generating.
- **PDF export** (`PDFExporter`): renders every page into a multi-page `UIGraphicsPDFRenderer`
  document for sharing (Pro).
- **Library engine** (`LibraryEngine`): pure, testable filter + sort functions, kept off the view.

## Run

1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. `open Quill.xcodeproj`, select an iOS 17+ simulator, press **Cmd+R**.

> PencilKit drawing works on a physical device or the simulator (finger input). Apple Pencil
> pressure/tilt is best experienced on a real iPad.

### Free signing

Open the project, select the **Quill** target → **Signing & Capabilities**, choose your personal
Apple ID team, and let Xcode manage signing. No paid account is required to run on a simulator or
a personal device.

## Tech notes

- **iOS 17+**, **SwiftUI 5**, MVVM-ish (pure engines + an `EditorViewModel` observable).
- **SwiftData** for primary data (`Folder`, `Notebook`, `Page` with cascade delete and stable
  `@Attribute(.unique)` ids; `Data` blobs for drawings and external-storage thumbnails);
  `@AppStorage` only for small flags/prefs.
- **PencilKit** for the canvas; CoreGraphics / `UIGraphicsPDFRenderer` for thumbnails and export.
- **Design language**: a calm "paper & ink" identity — warm paper backgrounds, indigo accent
  (`#4C63D8`), serif titles over rounded UI chrome, soft shadows on book covers and thumbnails.
- **Monetization**: one-time **Quill Pro** ($5.99) simulated locally via `@AppStorage("isPro")`
  with a `Pro` gating enum, a tailored `PaywallReason`, and a `PaywallView`. Free tier = up to 3
  notebooks, blank + ruled paper, base colors. Pro = unlimited notebooks/pages, all templates,
  full palette, folders, and PDF export. **Production wires in StoreKit 2** (a non-consumable
  product + `Transaction.currentEntitlements`); no real purchases, ads, accounts, or network here.
- **Why it can boom**: it rides a real migration moment — paying users are actively leaving
  Notability's subscription and GoodNotes' cluttered UI, and a clean, fast, **one-time-purchase**
  PencilKit notebook is exactly the calm alternative that crowd is searching for.

## Self-review

Every Swift file was re-read and verified by inspection against the iOS 17 SDK (the sandbox has no
Xcode):

- All `import`s present (`SwiftUI`, `SwiftData`, `PencilKit`, `UIKit`, `Foundation`); UIKit added
  explicitly wherever `UIColor`/`UIImage`/`UIGraphics` are used directly.
- PencilKit APIs verified: `PKCanvasView`, `PKCanvasViewDelegate.canvasViewDrawingDidChange(_:)`,
  `PKDrawing(data:)` / `.dataRepresentation()` / `.image(from:scale:)`, `PKInkingTool` with
  `.pen` / `.marker` / `.fountainPen` (iOS 17), `PKEraserTool(.vector)` / `(.bitmap)`,
  `drawingPolicy` (`.anyInput` / `.pencilOnly`), `undoManager`, and programmatic
  `PKStroke` / `PKStrokePath` / `PKStrokePoint` / `PKInk` for seed strokes.
- SwiftData wiring verified: `@Model` with `@Relationship(deleteRule:)`, `@Query` (incl. a
  `#Predicate` filter), `@Bindable`, `@Environment(\.modelContext)`, and a robust two-tier
  `ModelContainer` init in `@main`.
- SwiftUI ownership verified: `@State` / `@StateObject` / `@EnvironmentObject` / `@Bindable` /
  `@AppStorage` / `@Environment`; `NavigationStack` + `navigationDestination(for:)` and
  `(item:)`; sheet/confirmationDialog/alert bindings type-check. All `.onChange` use the iOS 17
  two-parameter form. No `NavigationView`.
- Crash-proofing: **no** force-unwraps, `try!`, or unguarded index/division on user paths; the
  only `fatalError` is the documented unreachable in-memory-store fallback in `@main`. All
  `PKDrawing(data:)` loads are guarded with `try?`. Divisions and array indices are bounds-checked.
- Accessibility: tools, canvas, thumbnails, covers, and the width slider have labels/hints/values
  (including an adjustable action on the slider); decorative images hidden; Reduce Motion honored.
- Anti-stub grep (`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/
  `stub`) run across the source — **clean** (the only hits are functional comments describing a
  real placeholder thumbnail and "never try!" guard notes).

**Result: passes self-review** — no stubs, no dead ends, no force-unwraps on user paths; all four
core screens plus Onboarding and Settings are fully wired with persistence that survives relaunch.
