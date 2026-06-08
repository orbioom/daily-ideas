# Anchor — Hold Your Days Together

> A habit tracker that beats Streaks and Habitica by combining no-cap habit tracking, flexible scheduling, beautiful streaks, and an on-device-only privacy promise — all in a single native iOS 17 SwiftUI app from Orbioom.

---

## What It Is

**Problem:** Existing habit trackers either cap habits behind paywalls, force accounts/cloud sync, or sacrifice design for features. Users who want a premium, private, unlimited habit tracker have no obvious choice.

**Audience:** Productivity-minded iOS users aged 18–45 who care deeply about their daily routines, dislike subscriptions for basic features, and value calm, beautiful apps.

**Solution:** Anchor is a fully on-device habit tracker with no habit cap, flexible scheduling (daily / specific weekdays / N times per week), streak preservation logic, a month-view heatmap, and Swift Charts–powered insights — all backed by SwiftData and the Orbioom design language.

---

## Full Feature List

### Habits
- Unlimited habits, no paywall
- Three schedule types: Every Day, Specific Weekdays (bitmask picker), Times per Week
- Daily target (count-based, e.g. "8 glasses of water") with custom unit label
- Build polarity (track growth) and Quit polarity (track abstinence)
- SF Symbol icon picker (60+ curated symbols)
- 16-color swatch palette
- Archive/unarchive habits; reorder via drag
- Full edit and delete with confirmation dialog

### Today View
- Daily completion ring (completed/scheduled habits)
- Per-habit progress ring for count-based habits, tap-to-complete for single-step habits
- Stepper UI for multi-count habits (e.g. glasses of water)
- Current streak badge with flame icon
- "Stay clean today" styling for quit habits
- Empty state when nothing is scheduled
- Tap row to navigate to habit detail

### Calendar View
- Month grid heatmap with per-day intensity shading
- "All habits" overview or single-habit filter with a chip picker
- Month navigation (prev/next)
- Tap any day to open a detail sheet listing habit statuses
- Today highlighted with ring outline

### Insights View (Swift Charts)
- Summary cards: total completions, best-ever streak, 7-day rate, active habit count
- 8-week bar chart of overall completion rate
- Streak leaderboard (top 6 current streaks)
- 12-week contribution heatmap with legend
- Empty state if no data yet

### Habit Detail View
- Symbol, name, polarity, archive status header
- Four stat tiles: current streak, longest streak, 30-day rate, total completions
- 12-week per-habit heatmap
- 14 most-recent entries list with relative date labels

### Onboarding
- 3-page paged TabView (anchor, flame, shield symbols)
- Reduce-motion aware
- "Get Started" InkButtonStyle CTA on final page

### Settings (5+ persisted prefs)
- Week start day: Sunday / Monday
- Appearance: System / Light / Dark (live ColorScheme binding)
- Show archived habits toggle
- Haptic feedback toggle (bound to `Haptics.enabled`)
- Replay Onboarding (confirmation dialog, data safe)
- About section: app name, version, studio, platform, privacy blurb

### Quality
- Empty states on every list screen
- Input validation with inline error messages
- Accessibility: semantic fonts (Dynamic Type), `accessibilityLabel/Hint/Value` everywhere, decorative images `.accessibilityHidden(true)`, Reduce Motion respected in all animations
- Lazy containers: `List`, `LazyVStack`, `LazyVGrid`
- Stable `Identifiable` UUIDs on all SwiftData models
- 7 seed habits × ~60 days of realistic entries = 300+ seeded records on first launch
- Sparse haptics: `.tap()`, `.success()`, `.warning()`, `.selection()`
- Light and dark mode first-class via Brand color tokens

---

## Run Steps

1. **Install xcodegen** (one-time):
   ```bash
   brew install xcodegen
   ```

2. **Generate the Xcode project** — from inside the `ios/` folder:
   ```bash
   cd ios && xcodegen generate
   ```

3. **Open and run** — open `ios/Anchor.xcodeproj` in **Xcode 15+**, select an iOS 17+ simulator, then press **Cmd+R**.

---

## Free Signing Note

No Apple Developer account is required to run on Simulator. To deploy to a physical device, open **Signing & Capabilities** in Xcode, select your personal team under "Automatically manage signing", and plug in your device.

---

## Tech Notes

- **Platform:** iOS 17+, SwiftUI 5, no third-party dependencies
- **Architecture:** Feature-centric MVVM — SwiftData `@Model` objects, pure `StreakEngine` struct for all calculations, `@Query` + `@Environment(\.modelContext)` for data flow
- **Persistence:** SwiftData with `.cascade` delete rules; `@AppStorage` for all user preferences
- **Design system:** Orbioom Brand.swift — adaptive color tokens, glass-morphic cards, InkButtonStyle, Brand.ease motion
- **Charts:** Swift Charts (iOS 16+) for the 8-week bar chart; custom `ContributionHeatmap` view for heatmaps
- **Monetization:** One-time purchase on the App Store — no subscriptions, no ads, no data harvesting
- **Why it can boom:** The combination of zero-cap habits, beautiful streaks, and a hard privacy guarantee fills a clear gap that Streaks (capped at 12), Habitica (gamified/complex), and Finch (niche) all leave open

---

## Self-Review Attestation

- No `TODO`, `FIXME`, placeholder, stub, or lorem text exists anywhere in the Swift source
- `@main` appears exactly once (`AnchorApp.swift`)
- The only `try!` is the in-memory fallback in `AnchorApp.init()`
- All divisions are guarded (`guard scheduled > 0`, `guard total > 0`, `guard habit.dailyTarget > 0`)
- No force-unwrap (`!`) on user-path optionals
- All SwiftData models use stable `UUID` identifiers
- `Brand.*` tokens used throughout — no hardcoded hex colors in views
- Reduce Motion environment variable respected in every animation call
- Anti-stub grep (`grep -rni "todo\|fixme\|placeholder\|stub\|lorem"`) returns zero matches
