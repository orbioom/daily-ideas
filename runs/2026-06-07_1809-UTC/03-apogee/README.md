# Apogee

A native iOS 17 SwiftUI app by the **Orbioom** studio — a **model-rocketry flight planner & logbook**.

Design a rocket (mass, body diameter, drag coefficient, CG & CP), pick a motor from a built-in Estes / AeroTech-style catalog, and Apogee predicts peak **altitude**, max velocity, time-to-apogee, recommends the ejection **delay**, and reports the **stability margin** in calibers. Then log real flights and compare predicted vs actual.

Audience: hobby rocketeers, parents and kids in NAR / TARC clubs, and STEM teachers. Everything runs on-device.

## Features

- **Rockets** — design rockets with full CRUD, a live stability read-out (calibers + status), a CG/CP balance diagram, and an inline **Simulator**: pick a motor, run the physics (with a brief computing state), and see the predicted apogee, max speed, time-to-apogee, recommended ejection delay, thrust-to-weight, and an altitude-vs-time chart with burnout and apogee marked. Log a flight straight from the result.
- **Motors** — the catalog grouped by NAR impulse class (A, B, C, …) with full specs and a thrust-profile note. Add, edit and delete your own custom motors.
- **Flights** — a newest-first logbook with predicted vs actual altitude, an average-prediction-error insight, and full CRUD. Enter the measured altitude to see the delta.
- **Settings** — haptics, appearance (System / Light / Dark), units (m / ft), a default drag coefficient for new rockets, library counts, Erase-all (with confirmation), and About.

## The engine

`Utilities/FlightEngine.swift` is the heart of the app: a pure, well-commented two-phase numeric integrator (Euler, dt = 0.01 s, g = 9.80665 m/s², ρ = 1.225 kg/m³).

- **Stability margin** (calibers) = (CP − CG) / diameter, guarded against a zero diameter. < 1 Unstable, 1–2 Stable, 2–3 Stable (firm), > 3 Overstable.
- **Boost phase** — constant average thrust over the burn time; mass falls linearly as propellant burns. `a = (thrust − k·v² − m·g) / m`.
- **Coast phase** — no thrust; integrate until vertical velocity reaches zero (apogee). Drag `k = ½·ρ·Cd·A`, area `A = π·(d/2)²`.
- Returns apogee, max velocity, time-to-apogee, burnout altitude/velocity, recommended delay (burnout → apogee), thrust-to-weight, the nearest available motor delay, and a sampled trajectory for charting.
- Robustness: mass and diameter guarded > 0, iterations capped at 60 s of flight to avoid runaway loops, and bad input returns a zeroed result rather than crashing. The sim runs on a detached task with an `@MainActor` publish so the UI shows an honest computing state.

## Architecture

- **SwiftData** for persistence (`Rocket`, `Motor`, `Flight`; cascade delete from rocket → flights). `@AppStorage` for preferences only. State survives relaunch.
- **Theme/Brand.swift** + **Views/Components/Components.swift** provide the Orbioom glass design system (shared scaffolding).
- First launch seeds ~12 motors, 3 rockets and 6 flights via `Utilities/SampleData.swift`.
- Light and dark are both first-class; animations use `Brand.ease()` and respect Reduce Motion; haptics are sparse and gated by the Settings toggle.

## Building

The project is generated with [XcodeGen](https://github.com/yonyz/XcodeGen) from `ios/project.yml`:

```sh
cd ios
xcodegen generate
open Apogee.xcodeproj
```

Target: iOS 17.0+. No third-party dependencies — only SwiftUI, SwiftData and Swift Charts.
