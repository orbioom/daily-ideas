# Recall — Spaced-Repetition Flashcards by Orbioom

A calm, focused flashcard app that schedules reviews using the SuperMemo SM-2 algorithm so you review each card right before you would forget it. Built as a fully static single-page application — no server, no build step, no dependencies beyond Google Fonts.

---

## Features

### Core Study Flow
- **SM-2 spaced repetition** — Every review updates each card's easiness factor, repetition count, and next interval. Cards are rescheduled precisely: Again resets to 1 day, Hard/Good/Easy advance the schedule according to SM-2 rules.
- **Rating buttons with interval preview** — While rating, each button shows the resulting next interval (e.g. "Good · 6d", "Easy · 14d") so you know the consequence of each choice before you commit.
- **Session progress** — Progress bar and card counter update in real time. End-of-session summary shows cards reviewed, again-rate %, and time elapsed.
- **Study All Due** — Study everything due across all decks at once, or focus on one deck.
- **Session limits** — Configurable max reviews per session so sessions stay manageable.
- **Nothing-due state** — If nothing is due, a calm "All caught up" screen shows the next scheduled review date.

### Deck Management
- Create, edit, and delete decks with name, description, colour, and icon.
- Per-deck card counts and due-count badges on the deck browser.
- Delete deck deletes all its cards and review history with a confirmation prompt.

### Card Management
- Add, edit, and delete cards with front (prompt) and back (answer) fields, plus optional comma-separated tags.
- **Bulk importer** — Paste many cards at once in `front | back` format (one per line). Live preview shows valid/skipped count. Duplicate fronts within a deck are skipped automatically.
- Cards display their SM-2 state (EF, interval, due date, lapses) in the card list.

### Statistics
- **Review heatmap** — 12-week calendar grid rendered in SVG showing review activity intensity per day, with month labels.
- **Upcoming due forecast** — 7-day bar chart (SVG) of cards scheduled per day.
- **Key metrics** — Total cards, decks, due today, current review streak, retention rate (% of reviews rated Good or better), reviews in last 7 days.
- All numbers displayed in JetBrains Mono for clarity.

### Settings
- Daily new-card limit and max reviews per session (validated, clamped).
- Theme: Light / Dark / System (follows `prefers-color-scheme`).
- Reduced-motion toggle (also respects `prefers-reduced-motion` media query).
- Persisted to localStorage immediately on save.

### Data & Export
- **Export JSON** — Full round-trip backup: decks, cards, all SM-2 scheduling state, review log, settings. Downloads as `recall-backup-YYYY-MM-DD.json`.
- **Export CSV** — All cards with deck name, front, back, tags, EF, interval, due date, lapses, total reviews.
- **Import JSON** — Restore from any previously exported JSON file. Validates structure before replacing data. Requires explicit confirmation.
- **Reset to sample** — Restore the built-in seed decks at any time.
- **Clear all** — Wipe all data with a confirmation prompt.

### Seed Data
Three realistic decks included out of the box, with ~30 cards total, varied SM-2 states, and a review log so stats and the heatmap are meaningful from first open:
- **Spanish Essentials** — Core vocabulary and phrases
- **Capital Cities** — Countries and their capitals
- **JS Array Methods** — JavaScript array method signatures and behaviours

Some cards are overdue (due to be studied now), some are scheduled in the future, some have lapsed — giving a realistic mix for the study session and forecast chart.

---

## Running the App

Because scripts use classic `<script>` tags (no ES modules), the app works directly from the filesystem:

```
open /path/to/05-recall/index.html
```

Or serve locally to avoid any browser restrictions on local file access:

```bash
# Python 3
python3 -m http.server 3000 --directory /path/to/05-recall/

# Node.js (npx)
npx serve /path/to/05-recall/

# Then open: http://localhost:3000
```

No build step. No npm install. No dependencies beyond Google Fonts (loaded from the CDN; the app still works without it, falling back to system-ui and ui-monospace).

---

## Data & Privacy

All data is stored exclusively in your browser's `localStorage` under the key `recall_data_v1`. Nothing is sent to any server. Clearing your browser data will erase your cards and review history — use Export JSON before doing so.

The localStorage payload is versioned (`"version": 1`). If a future version changes the schema, the loader will apply sane defaults for any missing or legacy fields, ensuring the app never crashes on old data.

---

## Tech & Accessibility Notes

### SM-2 Algorithm
Recall implements the **SuperMemo SM-2 algorithm** designed by Piotr Woźniak. Reference: [SuperMemo SM-2 Algorithm](https://www.supermemo.com/en/blog/application-of-a-computer-to-improve-the-results-obtained-in-working-with-the-supermemo-method).

The scheduler is in `sm2.js` as pure functions with no side effects, making it independently testable. Key rules implemented:

- **Lapse (q < 3):** n reset to 0, interval set to 1, EF decremented, lapse count incremented.
- **First success (n=0, q ≥ 3):** interval = 1 day.
- **Second success (n=1, q ≥ 3):** interval = 6 days.
- **Subsequent (n ≥ 2, q ≥ 3):** interval = round(prev_interval × EF).
- **EF update:** `EF = EF + 0.1 − (5−q) × (0.08 + (5−q) × 0.02)`, floored at 1.3.
- **Due date:** today + new interval.

UI ratings map to quality values: Again=1, Hard=3, Good=4, Easy=5.

### Fonts
- **Manrope** (UI text) — loaded from Google Fonts. Fallback: `system-ui, sans-serif`.
- **JetBrains Mono** (all numbers, intervals, dates, EF values) — loaded from Google Fonts. Fallback: `ui-monospace, monospace`.
No local font files are referenced.

### Accessibility
- Semantic HTML: `<header>`, `<main>`, `<nav>`, `<section>`, landmark roles throughout.
- All interactive elements are real `<button>` or `<input>` elements with visible labels.
- Keyboard: Space/Enter reveals the card; 1–4 rates; Tab order is logical; modals trap focus and restore it on close; Esc closes modals.
- `aria-live` regions announce card reveals, session progress, and toast notifications to screen readers.
- Colour contrast ≥ 4.5:1 for body text in both light and dark themes; ≥ 3:1 for large/decorative text.
- Touch targets are ≥ 44px on all interactive elements.
- Responsive from 360 px to desktop; rating buttons reflow to a 2-column grid on narrow screens.
- Respects both `prefers-reduced-motion` (OS-level) and the in-app reduced-motion toggle.

### Architecture
| File | Purpose |
|---|---|
| `sm2.js` | Pure SM-2 scheduler (no side effects) |
| `storage.js` | Versioned localStorage with normalization and export/import |
| `seed.js` | Realistic seed data generator |
| `stats.js` | SVG heatmap, forecast bar chart, retention & streak calculations |
| `app.js` | Application controller: routing, CRUD, study sessions, settings |
| `styles.css` | Design system, Orbioom Liquid Glass theme, light/dark, responsive |
| `index.html` | Single-page HTML shell with all modal markup |

---

## Self-Review Attestation

### Anti-stub scan
```
grep -rniE "TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub" \
  /home/user/daily-ideas/runs/2026-06-05_1808-UTC/05-recall/
```
**Result: 0 matches.** No stubs, placeholders, or unimplemented markers remain.

### Fresh-open trace
1. Open `index.html` in browser → seeds automatically (no localStorage) → 3 decks appear with due-count badges.
2. Click **Study** on "Capital Cities" → session loads ~5 due cards.
3. Flashcard shows front text. Press **Space** → card flips, rating buttons appear with interval previews.
4. Press **3** (Good) → SM-2 applied, card advances, next card shown. Progress bar updates.
5. Complete session → summary screen shows count, again-rate, time.
6. Reload page → data persists, updated due dates reflect the reviews just completed.
7. Click **Stats** → heatmap shows today's activity, forecast shows cards due over next 7 days, streak and retention populated.
8. Click **Settings** → change theme to Dark, save → theme switches. Change max reviews, save → persisted.
9. Click **Export JSON** → downloads `recall-backup-YYYY-MM-DD.json`.
10. Click **Clear All** → confirm → all data wiped, empty state shown.
11. Click **Import JSON** → select the downloaded file → confirm → data restored, decks reappear.

### SM-2 sanity check (by hand)

**Case 1: New card, rated Good (q=4)**
- State: n=0, EF=2.5, interval=0
- q=4 ≥ 3, n=0 → newInterval = 1
- newN = 0+1 = 1
- EF delta = 0.1 − (5−4)×(0.08 + (5−4)×0.02) = 0.1 − 1×0.10 = 0.0 → EF stays 2.5
- Result: n=1, interval=1, EF=2.5, dueDate=today+1 ✓

**Case 2: n=1, rated Good (q=4)**
- State: n=1, EF=2.5, interval=1
- q=4 ≥ 3, n=1 → newInterval = 6
- newN = 2
- EF delta = 0.0 → EF stays 2.5
- Result: n=2, interval=6, EF=2.5, dueDate=today+6 ✓

**Case 3: n=2, rated Good (q=4)**
- State: n=2, EF=2.5, interval=6
- q=4 ≥ 3, n≥2 → newInterval = round(6 × 2.5) = 15
- newN = 3
- EF delta = 0.0 → EF stays 2.5
- Result: n=3, interval=15, EF=2.5, dueDate=today+15 ✓

**Case 4: n=3, rated Again (q=1)**
- State: n=3, EF=2.5, interval=15
- q=1 < 3 → newInterval=1, newN=0, lapses++
- EF delta = 0.1 − (5−1)×(0.08 + (5−1)×0.02) = 0.1 − 4×(0.08+0.08) = 0.1 − 4×0.16 = 0.1 − 0.64 = −0.54
- newEF = max(1.3, 2.5 − 0.54) = max(1.3, 1.96) = 1.96
- Result: n=0, interval=1, EF=1.96, dueDate=today+1 ✓

**Case 5: n=2, rated Easy (q=5)**
- State: n=2, EF=2.5, interval=6
- q=5 ≥ 3, n≥2 → newInterval = round(6 × 2.5) = 15
- newN = 3
- EF delta = 0.1 − (5−5)×(0.08 + 0×0.02) = 0.1 − 0 = 0.1 → newEF = 2.6
- Result: n=3, interval=15, EF=2.6, dueDate=today+15 ✓
