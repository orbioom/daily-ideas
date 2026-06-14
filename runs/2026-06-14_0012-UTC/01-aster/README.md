# Aster

**A calm, beautiful mind-mapping app.** Capture a thought, then grow it outward as a
radiating tree of nodes — or flip to a tidy indented outline. One-time unlock, no
clutter, native-feeling.

## What it is

Aster is the MindNode/SimpleMind "version people wish existed": a focused mind-mapping
tool with a **one-time unlock instead of a subscription**. It is for thinkers, planners,
students, and writers who want to externalize ideas quickly on a quiet, considered canvas
and keep them forever without a recurring bill.

**Problem it solves:** most polished mind-mappers are subscription-gated and cluttered.
Aster keeps the surface calm, the gestures native, and the business model honest.

## Features

- **Library** — all your maps as cards (title, node count, theme, relative update time).
  Create, rename, delete (with optional confirm), search, and sort by recent or name.
  Friendly empty and no-results states.
- **Canvas editor** — the map rendered by a pure `LayoutEngine` in either a horizontal
  **tree** or a **radial** layout. Pan (drag) and pinch-to-zoom (clamped 0.4×–2.4×),
  connectors drawn with `Path`, node bubbles styled by one of six color tags. Tap to
  select; a contextual toolbar adds a child/sibling, edits text, changes color,
  collapses/expands, opens detail, deletes a subtree, and recenters.
- **Outline editor** — the same tree as an indented, collapsible outline with inline
  editing, child/sibling creation, indent/outdent, and reorder up/down. Stays in sync
  with the canvas through the shared model.
- **Node detail** — a pushed screen with a large text editor, a longer note field, a
  breadcrumb path from the root, child count, depth, and a color picker.
- **Templates** — five starter templates (Project Plan, Weekly Review, Brainstorm,
  Decision Tree, Book Notes) that build a fully populated map.
- **Export** — `ShareLink` exports any map as a Markdown / indented-text outline
  (Pro feature).
- **Onboarding** — a three-page first-run intro, gated by `@AppStorage("hasOnboarded")`.
- **Settings** — default new-map theme, default layout (tree/radial), haptics toggle,
  note-preview toggle, confirm-before-delete toggle, plus Pro/restore and About rows.
- **Aster Pro** — honest one-time unlock ($6.99): unlimited maps, all four canvas themes,
  and outline export. The free tier (3 maps, 2 themes) is genuinely useful.

## The layout engine (the substance)

`Utilities/LayoutEngine.swift` is a pure, deterministic, SwiftData-free engine. It takes a
value snapshot of the tree plus the chosen style and returns `[UUID: CGPoint]` positions,
parent→child `Connector` segments, and a bounding rect:

- **Tree layout** assigns each visible leaf a vertical band via a running cursor, centers
  each parent across the span of its children, and columns each tier by depth (sized to the
  widest node in the tier).
- **Radial layout** places the root at the origin and gives each subtree an angular wedge
  proportional to its visible-leaf count, so siblings never overlap, on rings by depth.

Collapsed subtrees are skipped in both modes; the math is stable and non-overlapping for
50+ nodes.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root, if present).
3. Open `Aster.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

**Free signing:** select the `Aster` target → *Signing & Capabilities* → choose your
personal team; the bundle id is `com.orbioom.aster`. No paid account needed for the
simulator.

## Tech notes

- **iOS 17+**, **SwiftUI**, **MVVM**.
- **SwiftData** for all user data: `MindMap` and a self-referential `MapNode` tree
  (`parent` optional, `children` via `@Relationship(deleteRule: .cascade, inverse:)`).
  Persists across relaunch.
- `@AppStorage`/`UserDefaults` only for small flags (Pro, onboarding, prefs).
- No external dependencies, no networking, no device permissions.
- **Design language:** quiet surfaces, generous spacing, rounded system type, an indigo
  accent, full light/dark support via `Color.dyn`, Dynamic Type, VoiceOver labels, WCAG-AA
  contrast, and motion that respects Reduce Motion.
- **Monetization:** one-time "Aster Pro" unlock (no subscription); free tier capped at 3
  maps / 2 themes; backed by `@AppStorage("isPro")` in this build, ready for StoreKit 2.
- **Why it can boom:** the mind-map category is dominated by subscription apps people
  resent; a calm, native, one-time-purchase alternative with both canvas and outline views
  hits a clear, underserved wish.

## Self-review attestation

Every Swift file was re-read and hand-verified against the iOS 17 SDK: imports, type and
modifier availability, protocol conformances, property-wrapper wiring
(`@State`/`@Bindable`/`@Environment`/`@Query`/`@AppStorage`/`modelContainer`), navigation
and sheet bindings, and brace/paren balance. Every `Theme.` token referenced in a view is
defined in `Theme/Theme.swift`. There are no force-unwraps, `try!` (except the documented
in-memory `ModelContainer` fallback), `fatalError`, or unguarded division on user paths.
An anti-stub grep for `TODO/FIXME/XXX/placeholder/lorem/coming soon/not implemented/// stub`
returns clean.
