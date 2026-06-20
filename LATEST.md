# Run 2026-06-20 — 6 Production-Ready iOS Apps

**Run timestamp:** 2026-06-20 UTC  
**Total apps shipped this run:** 6 (#310–315)  
**Cumulative total:** 315 apps

---

## Apps Shipped This Run

### 310 — Kin: Family Tree & Genealogy
**Path:** `01-kin/`  
**Bundle ID:** `com.orbioom.kin`  
**Niche:** Digital genealogy for families who want an offline, private alternative to MyHeritage/Ancestry.

- Hierarchical tree canvas with connector lines (ScrollView horizontal + vertical)
- Person → Relationship (5 types) + LifeEvent (11 categories) cascade SwiftData models
- PhotoStore JPEG storage with initials fallback avatar
- FamilyStatsEngine: generationsApprox via depth-first recursion
- Swift Charts events-by-category bar chart + upcoming birthdays
- Georgia serif font theme for archival feel
- 5-tab navigation: Tree / People / Chronicle / Insights / Settings

---

### 311 — Scaffold: Home Renovation Planner
**Path:** `02-scaffold/`  
**Bundle ID:** `com.orbioom.scaffold`  
**Niche:** Project tracking for homeowners doing DIY renovations — HomeZada alternative.

- 7 cascade SwiftData models: Property → Room → Project → Task / Material / ProjectPhoto
- 8 project categories, 4 statuses (Planned/In Progress/Completed/On Hold)
- Dashboard with overdue project alerts (red background), active project list
- Cross-project shopping list: unpurchased materials grouped by project, mark-purchased toggle
- Budget math: actualCost vs budget, budgetUsedFraction progress bar
- Photo picker per project with FileManager JPEG storage
- `#Predicate` macro for SwiftData status filtering

---

### 312 — Campfire: Camping Trip Planner
**Path:** `03-campfire/`  
**Bundle ID:** `com.orbioom.campfire`  
**Niche:** Full-featured camping companion — gear, meals, and nature journal in one offline app.

- CampTrip → GearItem / MealPlan / NatureLog cascade SwiftData
- Gear checklist: 10 categories, filter chips, tap-to-toggle packed, progress bar
- Meal planner: day-by-day layout with 5 prep methods (campfire/stove/no-cook/raw/cooler)
- Nature journal: 8 categories (Wildlife/Plant/Weather/Sky/Landscape/Sound/Water/Other) with SF Symbols
- Trip upcoming/past sections with countdown badge
- Swift Charts: trips by year, camp style breakdown, favorite campsites
- 2-step dark forest-green onboarding

---

### 313 — Fable: Kids Bedtime Story Creator
**Path:** `04-fable/`  
**Bundle ID:** `com.orbioom.fable`  
**Niche:** Offline story creator for young children — StoryBird/Storytime alternative without subscriptions.

- FableStory → StoryCharacter / StoryPage cascade SwiftData
- 6 built-in story templates: adventure, space, fantasy, mystery, silly, friendship
- AVSpeechSynthesizer TTS narration with adjustable speed (slider in settings)
- Immersive dark/light reader with page navigation and per-page text display
- Emoji character system: 20 emoji options, 6 roles (Hero/Sidekick/Villain/Mentor/Magical/Animal)
- Age groups: 2–4 / 4–6 / 6–8 / 8–10 years
- Read counter + last-read timestamp tracking

---

### 314 — Vault: Private Photo Album
**Path:** `05-vault/`  
**Bundle ID:** `com.orbioom.vault`  
**Niche:** Offline private photo locker — Keepsafe alternative, one-time purchase.

- LocalAuthentication Face ID / Touch ID with 4-digit PIN fallback
- CryptoKit SHA256 for PIN hashing — never stored in plaintext
- VaultAlbum → VaultPhoto cascade SwiftData
- FileManager JPEG storage in Documents/VaultPhotos/
- Batch PhotosPicker import (up to 20 photos)
- Swipeable full-screen viewer: pinch-to-zoom, favorites, caption editing
- Auto-lock: Immediate / 1 min / 5 min / 15 min / Never
- Configurable grid columns: 2, 3, 4
- Storage meter (MB used) + change-PIN flow with 3-step verification

---

### 315 — Rival: Sports Pick'em & Prediction Tracker
**Path:** `06-rival/`  
**Bundle ID:** `com.orbioom.rival`  
**Niche:** Track your own sports predictions and measure accuracy over a season.

- Seeded NFL (32 teams) + NBA (30 teams) on first launch via onboarding
- 5 pick types: Moneyline / Spread / Over-Under / Parlay / Prop Bet
- 4 confidence levels: Lean / Like It / Strong / Lock
- Result entry via context menu ellipsis (Won / Lost / Push)
- Win-rate stats: overall, by pick type, by confidence level, by sport
- Swift Charts bar charts for pick-type accuracy + confidence accuracy
- Current streak tracker + custom league/matchup creation

---

## Technical Notes

- All 6 apps use **XcodeGen `project.yml`** — no hand-written `.xcodeproj`
- All icons are 1024x1024 PNG generated via Python3 `struct` + `zlib`
- All apps target **iOS 17+ / SwiftUI 5 / SwiftData**
- All apps are **100% offline** — no API keys, no network calls
- All apps have **empty states** for every collection view
- All apps use **`try? context.save()`** — no force-try on user paths

## Self-Review Checklist

| Criterion | 03 Campfire | 04 Fable | 05 Vault | 06 Rival |
|-----------|:-----------:|:--------:|:--------:|:--------:|
| XcodeGen project.yml | OK | OK | OK | OK |
| SwiftData cascade models | OK | OK | OK | OK |
| 4+ distinct screens | OK (12) | OK (9) | OK (9) | OK (9) |
| Full CRUD | OK | OK | OK | OK |
| Empty states | OK | OK | OK | OK |
| Accessibility labels | OK | OK | OK | OK |
| Onboarding flow | OK | OK | OK | OK |
| Real AppIcon 1024x1024 | OK | OK | OK | OK |
| Light/dark color sets | OK | OK | OK | OK |
| No external dependencies | OK | OK | OK | OK |
| Monetization defined | OK | OK | OK | OK |
| README with market signal | OK | OK | OK | OK |
| Settings with clear-data | OK | OK | OK | OK |
