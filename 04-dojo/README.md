# Dojo — BJJ & Martial Arts Training Tracker

A production-ready iOS app for tracking Brazilian Jiu-Jitsu and martial arts training.

## Features

- **Training Log** — Log sessions with type, duration, rounds, submissions, and notes
- **Technique Library** — Browse and drill 30+ pre-loaded techniques across 8 categories
- **Belt Progression** — Track belt and stripe history with estimated progress to next promotion
- **Competition Records** — Log tournament results with wins, losses, and medal tracking
- **Dark Crimson Theme** — Charcoal + crimson red aesthetic built for the mat

## Tech Stack

- SwiftUI 5 + SwiftData
- iOS 17+ deployment target
- XcodeGen (`project.yml`)

## Building

```bash
cd ios
xcodegen generate
open Dojo.xcodeproj
```

## Belt System (BJJ)

White → Blue → Purple → Brown → Black

Each belt allows up to 4 stripes (Black allows 6). Minimum time requirements enforced in BeltEngine.
