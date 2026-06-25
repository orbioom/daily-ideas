# Atelier — Art Practice Tracker

The practice journal that serious amateur artists have been missing: track sessions by medium, subject, and skill; watch your mastery grow from learning to mastered; measure hours and streaks so the habit sticks.

## Features

- **Sessions** — Log every practice session: medium (pencil/watercolor/oil/digital/etc.), type (fundamentals/study/sketch/full piece), subject, skill worked, mood, rating, and notes. Filter by medium. Month-grouped history.
- **Skills Library** — Curate skills across 9 categories (Drawing, Painting, Anatomy, Perspective, Color Theory, Composition, Lighting, Texture, Style). Track status from Not Started → Mastered with visual progress bars.
- **Progress** — Weekly goal ring, monthly minutes bar chart, medium breakdown donut, mood histogram, skills mastery summary — all via Swift Charts.
- **Settings** — Weekly goal (slider), default medium and duration, haptics toggle, data management.

## Screens

1. Sessions (home with session log, medium filter chips, month groups)
2. Skills (status-grouped library with category filter, progress bars)
3. Progress (4 Swift Charts + weekly goal + skills summary)
4. Settings

## Seed Data

47 realistic practice sessions spanning 10 months, 25 seeded skills across all categories.

## Run Steps

```bash
cd ios
xcodegen generate
open Atelier.xcodeproj
```

Set your development team in Signing & Capabilities, then build to device or simulator.

## Monetization

One-time **Atelier Pro** (planned): iCloud sync, advanced analytics export, Apple Watch quick-log widget, reference image library with notes.

## Why it can boom

Adult learners starting art (YouTube tutorials, Skillshare, the "Bob Ross effect") have no dedicated iOS practice tracker — they use plain notes or spreadsheets. Proko, Skillshare, and DrawABox have taught millions but no one built the log. A calm, beautiful tracker with skills mastery is a natural companion and an easy one-time purchase.

## Architecture

- SwiftUI 5 / iOS 17+ / SwiftData / MVVM
- Models: `ArtSession`, `ArtSkill`, `StudyGoal`, `AtelierSettings`
- XcodeGen project (generate from `project.yml`)
- No external dependencies
