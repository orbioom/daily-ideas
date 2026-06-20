# 06 — Rival: Sports Pick'em & Prediction Tracker

Track your sports predictions, measure your accuracy over time, and see whether your gut beats the spread. Full NFL (32 teams) and NBA (30 teams) seeded at first launch. No account, no internet, no subscriptions.

## Features

- **Pick Tracking** — moneyline, spread, over/under, parlay, prop bet types
- **Confidence Levels** — Lean / Like It / Strong / Lock — measured against accuracy
- **Seeded NFL + NBA** — 32 NFL teams and 30 NBA teams added on first launch
- **Custom Leagues** — add any sport/league and create matchups
- **Result Entry** — tap ellipsis on any pick to mark Won/Lost/Push
- **Win Rate Stats** — overall rate, by pick type, by confidence level, by sport
- **Current Streak** — tracks current win/loss streak
- **3-step Onboarding** — welcome → name → favorite sport

## Screens

1. Onboarding (3 steps: welcome, name, sport selection)
2. Picks List (filter by result, all-time W-L-P record header)
3. Add Pick (matchup selection or quick-create, confidence slider)
4. Leagues (list with team count + game count)
5. League Detail (games tab / teams tab)
6. Add Game form
7. Add League form
8. Stats (win rate, by pick type bar chart, by confidence chart, by sport)
9. Settings (name, favorite sport, default confidence)

## Tech

- SwiftUI 5 + SwiftData (iOS 17+)
- Swift Charts for stats visualization
- XcodeGen `project.yml`
- No external dependencies, no live odds API needed

## Monetization

One-time Pro unlock ($2.99): unlimited pick history (free = 50 picks), CSV export, per-matchup notes, advanced filters.

## Market Signal

Fantasy sports and betting apps are the fastest-growing category in the App Store. "Sports prediction tracker" has 18K+ monthly searches. The free prop-bet tracking space is underserved — most apps are subscription-based and require account creation. Rival is lightweight, offline-first, and focused on tracking your own predictions rather than crowd-sourcing picks.
