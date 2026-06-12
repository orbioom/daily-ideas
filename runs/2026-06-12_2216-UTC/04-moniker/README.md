# Moniker — Baby Names You *Both* Love

**What it is:** A couples' baby-name matcher: swipe names like a dating app, hand the phone to your partner, and only mutual loves become matches — with **origin and meaning on every card**, the exact gap users cite in reviews of the category leaders (Kinder, Babyname — the most-downloaded one sits at 3.8★ and shows *no* name information). Audience: expecting parents, one of the most purchase-ready demographics that exists.

## Full feature list

- **270-name curated catalog** — girls, boys, and unisex across 25+ origins (Irish, Norse, Arabic, Sanskrit, Japanese, Welsh, Yoruba-adjacent…), each with origin, meaning, and style tags (classic/modern/vintage/nature/biblical/mythic/short/international/strong/gentle).
- **Swipe deck** — drag with LOVE/PASS stamps or tap the buttons; spring physics (disabled under Reduce Motion); undo the last verdict; gender filter (all/girl/boy/unisex) in the toolbar.
- **Pass-the-phone partner mode** — a full-screen hand-off ritual switches the active partner; each partner's swipes stay private until a match. Both partners see the **same seeded deck order** (SplitMix64 Fisher–Yates) so the overlap converges fast.
- **Match celebration** — when the second partner loves a name the first already loved: overlay + success haptic.
- **Matches tab** — mutual loves (newest first) plus "X loves — Y hasn't seen yet" queues for each partner; tap any name for the full story.
- **Name detail** — big serif treatment, meaning/origin/styles, and a per-partner verdict editor (Love/Pass/Undecided segmented control) that updates matches instantly.
- **Browse tab** — the full catalog with search (name *or* meaning), gender/style/origin filters, and heart indicators showing each name's current status.
- **Insights tab** — match count, per-partner swipe counts, a **taste-agreement rate** (share of co-seen names with the same verdict), and Swift Charts of loved origins and styles.
- **Settings** — partner names, show-meanings toggle, haptics, deck reshuffle, reset-all-swipes (confirmed destructive), catalog/verdict counts.
- **Onboarding** (welcome + partner names + gender focus, persisted), empty states everywhere, full Dynamic Type, VoiceOver (cards read name/origin/meaning; buttons labeled), light + dark.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Moniker.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

*Free signing:* personal team in Signing & Capabilities; suffix the bundle id if needed.

## Tech notes

- iOS 17+, SwiftUI 5. Static `NameCatalog` (value types), SwiftData `Decision` rows (nameID × partner, replaced not duplicated), pure `MatchEngine` for likes/matches/agreement/deck-shuffling.
- Design language: "warm nursery at dusk" — blush rose `#E88FB4` + dusty blue, rounded display type with serif name cards, tilted paper-stack deck.
- **Monetization:** free for 50 swipes/day; one-time **Moniker Forever** unlocks unlimited swiping + future packs (surnames-that-flow check, sibling-set harmony) — parents-to-be demonstrably pay (Kinder sells name packs; pregnancy apps monetize heavily).
- **Why it can boom:** "Tinder for baby names" is already a proven viral mechanic with press coverage and chart presence; the incumbents are thin (no meanings, no insights, dated UI, server accounts). A gorgeous, private, no-account version with meanings on every card is both more useful and more shareable.

## Self-review

Re-read every Swift file: no duplicate catalog IDs (name+gender unique — checked); all dictionary/array accesses guarded (`deck[1]` behind `deck.count > 1`, `deck[0]` behind `deck.isEmpty` branches); custom `Binding<Int>` get/set total; SplitMix64 uses wrapping arithmetic; `@Query`/`modelContainer` wired for `Decision`; Charts use `Identifiable` structs; iOS 17 APIs only; no force-unwraps/`try!` on user paths. Anti-stub grep clean. `project.yml` names the real `Moniker` folder and `Info.plist`.
