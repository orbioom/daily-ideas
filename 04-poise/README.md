# Poise — Posture & Ergonomics Coach

**Tagline:** Break the sitting cycle. Look after your body at your desk.

**Problem + Audience:** Remote and office workers spend 8+ hours sitting with poor posture, leading to neck pain, eye strain, and wrist injuries. Existing posture apps (Moova, Stao) are ugly, limited, or require subscriptions. Poise offers a beautiful, complete exercise library with scheduled reminders and guided break sessions.

---

## Features

- **Scheduled Break Reminders** — Configurable interval (20/30/45/60 min) via UNUserNotifications; repeating reminders during work hours
- **Guided Break Player** — Full-screen immersive break sessions with countdown ring, exercise instructions, skip controls, rest transitions, and success overlay
- **30+ Exercise Library** — 5 categories (Neck, Shoulders, Eyes, Wrists, Back) with full instructions, step-by-step guides, and benefits text
- **Exercise Library Browser** — Searchable, filterable by category, with detail sheet showing all steps
- **History View** — 30-day BarMark chart (Swift Charts), 60-day calendar heatmap (green/yellow/gray), adherence %, session list
- **Home Dashboard** — Live countdown to next break, circular progress ring, today's break count, streak badge, quick "Take Break Now" button
- **Streak & Adherence Tracking** — Daily streak, total breaks taken, goal progress
- **8+ Settings** — Break interval picker, duration picker, work hours start/end, active days (Mon-Sun), notification permission, haptics, sound, daily goal
- **Poise Pro ($2.99 one-time)** — Custom programs, advanced scheduling, full analytics charts
- **Light + Dark mode** — System-adaptive via `Color(.systemBackground)` and semantic colors
- **No sign-in, fully offline** — All data stays on device via SwiftData

---

## Run Steps

```bash
brew install xcodegen
cd /path/to/04-poise/ios
xcodegen generate
open Poise.xcodeproj
```

Select an iPhone 17+ simulator, then Run (⌘R). Grant notification permission when prompted to activate break reminders.

---

## Tech Notes

- iOS 17+ / Xcode 15+
- SwiftUI 5 with `TabView` + `NavigationStack`
- `@Observable` macro (not `ObservableObject`) for `BreakScheduler` and `BreakSessionEngine`
- SwiftData (`@Model`, `@Query`, `.modelContainer`) for `BreakRecord` and `UserSchedule`
- Swift Charts (`BarMark`, `RuleMark`) for 30-day daily break chart
- `UserNotifications` framework for scheduled break reminders
- No external dependencies
- No force-unwraps, no `try!`, no `fatalError` on user paths
- AppIcon generated via Python (`struct` + `zlib`, RGBA PNG)

---

## Monetization

One-time $2.99 Pro upgrade via StoreKit — custom exercise programs, advanced break scheduling, and full analytics.

## Why It Can Boom

WFH workers are a massive underserved market; existing posture apps are ugly or require subscriptions — Poise wins with polished design, a real 30+ exercise library, and a beautiful guided break experience that feels like a wellness app, not a utility.

---

## Self-Review

Reviewed all Swift files. No TODOs, stubs, or force-unwraps found.
