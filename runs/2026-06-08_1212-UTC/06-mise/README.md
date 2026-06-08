# Mise

**Cook from what you planned — recipes, a weekly plan, and a grocery list that actually talk to each other.**

The problem: Paprika is the beloved recipe-manager incumbent, but its single most-cited complaint is that **adding a recipe to the meal plan doesn't add its ingredients to the shopping list** — the two features don't communicate — and it charges separately per device. Mise is the version people wish existed: plan meals, then generate a consolidated grocery list in one tap where the same ingredient across recipes is summed, with a serving scaler and a full-screen cook mode. Audience: home cooks, meal-preppers, busy families.

## Features

- **Recipes** — list with course filter, favorites, and search across names and ingredients; full recipe CRUD with ingredients (qty + unit + aisle) and ordered steps.
- **Recipe detail** — a **serving scaler** that instantly re-computes every ingredient amount (with friendly fractions like ½, ¾), prep/cook/total times, and a **Cook mode** full-screen step-by-step player with scaled ingredients alongside each step.
- **Plan** — a weekly view (respects week-start setting) with breakfast/lunch/dinner/snack slots; assign any recipe at any serving count.
- **Grocery** — the headline integration: **generate a list from your plan** (next 7 days / all upcoming / entire plan) that consolidates identical ingredients into one line, grouped by store aisle; check items off with a progress bar; add manual items; clear checked/all. Manual items survive re-generation.
- **Settings** — theme, default servings (used when planning), week-starts-Monday (used by the planner), haptics, erase-all.
- Onboarding (persisted), empty/loading/success states, Dynamic Type + VoiceOver, light & dark, Reduce-Motion-aware, on-brand icon.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Mise.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team; bundle id `com.orbioom.mise`.

## Tech notes

iOS 17+, SwiftUI 5, MVVM with a pure `MealEngine` (serving scale factor and **grocery aggregation** that sums ingredients by name+unit across the plan) and a `Quantity` fraction formatter. Persistence in **SwiftData** — `Recipe` cascades to `Ingredient` and `Step`; `MealPlan` references recipes; `GroceryItem` persists checked state and distinguishes generated vs manual. Design language: **Orbioom**. No account, no network.

- **Monetization:** one-time purchase (or freemium with a recipe cap) — buy once, use everywhere, no per-device fees (directly countering Paprika's per-device pricing). Who pays: home cooks who already pay for Paprika/Mela.
- **Why it can boom:** proven paid category whose leader has a famous, unfixed core gap; Mise's plan→list integration is the single most-requested feature, done right.

## Self-review

Re-read every Swift file by hand. Imports resolve; SwiftData cascades + `@Query`, the related-object editor bindings, `navigationDestination(for: Recipe.self)`, `fullScreenCover` cook mode, and `sheet(item:)` for the assign context type-check; the grocery aggregation guards empty names and zero servings; no force-unwraps/`try!`/`fatalError` on user paths. Wired default-servings and week-start settings into the planner. Anti-stub grep clean.
