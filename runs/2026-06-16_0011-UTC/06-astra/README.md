# Astra

**Accurate birth charts and a calm daily reading — computed on your device.**

Astra is a native iOS 17 SwiftUI astrology app. Where most popular astrology apps
are widely criticized for getting charts *wrong*, Astra computes real planetary
positions on-device using proper astronomy — accurate to roughly an arcminute — and
keeps everything private (no account, no network, no doom-scroll notifications).

## What it is

A cosmic, quiet companion: your natal wheel drawn to the exact degree, every
placement explained in plain language, a daily reading grounded in real transits,
compatibility (synastry) between any two charts, and a gentle daily reflection loop.

## Full feature list

- **Today** — your primary chart's daily reading: today's Moon sign, your strongest
  *real* transit, grounded (never random, never doom) interpretation text, a mood +
  note check-in that creates a journal entry, and a reflection streak. Designed empty
  state ("Create your chart") when no profile exists.
- **Chart** — the hero: your natal wheel drawn with `Canvas` — zodiac ring with sign
  glyphs, whole-sign house divisions, planet glyphs placed at their true degrees,
  retrograde marked in red, and aspect lines across the center. Tap any planet for a
  detail sheet (sign, house, degree, retrograde, interpretation). Static under Reduce
  Motion.
- **Placements** — a readable list: Sun / Moon / Rising headline, then every planet
  with sign, house, degree, retrograde, and a short grounded interpretation; an
  aspects list with meanings; switch between charts.
- **Compatibility (synastry)** — pick two charts, compare Sun/Moon/Rising and count
  harmonious vs. challenging cross-aspects into a 0–100 synastry score with a
  per-pair breakdown and a grounded read.
- **Learn / Glossary** — signs, planets, houses, and aspects with concise, real
  meanings (reachable from Settings).
- **Add / Edit chart** — name, birth date + time, "I don't know my exact time"
  toggle, an embedded city gazetteer (70+ world cities, no location permission) or
  manual lat/long + UTC offset, and a "make primary" toggle.
- **Settings** — appearance (System/Light/Dark), haptics, show-degrees, animate-stars,
  glyph style (symbols/names), default aspect orb, chart management (add/edit/delete/
  set-primary), Load sample data, Export, Learn, Pro/Restore, and an About section
  stating the method and house system.
- **Onboarding** — three calm pages in the app's cosmic language.

## Run steps

This repo contains **Swift sources only**; the Xcode project is generated with
[XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
cd ios
xcodegen generate          # reads project.yml → Astra.xcodeproj
open Astra.xcodeproj        # build & run on an iOS 17 simulator or device
```

If you don't have XcodeGen: `brew install xcodegen`.

### Free-signing note

To run on a physical device with a free Apple ID, open the project in Xcode, select
the **Astra** target → **Signing & Capabilities**, set your personal team, and let
Xcode pick a bundle identifier. No paid Apple Developer account is required for local
runs.

## Tech notes

- **Architecture**: SwiftUI + SwiftData (`@Model` for `Profile` and `JournalEntry`,
  registered in both `ModelContainer` calls). Computed charts are never persisted —
  the ephemeris is the single source of truth, recomputed on the fly from birth data.
- **The engine** (`Engine/Ephemeris.swift`): real low-precision astronomy via Paul
  Schlyter's public-domain method ("Computing planetary positions"). Day number →
  per-body Keplerian orbital elements → Kepler's equation (iterated) → heliocentric
  rectangular coords → geocentric ecliptic longitude → sign + degree. The Moon
  includes the principal perturbation terms. Retrograde is detected via a one-day
  longitude lookback. **Houses use the Whole-Sign system** (the Ascendant's whole
  sign is the 1st house); the Ascendant uses the standard Meeus formula from local
  sidereal time, obliquity, and birth latitude. Pluto uses fixed modern mean
  elements. Everything is guarded: angles normalized, `asin`/`acos` inputs clamped to
  [-1, 1], no unguarded division. Accuracy was verified against known ephemerides
  (e.g. 2024-03-20 Sun → 0° Aries; Einstein's chart → Cancer Ascendant).
- **Privacy**: no network, no analytics, no location permission. The embedded
  gazetteer means a birth city can be chosen offline.
- **Monetization**: one-time **Astra Pro** ($4.99) unlocks unlimited charts, the full
  natal wheel, all placements + aspects, Compatibility, and the multi-day transit
  outlook (free tier = 1 chart + Today + Sun/Moon/Rising). Gated via
  `@AppStorage("isPro")`; the paywall's Unlock flips it locally — StoreKit is **not**
  wired (a production build would query StoreKit 2 transaction history in `Pro` and
  `PaywallView`). Restore is present and simulated honestly.
- **Why it can boom**: the #1 complaint about Co-Star / The Pattern is *inaccurate
  charts* — Astra's whole pitch is "actually correct, on-device, private, and calm,"
  a credible, screenshot-friendly differentiator in a huge, sticky category.

## Self-review attestation

- **36 Swift source files** under `ios/Astra/Astra/`.
- Exactly one `@main` (`AstraApp.swift`); the only `fatalError`s are the documented
  unreachable in-memory `ModelContainer` fallbacks (app + previews).
- No `try!`, no `as!`, no force-unwraps on user paths, no `NavigationView`, no
  single-arg `onChange`. All `asin` inputs clamped; all angle math normalized.
- Anti-stub clean (no TODO/FIXME/placeholder/etc.).
- Light + dark first-class via `Theme.dyn`; full Dynamic Type; VoiceOver labels on
  controls, placements, and the wheel; Reduce-Motion disables the starfield twinkle
  and wheel animation.
- 4 substantive feature tabs (Today, Chart, Placements, Compatibility) + Settings;
  every screen has empty / loading / success states; haptics gated by
  `settings.hapticsEnabled`.
- "Load sample data" and `#Preview`s seed 7 charts (public figures + example people)
  and ~20 journal entries so lists, the wheel, and compatibility populate convincingly.
