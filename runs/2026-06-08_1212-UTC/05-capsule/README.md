# Capsule

**Your whole wardrobe — fast, beautiful, and stable. Wear what you have.**

The problem: digital-wardrobe apps went viral on TikTok, but Whering is widely called "too glitchy to use" with frequent crashes, and Acloset caps free accounts at 100 items so most people can't really use it. Capsule is the version they wish existed: a fast, crash-free catalog with no harsh item cap, clean outfit building, an outfit planner, and real cost-per-wear — all on the device. Audience: fashion-conscious Gen Z/millennials, capsule-wardrobe and cost-per-wear enthusiasts.

## Features

- **Closet** — an adaptive grid of pieces with category filter and search; each piece is a clean color-swatch + category glyph (no fragile photo pipeline to crash on).
- **Piece detail** — wear count, cost, **cost-per-wear**, seasons, which outfits use it, a wear history, and a one-tap "I wore this today".
- **Outfits** — build outfits by selecting pieces (grouped by category), favorite them, see total value, and "wear today" to log a wear for every piece at once.
- **Planner** — a 14-day strip; assign an outfit to a day, mark it worn (which logs wears), and see what's coming up.
- **Insights** — wardrobe value, total wears, average cost-per-wear, a category donut, best-value and most-worn rankings, and **neglected** pieces not worn within your threshold (Swift Charts).
- **Settings** — theme, currency, neglected-after threshold (wired into Insights), haptics, erase-all.
- Onboarding (persisted), empty/loading/success states, Dynamic Type + VoiceOver, light & dark, Reduce-Motion-aware, on-brand icon.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Capsule.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free-signing: pick your personal team; bundle id `com.orbioom.capsule`.

## Tech notes

iOS 17+, SwiftUI 5, MVVM with a pure `WardrobeEngine` (value, cost-per-wear, most/least/neglected, category/color breakdowns). Persistence in **SwiftData** — `ClothingItem` ⇄ `Outfit` many-to-many, `WearLog` (cascade), `OutfitPlan`. Design language: **Orbioom** (the photo-free swatch system is a deliberate stability/taste choice). No account, no network.

- **Monetization:** freemium — generous free catalog (no 100-item wall); a Pro unlock adds unlimited outfits/planning history, packing/capsule tools, and export. Who pays: the large, engaged wardrobe-app audience frustrated by crashes and caps.
- **Why it can boom:** TikTok-proven demand where both leaders have glaring, repeated complaints (instability, free caps); Capsule wins purely on being fast, stable, and beautiful.

## Self-review

Re-read every Swift file by hand. Imports resolve; SwiftData many-to-many + cascade relationships, `#Predicate` `@Query`, `navigationDestination(for:)` for `ClothingItem` and `Outfit`, and the `FlexibleWrap` layout type-check; charts are iOS-17; bit-mask season logic precedence verified; no force-unwraps/`try!`/`fatalError` on user paths. Wired the neglected-days setting into Insights. Anti-stub grep clean.
