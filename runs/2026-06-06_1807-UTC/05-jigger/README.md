# Jigger — home bar & "what can I make" cocktail matcher

**One line:** Tell Jigger what's on your shelf and it instantly shows which cocktails you can pour right now — and the one bottle that would unlock the most new ones.

**Problem & audience:** Home bartenders own a drawer of bottles and a head full of half-remembered recipes, and the nightly question is always the same: *what can I actually make with this?* Recipe apps make you read every recipe and check the shelf yourself. Jigger inverts it — your shelf drives the recipes — and it's fully offline and private. For anyone with a home bar, from three bottles to thirty.

## Features

- **Make** (hero) — recipes you can pour right now (favorites first), plus a "just one ingredient away" section, with live counts of makeable / one-away / in-stock.
- **Recipes** — full CRUD with a real component editor (ingredient line + amount + measure + optional flag), method, glass, instructions. Each row carries a Make-now / Missing-N badge. Filter by All / Make now / One away / Favorites; search.
- **Recipe detail** — a **servings scaler** (amounts re-render with ¼/½/¾ fractions), color-coded build list (in-stock / missing / optional), a missing-ingredients shortcut to mark items in stock, method, and a favorite toggle.
- **Bar** — your shelf grouped by category with one-tap in/out-of-stock toggles, search, and full CRUD. Add new ingredients (including inline from the recipe editor).
- **Shop** — the standout: ranks every out-of-stock bottle that is the *sole* blocker for one or more recipes by how many it would unlock, lists those cocktails, and lets you mark it bought.
- **Real matching logic** — `MatchEngine` evaluates makeability (ignoring optional lines), finds one-away recipes, and computes the unlock-ranked shopping list.
- **Settings** — default measure (oz/ml), hide out-of-stock, haptics, a "mark everything out of stock" reset; reload sample bar; delete all.
- First-run onboarding (persisted), empty/loading/success/error states, light & dark, Dynamic Type, VoiceOver, Reduce Motion, sparse haptics.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Jigger.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team under Signing & Capabilities; no paid account needed.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-lite (pure `MatchEngine`, SwiftData models, thin views).
- Persistence: **SwiftData** — `Recipe` → `RecipeComponent` (cascade) → `Ingredient` (nullify), so the same ingredient is shared across recipes and the shelf. Prefs in `UserDefaults` via `@AppStorage`.
- Design language: **Orbioom** (glass, ink-gradient action, mono figures) with the rare green accent reserved for "make now / in stock".
- No external dependencies.

## Self-review

Re-read every Swift file against the iOS 17 SDK: imports (`SwiftUI`, `SwiftData`) resolve; three `@Model` types with cascade/nullify relationships and inverses, `@Query`, `@Bindable`, `@AppStorage`, `ForEach($drafts)` bindings in the component editor, `.sheet(item:)`/`.sheet(isPresented:)`, alert text fields, and `NavigationStack`/`navigationDestination(for: Recipe.self)` all type-check. `PersistentIdentifier` dedups missing ingredients and keys the shopping map. No force-unwraps, `try!` (except the in-memory `ModelContainer` bootstrap in `JiggerApp`), unchecked indices, or unguarded division on user paths. Anti-stub grep clean. Seeds 35 ingredients and 14 classic cocktails tuned so every state (make-now, one-away, two-away, a bottle that unlocks two) is exercised.
