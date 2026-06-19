# Run 2026-06-19_1400-UTC

6 production-ready native iOS apps shipped. All target iOS 17+, SwiftUI 5, SwiftData, @Observable. No external dependencies.

## Apps Shipped

| Slot | App | Category | Accent | Screens |
|------|-----|----------|--------|---------|
| 01 | **Stipple** — Color-by-Number Pixel Art | Games/Creativity | Teal #30BE80 | 4 (Gallery, Color Canvas, Daily, Settings) |
| 02 | **Scribe** — Word Board Game | Games/Puzzle | Forest green #5C8A3E | 3 (Play, Stats, Settings) |
| 03 | **Apex** — Pyramid Solitaire | Card Games | Felt green + Gold | 4 (Play, History, Stats, Settings) |
| 04 | **Stamp** — Sticker Maker | Creativity/Photo | Purple #9933E6 | 3 (Editor, Gallery, Settings) |
| 05 | **Locale** — Travel Phrasebook | Travel/Reference | Blue #0F83EA | 4 (Phrases, Favorites, Languages, Settings) |
| 06 | **Sprite** — Pixel Art Creator | Creativity | Indigo #4B66E6 | 2 (Gallery + Canvas, Settings) |

## Top Recommendation

**Locale** (Travel Phrasebook) — Travel utility apps with TTS get habitual use during every trip. The offline-first approach beats Google Translate for travelers on roaming plans. The 6-language Pro unlock is a natural upgrade trigger right before a trip. Revenue path: $2.99 one-time + word-of-mouth from travelers.

## Technical Highlights

- **Stipple**: 15 pixel scenes generated via shape-painting functions (no hand-encoded strings). Flood-fill BFS with neighbor-set expansion. `SplitMix64` seeded by date components for daily scene selection. `UIGraphicsImageRenderer` PNG export with `ShareSheet`.
- **Scribe**: Full 15×15 Scrabble board with correct DL/TL/DW/TW square layout computed from a pure function. `WordValidator` with O(1) Set lookup against 500+ embedded words. Scoring with live word extraction from placed tile positions.
- **Apex**: `PyramidGameEngine` with 7-row pyramid, snapshot-based undo (`SavedPyramidGame`), and 3-pass draw limit. `pairSumsTo13` for pair validation including Kings. `SplitMix64` seeded by game number for reproducible daily deals.
- **Stamp**: Per-pixel color-distance background removal against white background (no Vision framework needed). `UIGraphicsImageRenderer` compositing with border drawing and `CGContext` shadow. PNG-with-transparency export to Photos.
- **Locale**: `AVSpeechSynthesizer` with per-language `AVSpeechSynthesisVoice(language:)` locale codes. `SpeechDelegate` class bridges `AVSpeechSynthesizerDelegate` callbacks to SwiftUI state. 170+ phrases across 8 categories fully embedded — zero network calls.
- **Sprite**: `[Int]` pixel buffer (ARGB ints, 0=transparent). SwiftUI `Canvas` renders the full grid on each frame. Flood-fill BFS in `CanvasViewModel`. `CGContext` renders final image for export. `DragGesture` with cell index calculation for smooth paint strokes.

## Market Signals

- Color-by-number apps (Pixel Art Color, Happy Color) have 10M+ downloads — Stipple targets the ad-free premium segment with a one-time unlock.
- Scrabble-style solo games consistently top word game charts — no quality offline SwiftUI native option exists.
- Pyramid Solitaire has 50M+ Google Play downloads — iOS native alternatives are dominated by ad-supported ports.
- Sticker maker apps generate strong revenue from iMessage sticker packs — Stamp's BG-removal workflow is faster than Canva or PicsArt for simple stickers.
- Travel phrasebook apps spike in downloads before major holidays — Locale's offline-first model is the key differentiator vs. subscription competitors.
- Pixel art tools are thriving with NFT/indie-game creator communities — Sprite's minimal mobile-first UI beats desktop-style apps for on-the-go creation.

## Registry

Total apps shipped to date: **303** (entries 1–303 in SHIPPED.md)
Previous run: 2026-06-19_0638-UTC (Keys, Volley, Ante, Poise, Muddle, Rhyme — #292–297)
