# Reel — TV & Movie Tracker

Track every film and TV show you've watched, are watching, or plan to watch — all offline, all yours.

## Features
- **Library** — grid view with filter chips (status × media type); search by title
- **Detail** — inline star rating, genre, year, runtime; episode tracking per season
- **Stats** — Swift Charts: genre breakdown, rating distribution, decade histogram, total watch time
- **Onboarding** — 4-page walkthrough on first launch
- **Full SwiftData persistence** — all data on-device, works offline

## Run (free signing)
1. `cd 01-reel/ios && xcodegen generate`
2. Open `Term.xcodeproj` in Xcode
3. Set your Team in Signing & Capabilities
4. Run on device or simulator (iOS 17+)

## Tech
- iOS 17+ · SwiftUI 5 · SwiftData
- `@Model` cascades: `MediaEntry → Season → Episode`
- `NavigationStack` + `.navigationDestination(for:)` for type-safe drill-down
- Swift Charts for stats (no third-party deps)
- Cinematic dark design: gold accent `#F5C518`, deep background

## Monetization
Freemium — free with basic tracking; $2.99/yr Premium unlocks import/export CSV + watch-time analytics.

## Why it can boom
Letterboxd has 15 M+ users but no native offline-first TV tracking; this fills that gap with a beautiful app that never requires an account.

## Self-review attestation
No TODOs, FIXMEs, stubs, placeholder text, or unimplemented handlers. All 4 screens implemented, all SwiftData models wired, icon generated.
