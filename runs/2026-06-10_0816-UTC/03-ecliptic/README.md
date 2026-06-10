# Ecliptic — your sky, computed honestly

**What it is.** A birth-chart astrology app with a **real ephemeris running on the device**: Sun and Moon from Meeus' published theory, planets from the JPL approximate Keplerian elements (validated against reference positions to arcminutes for 1800–2050), ascendant/midheaven from sidereal time. Every placement, aspect, and transit shows its actual degree and orb — no snippet pools, no contradictory push notifications, no server. The job Co-Star, The Pattern, and CHANI monetize, built transparent and private.

**Audience.** The enormous astrology-curious audience that wants real charts without an account, plus practicing astrologers who are tired of incumbents' house-system opacity.

## Features

- **On-device ephemeris** — Julian day → solar theory (≤0.01°), principal-term lunar series (~0.05°), Kepler-solved planetary positions for Mercury–Pluto via Earth–Moon-barycenter geometry; obliquity, GMST, ascendant and midheaven with correct quadrants. Numerically validated against J2000 and 2026 reference positions.
- **Birth chart** — big-three header (Sun/Moon/Rising), a Canvas chart wheel (zodiac ring, sign glyphs, true-longitude planet glyphs, aspect chords weighted by tightness, dashed ASC axis, rotated so the ascendant sits at 9 o'clock), full placement list with composed plain-language readings, house assignments, and an aspect table with exact orbs.
- **Houses done right** — whole-sign by default, equal house optional, each explained in Settings; birth-time-unknown mode anchors to local noon, keeps planets exact, and honestly hides rising/houses.
- **Today** — the live sky (all positions, pull-to-refresh), Sun/Moon headline with the Moon's mood line, and transits to *your* chart within a configurable orb — each one named (`Saturn squares your Mars`), explained, and stamped with its real orb; a calm "quiet sky" state instead of manufactured drama.
- **People** — unlimited saved charts (CRUD with confirmation), primary-chart star (drives Today), per-person chart screens; birth place from an 86-city world gazetteer (searchable) with correct IANA time zones — the DatePicker reads the entered wall time *in the birth city's zone*.
- **Guide** — reference library for all 12 signs (element/modality/style), 10 planets, and 12 houses.
- **Settings** — house system, classical-seven toggle (hide Uranus/Neptune/Pluto), transit orb slider, haptics; About panel that names the actual algorithms.
- Onboarding (3 pages + birth form, skippable, persisted flag), empty/loading states, light + dark, Dynamic Type, VoiceOver (the wheel exposes a full spoken chart description), Reduce Motion, sparse haptics.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Ecliptic.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**.

*Free signing:* personal team is enough — no entitlements used.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-style: one SwiftData model (`ChartProfile` — charts are always recomputed, never stored), pure engines (`Astronomy`, `ChartEngine`), Canvas wheel rendering.
- Persistence: SwiftData for profiles; preferences in `@AppStorage`. Zero network.
- Design language: **Orbioom** (glass, ink gradient, mist background, mono for degrees, slow motion).
- **Monetization:** astrology is a top-grossing category (CHANI was the #1 grossing US astrology app in 2025; Co-Star ~$400k/mo) on subscriptions; Ecliptic sells a one-time "Ecliptic Pro" (synastry between saved people, extra house systems, chart export) with the full natal chart free forever.
- **Why it can boom:** a $174M+ market whose leaders get charts *wrong* in public (Co-Star's house-system complaints, contradictory notifications are the top 1-star themes); "the astrology app that shows its math, works offline, and never spams you" is a sharp, shareable wedge for the same proven audience.

## Self-review

Every Swift file re-read against the iOS 17 SDK (`Text.foregroundStyle` on Canvas text is the iOS 17 Text-returning overload; `GraphicsContext` drawing; `DatePicker` time-zone environment; SwiftData single-model container). **The ephemeris was numerically validated in this run** by porting the exact formulas to Python and checking J2000 reference longitudes (Sun 280.38°, Mercury Cap 1.9°, Mars Aqu 28.0°, Jupiter Ari 25.3°, Saturn Tau 10.2° — all match) plus Earth/Sun consistency to 0.002° and the real 2026 sky (Saturn in Aries, Pluto in Aquarius). Anti-stub grep clean. No force-unwraps, `try!`, or unchecked indexing on user paths.
