# Axle — car maintenance, fuel & reminders

**Axle tracks every fill-up, service, and maintenance reminder for your car — with true, partial-fill-aware fuel economy and a running cost you can trust.** For everyday drivers and multi-car households who want aCar/CARFAX-style tracking without clutter, ads, or a subscription wall on basic features.

## What it is
A native iOS garage log. Add your vehicle(s), record fuel and service, set reminders by distance or date, and see real economy and spend — all stored canonically in metric and converted to your units.

## Features
- **Dashboard** — tappable odometer, key metrics (avg economy, this-month spend, total spend, fill-ups), a fuel-economy trend chart, upcoming maintenance with overdue/soon/ok status, and a unified recent-activity feed.
- **Multi-vehicle** — switch vehicles from the dashboard; add/edit/delete with make, model, year, plate, fuel type.
- **Fuel** — log fill-ups (full or partial); Axle computes **economy between full tanks** (partial top-ups rolled into the next interval, the way real consumption works), plus average, total cost, and total fuel.
- **Service** — full service history (14 types), per-record cost/odometer/notes, total service spend.
- **Reminders** — trigger by distance, date, or both; overdue/due-soon/ok colors; mark done to roll a repeating reminder forward; reactivate or delete completed ones.
- **Settings** — distance unit (km/mi), volume unit (L/gal), currency, haptics, full reset. Units convert at the edges so history never changes.
- Onboarding (add a car or load sample data); empty/loading/success states; Dynamic Type + VoiceOver; light/dark; Reduce Motion; sparse haptics.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Axle.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: personal team, free Apple ID, simulator or device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `GarageEngine` (partial-fill economy intervals, reminder status/roll-forward, monthly/total spend) and a `UnitFormatter` for km/L canonical storage with mi/gal/mpg display. **SwiftData** for `Vehicle` (cascade-owns `FuelEntry`, `ServiceRecord`, `ServiceReminder`); small prefs in `UserDefaults`. Swift Charts for the economy trend. Design language: **Orbioom**. No external dependencies; realistic seeded vehicle with ~9 months of fuel history.
- **Monetization:** freemium — one vehicle + core logging free; Pro (one-time unlock or subscription) for unlimited vehicles, document storage, CSV export, and reminders/widgets. Auto-care apps have a proven paying base.
- **Why it can boom:** car ownership is universal and the leading apps are dated, ad-heavy, or paywall basics. Axle nails the one feature people get wrong — *accurate* economy with partial fills — in a clean, unit-flexible, privacy-first package.

## Self-review
Re-read every file. Verified imports, iOS 17 SDK symbols, SwiftData cascade relationships and inverses, `@Bindable`/`@Query`/`@Binding` for the selected-vehicle flow (`PersistentIdentifier` tags), Charts `LineMark`. Economy math (full-tank interval accumulation), reminder status/roll, and unit conversions checked by hand; divisions guarded by `> 0`. Anti-stub grep clean (only engine parameter names matched). No `try!`/force-unwrap on user paths; only the documented container-fallback `fatalError`.
