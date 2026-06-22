# Nourish — Food Sensitivity & Elimination Diet Tracker

A production-ready native iOS app that helps users identify food triggers through structured elimination diet tracking and correlation analysis.

## Overview

Nourish helps the ~20% of people with food sensitivities identify their triggers through the gold-standard elimination diet protocol. Log meals and symptoms, follow a structured elimination protocol, and discover what your body is reacting to with built-in correlation analysis.

**Pricing:** One-time $4.99 Pro purchase — beats Fig ($9.99/mo subscription) and similar apps.

## Features

- **Today Tab** — Log meals (breakfast/lunch/dinner/snacks) and symptoms with severity ratings
- **Protocol Tab** — Structured 21-day elimination + food challenge phases with progress tracking
- **Analysis Tab** — CorrelationEngine shows top 5 suspected food triggers with confidence scores
- **Library Tab** — 80+ foods organized by allergen category with quick-add functionality
- **Report Tab** — Generate doctor-ready plain text report with ShareLink export

## Tech Stack

- **Platform:** iOS 17+
- **Language:** Swift 5.9
- **UI Framework:** SwiftUI
- **Data:** SwiftData
- **Charts:** Swift Charts framework
- **Build:** XcodeGen (project.yml)

## Design

- **Accent:** Sage Green (#4A7C59)
- **Background:** Warm Cream (#FAF7F2)
- **Warning/Alert:** Warm Terra (#D4856A)
- **Text:** Charcoal (#2C2416)
- Calm, wellness aesthetic — like a health journal

## Building

### Prerequisites
- Xcode 15+
- XcodeGen (`brew install xcodegen`)

### Setup
```bash
cd ios
xcodegen generate
open Nourish.xcodeproj
```

## Architecture

### CorrelationEngine
Pure Swift algorithm — no ML required. For each food in the diary, counts how many times a symptom occurred within 4–48 hours of eating that food. Correlation score = symptom_occurrences_after_food / total_times_eaten. Returns top 5 suspects sorted by score.

### SwiftData Models
- `FoodLogEntry` — meal logs with allergen tags
- `SymptomEntry` — symptoms with 1–5 severity
- `EliminationPhase` — protocol phases with start/end dates
- `NourishSettings` — app configuration

### Food Catalog
80+ foods across 8 allergen categories: Gluten, Dairy, Eggs, Nuts, Soy, Corn, Nightshades, Low-FODMAP, and Safe/Neutral foods.

### Symptom Library
28 symptoms across 6 categories: GI, Skin, Head, Energy, Joint, Respiratory.

## Elimination Protocol

- **Phase 1 (21 days):** Remove gluten, dairy, eggs, nuts, soy, corn, nightshades simultaneously
- **Phase 2 (3 days each):** Challenge one food at a time, 3-day rest between challenges
- **Phase 3:** Maintenance — avoid confirmed triggers

## File Structure

```
ios/
  project.yml
  Nourish/
    NourishApp.swift
    Models/          — SwiftData models
    Utilities/       — CorrelationEngine, FoodCatalog, SymptomLibrary, Protocol
    Views/           — All SwiftUI views organized by tab
    Theme/           — Colors, typography, design tokens
    Assets.xcassets/ — App icon, accent color
```
