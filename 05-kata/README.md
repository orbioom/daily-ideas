# Kata — CrossFit WOD Tracker

**Category:** Health & Fitness  
**Platform:** iOS 17+  
**Run:** 2026-06-21_run4 · #356

## What It Does

Kata is a CrossFit WOD tracker with a built-in countdown timer, 12 benchmark/hero WODs, full result logging (RX/scaled, time/rounds/reps), personal record tracking for 40+ movements, and streak tracking — all offline with no subscription.

## Feature Screens

| Screen | Description |
|--------|-------------|
| **WODs** | Hero WODs section (Murph, DT) + Benchmark Girls/Others; WODCard with name/type/description; WODDetailSheet with movement list, Start Timer button, Log Result button; CustomWODSheet for freestyle logging |
| **Timer** | WODTimerView: circular progress ring with orange/yellow/red color states; 3-second countdown; play/pause/stop controls; movement chips scroll; time cap support; done/cap-reached states |
| **Log** | WOD log with RX/Scaled badges, score display (time for ForTime, rounds+reps for AMRAP); type filter chips; streak counter; LogWODView with time MM:SS, rounds, reps, effort flames rating |
| **PRs** | Personal records by movement category; MovementPickerView with 40+ standard movements; searchable; AddPRView with lb/kg toggle; swipe-to-delete |
| **Settings** | Box name, weight unit (lb/kg), haptic feedback, stats (WODs logged, RX count, PRs tracked) |

## Technical Highlights

- **TimerViewModel** — @Observable; countdown (3→0), running, paused, done states; time cap detection; elapsed/remaining display
- **WODTimerView** — Canvas-free circular progress using `Circle().trim()` with `.animation(.linear)` for smooth per-second updates
- **BuiltInWOD** — 12 structured WODs (Fran, Cindy, Murph, Grace, Isabel, Helen, Annie, DT, Chelsea, Barbara, Diane, Elizabeth)
- **WODResult.scoreDisplay** — Smart formatting: time for ForTime, rounds+reps string for AMRAP
- **SwiftData** — WODResult, PersonalRecord, KataSettings

## Self-Review

- ✅ Timer correctly handles time caps: counts up to cap, stops, shows "Time cap!" state
- ✅ scoreDisplay handles all 7 WOD types correctly
- ✅ commonMovements list covers all standard CrossFit movements
- ✅ Dark orange-on-brown theme evokes chalk/barbell aesthetic
- ✅ Streak calculation uses calendar day comparison (not 24-hour rolling)
- ✅ XcodeGen project.yml

## Monetization

Pro IAP: training program builder, 1RM calculator, programming calendar, WOD share card export. Free: full timer + all 12 WODs + unlimited logging.
