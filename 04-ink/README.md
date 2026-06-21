# Ink — Tattoo Idea Planner

**Category:** Lifestyle  
**Platform:** iOS 17+  
**Run:** 2026-06-21_run4 · #355

## What It Does

Ink is a private, offline tattoo planning notebook. Collect tattoo ideas with style/placement/status tagging, save artists with ratings and specialties, book appointments and track deposits/costs, and follow your journey from "wishlist" to "done" — all on-device with no account required.

## Feature Screens

| Screen | Description |
|--------|-------------|
| **Ideas** | Searchable+filterable idea cards; status filter chips (Wishlist→Done); IdeaCard with style/placement/tags/cost; IdeaDetailView with status picker, detail grid, notes, flow tags, cost; AddIdeaView CRUD form |
| **Artists** | Artist list with initial avatar, studio/city/star rating; ArtistDetailView with interactive 5-star rater, specialties, notes; AddArtistView form; swipe-to-delete |
| **Sessions** | Upcoming/completed appointment separation; cost/deposit tracking; session summary with total spent; AddAppointmentView with estimated hours stepper, deposit/total cost fields |
| **Settings** | Show cost estimates toggle, default style picker, currency picker (USD/EUR/GBP/AUD/CAD), tattoo journey stats (ideas/artists/sessions/completed/total spent) |

## Technical Highlights

- **InkTheme.swift** — 12 tattoo styles + 16 body placements + 6 idea statuses each with distinct colors; dark purple/magenta palette
- **SwiftData models** — TattooIdea, TattooArtist, TattooAppointment, InkSettings with full CRUD
- **FlexRow** — Simple inline tag layout (tags flow left-to-right wrapping)
- **StatusBadge** — Color-coded capsule badge per IdeaStatus
- **AppointmentRow** — Calendar day/month column, completion checkmark, swipe actions for mark-done and delete

## Self-Review

- ✅ All enums (TattooStyle, BodyPlacement, IdeaStatus) have exhaustive rawValue coverage
- ✅ SwiftData @Model properties use Codable-compatible types (no SwiftUI types in models)
- ✅ Tags stored as [String] — supported in SwiftData
- ✅ Photo library usage key in Info.plist (future photo attachment)
- ✅ Dark purple/magenta theme consistent across all views
- ✅ XcodeGen project.yml

## Monetization

Pro IAP: photo reference attachments, iCloud sync, custom style categories, export PDF mood board. Free: unlimited ideas/artists/appointments.
