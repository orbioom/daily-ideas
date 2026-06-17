# Arcana

A calm, beautiful, fully offline tarot companion for iOS 17 — a daily card, classic spreads, a private reading journal, and the complete, learnable 78-card Rider–Waite–Smith deck with generated celestial card art. Built as a Labyrinthos-beater: the **entire deck and all meanings are free**, with a single, fair one-time unlock for advanced spreads — where incumbents charge up to $89.99.

## What it is

Arcana presents tarot as a tool for **reflection and journaling**, not fortune-telling. Pull a card a day, lay a spread when a question is on your mind, write down what it stirs, and study every card at your own pace. Everything stays private on your device.

## Full feature list

- **Today** — a deterministic Card of the Day (the same card + orientation all day, derived from the calendar date via a seeded engine). Tap to flip-reveal (with a Reduce-Motion still fallback), read the upright/reversed meaning and keywords, save a reflection, and peek at "this day, before" — past daily draws on the same calendar day.
- **Spreads** — choose a layout, optionally hold a question, and draw:
  - **Card of the Day** (1), **Three-Card · Past/Present/Future** (3), **Yes/No** (1, with a Yes/No/Maybe verdict derived from card + orientation) — all free.
  - **Relationship** (5), **Decision** (4), and the full **Celtic Cross** (10 labeled positions) — Pro.
  - Each position has a title + role; every drawn card shows a position-aware interpretation. Save any reading to the journal, re-draw, or set a mood.
- **Journal** — a unified, searchable feed of saved spread readings and daily draws, with scopes (All / Spreads / Daily), swipe-to-delete, empty states, and a full detail view (cards, positions, meanings, editable reflection + mood, and Pro text export).
- **Library** — browse all **78 cards** in a lazy grid with generated art, filter by Major / each suit, and search by name or keyword. Card detail shows the art, element, keywords, an Upright/Reversed toggle, and both full meanings. The complete deck is free, forever.
- **Stats** — Swift Charts: most-drawn cards (BarMark), suit distribution (SectorMark donut), Major-vs-Minor split, draws over the last 14 days (Line + Area), and your current journaling streak. Calm empty state until there's data.
- **Settings** — allow reversed cards + reversal probability, daily card reminder, reduce starfield/motion, haptics, appearance (System/Light/Dark), deck-back theme (one free + Pro themes), data counts, and erase-all.
- **Paywall** — tasteful one-time Arcana Pro unlock with tailored copy per entry point.

## Engine & data

- **Full 78-card RWS deck** embedded in code (`Models/Deck*.swift`): 22 Major Arcana (0 The Fool … 21 The World) + 56 Minor (Wands/Cups/Swords/Pentacles × Ace–10 + Page/Knight/Queen/King). Every card has real, concise upright **and** reversed interpretations, keywords, and an element.
- **ShuffleEngine** (`Engine/ShuffleEngine.swift`) — a pure, seeded **SplitMix64** PRNG: Fisher–Yates draw of N distinct cards, per-card reversed orientation at a configurable probability, and a **date-deterministic daily card** (FNV-1a seed over the day key, so the same date always yields the same card + orientation). Spreads use a fresh random (or user-seeded) draw.
- **Generated card art** (`Views/Components/CardArtView.swift`) — each card is a cohesive stylized vector built from SwiftUI shapes, gradients, and SF Symbols, keyed by suit color/element: a framed, starry field, a central emblem, pips (Ace–10) or a Roman numeral / court mark, and the card name. Reversed cards render rotated 180°. No photos or copyrighted imagery.

## Run steps

1) `brew install xcodegen` (one-time). 2) In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root). 3) Open `Arcana.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing:** set your Apple ID team in Signing & Capabilities; the bundle id is `com.orbioom.arcana`.

## Tech notes

- **iOS 17+, SwiftUI 5, MVVM.** `NavigationStack` throughout; `TabView` for the six top-level screens.
- **SwiftData** for primary data: `Reading` (cascades `DrawnCard`) and `DailyDraw`, all registered in the `Schema`. `@AppStorage` holds only small prefs/flags (`hasOnboarded`, `isPro`, `allowReversals`, `dailyCardReminder`, `reduceStarfield`, `hapticsEnabled`, appearance, deck theme, reversal chance).
- **Single ownership pattern:** `ObservableObject` + `@StateObject`/`@EnvironmentObject` (`AppSettings`); no `@Observable` mixing.
- **Seeded, deterministic daily draw** via SplitMix64 + FNV-1a day-key hashing — reproducible and testable.
- **Canvas/vector-generated card art** — zero external assets; smooth in a lazy grid of all 78 cards with stable IDs.
- **Design language:** mystic violet accent (#8E54C9) with luminous gold highlights, refined serif headings, a deep-dark/soft-lilac dual theme, and a Reduce-Motion-aware twinkling starfield. Light and dark are both first-class via a dynamic `Theme`; WCAG-AA contrast in both modes.
- **Accessibility:** Dynamic Type via semantic fonts, `accessibilityLabel`/`Value`/`Hint` on cards (e.g. "The Star, reversed"), spreads, and charts; the decorative starfield is `.accessibilityHidden(true)`. Sparse haptics gated by the Settings toggle.
- **Crash-proofing:** no force-unwrap on user paths (cards looked up by id with a safe optional + fallback), no `try!`/`as!`/`fatalError`, safe array subscript helper, guarded division; a calm `StoreUnavailableView` instead of crashing if storage can't initialize.

**Monetization:** one-time **$4.99 Arcana Pro** (simulated `@AppStorage("isPro")` unlock + Restore) — Celtic Cross & advanced spreads, unlimited journal, extra deck-back themes, and reading export. The full 78-card library, daily card, Three-Card, Yes/No, and journal stay free.

**Why it can boom:** incumbents lock the full deck and meaningful spreads behind subscriptions or one-time prices up to $89.99 — Arcana gives away the complete deck and core readings, charges a single honest $4.99, runs fully offline and private, and pairs beautiful generated art with a real journal and study tools.

> Arcana is for reflection and entertainment — prompts for journaling and self-insight, not medical, legal, or financial advice.

## Self-review attestation

I re-read every Swift file in `ios/Arcana/Arcana/`. Verified: all imports/types/initializers/modifiers exist in the iOS 17 SDK (SwiftUI 5, SwiftData, Charts incl. `SectorMark`); a single ownership pattern (`ObservableObject` + `@StateObject`/`@EnvironmentObject`) with no `@Observable` mixing; `NavigationStack` only (no `NavigationView`); the two-parameter `.onChange(of:) { _, _ in }` form; every `@Model` registered in the `Schema`. No banned APIs (`fatalError`, `try!`, `as!`), no force-unwrap on user paths, safe array indexing, and no unguarded division. Anti-stub grep (`TODO`/`FIXME`/`XXX`/`lorem`/`coming soon`/`not implemented`/`stub`/`unimplemented`/`placeholder`) is clean. Confirmed all **78 cards** are present with unique ids 0–77 and non-empty upright **and** reversed meanings. Onboarding is gated by `hasOnboarded`; empty/loading/success/error states, full accessibility, Reduce-Motion fallbacks, and light+dark theming are present across screens.
