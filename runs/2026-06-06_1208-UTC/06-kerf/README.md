# Kerf

**Measure once. Cut well.** A woodworking cut-list optimizer: enter the parts you need and the stock you have, and Kerf packs your cuts onto the fewest boards — accounting for saw kerf — plus board-foot and quick-plan calculators.

**Audience:** woodworkers and DIY makers who want to minimize boards and waste before cutting, offline and ad-free.

**Design language:** Orbioom.

## Features

- **Projects** — full CRUD. Each project owns its parts, stock boards, kerf width, and notes. Summary of pieces, total required length, and kerf.
- **Parts & stock** — add/edit/delete parts (label, length, quantity) and stock boards (label, length, available count or unlimited, optional price).
- **Cut plan** — a best-fit-decreasing 1D cutting-stock optimizer (off the main actor, with a loading state) lays out every piece, respecting kerf and limited stock. Shows boards needed, material-used %, total waste, estimated cost, a per-board **visual layout** with proportional cut segments and offcut, and the cut list per board. Flags pieces too long for any stock or shortfalls when stock runs out.
- **Board-foot calculator** — thickness × width × length × quantity → board feet and cost.
- **Quick cut planner** — a one-off optimizer (single stock length + a quick list of cuts) with live boards, efficiency, and waste, without saving a project.
- **Settings** — units (mm/inches), default kerf, haptics; reload sample data; delete all (confirmed).
- Onboarding gate, empty/loading/success/error states, light + dark, Dynamic Type, VoiceOver, Reduce Motion.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Kerf.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, **Cmd+R**.

**Free signing:** Signing & Capabilities → your personal team.

## Tech notes

iOS 17+, SwiftUI 5. Lengths stored in millimetres, converted for display (mm/inches). Persistence is **SwiftData** (`Project`, `Part`, `StockBoard`, cascade-owned). The optimizer is a pure, `Sendable` value-type `CutOptimizer` run via `Task.detached` so large lists never block the UI; SwiftData models are read into Sendable specs on the main actor first. No dependencies, no network.

## Self-review

Hand-checked every file: imports, iOS 17 APIs, SwiftData cascade relationships, `Sendable` conformance on the optimizer types crossing the actor boundary, `navigationDestination(isPresented:)`, and the `BoardBar` geometry math. Optimizer guards against empty stock, oversize pieces, and exhausted availability. Anti-stub grep clean. No force-unwrap/`try!`/unguarded division on user paths (only the bootstrap in-memory container fallback uses `try!`). States, accessibility, light/dark verified by reading.
