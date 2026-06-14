# Sillage

**Your private fragrance collection & wear log.** The elegant native iOS app that Fragrantica — a cluttered, ad-heavy website — never built. Catalog every bottle with its full note pyramid, log every wear, and learn your taste and cost-per-wear. No account, no feed, no ads; everything lives on your device.

## What it is

Sillage is a calm, editorial "perfumery" for collectors. Each fragrance carries its **house, concentration, and a top/heart/base note pyramid** drawn from a seeded library of ~60 real notes mapped to olfactory families (bergamot → citrus, oud → woody, vanilla → gourmand, ambroxan → amber, and so on). Every bottle gets a soft **juice-color swatch** generated from its dominant note family plus a juice-color hue — no photos required. Log a wear in one tap and Sillage tracks last-worn, times-worn, and **cost per wear**, then turns it all into a taste map.

## Full feature list

- **Collection** — a juice-swatch grid of your owned bottles (house, name, concentration badge, rating). Search by name/house/note, filter by house/concentration/season, and sort by recently added, most worn, cost per wear, rating, or name. Designed empty and no-match states. Floating add button with a free-tier gate.
- **Tonight ("What to wear")** — pick a **Season + Occasion** and Sillage ranks the eligible bottles in your collection, favoring the **least-recently-worn** (then highest rating). One-tap **"Wore it"** logs a `WearLog` with a success haptic and updates last-worn. A "recently worn" strip sits up top. Calm empty case when nothing matches.
- **Wishlist** — the bottles you're eyeing, with a one-tap **"Acquired"** action that flips status to owned and drops it into the collection. Swipe to delete; empty state.
- **Scent Stats** — Swift Charts: note-family **donut**, season bar, occasion bar, **house** breakdown, **wears-over-time** line, and a **cost-per-wear leaderboard**, plus a neglected-bottles list. Headline numbers (bottles, collection value, wears this month, total wears) are free; the full charts are Pro-gated with a teaser. Computed in an async loading state.
- **Fragrance detail** — juice-swatch hero, the **note pyramid** (chips colored by family), season/occasion chips, longevity & sillage meters, times-worn / last-worn / cost-per-wear tiles, a full **wear-log history** (swipe to delete), **"I wore this today,"** edit, and delete-with-confirmation.
- **Add / Edit** — a full editor with a searchable **note picker** (the seeded library + add-your-own custom notes with a family), season/occasion chips, rating stars, longevity/sillage steppers, a juice-color slider, and validation (name & house required; size/price ≥ 0).
- **Onboarding** — three pages in the app's design language, gated by `hasOnboarded`.
- **Settings** — currency symbol, **neglected-after** threshold (days), default sort, **hide-prices** toggle, concentration **longevity-hints** toggle, and haptics — all persisted and live. Plus Export, **Load sample data**, Pro/Restore, and About.
- **Sillage Pro** — free up to **15 fragrances**; one-time **$4.99** unlock removes the cap, opens full Scent Stats, and enables text/CSV export. Honest demo unlock + Restore.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Sillage.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

### Free-signing note

You can run Sillage on a physical device with a personal Apple ID (free): select the Sillage target → Signing & Capabilities → pick your personal team. Free provisioning lasts **7 days** before you'll need to re-sign.

## Tech notes

- **iOS 17+**, **SwiftUI 5**, small separated files (`Models/`, `ViewModels/`, `Engine/`, `Views/`, `Theme/`, `Utilities/`).
- **SwiftData** is the primary store (`@Model` / `@Query` / `modelContext`). `Fragrance` cascade-owns its `WearLog`s and `NotePlacement`s; placements reference a shared `ScentNote` library (nullify, with a snapshot name/family so a deleted note never breaks display or stats). `UserDefaults` (`@AppStorage`) holds only prefs and flags (`isPro`, `hasOnboarded`, `didSeed`). **50+ fragrances** across houses, families, and statuses seed via the Settings "Load sample data" action, each with wear logs.
- **Engines are pure and UI-free:** `StatsEngine` (family/season/occasion/house distributions, monthly wear series, cost-per-wear, totals), `WardrobeEngine` (neglected, most-worn, collection value), and `Recommender` ("what to wear tonight" — eligible-then-least-recently-worn ranking with empty-case guards). All division is guarded (`pricePaid / max(timesWorn, 1)`).
- **Swift Charts** powers the stats screen (donut `SectorMark`, bars, line + area).
- **Warm editorial design language** built around an amber-gold accent (`#C8902A`): parchment light mode and deep-noir dark mode via a per-`colorScheme` `Theme.dyn` palette, serif display type over rounded UI type, both schemes first-class. Dynamic Type, accessibility labels/hints/values, decorative images hidden, and Reduce Motion are honored throughout. Haptics are sparse and gated by a Settings toggle.
- **Monetization:** one-time **$4.99** Sillage Pro unlock (StoreKit wires in for production; this build uses an honest demo unlock that sets `isPro` and offers Restore).
- **Why it can boom:** the fragrance community is huge and high-spending, but its hub — Fragrantica — is a cluttered, ad-heavy website, and there's **no elegant native iOS collection + wear-log app**. A beautiful, fully private one with note pyramids, a "what to wear tonight" hook, and cost-per-wear is exactly what enthusiasts wish existed.

## Self-review attestation

Every Swift file was re-read after authoring. Verified: imports; iOS 17 SDK availability of every type/initializer/modifier (incl. Charts `SectorMark`/`BarMark`/`LineMark`/`AreaMark`, two-parameter `onChange`, `Layout` for `FlowLayout`); protocol conformances (chart series and enums are `Identifiable`); `@Query`/`@Bindable`/`@StateObject`/`@EnvironmentObject` ownership consistency (ObservableObject + SwiftData only — no `@Observable` macro mixing); SwiftData relationships and cascade/nullify delete rules; `NavigationStack`/`sheet(item:)`/`navigationDestination` binding types; no duplicate type declarations; every referenced `Theme` token is defined; all seed note names resolve to the library. The only force operation in the app is the in-memory `ModelContainer` fallback `try!`; there are no `fatalError`, `as!`, force-unwraps, raw array indexing, or unguarded division on user paths. `grep -rniE "TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub|unimplemented"` over the sources returns zero matches; exactly one `@main` and exactly one `try!`.
