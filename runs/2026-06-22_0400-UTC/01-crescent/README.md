# Crescent — Moon Phase Journal & Lunar Ritual Planner

**Platform:** iOS 17+  
**Bundle ID:** com.orbioom.crescent  
**Pricing:** Free base app · Pro at $3.99 one-time purchase  
**Competitive position:** Beats Moonly ($30/yr) with a one-time $3.99 Pro unlock

---

## Overview

Crescent is a private lunar companion that helps users track moon phases, write phase-aware journal entries, follow guided new and full moon rituals, and discover how the lunar cycle influences their mood and energy.

---

## Building

### Prerequisites

- Xcode 15+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Generate & Open

```bash
cd ios
xcodegen generate
open Crescent.xcodeproj
```

Then build and run on any iOS 17 simulator or device.

---

## Feature Screens

### 1. Today Tab
- Large geometrically accurate moon canvas (SwiftUI `Canvas`)  
- Phase name, energy keyword, and illumination percentage  
- Days until next new moon and next full moon  
- Today's ritual suggestion based on current phase  
- Quick button to write a journal entry  
- Gear icon in navigation bar links to Settings

### 2. Calendar Tab
- 30-day grid with moon phase emoji per day  
- Tap any day to see phase details, illumination, and description  
- New moon and full moon days highlighted with indicator dots  
- Month navigation with chevron buttons  

### 3. Journal Tab
- List of entries sorted newest-first, each tagged with moon phase and mood  
- Swipe-to-delete entries  
- Tap any entry to edit  
- Write new entries via toolbar pencil icon  
- Entry editor shows current phase, mood stars (1–5), and full-text editor  
- Haptic feedback on save  

### 4. Rituals Tab
- 10 built-in ritual templates (5 New Moon + 3 Full Moon + 2 other phases)  
- Tap any ritual to open the detail view  
- Step-by-step checklist with tap-to-complete steps  
- Notes field for reflection  
- Mark as Complete records a `RitualCompletion` with current phase  
- Completion history shown below each ritual card  
- Haptic feedback on completion  

### 5. Insights Tab
- Journaling streak counter  
- Entry count and ritual completion count  
- Bar chart: average mood by moon phase (requires `Charts` framework)  
- Phase distribution: entries per phase as a horizontal bar chart  
- Empty state when no entries exist  

### Settings (via gear icon on Today tab)
- Toggle moon phase reminders (on/off)  
- Reminder time picker (hour/minute)  
- Toggle haptic feedback  
- App version and moon algorithm info  

### Onboarding (3 steps)
- Shown on first launch (gated by `CrescentSettings.hasCompletedOnboarding`)  
- Swipeable page-style onboarding with `TabView`  
- Completes onboarding and shows main app on "Begin My Journey"  

---

## Moon Engine (Pure Math)

No location, no network. Purely deterministic.

```
Known new moon: January 11, 2024 at 11:57 UTC
Synodic month: 29.53059 days

phaseAngle = elapsed_days / 29.53059  (mod 1.0)
illumination = (1 - cos(2π × phaseAngle)) / 2

Phase boundaries:
  New Moon:        0.000 – 0.034
  Waxing Crescent: 0.034 – 0.233
  First Quarter:   0.233 – 0.284
  Waxing Gibbous:  0.284 – 0.483
  Full Moon:       0.483 – 0.517
  Waning Gibbous:  0.517 – 0.716
  Last Quarter:    0.716 – 0.767
  Waning Crescent: 0.767 – 1.000
```

---

## Moon Canvas Drawing

Rendered with SwiftUI `Canvas`. Algorithm:

- **Background:** Dark sphere `Color(red: 0.04, green: 0.04, blue: 0.10)`
- **New Moon:** Dark sphere only with faint glow stroke
- **Full Moon:** Pearl ellipse fill + inner brightness overlay + outer glow ring  
- **Crescent / Gibbous (waxing, phase < 0.5):**  
  - Right semicircle arc + cubic bezier terminator  
  - Terminator control point x = `cos(phaseAngle × 2π) × R`  
- **Waning (phase > 0.5):**  
  - Left semicircle arc + mirrored terminator  
- **Accessibility:** `accessibilityLabel("Moon phase illustration")` set on canvas  
- **Reduce Motion:** Glow pulse animation skipped when system preference is on  

---

## SwiftData Models

### `MoonJournalEntry`
| Property | Type | Notes |
|---|---|---|
| id | UUID | Auto-generated |
| date | Date | Entry date |
| content | String | Full journal text |
| moodRating | Int | 1 (low) – 5 (radiant) |
| moonPhaseRaw | String | Phase rawValue at time of entry |
| illumination | Double | 0.0–1.0 |
| tags | [String] | User-entered space-separated tags |

### `RitualCompletion`
| Property | Type | Notes |
|---|---|---|
| id | UUID | Auto-generated |
| date | Date | Completion date |
| templateId | String | Matches `RitualTemplate.id` |
| notes | String | Optional reflection notes |
| moonPhaseRaw | String | Phase rawValue at time of completion |

### `CrescentSettings`
| Property | Type | Notes |
|---|---|---|
| id | UUID | Auto-generated |
| hasCompletedOnboarding | Bool | Gates onboarding display |
| reminderEnabled | Bool | Notification toggle |
| reminderHour | Int | 0–23 |
| reminderMinute | Int | 0–59 |
| hapticsEnabled | Bool | Haptic feedback toggle |

---

## Monetization

| Feature | Free | Pro ($3.99 one-time) |
|---|---|---|
| Full moon calendar (all phases) | ✓ | ✓ |
| Journal entries (unlimited) | ✓ | ✓ |
| 10 built-in ritual templates | ✓ | ✓ |
| Insights & mood charts | ✓ | ✓ |
| Custom ritual templates | — | ✓ |
| Moon phase reminder notifications | — | ✓ |
| Extended insights history (90 days+) | — | ✓ |

---

## Design System

| Token | Value |
|---|---|
| `CrescentTheme.navy` | `#0D0F1E` — background |
| `CrescentTheme.silver` | `#C0C0CC` — secondary text |
| `CrescentTheme.pearl` | `#F5F0E8` — primary text / highlights |
| `CrescentTheme.gold` | `#C8A96E` — accent / CTA |
| `CrescentTheme.cardBg` | `#141728` — card surfaces |
| `CrescentTheme.dark` | `#080912` — deepest background |

Typography: System serif (`Georgia` / `.serif` design) for headings; system sans-serif for body.

---

## Self-Review Checklist

### Features
- [x] Today view with moon canvas, phase name, illumination, countdown cards, ritual suggestion
- [x] Calendar with 30-day grid, moon phase emoji per day, tap-for-detail
- [x] Journal list with phase tags, mood indicators, swipe-to-delete, edit support
- [x] Journal entry editor with phase context, mood picker, full text editor
- [x] Rituals list showing 10 templates across all phases
- [x] Ritual detail with step checklist, notes, completion recording, history
- [x] Insights with mood chart, phase distribution, streak counter
- [x] Settings with 3 real persisted prefs (reminder toggle, reminder time, haptics)
- [x] 3-step onboarding gated by `hasCompletedOnboarding`
- [x] Empty states on Journal, Rituals history, Insights

### Code Quality
- [x] No `TODO`, `FIXME`, or placeholder comments
- [x] No `try!` or force-unwrap (`!`) on user data paths
- [x] All `@Query` properties are in `@MainActor` SwiftUI views
- [x] `modelContainer` configured in `CrescentApp.swift` for all 3 model types
- [x] `@Environment(\.modelContext)` used for inserts and deletes
- [x] `@Environment(\.accessibilityReduceMotion)` used in `MoonCanvasView`
- [x] `Charts` framework used for `BarMark` in `InsightsView`
- [x] Haptic feedback wired to hapticsEnabled setting
- [x] Dark mode enforced via `.preferredColorScheme(.dark)` in MainTabView
- [x] `accessibilityLabel` on moon canvas
- [x] Dynamic Type honored via system fonts throughout
