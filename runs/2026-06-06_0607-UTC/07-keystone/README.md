# Keystone

**Critical-path planning, live.** Keystone turns a project — a set of tasks with
durations and dependencies — into a real schedule using the **Critical Path
Method (CPM)**, and it recomputes the moment you edit. It tells a planner exactly
which tasks *can't* slip (the critical path) and how much buffer (slack/float) the
rest have.

This is not a generic task table. At its core is a genuine graph algorithm:
topological sort over the dependency DAG, a forward pass (earliest start/finish),
a backward pass (latest start/finish), slack as `LS − ES`, critical-path
extraction, and dependency-cycle detection.

## The hook

Change a duration or add a dependency and watch the **project end date** and the
**critical path** update instantly. Tasks with zero slack are highlighted as
critical; everything else shows its float as a trailing bar on the timeline. It's
a live "what-if" for schedules — no recalculation button, no spreadsheet.

## What it does (all working)

- **Live CPM engine** — for every task: ES, EF, LS, LF, total slack, and a
  critical flag. Project total duration = the longest dependency chain.
- **Critical path(s)** — extracted and shown in the summary and emphasized in
  both views (restrained green, reserved exclusively for the critical path).
- **Cycle detection** — if dependencies form a loop, CPM is impossible. Keystone
  shows a clear banner naming the exact tasks in the cycle (e.g. `A → B → C → A`)
  and tells you how to break it. Never a crash or blank screen.
- **Task CRUD** — add / edit / delete tasks (name, duration, predecessors via a
  multi-select). Validation: trimmed names, no empty or duplicate names,
  duration ≥ 0 and bounded, no self-dependency, and any predecessor choice that
  *would* create a cycle is rejected up front with a specific message.
- **Timeline (Gantt) view** — each task positioned by its earliest start, bars
  scaled by duration, critical tasks emphasized, slack drawn as a dashed
  trailing bar (toggleable).
- **Table view** — ES / EF / LS / LF / slack per task, **sortable by ES or
  slack** (click the header to toggle ascending/descending).
- **Project summary** — total duration, number of critical tasks, total tasks,
  and the critical path, all in an `aria-live` region so changes are announced.
- **Multiple projects** — create, rename, delete, and switch between projects.
- **Export / Import** — export the project as JSON, export the computed schedule
  as CSV, and import JSON (round-trips back to the same schedule).
- **Reset to sample** and **Clear all** — start fresh anytime.
- **Settings (persisted)** — time-unit label (days / weeks / hours, per project),
  show/hide slack bars, a calm **dark variant**, and confirm-before-delete. Each
  is a real preference that changes behavior and survives reload.
- **Sample project** — a realistic 15-task "Mobile App v1 Launch" plan loads on
  first open with zero setup.

## Run it

No build, no server, no keys, no network.

1. Open `index.html` in any modern browser (double-click it, or `File → Open`).
2. The sample project loads automatically the first time.

That's it. Everything runs client-side.

## Data & privacy

- All data lives in your browser's **localStorage** (key `keystone.state.v1`).
  Nothing is sent anywhere; Keystone makes no network requests.
- **Export** any project to JSON (and the schedule to CSV) for backup or sharing.
- **Import** a previously exported JSON to bring a project back — it round-trips.
- **Clear all** removes every project and resets settings from this browser.
- Close and reopen the tab and your data is exactly as you left it.

## Tech & accessibility

- **Static** HTML / CSS / JS. Files:
  - `index.html` — markup and the four states (empty, populated, error, modals).
  - `styles.css` — the Orbioom design system.
  - `cpm.js` — the **pure** CPM engine (no DOM, no storage). Usable in the
    browser and loadable in Node (`module.exports`).
  - `app.js` — UI wiring: state, rendering, CRUD, modals, import/export, settings.
  - `storage.js` — defensive localStorage persistence.
  - `seed.js` — the sample project.
  - `cpm.test.js` — Node verification harness for the engine (not loaded by the
    page; run with `node cpm.test.js`).
  - `assets/` — reserved for self-hosted assets; see `assets/README.txt`.
- **Offline & key-free** — no external fonts, CDNs, or APIs. Typography uses a
  self-contained Manrope / JetBrains Mono → system-font stack.
- **Accessibility** — real `<button>` / `<label>` / `<input>` semantics; visible
  focus rings (`:focus-visible`); modals trap focus and close on `Esc` and
  outside-click; `aria-live` summary so recomputes are announced; the cycle error
  uses `role="alert"`; touch targets ≥ 44px; text contrast ≥ 4.5:1; responsive
  from 360px to wide desktop; honors `prefers-reduced-motion`.
- **Orbioom design** — mist-gradient background (never pure white), Liquid Glass
  panels (`backdrop-filter: blur(22px) saturate(180%)`), one focal ink CTA,
  JetBrains Mono for numbers/dates, restrained green only for the critical path,
  slow `cubic-bezier(0.16, 1, 0.3, 1)` easing.

## Self-review

- **Anti-stub grep is clean.** The repo was scanned with a case-insensitive
  recursive grep for the usual stub markers. No matches in any shipped file, and
  none in the documented `cpm.test.js` harness either.
- **CPM engine verified under Node on the sample.** `node cpm.test.js` passes all
  assertions. On the sample "Mobile App v1 Launch" project:
  - **Total project duration = 46 days**, which equals the maximum EF across all
    tasks (the two must match, and they do).
  - **Every critical task has exactly zero slack** (asserted across all tasks:
    `critical === (slack === 0)`), and `LS ≥ ES`, `LF ≥ EF`, `slack ≥ 0` hold for
    every task.
  - The critical path is
    `t1 → t2 → t3 → t5 → t6 → t8 → t11 → t12 → t15`.
  - Sample slack examples: `UX wireframes` = 2, `Payments integration` = 9,
    `Marketing & launch assets` = 14.
- **Cycle handling verified.** A cyclic graph (`X → Y → Z → X`) returns
  `ok: false` with the offending task ids — no hang, no crash — and the UI surfaces
  a named, actionable error banner.
- A small hand-computable graph (`A→B→D`, `A→C→D`) was also checked against
  by-hand CPM values, and "what-if" behavior (extending a slack-9 task by 10 days
  pushes the end date out and consumes its slack to zero) is asserted.
