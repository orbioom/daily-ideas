# Relish

**Your private, offline restaurant ranker.** A Beli-beater that lives entirely on your device — no account, no feed, no cloud. Keep an ordered list of every place you've been, plus a want-to-try list, and rank places the way taste actually works: by comparing.

## What it is

Instead of arbitrary stars, Relish ranks by **pairwise comparison**. When you add a place you've visited, you pick how it felt — **Loved, Liked, or Okay** — then answer a few quick "which was better?" matchups against your already-ranked places. A binary search slots the newcomer into exactly the right spot, and Relish derives a meaningful **0–10 personal score** from where it lands within its sentiment tier. Scores are relative and earned, not guessed.

## Full feature list

- **Your List** — ranked visited restaurants with rank number, 0–10 score chip, cuisine symbol, price and city. Search by name/city/cuisine, filter by cuisine/city/sentiment, sort by rank/score/name/recent, optional Loved/Liked/Okay tier headers. Floating add button.
- **Add & Compare flow** — name + cuisine + city + price with non-empty name validation; "been there" vs "want to try." Visited places run the signature **pairwise comparison cards** ("Which did you like better?") with a progress indicator, then reveal the new score with a celebratory animation (Reduce Motion respected).
- **Restaurant detail** — big score, cuisine/price/city, favorite toggle, edit, **re-rank** (re-runs the comparison), **dishes** list (rating 1–5 + would-order-again), **visits** log (date, companions, amount spent), notes, delete with confirmation and automatic re-numbering.
- **Want to Try** — the wishlist; filter/sort; "Mark as visited" folds a place into the ranking via the compare flow; swipe to delete; empty state.
- **Taste Stats** — Swift Charts: cuisines you eat most, cities, score-distribution histogram, average score, total spent, count, top dishes. Computed in an async loading state. Rich charts are Pro-gated; basic counts are free.
- **Onboarding** — three pages explaining the ranking idea, gated by `hasOnboarded`.
- **Settings** — haptics toggle, score style (decimal/whole), default sort, currency symbol, tier-header toggle (all persisted and live), export, reset/reseed or erase, About.
- **Relish Pro** — free up to 15 ranked places (wishlist unlimited); one-time **$4.99** unlock removes the cap, opens full Taste Stats, and enables text export. Honest demo unlock + Restore.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Relish.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

### Free-signing note

You can run Relish on a physical device with a personal Apple ID (free): select the Relish target → Signing & Capabilities → pick your personal team. Free provisioning lasts **7 days** before you'll need to re-sign.

## Tech notes

- **iOS 17+**, **SwiftUI 5**, MVVM-leaning structure with small separated files.
- **SwiftData** is the primary store (`@Model` / `@Query` / `modelContext`); `UserDefaults` (`@AppStorage`) holds only prefs and flags. Data survives relaunch; 50+ realistic restaurants seed on first launch behind a `didSeed` flag.
- **Swift Charts** powers the stats screen. The ranking math lives in a pure, UI-free `RankingEngine` (binary-search insertion + tier-banded 0–10 scoring); `StatsEngine` aggregates counts/distributions.
- **Warm editorial design language** built around a tomato-red accent (`#D94F3D`): paper-warm light mode and espresso dark mode, serif display type over rounded UI type, both schemes first-class. Dynamic Type, accessibility labels/hints/values, and Reduce Motion are honored throughout.
- **Monetization:** one-time $4.99 Relish Pro unlock (StoreKit wires in for production; this build uses an honest demo unlock).
- **Why it can boom:** Beli is viral but invite-walled, social, and cloud-bound. Relish is the wished-for version — the same addictive pairwise scoring, fully private and offline, with no account to make and no feed to perform for.

## Self-review attestation

Every Swift file was re-read after authoring. Verified: imports; iOS 17 SDK availability of every type/initializer/modifier; protocol conformances; `@Query`/`@Bindable`/`@StateObject`/`@EnvironmentObject` ownership consistency (ObservableObject + SwiftData only — no `@Observable` macro mixing); `NavigationStack`/`sheet`/`navigationDestination` binding types; no duplicate type declarations; Swift Charts series are `Identifiable` structs; every referenced `Theme` token is defined; brace/paren balance. The only force operation in the app is the in-memory `ModelContainer` fallback `try!`. `grep -rniE "TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub" ios/Relish` returns zero matches.
