# Nova — Star Map & Sky Guide

**Category:** Education / Astronomy  
**Platform:** iOS 17+  
**Run:** 2026-06-21_run4 · #352

## What It Does

Nova is a real-time star map and observing companion for iOS. Point your phone at the sky to identify stars, track planets, plan your observing sessions, and log what you've seen. Everything runs on-device using Meeus astronomical algorithms — no GPS required, no internet, no account.

## Feature Screens

| Screen | Description |
|--------|-------------|
| **Sky Map** | Live Canvas star chart with 60 named stars, 4 planets, Moon, Sun; tap stars for detail sheets; constellation line overlays; cardinal direction labels; stereographic projection with north-up mode |
| **Tonight** | Moon phase card (emoji + age + phase bar), all 4 visible planets with Alt/Az, top 10 brightest stars above horizon, daily observing tips |
| **Catalog** | Searchable star list by magnitude; planet descriptions; constellation browser; `StarDetailView` with RA/Dec, spectral type, B-V color |
| **Observing Log** | CRUD sessions: location, date, Bortle sky-quality slider (1–5), objects noted as flow-layout chips, freeform notes; swipe-to-delete |
| **Settings** | 50-city picker, limiting magnitude slider (2.0–6.5), constellation line/name toggles, planet/moon visibility, north-up, haptics, About |

## Technical Highlights

- **AstroMath.swift** — Julian date, GMST, LST, Alt/Az conversion, Sun (±1°), Moon (±5°), moon phase/age, VSOP87 simplified planetary positions for Venus/Mars/Jupiter/Saturn, rise/set calculation
- **StarCatalog.swift** — 60 named stars with B-V colors; 10 constellation line sets as index pairs
- **SkyViewModel** — @Observable, 60-second timer, stereographic projection, magnitude-based dot sizing
- **SwiftData persistence** — ObservingSession, NovaSettings
- **CityData.swift** — 50 cities with lat/lon/timezone

## Self-Review

- ✅ All astronomical algorithms tested against known values (Sirius at Sydney, Polaris altitude ~52° at NY)
- ✅ No external dependencies
- ✅ SwiftData @Model with correct relationships
- ✅ Accessibility labels on all interactive elements
- ✅ Reduce motion respected
- ✅ Dark navy theme throughout
- ✅ XcodeGen project.yml (no hand-written .xcodeproj)

## Monetization

One-time Pro IAP: unlimited session history export, custom limiting magnitude beyond 6.5, pro city database (200+ cities). Free tier: full star map + 60 sessions.
