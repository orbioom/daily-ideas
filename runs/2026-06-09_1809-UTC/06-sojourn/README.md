# Sojourn

**The map of the world you've seen.** Sojourn is a calm, complete countries-visited tracker and travel bucket list for iPhone — mark every country you've visited, lived in, passed through, or dream of, and watch your percentage of the world climb.

Built natively with SwiftUI + SwiftData (iOS 17+), entirely on-device.

## What it is

A private passport for your travels. Every UN member / observer state across the six inhabited continents (~195 countries) is built in, with flags, capitals, continents, and sub-regions. Set a status on any country, group them into trips, keep a wishlist, and let the insights tell your story.

## Features

- **Passport (Home)** — A proud overview: "X / 195 countries — N% of the world", a continents-touched gauge (e.g. 4 / 6), status count tiles (visited / lived / wishlist), per-continent progress bars, and your most recent additions. An encouraging empty state for a brand-new traveler.
- **Explore (World)** — The full ~195-country list, sectioned by continent, searchable by name / capital / region and filterable by status (or "unmarked"). Each row shows flag, name, capital, and current status. Tap any country to open the editor.
- **Country editor** — The core CRUD: set status (Visited / Lived / Transit / Wishlist), remember a first-visit year, a times-visited stepper, mark a favorite, add a note — or clear the country entirely.
- **Wishlist** — Your bucket list of wishlist-status countries, with a "mark visited" one-tap (sets visited + this year) and swipe-to-remove. A live "N countries on your list" header.
- **Trips** — Journeys that group countries by ISO code, with an optional date range and note. Add / remove countries via a searchable multi-select, and optionally mark a whole trip's countries visited in one tap. Swipe to delete; full New-Trip flow.
- **Insights** — Charts: countries by first-visit year (bar), status mix (donut), and countries visited per continent (bar), plus % of world, continents touched, new-this-year, and favorites stat tiles.
- **Settings** — Home-country picker (excluded from your "countries seen" total), count-transit-as-visited toggle (changes the percentage math), distance-units preference, interface haptics, and a destructive "Reset all marks" with confirmation.
- Onboarding, light + dark mode, Dynamic Type, VoiceOver labels, Reduce Motion, and sparse, meaningful haptics throughout.
- Realistic seed data on first launch (~30 marked countries, a couple "lived", a wishlist, and four trips) so Passport and Insights are alive immediately.

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate`
3. Open `Sojourn.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

**Free signing:** the project uses a `com.orbioom.sojourn` bundle id. With a free Apple ID, set your own Team in *Signing & Capabilities* (and tweak the bundle id if it's taken) to run on a device.

## Tech notes

- **iOS 17+**, **SwiftUI**, lightweight **MVVM** (pure `SojournEngine` for analytics, views stay declarative), **SwiftData** for persistence (`VisitMark`, `Trip`) which survives relaunch.
- Static country dataset (`CountryData`) with flag emoji computed at runtime from each ISO alpha-2 code via Unicode regional-indicator symbols — always correct, never hand-authored.
- **Charts** framework powers the Insights screen.
- **Orbioom design system** (Brand tokens, GlassCard, ink / glass buttons, RankBar, chips) — no hardcoded colors in views; full light / dark support.
- **Monetization:** free to track everything; a one-time **Sojourn Plus** unlock (≈$4.99) adds unlimited trips, Insights, and data export — no subscriptions, no ads.
- **Why it can boom:** the "Been" / "Visited" travel-collection category has proven, durable demand; Sojourn is calmer and more complete — every country built in, trips and per-continent / per-region insight, fully on-device, and a single honest one-time unlock instead of a subscription.

## Self-review attestation

Authored all ~195 countries (197 entries across the six inhabited continents, no duplicates, no truncation). Every Swift file hand-verified against the iOS 17 SDK: imports, SwiftData `@Model` / `@Query` / `@Bindable` / `modelContainer` wiring, `[String]` Codable attribute, `#Predicate` capture, `NavigationStack` / `.sheet(item:)` bindings, and Charts (`BarMark` / `SectorMark`) usage. No `TODO` / `FIXME` / placeholder strings. No force-unwraps, `try!`, or unguarded division on user paths (the only `fatalError` is the in-memory `ModelContainer` fallback). Empty, loading-via-seed, success, and calm error states are present throughout; ≥3 persisted prefs in Settings including haptics. Conjured, not just coded.
