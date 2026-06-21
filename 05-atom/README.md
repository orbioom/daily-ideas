# Atom — Interactive Periodic Table

**Interactive periodic table + chemistry quiz for students and science enthusiasts.**

A clean, fast, native iOS app with all 118 elements, a zoomable periodic table canvas, deep element detail pages, and adaptive quizzes. Built in SwiftUI + SwiftData, targeting iOS 17+.

---

## Features

### Periodic Table
- Full 118-element zoomable canvas with pinch-to-zoom (0.5×–2.5×) and pan gestures
- Color-coded by element category (10 categories)
- Lanthanide and actinide rows displayed below the main table
- Tap any cell to open the full element detail page

### Element Details
- Large symbol hero with category color gradient
- Atomic number, mass, group, period
- Electron configuration (Unicode superscripts)
- Electronegativity (Pauling scale)
- Melting and boiling points (°C or K, switchable)
- Year of discovery
- Real-world uses
- Fun fact for every element

### Search
- Fuzzy search by name, symbol, or atomic number
- Filter by element category (chips)
- Sort by atomic number, name, or atomic mass

### Quiz (4 Modes)
1. **Symbol → Name** — given a symbol, pick the element name
2. **Name → Number** — given a name, pick the atomic number
3. **Name → Category** — given a name, pick the category
4. **Name → Atomic Mass** *(Pro)* — pick the correct mass range

- 10 questions per session
- Live score, streak counter, correct/wrong tally
- Post-session result screen with missed elements for review
- Progress saved to SwiftData

### Stats
- Total quizzes, total correct, overall accuracy
- Best streak
- Per-mode accuracy bars
- Line + area chart (accuracy over last 10 sessions) via Swift Charts
- Most-missed elements (tap to review)

### Settings
- Color blind mode (accessible palette)
- Temperature units (°C / K)
- Default quiz mode selector
- Show/hide atomic mass on cells
- Pro unlock ($3.99 one-time)
- Reset all progress

### Onboarding
- 3-page walkthrough with swipe/tap navigation
- Skip option available

### Accessibility
- VoiceOver labels on every element cell (`Element name, symbol, atomic number`)
- Answer feedback announced via `UIAccessibility.post`
- Reduce Motion support (disables animations)
- Dynamic Type compatible layout

---

## Run Instructions

### Requirements
- macOS 13+ with Xcode 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- iOS 17.0 Simulator or device

### Steps
```bash
cd daily-ideas/05-atom/ios
xcodegen generate
open Atom.xcodeproj
```
Then select a simulator and press **Run** (⌘R).

---

## Project Structure

```
ios/
  project.yml              # XcodeGen spec
  Atom/
    AtomApp.swift          # @main entry, .modelContainer
    Models/
      Element.swift        # 118 elements with full data
      ElementCategory.swift
      QuizEngine.swift     # @Observable quiz state machine
    Views/
      ContentView.swift    # TabView root
      Onboarding/          # 3-page onboarding
      Table/               # PeriodicTableView, ElementCellView, ElementDetailView
      Search/              # SearchView with filter + sort
      Quiz/                # QuizView, QuizResultView
      Stats/               # StatsView with Swift Charts
      Settings/            # SettingsView
      Components/          # PropertyRow, PropertyDivider
    Theme/
      AtomTheme.swift      # Colors, styles, button style
    Persistence/
      AtomProgress.swift   # @Model — quiz history
      AtomPrefs.swift      # @Model — user preferences
      AtomOnboarding.swift # @Model — onboarding state
```

---

## Monetization

**One-time Pro unlock: $3.99**

Unlocks:
- Atomic Mass quiz mode
- Full quiz stats history (last 50 sessions in charts)

Free tier gives all 118 elements, 3 quiz modes, and core stats. The paywall is soft — students get full reference value for free and unlock quizzing depth when they want it.

---

## Market Opportunity

Chemistry students are a durable global buying audience — every high school and university chemistry course is a pipeline. Key advantages over incumbents:

| Competitor | Problem |
|---|---|
| Merck Periodic Table | Subscription model ($3.99/mo) — one-time $3.99 beats it |
| PTOE (web port) | Cluttered UI, not native, no offline quiz |
| Wikipedia | No quiz, no UX |

Native SwiftUI on iOS 17 means smooth 120Hz scrolling, instant launches, and no subscription fatigue. A clean dark-science aesthetic positions it above every existing app in screenshots.

---

## Self-Review Checklist

- All 118 elements included (H through Og) with symbol, name, mass, category, group, period, electron config, fun fact, and uses
- No stubs or TODO comments in any source file
- SwiftData wired up with `.modelContainer(for: [AtomProgress.self, AtomPrefs.self, AtomOnboarding.self])`
- All 5 tabs implemented: Table, Search, Quiz, Stats, Settings
- Onboarding with 3 pages and skip button
- Color blind mode switches palette across the entire UI
- Kelvin/Celsius toggle propagated through detail views
- Quiz engine fully functional: 4 modes, answer validation, streak tracking, result summary
- Swift Charts in StatsView for accuracy trend
- Accessibility labels on element cells and quiz options
- Reduce Motion respected in onboarding and quiz transitions
