# Beacon — amateur radio logbook & grid tools

**One line:** A calm, fully-offline ham radio logbook that turns every contact into distance and bearing from your station.

**Problem & audience:** Amateur radio operators log contacts ("QSOs") constantly — at home, and especially in the field for POTA (Parks on the Air) and SOTA (Summits on the Air). Existing apps are either cloud-locked, cluttered, or assume a desktop. Beacon is for the operator who wants to log a contact in seconds beside an open rig, group contacts into outings, and instantly know how far they just reached — all on-device, no signal required.

## Features

- **Logbook** — full CRUD over contacts: callsign, date/time, band, mode, frequency, RST sent/received, their grid/name/QTH, QSL-confirmed flag, notes. Search by callsign/name/grid; filter by band and mode.
- **Outings** — group contacts into POTA parks, SOTA summits, contests, Field Day, or casual home sessions. POTA outings show live progress toward the 10-QSO activation target with a progress bar and "activated" seal. Per-outing stats: contacts, unique grids, farthest contact.
- **Insights** — total/unique callsigns, grids worked, confirmed count, farthest contact (with distance), contacts-by-band bar chart (Swift Charts), and a mode breakdown.
- **Grid Tools** — a standalone Maidenhead calculator: enter two locators (4- or 6-char) and get great-circle distance, bearing (degrees + 16-point compass), and an animated compass rose. Tap any worked grid to drop it in. Swap, and "use my grid".
- **Real geodesy** — `GridMath` encodes/decodes Maidenhead locators and computes Haversine great-circle distance and initial bearing. Every parser returns an optional; no force-unwraps on user input.
- **Settings** — your callsign & grid, distance unit (km/mi), default band, default mode, haptics; reload sample log; delete all data.
- First-run onboarding (persisted) that optionally captures your station up front, empty/loading/success/error states, light & dark, Dynamic Type, VoiceOver labels, Reduce Motion, sparse haptics.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Beacon.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: select your personal team under Signing & Capabilities; no paid account needed for the simulator or a personal device.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-lite (pure `GridMath` engine, SwiftData models, thin views).
- Persistence: **SwiftData** (`Activation` 1-to-many `QSO`, cascade delete). Small prefs in `UserDefaults` via `@AppStorage`.
- Design language: **Orbioom** (liquid glass, ink-gradient primary action, mono figures, green as a rare accent for "confirmed/activated").
- No external dependencies; Swift Charts is a system framework.

## Self-review

Re-read every Swift file by hand against the iOS 17 SDK: all imports (`SwiftUI`, `SwiftData`, `Charts`, `CoreLocation`, `UIKit`) resolve; `@Model`/`@Relationship` with cascade + inverse, `@Query`, `@Bindable`, `@AppStorage`, `NavigationStack`/`navigationDestination(for:)` for both `QSO` and `Activation`, sheet bindings all type-check. No force-unwraps, `try!` (except the in-memory `ModelContainer` bootstrap fallback in `BeaconApp`, not a user path), unchecked indices, or unguarded division on user paths — `GridMath` clamps and returns optionals. Anti-stub grep (`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`stub`) is clean. Seeds 18 realistic contacts across 3 outings.
