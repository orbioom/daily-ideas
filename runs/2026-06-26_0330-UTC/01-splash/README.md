# Splash — Swimming Session Tracker

Private, offline swimming log and training tracker for iOS. No account, no subscription, no cloud.

## Features

- **Session logging** — log swim sessions with detailed sets (stroke type, distance, reps, rest, intensity)
- **8 stroke types** — Freestyle, Backstroke, Breaststroke, Butterfly, IM, Kick, Pull, Drill
- **Pool management** — indoor/outdoor/open-water pools with custom lengths (25m, 33m, 50m)
- **Weekly goal ring** — visual progress toward your weekly km goal
- **4 Swift Charts** — weekly distance with goal line, stroke distribution donut, pace trend, sessions per month
- **Session history** — month-grouped log with swipe-to-delete
- **Session detail** — per-set breakdown with pace, intensity, rest time
- **Feel ratings** — 1–5 star session rating for tracking fatigue and quality
- **25 seeded sessions** — realistic training data populated on first launch
- **Full CRUD** — create, edit, delete sessions, sets, and pools
- **Accessibility** — Dynamic Type, VoiceOver labels/hints, WCAG AA contrast, Reduce Motion support
- **Haptics** — toggle in settings

## Screens

1. **Today** — weekly ring, recent sessions, quick log button
2. **History** — month-grouped full session log
3. **Session Detail** — set-by-set breakdown with stats
4. **Stats** — 4 Swift Charts with weekly distance, stroke distribution, pace trend, sessions/month
5. **Settings** — pools CRUD, units (m/yd), weekly goal, intensity default, haptics

## Run Steps

1. `cd ios && xcodegen generate`
2. Open `Splash.xcodeproj` in Xcode 15+
3. Select a simulator or device
4. Product → Run

> Free signing: In Xcode → Signing & Capabilities, set your personal team.

## Monetization

One-time Pro unlock ($3.99): CSV export, custom workouts/programs, unlimited pools, full history export.

## Why it can boom

MySwimPro has millions of users but requires a $79/year subscription for core features. Swim.com is social/cloud. No clean, private, one-time-purchase native iOS swim log exists — Splash fills that gap for the 3M+ regular US lap swimmers.
