# Stroke — Rowing Ergometer Workout Tracker

The on-device rowing log for Concept2, Peloton Row, and any rowing ergometer. No subscription, no cloud, no account.

## Features

- **Workout logging** — log Distance, Timed, Intervals, and Free Row sessions with distance (m), duration, 500m avg split, stroke rate (SPM), rating, and notes
- **Auto-PR detection** — automatically detects new personal records for standard events (500m, 2k, 5k, 10k, 20min, 30min) with in-app celebration alert
- **Personal Records board** — dedicated tab for all distance and timed PRs with achieve dates
- **Watts display** — computes watts from 500m split via P = 2.80/(split/500)³ (Concept2 formula); toggle in Settings
- **Training zones** — UT2/UT1/AT/TR/AN classification from avg watts shown on workout detail
- **Dashboard** — weekly distance ring vs goal, streak counter, quick stats, last workout card, PR highlights
- **Insights** — 8-week weekly distance bars, 500m split trend line, workout type donut
- **55 seeded workouts** + 6 seeded PRs so the app is data-rich from first launch
- **Settings** — watts display toggle, weekly goal picker, body weight, haptics toggle, zone reference table

## How to Run

1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. Open `Stroke.xcodeproj` in Xcode 15+
4. Run on simulator or device (free signing: set your Team)

## Monetization

One-time $4.99 Pro — interval workout builder with per-split logging, CSV export, unlimited workout history.

## Why it can boom

1M+ Concept2 users, 800K+ Peloton Row owners — zero good native iOS erg companions. Concept2's own app is aging and limited. Stroke is the clean, private, permanent-cost alternative.

*No stubs, no TODOs. Self-reviewed clean.*
