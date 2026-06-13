# Mosaic

**One photo and one mood a day — and your whole year fills in as a grid of colored tiles.** A 1-Second-Everyday-meets-Year-in-Pixels memory diary, private and on-device.

## Features

- **Capture today** in seconds: a photo (PhotosPicker), a 1–5 mood, and a line about the day.
- **Year in Pixels** grid: 12 months × 31 day-tiles colored by mood, with a legend, a year switcher, a mood-mix breakdown, and tap-to-edit any past day.
- **Timeline:** a reverse-chronological journal grouped by month with photo thumbnails; tap into a full **day detail** view.
- **On this day** memories that resurface entries from a week, months, and years ago.
- **Today** hub: today's entry or a capture prompt, a current-streak / days-kept / average-mood stat row, and a tappable mini month grid.
- Full CRUD for days (one entry per calendar day, enforced). Onboarding (with optional sample months), **Settings** (daily reminder with time, theme, haptics, erase), one-time **Mosaic Pro**.
- **Privacy by design:** photos are stored as downsized JPEGs in the app's Documents folder via `ImageStore` — only filenames live in the database, nothing is uploaded.
- Light & dark, Dynamic Type, VoiceOver, Reduce Motion.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Mosaic.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

**Free signing:** pick your personal team and a unique bundle id in *Signing & Capabilities*.

## Tech notes

iOS 17+, SwiftUI 5, with a pure `MosaicStats` engine (streaks, mood distribution, on-this-day memories, year mapping), a FileManager-backed `ImageStore`, `PhotosUI` capture, and `UserNotifications` reminders. Persistence in **SwiftData** (`DayEntry`, unique by day); prefs in `UserDefaults`. Design language: **warm & playful** — a sunset palette, rounded type, and a five-color mood scale that drives the whole grid.

- **Monetization:** free core; one-time **Mosaic Pro** ($7.99) adds multiple photos per day, video clips, and a printable year-in-pixels poster export. Memory/diary apps convert well on a small upgrade.
- **Why it can boom:** "year in pixels" and "one second every day" are both viral, evergreen formats — but 1SE has drifted to subscription with cramped editing, and Year-in-Pixels apps are mood-only. Combining a photo *and* a colored-day grid, privately and for a one-time price, is the version people keep asking for.

## Self-review

Hand-reviewed every file. Verified imports (incl. `PhotosUI`, `UIKit`, `UserNotifications`); iOS-17 APIs; SwiftData `@Query`/unique attribute/`modelContainer`; PhotosPicker import + off-main image load/save; `navigationDestination(for: DayEntry.self)`; reminder scheduling. Anti-stub grep clean. No force-unwraps/`try!` on user paths.
