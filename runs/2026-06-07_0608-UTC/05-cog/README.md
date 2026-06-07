# Cog — Bike maintenance & component wear

**Know what's worn before it breaks.** Cog tracks every component on every bike against its expected life, updates wear from your rides, projects when each part is due, and keeps a full service history.

Design language: **Orbioom** (Liquid Glass, ink-gradient buttons, SF Pro + JetBrains Mono, green/amber/red for wear status).

## The problem
Chains, tyres, brake pads and cables all wear at different rates, and riders forget what's been replaced and when. Cog turns logged rides into live wear bars and refill-by dates — offline, with sensible lifespan presets.

## Features
- **Garage** — every bike with its odometer and at-a-glance due/soon counts; full bike CRUD (name, type, starting odometer).
- **Bike detail** — big odometer, one-tap ride logging, a components list with wear bars + status + projected replacement date, and recent-riding stats (7-day, 30-day, avg/day).
- **Components** — full CRUD with lifespan presets (chain, cassette, tyres, pads, sealant…), distance and/or time-based life, install odometer & date, and a **Replace** action that resets wear to 0 and logs a service.
- **Wear engine** (`Utilities/WearEngine.swift`): distance & time wear (overall = the further-along of the two), OK/Soon/Replace status, projected replacement date from the bike's average daily distance, trailing-window and weekly distance, plus a `Units` km⇄mi converter.
- **Health** — cross-bike overview grouped into Replace now / Coming soon / Healthy, sorted by wear.
- **Rides** — full ride log with an 8-week distance chart; add a ride for any bike; deleting a ride removes its distance from the odometer.
- **Service** — maintenance history across bikes with total spend; log a service (component, action, date, cost, notes) for any bike.
- **Settings** — haptics, miles/km units, appearance, confirm-before-delete, garage counts, guarded erase-all.
- Onboarding gated by a persisted flag; empty states; full Dynamic Type, VoiceOver, Reduce Motion, light & dark, designed gear app icon. Seeds two bikes, components at varied wear, a season of rides, and service records.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Cog.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** personal team under Signing & Capabilities; bundle id `com.orbioom.cog`. No network, accounts, or API keys.

## Tech
iOS 17+, SwiftUI 5, SwiftData (`Bike`/`Component`/`Ride`/`ServiceRecord`; distances stored in km, converted for display), pure value-type engine, native bar charts, `UserDefaults` for prefs. No third-party dependencies.

## Self-review
Re-read every Swift file by hand: imports, iOS 17 SDK symbols, SwiftData relationships & `@Query` keypaths, `sheet(item:)` Identifiable, `Picker`/`Menu` usage, `.onChange` two-parameter form, `project.yml`. Anti-stub grep clean. Division/projection paths guarded (`dailyKm>0.01`, week-index bounds, odometer floored at 0). Only `try!` is the in-memory container fallback. An automated by-hand compile review of this app returned clean. Believed to compile cleanly under Xcode 15+ after `xcodegen generate`.
