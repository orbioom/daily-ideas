# Run 2026-06-20 — run6

**6 production-ready iOS apps shipped today (entries 328–333 in SHIPPED.md)**

| Slot | App | Category | Bundle ID | Monetization |
|------|-----|----------|-----------|--------------|
| 01-canopy | **Canopy** | Carbon footprint tracker | com.orbioom.canopy | $3.99 one-time Pro |
| 02-pair | **Pair** | Memory match card game | com.orbioom.pair | $1.99 one-time Pro |
| 03-glow | **Glow** | Skincare ingredient checker | com.orbioom.glow | $3.99 one-time Pro |
| 04-script | **Script** | Fountain screenwriting editor | com.orbioom.script | $6.99 one-time Pro |
| 05-rampart | **Rampart** | Tower defense game | com.orbioom.rampart | $2.99 one-time Pro |
| 06-halo | **Halo** | Binaural beats / focus audio | com.orbioom.halo | $4.99 one-time Pro |

---

## Top Pick: Glow (03-glow)

**Why:** Skincare is a $200B market with no dominant offline ingredient checker. YUKA charges €14.99/year and requires internet. Glow works offline, covers 158 real INCI ingredients with safety scores (1-5), ingredient conflict detection (10 incompatible pairs), and skin-type compatibility filters. The SavedProduct library lets users build a personal database of vetted products. This hits beauty enthusiasts, people with sensitive skin, and anyone tired of marketing buzzwords — a wide, monetizable audience.

**Revenue signal:** "skincare ingredient checker app" is a top-100 Health & Fitness App Store search with no strong offline-only competitor. One-time $3.99 Pro removes the 5-product cap.

---

## App Summaries

### Canopy (01-canopy) — Carbon Footprint Tracker
- 28-activity EmissionsEngine covering transport (car/bus/train/flight), food (meat/dairy/produce), energy (electricity/heating), shopping, and waste with real CO2e factors
- InsightsEngine: weekly totals, 8-week trend chart, category breakdown, daily streak
- Home tab shows a circular progress ring toward user's daily CO2 target
- 3-step LogEntryView wizard: pick category → pick activity → enter quantity
- Swift Charts: weekly bar chart + category donut in Insights tab
- Forest green #2D6A4F theme; $3.99 one-time Pro unlocks unlimited history export + custom targets

### Pair (02-pair) — Memory Match Card Game
- 5 themes: Animals, Space, Food, Nature, Symbols — each with 18 unique emoji cards
- 3 grid sizes: Easy (4×4), Medium (4×5), Hard (5×6)
- FlipEngine (@Observable) with SplitMix64 seeded RNG for reproducible daily challenges
- CardView: 3D flip animation (rotation3DEffect) with haptic feedback on match/mismatch
- Daily challenge: same seed for all players on a given date; streak tracked in SwiftData
- Swift Charts bar chart for games-per-day; PairResult @Model stores time + moves
- Navy #1A1B3A + coral #FF6B6B theme; $1.99 one-time Pro unlocks all themes and hard mode

### Glow (03-glow) — Skincare Ingredient Checker
- 158 real INCI ingredient database across 15 categories: Humectants, Emollients, Occlusives, Exfoliants, Antioxidants, Retinoids, Peptides, SPF, Preservatives, Surfactants, Emulsifiers, Film-formers, Colorants, Fragrances, Actives
- Each ingredient: safety score (1-5), benefits, concerns, skin-type compatibility (oily/dry/combo/sensitive/all)
- GlowEngine: `search()` with fuzzy matching, `analyze([String])` for full product label, `checkConflict()` covering 10 incompatible pairs (Retinol+AHAs, Vitamin C+Niacinamide, etc.)
- SavedProduct library (5 free / unlimited Pro) persisted in SwiftData
- Skin-type filter chip row; IngredientDetailView with color-coded safety badge
- Rose #E8A0B4 theme; $3.99 one-time Pro

### Script (04-script) — Fountain Screenwriting Editor
- FountainParser: line-by-line state machine covering all Fountain spec elements (scene heading, action, character, dialogue, parenthetical, transition, centered text, page breaks, bold/italic/underline)
- FountainTextEditor: UITextView UIViewRepresentable with keyboard accessory bar (EXT./INT. quick-insert, TAB indents for character → dialogue, format buttons)
- ScriptPDFExporter: UIGraphicsPDFRenderer generating Letter 8.5×11" PDFs, Courier 12pt throughout, proper margins (1.5" left, 1" top/right/bottom), title page with author + date
- Page count estimator: 1 min/page standard; shown live in editor toolbar
- ScriptProject @Model with last-modified timestamp; ProjectListView swipe-to-delete
- Amber #F4A261 dark theme; $6.99 one-time Pro (Final Draft FDX export + custom fonts)

### Rampart (05-rampart) — Tower Defense Game
- 320×480 logical coordinate system; 16×24 cell grid (20×20 units/cell); Canvas + TimelineView at 60fps via GameViewUpdater @Observable
- 3 towers: Archer (50g, 10dmg, fast 0.8s, single-target), Cannon (100g, 40dmg, splash r=20, slow 2.5s), Frost (75g, 5dmg, 50% speed slow for 2s)
- 4 enemy types: Goblin (fast/weak), Orc (medium), Troll (tanky), Dragon (boss-level)
- 5 maps with hand-crafted CGPoint waypoint paths; 5 waves each with HP scaling per wave
- RampartGame @Observable: `hasTower(at:)`, `canBuild(at:)`, `placeSelectedTower(at:)`, `sellTower(at:) -> Int`; range preview circle on cell selection
- SwiftData GameRecord (mapID, wave, score, won); StatsView with per-map best scores + 14-day chart
- Dark parchment #2C2416 + gold #D4AF37 theme; $2.99 one-time Pro (3 bonus maps)

### Halo (06-halo) — Binaural Beats / Focus Audio
- AVAudioSourceNode real-time DSP: left channel = carrier Hz (100Hz), right channel = carrier + binaural offset Hz; pure sine generation without audio files
- Pink noise: Kellet's 7-state IIR filter blended in at configurable level (ambientNoiseLevel slider)
- UIBackgroundModes: audio — keeps playing when screen locks; AVAudioSession .playback category
- 12 presets across 5 brainwave categories: 4 free (Focus Flow 10Hz α, Deep Meditate 6Hz θ, Sleep Drift 2Hz δ, Study Mode 18Hz β) + 8 Pro
- Session timer (5–120 min) with auto-stop; HaloRingView Canvas concentric ring pulse animation
- NowPlayingBar: mini-player overlay above tab bar showing preset name + remaining time + stop button
- SwiftData HaloSession history; Swift Charts weekly minutes bar chart in Insights tab
- Deep purple #0D0D1A + lavender #C084FC theme; $4.99 one-time Pro (8 additional presets)

---

## Tech Notes
- All apps: iOS 17+, SwiftUI 5, `@Observable` (not ObservableObject), SwiftData `@Model`
- XcodeGen `project.yml` (no hand-written .xcodeproj)
- Build any: `brew install xcodegen && cd <app>/ios && xcodegen generate && open <App>.xcodeproj`
- App icons generated via Python stdlib (struct/zlib PNG encoding), 1024×1024
- Halo requires real device for audio (AVAudioSourceNode restricted in Simulator)

---

## Next-Run Signals
- **Glow** strongest near-term revenue candidate — tap into skincare Reddit communities
- **Script** targets a high-willingness-to-pay niche (writers pay for tools); FDX export is a real unlock
- **Halo** benefits from social proof; add a "Shared Presets" social feature in a future run
- Avoid finance/budgeting/tax/investment/money-management (off-limits per mandate)
- Candidates for next run: Chess clock/trainer, Nonogram/Picross puzzles, Guitar chord library, Recipe nutrition calculator, Habit streak tracker (non-generic), Morse code trainer
