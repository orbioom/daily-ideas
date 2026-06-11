# Moniker — baby names you both love

**What it is.** Moniker is the "Tinder for baby names" done right: two partners swipe through a hand-curated catalog on one phone, and when you both like a name it lands on a shared, ranked shortlist — every name carrying its real origin and meaning. For expecting and planning couples, a proven, beloved category (Kinder, BabyName) that's currently nickel-and-diming users for "name sets" and serving thin data.

## Full feature list

- **Swipe deck** — pass-the-phone with a per-partner toggle (named, color-coded); a real swipeable card stack (drag, rotation, LIKE/PASS stamps, fling animation, Reduce-Motion safe); three verdicts (Pass / Like / Love it) via swipe or buttons; live match detection with a celebratory sheet (animated hearts) when both partners like the same name.
- **Curated catalog** — 230+ names (girl / boy / neutral), each with origin, meaning, and style tags; no paywalled "name packs".
- **Filters** — gender + 7 styles (classic, modern, vintage, nature, international, mythic, short); persisted; live match-count; clear-all.
- **Matches** — shared shortlist ranked by combined "heat" (both-loved → both-liked) then recency; gender filter; baby last-name appended; **ShareLink** export of the top 10 as a clean text list.
- **Browse** — searchable full catalog (name/origin/meaning) with per-partner verdict dots; name detail page to set either partner's verdict explicitly with match highlighting.
- **Insights** — matches + per-partner like tiles; agreement-rate meter (needs ≥5 mutually-judged names); each partner's top 3 favorite styles (weighted, loves count double); shortlist gender donut.
- **Settings** — partner names + baby last name, haptics, appearance, deterministic sample-swipe loader (≈85 verdicts → instant matches/insights), reset-all with confirmation, privacy statement.
- Onboarding (3 pages incl. partner setup, persisted flag), empty states on every tab, Dynamic Type, accessibility labels/hints on cards & buttons, Reduce Motion respected, dark + light first-class.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Moniker.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

*Free signing:* Xcode → Signing & Capabilities → personal team.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM: pure `MatchEngine` (match detection, heat ranking, agreement rate, style weighting, share text — no UI imports) + static `NameCatalog`, SwiftData `Verdict` (one row per name+partner, re-deciding replaces).
- Design language: soft nursery at golden hour — blush/sky/butter/mint pastels, deep plum ink, rounded display type; custom `Layout` for chip wrapping; gradient-headed cards.
- **Monetization:** couples reliably pay here — free core swipe/match; Moniker+ one-time ~$7.99 unlocks insights, unlimited filters, and a "name story" expansion. Beats Kinder's per-pack microtransactions with one honest unlock.
- **Why it can boom:** the swipe-for-names format is viral and proven (Kinder 4.2★, BabyName most-reviewed) but incumbents are ugly, paywall name packs, and lack meanings; a gorgeous, single-purchase, meaning-rich version is exactly the upgrade couples wish existed — and the "it's a match" moment is made for sharing.

## Self-review

Re-read every Swift file: imports verified; iOS 17 APIs only (DragGesture, custom Layout, SectorMark, ShareLink, NavigationStack/navigationDestination, confirmationDialog); `NameCard` is Hashable for navigation values; verdict re-decide deletes prior rows before insert (no duplicate accumulation); `MatchEngine` handles latest-wins; no force-unwraps/`try!` on user paths; SeededRNG conforms to RandomNumberGenerator; Charts data keyed by Hashable enums. Anti-stub grep clean. project.yml names the real `Moniker` folder and Info.plist.
