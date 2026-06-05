# Folio — your reading, paced

A calm iOS reading tracker that answers the only question that keeps you turning
pages: *when will I finish?* Log the page you're on, and Folio computes your
pace (pages/day) from your real sessions and projects a finish date — with a
quiet progress arc and a curve of how you're moving through the book.

No accounts, no scanning, no social feed. Just your shelf, saved on your device.

## Why it earns weekly opens

Reading apps are either heavyweight social libraries or barcode scanners. Most
readers just want a nudge of momentum: *at this pace, you'll finish Thursday.*
That single projection turns a vague pile of half-read books into something with
a rhythm — and seeing the curve flatten is a gentle prompt to pick the book back
up. It's the kind of small, honest tool you open on a Sunday evening.

## What's inside

- Pace = pages/day computed across your logged sessions (DST-safe day math)
- Projected finish date + days-remaining, recomputed live
- Circular progress arc + a progress-over-time curve per book
- Active vs. finished shelves; add/remove; slider to log today's page
- Persisted with `Codable` to `UserDefaults`; seeded with two sample books
- Orbioom Liquid-Glass UI, serif titles, restrained live green

## Architecture (MVVM)

```
Models/      Book.swift              book + sessions + pace/projection logic
ViewModels/  LibraryViewModel.swift  CRUD, persistence, shelves
Views/       BookCard.swift          shelf row with arc + finish date
             BookDetailView.swift    log progress + progress curve
             ProgressArc.swift       reusable circular progress
             AddBookSheet.swift      new-book form
ContentView.swift                    composition
Theme/       OrbioomTheme.swift      tokens + glass
```

## Build & run

Open `ios/Folio.xcodeproj` in Xcode 15+ on macOS, pick an iPhone simulator,
**Cmd+R**. iOS 17+, SwiftUI 5.
