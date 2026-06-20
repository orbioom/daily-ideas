# Kin — Private Family Tree & Genealogy Journal

**One-line:** Build your private offline family tree with rich profiles, life events, and a visual chronicle — no subscription, no cloud.

## The Problem
Ancestry.com and MyHeritage charge $40–$60/year and require uploading your most intimate family data to their servers. There's no beautiful, truly private, native iOS offline genealogy app for the hundreds of millions of people who want to document their family's story.

## Features
- **Visual Family Tree** — Pannable/scrollable hierarchical canvas showing your family's generations at a glance; tap any node to view the full profile
- **Rich Person Profiles** — Name, gender, birth/death dates & places, biography, notes, and photo; initials-avatar with gender-coded color when no photo
- **Relationship Web** — Link people as Parent/Child/Spouse/Sibling/Other; relationships show on each profile for quick navigation
- **Life Events Timeline** — 11 event categories (Birth, Marriage, Education, Career, Military, Migration, Health, Achievement, more) with dates, locations, and descriptions; approx-date support
- **Family Chronicle** — Cross-family timeline of all life events grouped by year, filterable by category, searchable by name or event
- **Insights Tab** — Family stats (people count, surnames, generations, total events), upcoming birthdays within 60 days, bar chart of events by category
- **Onboarding Flow** — 3-step first-run: welcome → name your family → add yourself first
- **Full CRUD** — Add/edit/delete people, events, and relationships; batch delete with swipe; cascade deletes preserve data integrity
- **Settings** — Family name, tree display preferences, deceased indicator toggle, sort order; complete data clear with confirmation

## Run Steps
1. `brew install xcodegen` (one-time)
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root)
3. Open `Kin.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R

## Free-Signing Note
Xcode will automatically assign a development team from your Apple ID for on-device testing. No paid developer account needed for simulator.

## Tech Notes
- **Platform:** iOS 17+, SwiftUI 5, MVVM
- **Persistence:** SwiftData (Person, Relationship, LifeEvent, KinSettings cascade models)
- **Photos:** FileManager JPEG store (PhotoStore) — photos never in SwiftData blobs
- **Design:** Warm archival aesthetic — cream/sepia palette, serif typography (Georgia), gender-coded avatar colors, organic card shadows
- **Charts:** Swift Charts bar chart for events-by-category
- **Monetization:** One-time Pro unlock (unlimited photo imports, PDF family report export, relationship notes) — genealogy enthusiasts pay for privacy
- **Why it can boom:** Ancestry has 4M paid subscribers at $40/year and requires cloud uploads; FamilySearch has 100M visits/month; zero great private-offline native iOS apps exist — Kin fills that gap with a clean, fast, on-device experience

## Self-Review
- All imports verified (SwiftUI, SwiftData, Charts, PhotosUI, Foundation, UIKit)
- Every screen wired: TreeView → PersonDetail (via sheet), PeopleList → PersonDetail (NavigationLink), Chronicle (standalone), Insights (standalone), Settings
- SwiftData @Model conformances: Person, Relationship, LifeEvent, KinSettings — all `@Relationship` rules set
- No force-unwrap on user paths; `try? context.save()` used throughout
- Empty states: tree empty, people list empty, chronicle empty
- Accessibility: `accessibilityLabel` on all interactive elements, `accessibilityHidden` on decorative icons
- Light/dark: all colors via asset catalog color sets with dark variant
- Anti-stub grep: clean — no TODO/FIXME/placeholder/lorem/stub text
