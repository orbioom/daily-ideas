# Verso

**A calm, fast home for Markdown notes — with links between ideas and no subscription to read your own words.** For writers, students, and thinkers who want a beautiful "second brain" without Bear's iCloud-sync paywall or Notion's bloat.

## Features

- **Markdown notes** with a live block renderer: headings, **bold**/*italic*/`code`, bullet, numbered, and checkbox lists, quotes, code blocks, and dividers.
- **Wiki-links** — type `[[Note title]]` to link notes; Verso renders them as tappable links and auto-builds the **backlinks** ("linked from") on the target note. Tapping a link to a missing note offers to create it.
- **Write / Preview** toggle in the editor, with a Markdown formatting bar above the keyboard.
- **Folders** with custom SF Symbol icons and colors; **Unfiled** and **Archived** smart folders.
- **Tags** (many-to-many) with a sized **tag cloud**, per-tag note lists, rename, and delete.
- **Library** with search across title/body/tags, sort (last edited / created / title / length), a pinned section, and swipe to pin, archive, or delete.
- **Note accents** (six colors), pin, and per-note details panel.
- First-run onboarding, full **Settings** (theme, default sort, haptics, restore samples), and a one-time **Verso Pro** unlock.
- Light & dark, Dynamic Type, VoiceOver labels, Reduce Motion, haptics.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Verso.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

**Free signing:** in *Signing & Capabilities*, pick your personal team and a unique bundle id; no paid account needed to run on a device.

## Tech notes

iOS 17+, SwiftUI 5, MVVM-ish with a pure `MarkdownTools` engine (block parser + inline `AttributedString` rendering + wiki-link extraction). Persistence in **SwiftData** (`Note` ⇄ `Tag` many-to-many, `Folder` → `Note`); small prefs in `UserDefaults`. Design language: **editorial / letterpress** — warm paper, serif titles, a single teal accent — applied consistently across every screen.

- **Monetization:** free for everyday use; one-time **Verso Pro** ($7.99) unlocks export to Markdown/PDF, extra accent themes, and unlimited folders. Note-app users have proven, high willingness to pay.
- **Why it can boom:** notes is a perennially top-charts category whose leaders increasingly paywall *syncing your own text* (Bear) or overwhelm with complexity (Notion). "Honest, local-first, link-your-thoughts" is a clear, sharable wedge.

## Self-review

Re-read every Swift file by hand (no Xcode in the build sandbox). Verified: all imports; iOS-17-only APIs; SwiftData relationships/`@Query`/`modelContainer` wiring; `NavigationStack`/`navigationDestination`/`sheet` bindings; `@Observable`/`@State`/`@Bindable` ownership; custom `FlowLayout` `Layout` conformance; `OpenURLAction` wiki-link handling. Anti-stub grep clean (only the Markdown "todo" block feature and the in-memory store fallback match). No force-unwraps or `try!` on user paths.
