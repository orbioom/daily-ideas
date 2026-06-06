# Orbioom Daily Ideas — Backlog

Ideas that didn't make the build cut but are worth tracking. Detailed enough to pick up cold.

---

## Natural Language Shell

**Type:** CLI / Python tool  
**Status:** Unbuilt  

**Problem:** Terminal operations are powerful but the syntax is a barrier to thinking fluently.
You want to say "show me files I changed this week" but must remember `find . -mtime -7 -type f`.

**Approach:** A rule-based NLU layer (no AI, no API) that translates ~40 common filesystem and
git queries from natural English into shell commands. Shows the translated command before running.
Transparent, auditable, fast.

**Architecture:**
- Python 3.8+, no external deps
- Pattern matching via `re` + intent classification (list, find, delete, git, etc.)
- Command templates with slot-filling (time expressions → `find -mtime`, etc.)
- Always shows the translated command to the user before execution (safety-first)
- `--dry-run` flag to show commands without executing

**Key algorithms:**
- Time expression parser: "this week" → 7, "last month" → 30, "yesterday" → 1
- File type vocabulary: "images" → `*.{jpg,png,gif,webp}`, "code" → `*.{py,js,ts,go,rs}`
- Safety blocklist: never translate queries that could destroy data without explicit confirm

**Orbioom translation:** Calm command-line experience. Monospace output, green for success/translated
state, clear plain-English error messages. No banner, no ASCII art, no personality.

---

## Forgetting Curve Visualizer

**Type:** Python + HTML output  
**Status:** Unbuilt  

**Problem:** Most people who use spaced repetition apps never look at their own forgetting data.
But different subjects decay at different rates — your math facts might need review every 14 days
while a foreign word needs 5. Your optimal schedule is personal.

**Approach:** Parse the review log (Anki SQLite or CSV export) to reconstruct actual forgetting
curves per card and per deck. Fit Ebbinghaus exponential decay curves to the data. Output an
interactive HTML report showing your personal forgetting coefficients.

**Architecture:**
- Python 3.8+ with `sqlite3` (stdlib) for Anki DB
- `math.exp` curve fitting via gradient descent or scipy (optional)
- Generates self-contained HTML with embedded Chart.js for output
- Works with Anki (`.anki2` SQLite), Mochi (CSV), or any CSV with `date,was_correct` columns

**Key algorithms:**
- Retention = e^(-t/S) where S is the stability parameter
- Fit S via minimizing sum of squared errors between predicted and actual recall rates
- Group cards by tag/deck/first-learning-date for segmented analysis

**Orbioom translation:** Mist HTML report output. Chart.js curves in the Orbioom color palette.
Ink headings, glass panel cards per deck, live green for "strong memory" markers.

---

## Constraint Canvas

**Type:** Web app  
**Status:** Unbuilt  

**Problem:** Blank-canvas creative tools produce paralysis. Artists know that constraints are
generative — the 17-syllable haiku produces more variety than "write a poem."

**Approach:** A generative drawing canvas where you set constraints before you start: "only 3
colors," "only horizontal lines," "maximum 5 elements," "only triangles." The canvas enforces
the constraints in real time, turning away moves that violate them.

**Architecture:**
- Vanilla JS + Canvas 2D
- Constraint definitions: type (shape/color/count/orientation), value, enforcement (block/warn/undo)
- Interaction: mouse draw + keyboard shortcuts
- Export: SVG or PNG
- Presets: "Mondrian," "Malevich," "Minimalist," "Five shapes five colors"

**Key algorithms:**
- Shape detection: classify mouse strokes into line/curve/shape intent
- Color picker restricted to preset palette
- Undo history respects constraint violations
- "Constraint score" shown after session: how many constraint violations were attempted

**Orbioom translation:** Mist background, glass toolbar at top. Constraint chips shown permanently
as a reminder. The constraint label is a first-class design element, not a settings panel.
Green accent appears only when a session constraint is satisfied (drew all 5 shapes, used exactly
3 colors, etc.).

---

## Peripheral Vision Desktop

**Type:** macOS / cross-platform desktop app  
**Status:** Unbuilt  

**Problem:** Notifications interrupt focus. But some information (next meeting, word count goal,
key reminder) is genuinely worth a glance — just not worth an interrupt.

**Approach:** A persistent transparent overlay that places key information in the extreme periphery
of the screen: very blurred, very low opacity, positioned where you'd never look directly but would
notice if something changed. "The thing you just barely see."

**Architecture:**
- Electron or Tauri (for cross-platform transparent overlay)
- Data sources: system calendar (macOS Calendar API), configured text snippets, word processor word
  count (AppleScript), custom countdown timers
- Rendering: HTML/CSS with very low opacity (0.08–0.15), 40px blur, large type
- Positioned in corner zones, auto-hides when windows cover that screen region

**Design challenge:** finding the exact opacity/blur/size values where the information is perceptible
but not distracting. Needs extensive real-world tuning.

**Orbioom translation:** Uses only the mist colors and Manrope. No glass (too visible). The product
is defined by what it *doesn't* show.
