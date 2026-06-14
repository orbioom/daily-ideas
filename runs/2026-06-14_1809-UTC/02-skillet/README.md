# Skillet — cook with what you have

**One-liner:** Tell Skillet what's in your kitchen and it instantly shows what you can cook right now — and what you're just one ingredient away from.

**The problem + audience:** "What can I make with what I have?" is one of the most common cooking questions, and SuperCook proved the demand — but it's ad-heavy, dated, and clumsy. Skillet is for home cooks who want to cut food waste and decide dinner fast, with a warm, beautiful, ad-free experience that works entirely offline.

## Full feature list
- **Cook Now** — every recipe ranked by a real match engine into **Ready to cook**, **One ingredient away**, and **Almost there**, each card showing match %, the missing-ingredient chips, time, and cuisine. Loading state while the ranking computes; designed empty states for no recipes / empty pantry / no matches.
- **Pantry** — your ingredients grouped by aisle (produce, meat, dairy, staples, grains, spices, frozen, condiments, bakery), in-stock toggles, custom items with an aisle guess, search, and a one-tap **Stock the basics**. Full CRUD with swipe-delete.
- **Recipe detail** — serif title, time/servings/cuisine, ingredients list with **have = green check / missing = terracotta** highlighting (optional ones flagged), a live **servings scaler** that rescales numeric amounts (including fractions like "1 1/2"), numbered steps, favorite toggle, and **Add missing to shopping list**.
- **Recipes (Browse)** — all recipes with filters (cuisine, max time, makeable-only, favorites) and sort; add your own recipe via a validated editor (name, ingredients, steps, time).
- **Shopping list** — missing ingredients aggregated from your favorited/queued recipes and **unlock-ranked** (buy the item that makes the most new recipes cookable), with check-off and clear.
- **Settings** — assume-staples toggle (changes matching), default servings, hide-optional-ingredients, a measurement note, default sort, haptics; plus Pro, export, Load sample data, reset, About.
- **Onboarding** (3 pages), first-run gated; **56 seeded recipes** across 10 cuisines + 42 pantry items so Cook Now is lively immediately.

## Run steps
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Skillet.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing note:** No paid account needed — set a Personal Team and use the `com.orbioom.skillet` bundle id (or your own). No entitlements required.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. **SwiftData** (`PantryItem`, `Recipe` cascade `RecipeIngredient`), small prefs in `@AppStorage`.
- Pure `MatchEngine`: normalized two-way name matching (e.g. "tomato" ↔ "tomato paste"), staples shortcut, makeable / one-away / match-% (guarded against zero required), ranked recipes, and `shoppingUnlocks` ranking; `AmountScaler` handles fractions and mixed numbers, guarded against zero factors/denominators.
- Design language: warm cookbook — terracotta accent, serif titles, appetizing cards; first-class light & dark via `Theme.dyn`; Dynamic Type, VoiceOver labels, Reduce Motion respected.
- **Monetization:** browsing & matching are free; **adding custom recipes beyond 5** and **shopping-list export** are a one-time **$3.99** Pro unlock (StoreKit not wired; demo unlock + Restore). Who pays: cooks who build a personal recipe box and want it to drive their shopping.
- **Why it can boom:** "recipes from what I have" is a proven, broadly-loved job (SuperCook's traffic proves it), and the incumbents are ad-cluttered and ugly. Skillet delivers the same instant gratification with taste, an offline pantry, and a smart shopping-unlock list the others lack.

## Self-review
35 Swift files. Static audit clean: one `@main`, one `try!` (in-memory fallback), anti-stub grep clean, valid asset JSON, real 1024² icon, balanced delimiters. All 3 `@Model` types registered in both `ModelContainer` calls; cascade delete on `RecipeIngredient`; ≥4 feature screens + Settings; empty/loading/error/success states throughout; all divisions guarded. A dedicated compile-review pass verified cross-file types and SF Symbol availability against the iOS 17 SDK.
