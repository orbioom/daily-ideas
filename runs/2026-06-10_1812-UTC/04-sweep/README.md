# Sweep — swipe your photo library clean

**One line:** Reclaim storage by swiping through screenshots, near-duplicates, and forgotten months — keep right, clear left — privately and without dark patterns.

**Problem & audience:** "Photo cleaner" is one of the highest-grossing utility categories on the App Store, but the popular ones are notorious for fake "you have 14,000 duplicates!" scares, hard paywalls before you can delete anything, and aggressive weekly subscriptions. Sweep is for the enormous audience of people whose libraries are full and whose iCloud is nagging — done honestly, on-device, one calm swipe at a time.

## Features

- **Clean (overview)** — library summary (photos, videos, approx. size) and review groups: **Screenshots**, **Similar Shots** (bursts taken within seconds), **Videos**, and **By Month** — each with a cover thumbnail, count, and estimated size.
- **Swipe deck** — a full-screen card stack per group: swipe right to **keep** (kept photos never reappear), left to **clear**. Buttons, drag badges, progress, and one-tap **undo**.
- **To Delete** — a grid basket of everything marked, with estimated space to reclaim; remove individual photos, then delete the whole batch (iOS shows its own confirmation; items go to Recently Deleted).
- **Progress** — reclaimed space, photos deleted/kept/reviewed, and a per-cleanup chart (Swift Charts).
- **Settings** — confirm-before-deleting, theme, haptics, and "review kept photos again."
- Permission flow handled calmly (not-determined / denied / authorized) with a Settings deep link; loading state while scanning; empty states; full Dynamic Type, VoiceOver, Reduce-Motion-aware swiping.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Sweep.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator (or a device with photos), Cmd+R, grant photo access.

Free-signing: set your Team in Signing & Capabilities; bundle id `com.orbioom.sweep`. Requires `NSPhotoLibraryUsageDescription` (already in `Info.plist`).

## Tech notes

- iOS 17+, SwiftUI 5. `PhotoLibraryService` (`@MainActor` `ObservableObject`) wraps PhotoKit: authorization, off-main scanning into groups (`nonisolated` builders), `PHCachingImageManager` thumbnails, size estimation, and `PHPhotoLibrary.performChanges` deletion.
- Persistence: **SwiftData** stores only kept-photo identifiers (`KeptPhoto`) and cleanup history (`CleanSession`) — never the images. Nothing leaves the device.
- Design language: **Orbioom**.
- **Monetization:** freemium — a free daily review quota; Pro unlocks unlimited swipes, smart-album cleanup, and video compression. The exact model incumbents use, minus the scare tactics.
- **Why it can boom:** a top-grossing utility category whose leaders are despised in reviews; an honest, private, beautifully-designed cleaner is a clear "the version people wish existed."

## Self-review

Hand-checked every file against the iOS 17 SDK: PhotoKit async authorization/`performChanges`, `PHFetchResult` enumeration, `PHImageRequestOptions`, `Task.detached` with `nonisolated` builders, `navigationDestination(for: PhotoGroup.self)` (Hashable), and Charts all type-check. No stubs/TODOs; no force-unwraps/`try!`/`fatalError` on user paths beyond the in-memory container fallback. `project.yml` is valid and names the real `Sweep` sources and `Info.plist`.
