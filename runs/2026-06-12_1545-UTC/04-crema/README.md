# Crema — espresso dial-in & brew log

**One-liner:** Log every shot and pour, and Crema tells you exactly what to change next — finer, coarser, longer, shorter — to dial in a great cup.

**The problem & audience:** Home espresso exploded post-2020 and coffee is a massive consumer market. The leading app, Filtru, hides espresso dial-in behind a buggy subscription (reviewers complain it "forces a 1:2 ratio no matter what" and "doesn't log consistently"). Enthusiasts want a fast, honest brew log plus actual dial-in guidance, without a refractometer or a monthly fee. Crema is for the large, gear-loving, willing-to-pay home-coffee crowd.

## Full feature list

- **Shelf** — your bags with a live freshness badge (resting → peak → fading → stale, computed from roast date), grams remaining, brew count, and a finished-bags section.
- **Bean detail** — freshness advice, your **best recipe so far**, a full brew history, and one-tap "log a brew". Edit, mark finished, delete (cascade).
- **Brew log** — every brew across all beans, filterable by method, each row showing dose → output, ratio, time, taste icon and rating.
- **Brew detail** — the full recipe (dose, yield/water, ratio, time, temp, grind, flow rate) plus a **dial-in panel**: extraction observations (fast/slow shot, tight/long ratio) and a taste-based next step.
- **Dial-in tab** — a standalone **recipe calculator** (method + dose + ratio → target yield/water with method ranges), a **"fix my cup"** taste→adjustment helper, and a quick-reference ratio table for six methods.
- **Stats** — total brews, average rating, open bags; brews-by-method bar chart, a taste-balance donut, a 14-day activity chart, and your top-rated coffee.
- **Settings** — default method, currency, haptics, shelf counts, delete-all.
- Onboarding gated by a flag; empty states; Dynamic Type, VoiceOver, Reduce Motion, light/dark throughout.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Crema.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R. A seeded shelf with dialed-in shots fills every screen.

**Free-signing note:** Runs with a personal Apple ID — no paid account, no entitlements, no network.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM with a pure `DialInEngine` (freshness windows, extraction analysis, taste→adjustment logic, ratio math) and `BrewStats`. **SwiftData** models `Bean` (cascade) and `Brew`; `Identifiable` structs back the charts.
- Design language: "warm roast" — caramel/copper on espresso brown / warm cream, with crema-gold as the signal colour.
- **Monetization:** Free for the shelf and logging; one-time **Pro** unlock for unlimited beans, full stats and the advanced dial-in — a fair alternative to Filtru's subscription.
- **Why it can boom:** A big, fast-growing, gear-obsessed market with a hated subscription incumbent; "tell me why my shot is sour" is a concrete, repeatable value prop that fits one-time-purchase buyers.

## Self-review

Re-read every file: imports and all SwiftUI/SwiftData/Charts APIs verified for iOS 17; chart/`ForEach` series are `Identifiable` structs (no tuple key-paths); `NavigationLink(value:)` destinations registered for `Bean`/`Brew`; brew↔bean grams tally maintained on add/edit/delete; no `try!`/force-unwraps on user paths (division guards everywhere ratios are computed). Anti-stub grep clean; `project.yml` valid; icon is a real 1024² RGBA PNG.
