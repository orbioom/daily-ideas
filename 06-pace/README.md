# Pace — Privacy-First GPS Run Tracker

A native iOS app that tracks runs, walks and hikes with GPS — without harvesting your data.

## The Problem

Strava logs your home address, requires an account, and has an aggressive social feed. Nike Run Club phased out offline mode. Millions of runners want a simple tracker that just works without the surveillance capitalism.

## Why It Can Boom

- Privacy concerns about Strava are growing (r/running, Twitter/X)
- No dominant offline-first native iOS runner exists
- Simple + beautiful + private = massive gap in the market
- One-time purchase model is rare and beloved by users

## Features

- **Live GPS tracking** with MapKit route display
- **Activity types**: Run, Walk, Hike
- **Real-time metrics**: Pace, Distance, Elevation Gain, Calories
- **Route history** with map previews
- **Stats & Charts**: 8-week distance chart (Swift Charts), personal records
- **Privacy**: All data stored on-device only. No account. No cloud.
- **Pro unlock**: One-time $3.99 (no subscription)

## Tech Stack

- iOS 17+, SwiftUI 5, Swift 5.9
- SwiftData for persistent storage
- CoreLocation for GPS tracking
- MapKit for maps and route display
- Swift Charts for analytics
- @Observable for state management

## Monetization

**Pace Pro — $3.99 one-time**
- Advanced statistics & analytics
- GPX route export
- Custom interval training
- Training plans & goals
- Pace alerts during runs

## Requirements

- Physical iPhone required for GPS tracking
- Simulator shows static location only
- iOS 17.0+
- Location permission required ("When In Use" minimum)
- Background location for tracking while screen is locked

## Build Instructions

```bash
# Install XcodeGen
brew install xcodegen

# Generate Xcode project
cd ios
xcodegen generate

# Open in Xcode
open Pace.xcodeproj
```

## Privacy Policy

All workout data is stored exclusively on the user's device using SwiftData. No data is transmitted to any server. No account is required. We do not collect, store, or sell any personal data.
