# Tote — a grocery list that sorts itself

**One line:** Type "milk," get it filed under Dairy; save recipes once and pour their ingredients into any list — the AnyList/OurGroceries job, faster and without the subscription wall.

**Problem & audience:** Shared grocery lists are a huge, sticky market (AnyList, OurGroceries, Bring). The leaders work but gate the obvious stuff — recipe import, sane categorization — behind subscriptions, or feel cluttered. Tote is for households and solo shoppers who want a fast, smart, on-device list that reads like their walk through the store.

## Features

- **Lists** — multiple lists with live to-buy / in-cart progress; create, rename, archive, delete.
- **List detail** — items auto-grouped into store aisles (Produce → Bakery → Dairy → … → Household) in walk order; one-tap check-off, an inline add bar with **autocomplete from your history** and automatic aisle guessing, per-item editor (quantity, unit, aisle, note), hide-in-cart, clear-cart, and move-all-back.
- **Recipes** — recipes own ingredients (auto-aisled); **Add to list** pours them into any list and *merges duplicates* so two recipes calling for onions become one line.
- **Staples** — Tote remembers what you buy often (frequency-ranked), lets you star staples, and re-adds any of them to a chosen list in one tap.
- **Settings** — hide-checked default, confirm-before-clear, theme, haptics, and a clear-remembered-items action.
- Onboarding gated by a flag; empty/success states throughout; full Dynamic Type, VoiceOver, calm motion.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Tote.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

Free-signing: set your Team in Signing & Capabilities; bundle id `com.orbioom.tote`.

## Tech notes

- iOS 17+, SwiftUI 5, pure `ToteEngine` (aisle resolution from a learned catalog + keyword guesser, recipe→list aggregation, aisle grouping).
- Persistence: **SwiftData** with relationships (`GroceryList`→`ListItem` cascade, `Recipe`→`RecipeIngredient` cascade, unique `CatalogItem` memory).
- Design language: **Orbioom**.
- **Monetization:** freemium — free lists & recipes; Pro unlocks real-time list sharing/sync across a household and unlimited recipes. Sharing is exactly what AnyList charges for.
- **Why it can boom:** proven category with paywalled basics; Tote gives smart auto-categorization, recipe aggregation, and staples for free, beating the incumbents on speed and taste.

## Self-review

Read every file against the iOS 17 SDK: SwiftData relationships/inverse keypaths, `@Query`, `@Bindable`, `Menu` primary-action, and grouping logic check out. Delete affordances use `.contextMenu` (works outside `List`). No stubs/TODOs; no force-unwraps/`try!`/`fatalError` on user paths beyond the in-memory container fallback. `project.yml` is valid and names the real `Tote` sources and `Info.plist`.
