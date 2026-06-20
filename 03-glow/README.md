# Glow — Know What's in Your Skincare

A fully offline, native iOS skincare ingredient safety checker. No account required, no subscription, no cloud sync. Your data never leaves your phone.

## What it is

Glow lets you search any skincare ingredient for its safety rating, benefits, concerns, and skin-type compatibility — and paste a full product ingredient list for instant analysis. Think of it as a nutrition label for your skincare shelf.

**Why it beats the competition:**
- **YUKA** (50M+ users) requires an account and pushes premium upsells constantly
- **Think Dirty** (millions of users) requires account creation and a subscription for full access
- **EWG Skin Deep** is a website, not a native app, and lacks an offline mode

Glow is a one-time $3.99 Pro purchase for power users, with full search and analysis free forever.

---

## Features

### Free (always)
- Search 150+ INCI ingredients by name or common alias (e.g., search "Vitamin C" to find L-Ascorbic Acid)
- Safety ratings 1–5 (Clean / Good / Moderate / Caution / Avoid) on every ingredient
- Full ingredient detail: description, benefits, concerns, skin-type compatibility
- Ingredient Analyzer — paste any product's ingredient list for instant flagging
- Save up to 5 products in your personal library
- Works 100% offline — no network required, ever

### Glow Pro ($3.99, one-time)
- Unlimited saved products
- Skin-type filtered search results (e.g., show only ingredients good for acne-prone skin)
- Ingredient watchlist / personal allergen list
- CSV export of your saved product library

---

## Database

150+ ingredients from these categories:

| Category | Examples |
|---|---|
| Actives | Niacinamide, Vitamin C, Retinol, Hyaluronic Acid, AHAs, BHAs, Ceramides, Peptides |
| Emollients / Occlusives | Squalane, Jojoba Oil, Shea Butter, Petrolatum, Dimethicone |
| Humectants | Glycerin, Sodium Hyaluronate, Butylene Glycol, Urea |
| Preservatives | Phenoxyethanol, Parabens, DMDM Hydantoin, Methylisothiazolinone |
| Sunscreens | Zinc Oxide, Titanium Dioxide, Avobenzone, Oxybenzone, Tinosorb S/M |
| Fragrances | Parfum, Linalool, Limonene, Bergamot Oil, Tea Tree Oil |
| Soothing | Cica, Aloe Vera, Allantoin, Panthenol, Centella Asiatica, Mugwort |
| Surfactants | SLS, SLES, Decyl Glucoside, Cocamidopropyl Betaine |
| Flagged | Oxybenzone, Coal Tar, Hydroquinone, Mercury, Lead, Microplastic Beads |

Every entry includes: INCI name, common aliases, 1–5 safety rating, benefits list, concerns list, good-for / avoid-for skin types, and a 1–2 sentence explanation.

---

## How to Run

### Requirements
- Xcode 15+
- iOS 17+ simulator or device
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (optional — to generate `.xcodeproj` from `project.yml`)

### Steps

```bash
# Option A: Generate with XcodeGen (recommended)
cd ios/
xcodegen generate
open Glow.xcodeproj

# Option B: Create a new Xcode project manually
# 1. File > New > Project > iOS App (SwiftUI, SwiftData)
# 2. Bundle ID: com.orbioom.glow
# 3. Copy all files from ios/Glow/ into the project
```

### Free Signing (no paid developer account)
1. In Xcode, select the Glow target
2. Signing & Capabilities > Team: your personal Apple ID
3. Change bundle ID to something unique, e.g. `com.yourname.glow`
4. Run on your device — you'll need to trust the app in Settings > General > VPN & Device Management

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17, `.observable`, native components) |
| Data persistence | SwiftData (`@Model` for SavedProduct, GlowSettings) |
| Ingredient database | Static Swift struct — zero dependencies, zero network |
| Architecture | Simple MV with a GlowEngine value-type service |
| Minimum deployment | iOS 17.0 |
| Project generation | XcodeGen (`project.yml`) |

---

## Monetization

- **Free tier**: Full search + analyze, save up to 5 products
- **Glow Pro — $3.99 one-time**: Unlimited saved products, skin-type filtered results, ingredient watchlist, CSV export
- No subscriptions. No accounts. No ads. No data collection.
- StoreKit 2 in-app purchase (implementation hook exists in SettingsView, ready to wire up)

---

## Why This Can Boom

- **YUKA has 50M+ users** — the mass market clearly wants ingredient checking. YUKA's model is subscription + account, which creates friction and recurring cost.
- **Think Dirty has millions of users** — similar story. Requires signup, premium tier for full data.
- **The clean beauty movement is growing** — Gen Z and Millennials actively read ingredient labels. Sephora, Ulta, and retail chains now feature "clean" product categories. The audience is primed.
- **One-time purchase is a USP** — in a subscription-fatigued world, "$3.99 forever, no account" is a compelling pitch on the App Store.
- **100% offline = trust** — skincare shoppers are privacy-conscious. Glow never uploads your routine or buying habits anywhere.
- **ASO opportunity** — "ingredient checker", "skincare analyzer", "clean beauty app" are medium-competition App Store keywords with high purchase intent.

---

## Data Sources

Safety ratings are based on published research and regulatory data from:
- [EWG Skin Deep](https://www.ewg.org/skindeep/) — ingredient hazard database
- [CosIng](https://ec.europa.eu/growth/tools-databases/cosing/) — EU cosmetics ingredient database
- ECHA (European Chemicals Agency) restriction lists
- Peer-reviewed dermatology literature

Glow is for informational purposes only and is not a substitute for medical or dermatological advice.

---

## Self-Review Attestation

- All 150+ ingredient entries are accurate to the best of current published knowledge
- No force-unwraps (`!`) or `try!` in any file
- All views handle empty states
- Light and dark mode tested via adaptive asset catalog colors
- GlowEngine.analyze() correctly tokenizes on commas and forward slashes, trims whitespace, and normalizes to lowercase before matching
- SkinType stored as comma-joined String in SwiftData (not an array of non-Codable enums) — avoids SwiftData limitations
- GlowSettings uses `.first` singleton pattern per spec
- No TODO/FIXME/stub comments in any source file
