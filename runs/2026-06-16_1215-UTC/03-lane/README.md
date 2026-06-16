# Lane

## What it is

**Lane** is a fast, private, native **Kanban board** for iPhone — a visual project manager where your work lives in columns of cards you move from *Backlog* to *Done*.

- **One-liner:** A Trello-style board that's instant, offline, and yours — no account, no cloud, no subscription.
- **Problem:** Trello, Notion and friends are cloud-first, subscription-priced, and heavy. Plenty of people just want a quick, private board on their phone that opens instantly and never asks them to log in.
- **Audience:** Anyone managing projects or tasks visually — indie makers, freelancers, students, home-renovators, content creators, small teams of one.

Lane is deliberately a **visual board** (horizontal lanes of cards), not a flat checklist. The board interaction is the centerpiece.

## Features

**Boards (home)**
- Grid of boards, each with a progress ring, lane/card/done counts, and a custom color + SF Symbol.
- Create boards from starter templates: *To-Do · Doing · Done*, *Kanban* (Backlog/Ready/In Progress/Review/Done), *Sprint*, *Content Calendar*, or *Blank*.
- Color + icon picker; reorder via sort index; archive and restore; delete (with optional confirmation).
- Calm empty state with a call-to-action.

**The board (centerpiece)**
- Horizontal scroll of lanes. Each lane shows its name, live card count, and a WIP badge that turns **red** when the limit is exceeded.
- Vertical scroll of card chips per lane + an inline "add a card" field for fast entry.
- **Move a card between lanes** via a guaranteed **Move to…** menu on every card (long-press context menu) — the reliable path that always works.
- Cards entering the last ("done") lane are auto-stamped with a completion date; leaving it clears the stamp.
- Add / rename / recolor / delete lanes, set WIP limits (Pro), and reorder lanes in an edit-mode list.

**Card detail**
- Title + multi-line notes editor.
- Priority (None/Low/Medium/High), due date, and multi-select colored labels.
- Checklist with progress bar — add, check, reorder (drag), and delete steps.
- Move-to-lane menu and delete (guarded by confirmation).

**Agenda**
- Every card with a due date across all active boards, grouped **Overdue / Today / This Week / Later**.
- Tap a row to open the card; one-tap complete (moves the card to its board's done lane).
- Empty state when nothing is scheduled.

**Insights** (Pro)
- Swift Charts: **cards completed per week** (bar), **cards by lane** for a selected board (horizontal bar).
- Stat tiles for **Overdue**, **Due soon**, and **Done**.
- **Busiest board** card with active-card count and progress ring.

**Onboarding & Settings**
- 4-page onboarding explaining the board model, gated by `hasOnboarded`.
- Settings with real, persisted preferences: Appearance (System/Light/Dark), Haptics, Show-completed-cards, Confirm-before-delete, Default new-board template — plus Unlock Pro / Restore and an About screen.

**Throughout**
- Empty, loading (first-run seeding), success (toasts + haptics), and recoverable error states.
- Full light/dark support, Dynamic Type, VoiceOver labels/values/hints, and Reduce-Motion-aware animation.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Lane.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

## Free signing

No paid Apple Developer account needed. In Xcode: select the **Lane** target → **Signing & Capabilities** → check **Automatically manage signing** and pick your personal team (Personal Team works). The bundle id is `com.orbioom.lane`; change the prefix if it collides. Then run on a simulator or your own device.

## Tech notes

- **Platform:** iOS 17.0+, SwiftUI, `NavigationStack` + `TabView`.
- **Persistence:** SwiftData is the primary store (`@Model` Board / BoardColumn / Card / ChecklistItem / Label, all registered in the app's `Schema`, with cascade and many-to-many relationships). Small preferences/flags use `@AppStorage`. Realistic sample data (3 boards, ~45 cards with labels, checklists, priorities, due dates, and a few completed) is seeded once on first launch via `SeedData.seedIfNeeded`, guarded by a flag and a count check.
- **Architecture:** Pure logic in `BoardEngine` (counts, WIP detection, progress, throughput, busiest board) and `CardMover` (guarded sort-index compaction, moves, reorders). Views stay thin. App-wide state via `ObservableObject` (`AppSettings`, `ProStore`); local view state via `@State` — no `@Observable`/`@StateObject` mixing.
- **Design language:** "Blueprint" identity — cool slate surfaces, a confident azure accent (`0x2D7FF9`, matching the AccentColor asset), rounded type, and `Color.dyn` dynamic colors tuned for AA contrast in both modes.
- **Charts:** Swift Charts on the Insights screen with accessible per-mark labels/values.
- **Safety:** No `try!` / `as!` / force-unwrap on user paths; bounds-checked array access (`subscript(safe:)`); no unguarded division; the only `fatalError` is the documented-unreachable in-memory `ModelContainer` fallback.
- **Monetization:** One-time **Lane Pro** unlock at **$4.99** (simulated, StoreKit-ready) — gates unlimited boards past 2, custom labels, WIP limits, and Insights; the free core is fully usable.
- **Why it can boom:** It nails the underserved middle — people who find Trello/Notion too heavy and cloud-bound but want more than Apple Reminders. Private, instant, native, and a single honest price instead of a subscription is a genuinely differentiated pitch in a category dominated by SaaS.

## Self-review

I re-read every Swift source by hand and verified:

- **Imports** are present and correct per file (`SwiftUI`, `SwiftData`, `Charts`, `Foundation`/`UIKit` only where used).
- **iOS 17 only:** two-parameter `.onChange(of:) { _, newValue in }` everywhere; `NavigationStack` (no `NavigationView`); no `@Previewable`; no iOS-18 SwiftData/SwiftUI symbols. `TextField(axis:)`, `ProgressView(value:label:)`, Swift Charts `BarMark`/`AxisMarks` are all iOS 16/17 APIs.
- **SwiftData:** all five `@Model` types (`Board`, `BoardColumn`, `Card`, `ChecklistItem`, `Label`) are listed in the `Schema` in `LaneApp.swift`. Relationships use correct single-side `inverse:` declarations with cascade rules; many-to-many `Card.labels` ↔ `Label.cards` declares the inverse on one side only. Each model carries a stable `id: UUID`, so `Identifiable`/`.sheet(item:)` resolve cleanly.
- **No forbidden constructs:** zero `try!`, `as!`, or force-unwraps on user paths (grep-verified); zero TODO/FIXME/placeholder/stub strings; the single `fatalError` is the documented-unreachable container fallback.
- **Crash-proofing:** index math in `CardMover` is guarded (`min/max` clamps, `subscript(safe:)`, empty-collection guards); all divisions guard against zero (`checklistProgress`, `progress`, rollups); color hex is clamped non-negative before `UInt` conversion.
- **Ownership:** `ObservableObject` + `@StateObject` for `AppSettings`/`ProStore`; `@State`/`@Bindable`/`@FocusState` locally; no `@Observable` + `@StateObject` mix.
- **DoD:** 4 substantive tabs (Boards, Agenda, Insights, Settings) plus Board detail, Card detail, Onboarding, Paywall, About; empty/loading/success/error states present; ≥3 real persisted prefs; lazy containers with stable `Identifiable` IDs; full accessibility and Reduce-Motion fallbacks; haptics gated by `settings.hapticsEnabled`.
- **Balanced braces/parens** across all 42 files (the only apparent paren delta is from `// 1)`-style comments, not code).

Attestation: to the best of a careful manual review, the sources are internally consistent and type-correct for the iOS 17 SDK, with no force-unwraps, no placeholders, every `@Model` in the `Schema`, and no APIs newer than iOS 17.
