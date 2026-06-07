# Latest Run — 2026-06-07 1809 UTC

Folder: `runs/2026-06-07_1809-UTC/` — 6 production-ready native iOS apps, slots 01–06, all built. All Orbioom design language, all SwiftUI + SwiftData (iOS 17), no external dependencies, no accounts, fully on-device. Each ships a XcodeGen `project.yml` (run `xcodegen generate`, then open in Xcode 15+).

## The six apps

- **Datum** — built — `runs/2026-06-07_1809-UTC/01-datum` — Aircraft weight & balance planner: build an aircraft (empty weight/arm, loading stations, CG envelope, fuel) and each flight shows total weight, CG and in/out-of-envelope status at ramp/takeoff/landing/zero-fuel, with a plotted CG envelope chart + density-altitude tool.
- **Ramp** — built — `runs/2026-06-07_1809-UTC/02-ramp` — Cycling training-load tracker: every ride → TSS, building Fitness (CTL) / Fatigue (ATL) / Form (TSB) on a TrainingPeaks-style Performance Management Chart, plus FTP history, Coggan power zones and W/kg — fully offline, no Strava.
- **Apogee** — built — `runs/2026-06-07_1809-UTC/03-apogee` — Model-rocketry flight planner & logbook: pick a rocket + a real catalog motor → predicted altitude, max velocity, recommended ejection delay, thrust-to-weight and caliber stability margin (two-phase drag sim), then log predicted-vs-actual flights.
- **Reserve** — built — `runs/2026-06-07_1809-UTC/04-reserve` — Off-grid power budget planner for vanlife/RV/boat/cabin: loads → daily Wh/Ah, days of autonomy, solar harvest, net surplus/deficit, recharge time, inverter headroom, plus a battery/solar sizing recommender and appliance catalog.
- **Gauge** — built — `runs/2026-06-07_1809-UTC/05-gauge` — String tension calculator for guitarists/bassists/luthiers: per-string and total neck tension from gauge/material/tuning/scale-length, set balance, a set + tuning library, and a forward/reverse (suggested-gauge) calculator.
- **Latent** — built — `runs/2026-06-07_1809-UTC/06-latent` — Darkroom film-development companion: recipes + chemistry temperature + push/pull → adjusted dev time, then a calm relaunch-safe multi-phase process timer (dev/stop/fix/wash) with agitation cues, plus a session log and film/developer catalog.

## Top recommendation

**Ramp.** It hits the strongest combination of a passionate, paying audience (data-driven cyclists/triathletes) and a genuine unmet need: the TrainingPeaks PMC (CTL/ATL/TSB) is the metric people care about most, yet getting it without a subscription or a Strava round-trip is painful. The engine (TSS → exponentially-weighted fitness/fatigue/form, power zones, W/kg) is real sports science, the Performance Management Chart is a strong Swift Charts showpiece, and the whole thing is on-device and free. **Datum** is the close runner-up — pilots already pay $10+ for W&B apps, and a calm, correct, offline one with a proper envelope plot is immediately useful and safety-relevant.

## Research signals worth following next run

- **Aviation adjacent:** pilots also ask for a clean offline E6B flight computer (wind triangle, true airspeed, density altitude, fuel) and a VFR fuel/endurance planner — distinct from Datum's W&B records angle.
- **Endurance training:** running/triathlon equivalents of Ramp (rTSS/hrTSS), and a "taper planner" that projects TSB to a target race date, are frequently requested.
- **Off-grid/maker:** electrician NEC helpers (voltage drop over distance, conduit fill, wire ampacity) are a different professional audience from Reserve's energy budgeting.
- **Analog photo:** a reciprocity-failure + long-exposure calculator, and a darkroom print-exposure / test-strip timer, would pair naturally with Latent.
- **Music/luthier:** a fret-position / intonation & compensation calculator and a multiscale (fanned-fret) layout tool extend Gauge's physics into adjacent niches.
- **General:** hobby logbook+engine apps for a specific passionate niche remain the most reliable "download, keep, pay for" shape — the constraint is finding domains with real math not yet in SHIPPED.md.
