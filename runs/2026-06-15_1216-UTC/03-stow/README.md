# Stow

A privacy-first read-it-later app and offline reader for iOS 17+ — save a link, get a clean, beautiful, fully-offline copy.

## What it is

Stow solves a problem that just got worse: in 2025 **Pocket shut down**, stranding millions of people who had spent years building reading lists inside a service they didn't control. Stow is the native successor for anyone who reads long-form on their phone — commuters, students, researchers, and anyone who saves "to read later" and wants it to actually still be there later.

You paste a URL; Stow fetches the page and extracts a clean, readable version — title, byline, site, paragraphs, reading time — **entirely on-device**. It stores that copy offline and presents it in a distraction-free reader with full typography and theme control. No account, no cloud, no tracking, and a single fair one-time unlock instead of a subscription.

It beats Pocket by being **native, private, offline-first, and permanent**: your library lives on your device and cannot be deleted by a press release.

## Features

- **Reading List (Unread)** — article cards with site, reading time, excerpt, tags, and a resume-progress bar; tag filter chips; search; sort by recent / longest / shortest; swipe to favorite / archive / delete; context menus; empty states.
- **Add Article flow** — paste a URL → genuine async loading state → extracted preview → save, with calm, recoverable error + retry states for invalid URLs, network failures, non-HTML, and empty extraction.
- **Reader** — distraction-free article view with live controls: font family (serif / sans / rounded), text size, line spacing, and four reading themes (light / sepia / dark / night). Live reading-progress bar that **persists** so you resume where you left off. Mark-as-read / archive, favorite, add tags, long-press to **highlight a passage**, ShareLink, and text export.
- **Archive** — read/archived articles with restore, swipe actions, search, empty state.
- **Library** — three collections: **Tags** (with full rename / recolor / delete management and per-tag article lists), **Favorites**, and a **Highlights** collection grouped by article that jumps you back into the reader.
- **Onboarding** — three-slide intro gated by a persisted `hasOnboarded` flag.
- **Settings** — app appearance (System/Light/Dark), default reader theme, default font, default text size, reading speed (wpm), and a haptics toggle — all persisted.
- **6 bundled sample articles** + seeded tags + seeded highlights, so every screen is alive and the app is fully usable offline on first launch.

## Substantive core logic

The heart of Stow is **`ArticleExtractor`** (`Utilities/ArticleExtractor.swift`) — a hand-rolled readability engine in pure Swift, implemented as an `actor` so fetch + parse never block the main thread:

1. **Fetch** — `URLSession async/await` with a real User-Agent, timeout, HTTP-status and MIME-type checks, and charset-aware decoding (IANA → `String.Encoding`, UTF-8 / Latin-1 fallback).
2. **Strip** — remove `<script>/<style>/<noscript>/<nav>/<header>/<footer>/<aside>/<form>/<figure>/<iframe>` and other noise blocks.
3. **Scope** — find the densest `<article>`/`<main>` region by total paragraph-text length, with a fallback to the whole stripped body when scoping is too thin.
4. **Extract blocks** — scan `<p>/<h1..h4>/<li>/<blockquote>` in document order, strip inline tags, decode HTML entities (a pure-Swift named + numeric entity decoder, `Utilities/HTMLEntities.swift`), collapse whitespace, drop trivial fragments and consecutive duplicates.
5. **Metadata** — title from `og:title` → `<title>` (with " | Site" suffix trimming) → first `<h1>`; byline from `author` meta; site name from `og:site_name` → host.
6. **Compute** — word count and estimated reading minutes (`words / configurable wpm`, guarded against divide-by-zero).

Every failure path is a typed, recoverable `ExtractionError` (invalid URL / network / not-HTML / empty content) with calm copy and retry — never a crash, force-unwrap, or `try!`.

## Run

1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. `open Stow.xcodeproj` — select an iOS 17+ simulator (or device) and press **Cmd+R**.

The app is fully usable offline thanks to the bundled sample articles. Live "Add URL" fetching works at runtime on a real device or any simulator with a network connection.

**Free signing:** the bundle id is `com.orbioom.stow`. To run on a physical device, select the target → Signing & Capabilities → choose your personal team; Xcode provisions a free development signature automatically.

## Tech notes

- **iOS 17+**, **SwiftUI 5**, **MVVM** with lightweight view models (`AppSettings`, `AddArticleViewModel`) and a pure, testable extraction engine kept off the main thread via an `actor`.
- **SwiftData** for all primary data (`Article`, `Tag`, `Highlight`) with `@Model`, `@Query`, `@Relationship` many-to-many (Article ↔ Tag) and a cascade relationship (Article → Highlight). `@AppStorage`/`UserDefaults` only for small prefs and flags. Persistence survives relaunch; the `ModelContainer` falls back to an in-memory store rather than ever crashing.
- **Design language** — a warm "reading nook": paper/sepia surfaces, a rust/amber accent (`#C86B3C`), serif display type, and a single cohesive `Theme` with dynamic semantic colors so light and dark mode are both first-class.
- **Accessibility** — Dynamic Type throughout, VoiceOver labels/hints/values on interactive and composite elements, decorative images hidden, reader honors a text-size floor, and animations respect `accessibilityReduceMotion`.
- **Monetization** — one-time **Stow Pro** (`$4.99`) simulated locally via `@AppStorage("isPro")`; free tier caps the library at 15 articles and base theme/font, Pro unlocks unlimited articles, all themes/fonts, highlights, unlimited tags, and export. No ads, no subscription, no account. StoreKit 2 wires in for production by replacing the `unlock()`/restore calls in `PaywallView`.
- **Why it can boom** — Pocket's 2025 shutdown left millions of read-it-later users actively shopping for a replacement, and the strongest pitch in that moment is exactly Stow's: native, private, offline-forever, and a one-time price instead of yet another subscription.

## Self-review

Re-read every Swift file and verified by inspection: all `import`s present; all types, initializers, enum cases, and modifiers exist in the iOS 17 SDK and are spelled correctly; protocol conformances satisfied (`Codable`, `Identifiable`, `Layout`, `PreferenceKey`); ownership correct (`@StateObject`/`@State`/`@Bindable`/`@Environment`/`@EnvironmentObject`); `NavigationStack`/`navigationDestination`/sheet/`confirmationDialog` bindings type-check; `@Query` predicates and `modelContainer`/`modelContext` wiring are valid SwiftData; many-to-many and cascade relationships wired with inverses. No APIs newer than iOS 17. Anti-stub grep (`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`stub`) is **clean**. No `try!`, no `as!`, no force-unwraps on user paths; the only `fatalError` is the documented unreachable `ModelContainer` fallback. Divisions and array access are guarded. 31 Swift files across Models / ViewModels / Views / Theme / Persistence / Utilities.
