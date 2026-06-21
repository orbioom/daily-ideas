# Run 3 — 2026-06-21

**6 apps shipped · entries #346–351 in SHIPPED.md**

---

## 01 · Gomoku (`01-gomoku`) — Five-in-a-Row vs AI

Classic 15×15 Gomoku against a minimax AI with three difficulty levels. The AI evaluates candidate cells within 2 squares of existing stones, checks for immediate wins/blocks, then scores open-fours (100K), blocked-fours (10K), open-threes (5K) and smaller patterns. A Canvas-rendered board supports three themes (Classic/Dark/Bamboo), coordinate labels, last-move indicators, and winning-cell highlights. Tap anywhere on the board to place a stone.

**Screens:** Play · History · Stats (win-rate ring + Charts) · Settings  
**Persistence:** `GomokuResult`, `GomokuPrefs` (SwiftData)  
**AI:** `Task.detached` minimax with static board scorer, results posted back via `MainActor.run`

---

## 02 · Farkle (`02-farkle`) — Push-Your-Luck Dice Game

Full Farkle with pip-rendered dice, hot dice, farkle detection, and AI opponent. `FarkleEngine` implements the complete scoring table (straight=1500, three pairs=1500, three-of-a-kind, four/five/six-of-a-kind multipliers, singles 1=100/5=50). AI difficulty (Conservative/Normal/Aggressive) controls the banking threshold; AI turn runs async with `Task.sleep` delays for natural feel.

**Screens:** Play · History · Rules (full scoring chart) · Settings  
**Persistence:** `FarkleGame`, `FarklePrefs` (SwiftData)  
**Dice:** Custom `DiceFaceView` + `DicePipsView` with GeometryReader pip layout

---

## 03 · Rung (`03-rung`) — Word Ladder Puzzle

Transform one 4-letter word into another, one letter at a time. Each step must be a valid word from an 800+ word list. BFS shortest-path engine (runs on background thread) provides directional hints without revealing the word. Thirty curated daily puzzles have seeded par values; practice mode generates random solvable pairs via reachability check.

**Screens:** Daily · Practice · Stats (Charts performance) · Settings  
**Persistence:** `RungResult`, `RungPrefs` (SwiftData)  
**Hint Engine:** `Task.detached` BFS path-tracer → `MainActor.run` to post hint character

---

## 04 · Numble (`04-numble`) — Math Equation Guessing

Wordle, but for math. Guess a 5-character equation (`digit op digit = digit`) in 6 tries. Only valid equations from the 90-entry pool are accepted. Feedback is correct (green), present (yellow), absent (gray) — per character. A custom numpad with color-coded key state and a guess distribution chart complete the experience.

**Screens:** Play · Stats (distribution chart) · Settings  
**Persistence:** `NumbleResult`, `NumblePrefs` (SwiftData)  
**Engine:** `NumbleEngine.evaluate()` with positional Wordle algorithm

---

## 05 · Salvo (`05-salvo`) — Battleship vs AI

Classic 10×10 naval combat. Both fleets shown simultaneously — player fires on the top enemy grid, AI fires on the bottom player grid. Three AI personalities: Easy (pure random), Normal (Hunt & Target queue), Hard (checkerboard sweep + targeting). Ships are placed randomly at game start. Canvas rendering with `DragGesture(minimumDistance:0)` for cell tap detection.

**Screens:** Battle · History (Charts) · Settings  
**Persistence:** `SalvoResult`, `SalvoPrefs` (SwiftData)  
**AI:** Hunt & Target with adjacent-cell queue; Hard adds parity checkerboard

---

## 06 · Spello (`06-spello`) — Kids Spelling Trainer

Grade-level spelling practice for kids (Grades 1–5, 40 words per grade). Three modes: Multiple Choice, Type It, and Listen & Spell (uses `AVSpeechSynthesizer` for word pronunciation). Up to five child profiles each with independent grade level and session history. Progress tab shows accuracy trend line chart per active profile.

**Screens:** Home · Practice · Progress (Charts) · Settings  
**Persistence:** `SpelloProfile`, `SpelloSession`, `SpelloPrefs` (SwiftData)  
**Speech:** `AVSpeechSynthesizer` with en-US voice

---

## Technical Notes

- All six apps: SwiftUI 5 / iOS 17+, `@Observable` + `@MainActor`, XcodeGen `project.yml`, no API keys, fully offline
- Game AI runs on `Task.detached` background threads; results returned via `await MainActor.run`
- All icons: 64×64 solid-color PNGs generated via Python `struct`/`zlib` (no PIL dependency)
- SwiftData models use `@Model` with implicit `UUID` primary keys and default values for forwards-compat
