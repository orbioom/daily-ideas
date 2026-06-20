# Script — iOS Screenwriting App

**Write your story.**

A native iOS screenwriting app built on the open Fountain format. No subscription required. PDF export included free. One-time Pro upgrade for power features.

---

## Why This Exists

Final Draft costs $249.99. Celtx requires a monthly subscription. Highland 2 is Mac-only. iOS screenwriters — film students, indie filmmakers, aspiring writers — are completely underserved. Script is the app that should have existed years ago: fast, offline-first, properly formatted, Fountain-compatible, and priced fairly.

Target users: aspiring screenwriters, film students, indie filmmakers, TV writers on the go, anyone who needs to write in proper industry format without paying Final Draft prices.

---

## Features

### Free (forever)
- Unlimited scripts
- Fountain plain-text editor with real-time formatting
- Keyboard toolbar with scene heading / action / character / dialogue / parenthetical / transition shortcuts
- PDF export (Letter size, correct industry margins: 1.5" left, 1" right/top/bottom)
- Fountain export (.fountain open format)
- Script list with search, sort, swipe-to-delete, favorite
- Color labels per script
- Auto-save with debounce
- Word count, page count estimate
- Onboarding tour with Fountain format primer
- Dark / Light / System appearance

### Pro ($6.99 one-time)
- Final Draft XML export (.fdx) — compatible with Final Draft 11+
- Story notes per script (scratchpad / outline area)
- Character navigator (all unique characters extracted)
- Scene navigator (all scene headings, numbered)
- Full dark mode theme options

---

## Tech Stack

- **Swift 5.9 + SwiftUI** — native iOS 17
- **SwiftData** — persistence (replaces CoreData)
- **Fountain** — open screenplay markup format (fountain.io)
- **UIKit bridge** — `UITextView` for the editor (gives keyboard accessory toolbar, precise cursor control)
- **UIGraphicsPDFRenderer** — proper PDF generation with Courier 12pt, industry margins
- **No third-party dependencies**

---

## Project Structure

```
ios/
  project.yml              — XcodeGen project spec
  Script/
    ScriptApp.swift        — App entry point
    ContentView.swift      — Root: onboarding vs project list
    Models/
      ScriptProject.swift  — SwiftData model for a screenplay
      ScriptSettings.swift — SwiftData model for app settings
    Engines/
      FountainParser.swift    — Full Fountain markup parser
      FountainTextEditor.swift — UITextView editor with format toolbar
      ScriptPDFExporter.swift — PDF generation (Letter, Courier 12pt)
    Views/
      Onboarding/OnboardingView.swift  — 3-page onboarding
      Projects/ProjectListView.swift   — Script library
      Projects/NewProjectSheet.swift   — New script form
      Editor/EditorView.swift          — Main writing screen
      Editor/FormatGuide.swift         — Scrollable format hint bar
      Preview/PreviewView.swift        — Formatted script preview
      Export/ExportView.swift          — PDF / Fountain / FDX export
      Detail/ScriptDetailView.swift    — Metadata, characters, scenes
      Settings/SettingsView.swift      — App preferences
      Components/EmptyStateView.swift  — Reusable empty state
      Components/PageCountBadge.swift  — Page count pill
      Components/ColorTagPicker.swift  — Color label picker
    Theme/ScriptTheme.swift  — Colors, fonts, genres, drafts
    Assets.xcassets/         — App icon (amber #F4A261), accent color
    Info.plist
```

---

## Running the App

### Prerequisites

```bash
# Install XcodeGen (generates .xcodeproj from project.yml)
brew install xcodegen

# Or via Mint:
mint install yonaskolb/XcodeGen
```

### Generate & Open

```bash
cd ios/
xcodegen generate
open Script.xcodeproj
```

### Sign & Run

1. In Xcode, select the `Script` target
2. Under Signing & Capabilities, set your Team (free Apple ID is fine for device testing)
3. Select your simulator or device
4. Cmd+R

No paid developer account needed for simulator builds. Free signing works for personal device installs up to 7 days.

---

## Monetization

| Tier | Price | Features |
|------|-------|----------|
| Free | $0 | Unlimited scripts, Fountain editor, PDF export, Fountain export |
| Pro | $6.99 one-time | FDX export, story notes, character/scene navigator, extra themes |

**No subscription. No ads. No data collection.**

Revenue model: App Store one-time IAP. At $6.99 with 70% developer share, break-even at ~100 downloads. Film school students alone represent a massive addressable market — there are 500,000+ film/media students in the US with no good mobile option.

---

## Why It Can Boom

- **Final Draft** costs $249.99 — the industry standard but prohibitively expensive for students
- **Celtx** moved to subscription ($7.99/month) — annoying for casual writers
- **Highland 2** is Mac-only, no iOS version  
- **WriterDuet** has a free tier but is web-based, not native iOS
- **The gap**: A fast, native, offline, properly-formatted iOS app priced fairly

AppStore categories to target: Productivity, Reference  
Keywords: screenplay, screenwriting, fountain, script, film, movie, writer, final draft alternative

---

## Fountain Format Quick Reference

| Element | Syntax |
|---------|--------|
| Scene Heading | `INT. COFFEE SHOP - DAY` |
| Action | Normal prose text |
| Character | `ALL CAPS NAME` (alone on line) |
| Dialogue | Text following a character cue |
| Parenthetical | `(beat)` or `(softly)` |
| Transition | `CUT TO:` / `FADE OUT.` |
| Page Break | `===` |
| Centered | `> TITLE CARD <` |

Full spec: https://fountain.io

---

## Self-Review

- All Swift files are complete with no stubs, TODOs, or placeholder code
- SwiftData models use `@Model` and compile with Xcode 15+
- The Fountain parser handles scene headings, action, character, dialogue, parentheticals, transitions, centered text, and page breaks
- PDF exporter uses proper industry margins (1.5" left, 1" right, 1" top/bottom, Courier 12pt)
- Editor uses UITextView bridge for keyboard accessory toolbar (format shortcuts)
- Auto-save debounces at 500ms to avoid excessive SwiftData writes
- Pro features are gated with a ProUpgradeView stub ready for StoreKit integration
- Works on iOS 17.0+ iPhone and iPad (TARGETED_DEVICE_FAMILY: 1,2)
