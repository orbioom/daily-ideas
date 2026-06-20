# Scaffold — Home Renovation & DIY Project Tracker

**One-line:** Track every home improvement project with tasks, materials, budget, and before/after photos — all on-device, no subscription.

## The Problem
Houzz is bloated with a social feed and marketplace. HomeZada costs $59/year and has 2.7★ reviews for terrible UX. There's no clean, fast, private iOS app that simply helps homeowners track what they're building and how much it costs.

## Features
- **Dashboard** — Live overview of active/overdue projects, upcoming materials to buy, and total spend across all projects
- **Rooms** — Organize projects by room (Kitchen, Bathroom, Garage, etc.) with type icons; room-level status summary
- **Project Detail** — Full project view with status, budget ring, task checklist, materials shopping list, before/after photos, target dates
- **Tasks** — Inline quick-add tasks per project; tap to cycle Todo → In Progress → Done; progress bar shows completion %
- **Materials & Budget** — Per-project material list with quantity × unit cost = total; budget vs actual ring; unpurchased materials aggregate to shopping list
- **Shopping List** — Cross-project shopping list grouped by project; mark items purchased; total "to buy" vs purchased summary
- **Before/After Photos** — Add photos to projects via PhotosPicker; stored in FileManager JPEG store
- **Onboarding** — 3-step: welcome → name property + address → ready to build
- **Settings** — Currency symbol (4 options), budget card display toggle, task view default, data clear with confirmation

## Run Steps
1. `brew install xcodegen` (one-time)
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root)
3. Open `Scaffold.xcodeproj` in Xcode 15+, select iOS 17+ simulator, Cmd+R

## Free-Signing Note
Xcode assigns a development team automatically from your Apple ID for simulator testing.

## Tech Notes
- **Platform:** iOS 17+, SwiftUI 5, MVVM
- **Persistence:** SwiftData (Property → Room → Project → Task/Material/Photo cascade; 7 @Model classes)
- **Photos:** FileManager JPEG store (ScaffoldPhotoStore) — never in SwiftData blobs
- **Design:** Industrial/contractor aesthetic — dark slate background on onboarding, safety-orange accent, bold rounded numerals, blueprint grid motif
- **Monetization:** One-time Pro unlock (multiple properties, photo export, project report PDF) — homeowners and contractors pay once to track unlimited projects
- **Why it can boom:** US home improvement market is $500B+; Houzz has 65M users but zero project tracking; HomeZada charges $59/year with 2.7★ UX; we give homeowners a clean, permanent on-device tracker

## Self-Review
- Imports verified: SwiftUI, SwiftData, PhotosUI, Foundation, UIKit
- All tabs and navigation links wired and tested: Dashboard → ProjectDetail, Rooms → RoomDetail → ProjectDetail
- SwiftData models: Property, Room, Project, ProjectTask, Material, ProjectPhoto, ScaffoldSettings all with correct cascade delete rules
- Empty states on all collection views
- No force-unwrap on user paths; safe `try? context.save()` throughout
- Accessibility labels on all interactive elements
- Budget math: `actualCost = Σ(unitCost × quantity)`, `budgetRemaining = budget - actualCost`
- Anti-stub grep: clean
