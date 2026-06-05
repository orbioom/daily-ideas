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

---

## Interval

**Type:** iOS app (native, SwiftUI) — run 2026-06-05_1209-UTC, slot 02 (Category A)
**Status:** Spec — not built this run (quality floor protection; one strong iOS app, Cellar, shipped instead)

**Problem:** HIIT, mobility, and circuit workouts live in scraps of paper and generic countdown
timers that can't represent a real routine (warm-up → rounds of work/rest → cooldown) and can't be
reused. People want to *build* a routine once and run it hands-free.

**Approach:** A native interval-timer builder with a real multi-entity model. A **Routine** owns an
ordered list of **Segments** (each with a kind — prepare / work / rest / cooldown — a duration, an
optional label, and an optional repeat-group). A routine can express "warm-up 60s, then 8× (work 40s
/ rest 20s), then cooldown 90s." Running a routine drives a full-screen timer engine with large
mono countdown, segment name, next-up preview, progress ring, audio + haptic cues at transitions and
the final 3-second lead-in, and a screen that stays awake.

**The bar it meets:** multi-entity domain model (Routine, Segment, repeat-groups, plus a Session log
of completed runs) — comfortably clears the substance floor. ≥4 feature screens: Routine library,
Routine builder (reorderable segments + repeat groups), Run/timer screen, History/Insights; plus
Onboarding and Settings.

**Architecture & stack:**
- iOS 17+, SwiftUI 5, MVVM, no external deps.
- **SwiftData** for Routines/Segments/Sessions (cascade relationships). `UserDefaults` only for the
  onboarding flag and settings (default rest sound, count-in length, keep-awake, haptics).
- Timer engine: a single `@Observable` `WorkoutEngine` driven by an absolute-time scheduler
  (`Date`-based, not tick-accumulation, so it stays accurate across backgrounding) with `@MainActor`
  UI updates; precomputes the flattened segment timeline from the routine + repeat-groups.
- Audio cues via `AVAudioPlayer` (short bundled blips) honoring the silent switch setting;
  `UINotificationFeedbackGenerator`/`.sensoryFeedback` for transitions; `UIApplication.isIdleTimerDisabled`
  during a run.

**Key logic:** timeline flattening of nested repeat-groups; pause/resume with correct elapsed math;
remaining-total vs remaining-segment; "skip segment" and "add 15s"; session summary (total work time,
rounds completed) written to the History log.

**States:** empty library (designed, "build your first routine"), running, paused, completed
(summary), and error (a routine with zero segments can't be run — guarded). All Dynamic Type sizes,
light/dark, VoiceOver labels on every control, Reduce Motion (progress ring fades instead of spins).

**Definition of done:** a person builds a routine, runs it end-to-end hands-free, sees a session in
History, and finds it intact after relaunch. App icon = an on-brand Orbioom orb with an interval arc.

---

## Apertura

**Type:** iOS app (native, SwiftUI) — run 2026-06-05_1209-UTC, slot 03 (Category A)
**Status:** Spec — not built this run (quality floor protection)

**Problem:** People learning manual photography (or shooting film) want to (a) reason about the
exposure triangle before a shot and (b) keep a real logbook of what settings produced what result —
especially on film, where there's no EXIF and feedback is delayed by weeks.

**Approach:** Two halves that reinforce each other. An **exposure calculator/visualizer**: pick any
two of aperture / shutter / ISO and a target EV, and see the third solved, plus a live diagram of the
trade-offs (depth-of-field band as aperture changes, motion-blur risk as shutter changes, noise hint
as ISO changes) using real photometric relationships (EV = log2(N²/t), reciprocity in full/half/third
stops). And a **shot log**: a multi-entity journal of **Rolls** (film stock, ISO, format, camera) each
owning ordered **Frames** (aperture, shutter, focal length, subject, location, notes, and the computed
EV). This clears the substance floor on both axes — non-trivial photometric computation *and* a real
relational model.

**Architecture & stack:**
- iOS 17+, SwiftUI 5, MVVM, no external deps.
- **SwiftData** for Rolls/Frames (cascade); `UserDefaults` only for preferences (default stop
  increment ⅓/½/full, default film stock, units, haptics) and onboarding.
- Pure, testable `Exposure` value type implementing stop math, EV solving, and equivalent-exposure
  enumeration (all aperture/shutter pairs for a given EV in the chosen increment).

**Screens (≥4 feature):** Calculator/visualizer; Roll library; Roll detail with its frames + add-frame;
Frame detail/editor; plus Onboarding and Settings. Export a roll's log as CSV/JSON.

**Key logic:** EV computation and the inverse (solve the missing leg), snapping to the nearest valid
third/half/full stop, equivalent-exposure generation, and a "you're 1⅓ stops under" readout against a
metered target. DoF/blur indicators are qualitative-but-honest (driven by aperture/focal/shutter,
clearly labelled as guidance, not a light meter).

**States:** empty roll library, populated calculator (always usable — preloaded with a sensible scene),
invalid input guarded (shutter 0, ISO ≤ 0), error messaging calm. Full accessibility (Dynamic Type,
VoiceOver values on the sliders, Reduce Motion), light/dark, on-brand orb app icon with an aperture
blade motif.

**Definition of done:** solve an exposure and see the trade-off diagram update; log a roll of frames;
export it; everything intact after relaunch.
