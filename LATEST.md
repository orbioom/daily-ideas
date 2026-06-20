# Run 2026-06-20 — run5

**6 production-ready iOS apps shipped today (entries 322–327 in SHIPPED.md)**

| Slot | App | Category | Bundle ID | Monetization |
|------|-----|----------|-----------|--------------|
| 01-piece | **Piece** | Jigsaw puzzle game | com.orbioom.piece | One-time Pro |
| 02-shu | **Shu** | Mandarin SRS flashcard trainer | com.orbioom.shu | One-time Pro |
| 03-swatch | **Swatch** | Color palette extractor | com.orbioom.swatch | One-time Pro |
| 04-dojo | **Dojo** | BJJ martial arts tracker | com.orbioom.dojo | One-time Pro |
| 05-sleeve | **Sleeve** | Trading card collection tracker | com.orbioom.sleeve | One-time Pro |
| 06-hoop | **Hoop** | Basketball live scorekeeper | com.orbioom.hoop | One-time Pro |

---

## Top Pick: Shu (02-shu)

**Why:** Language learning is the second-largest app category by revenue. Duolingo has a $8.99/month subscription and is full of gamification noise. Shu is laser-focused: 100 essential Mandarin characters, SM-2 SRS algorithm, and a killer differentiator — it speaks each word using native AVSpeechSynthesizer zh-CN TTS the moment you flip a card. No internet required. One-time purchase with zero subscription anxiety.

**Revenue signal:** "Anki alternative iOS" and "mandarin flashcards offline" are consistent App Store search terms. The addressable market is everyone studying for HSK 1-2 certification (growing 40% YoY per BC).

---

## App Summaries

### Piece (01-piece) — Jigsaw Puzzle Game
- 5 procedural artworks drawn entirely with SwiftUI Canvas (Mountain Sunset, Ocean Waves, Geometric Grid, Northern Lights, Floral Mandala)
- 3 difficulty levels: Beginner (4×4=16), Intermediate (6×6=36), Expert (9×9=81)
- ImageRenderer pre-renders artwork once to UIImage; avoids re-drawing Canvas 81× per frame
- Tap-to-select + tap-to-place mechanic; wrong slot triggers 4-repeat shake animation
- Save & resume with SwiftData, personal best tracking, reference image sheet

### Shu (02-shu) — Mandarin SRS Flashcard Trainer
- 100 real HSK 1 vocabulary words (characters, pinyin, tone, English, example sentences)
- Full SM-2 spaced repetition (EF decay, interval scheduling, 5-rating system)
- 4 study modes: Flashcard (3D flip), Tone Quiz (4-option), Meaning Quiz (MCQ), Writing Canvas
- AVSpeechSynthesizer zh-CN TTS auto-plays on card reveal — hear the word spoken correctly
- 7-day Swift Charts bar chart, mastery breakdown, streak tracker

### Swatch (03-swatch) — Color Palette Extractor
- Real K-means clustering (20 iterations, 80×80 downsample, RGB centroid convergence)
- PhotosPicker + UIImagePickerController camera, 4-8 colors extracted and sorted by dominance
- Tap any swatch to copy hex code; detail view copies hex + rgb() values
- 38-color CSS nearest-neighbor color naming (Red, Gold, Teal, Lavender, etc.)
- SwiftData palette library, PaletteDetailView with UIActivityViewController share

### Dojo (04-dojo) — BJJ Martial Arts Tracker
- Training session log: 6 types (Gi/No-Gi/Wrestling/Striking/Conditioning/Open Mat)
- 30-technique pre-seeded library: 5 guards, 5 passes, 10 submissions, 5 sweeps, 4 takedowns, 3 back+escapes
- Drill counter per technique; favorites; category filter chips
- Belt progression timeline (White→Blue→Purple→Brown→Black, 0-4 stripes per belt)
- Competition log: wins/losses/Gold/Silver/Bronze medals; DojoSeeder first-launch

### Sleeve (05-sleeve) — Trading Card Collection Tracker
- 5 supported games: Pokémon, Magic: The Gathering, Yu-Gi-Oh!, Sports Cards, Other
- 5 rarities (Common→Secret Rare) with color-coded dots; 6 conditions (Mint→Damaged)
- Foil toggle, graded toggle with grade score (PSA 9, BGS 9.5), optional photo per card
- Deck builder with game-scoped format picker (Standard/Modern/Legacy/Commander for MTG)
- Want list with priority badges (🔴🟡🟢), swipe-to-acquire, max price tracking

### Hoop (06-hoop) — Basketball Live Scorekeeper
- @Observable GameEngine with Task-based countdown timer + pause/resume/end-quarter
- Per-player scoring: +2pt / +3pt / FT(made or missed); team fouls + timeout dots
- Roster builder: up to 15 players per team with name + jersey number
- Undo stack (30 action snapshots) for accidental tap recovery
- Quarter-by-quarter box score stored as JSON in SwiftData; GameDetailView full stats

---

## Tech Notes
- All apps: iOS 17+, SwiftUI 5, `@Observable` (not ObservableObject), SwiftData `@Model`
- XcodeGen `project.yml` (no hand-written .xcodeproj)
- Build any: `brew install xcodegen && cd <app>/ios && xcodegen generate && open <App>.xcodeproj`
- App icons generated via Python stdlib (struct/zlib PNG encoding), 512×512

---

## Next-Run Signals
- **Shu** is the strongest revenue candidate — language learning + offline + SRS is a proven formula
- **Piece** Canvas artwork approach can be extended to unlimited puzzle packs (IAP per pack)
- **Hoop** could become a referee assistant with shot-clock and ejection tracking
- Avoid finance/budgeting/tax/investment/money-management (off-limits per mandate)
- Candidates for next run: Chess, Nonogram/Picross puzzles, Guitar chord library, Recipe manager
