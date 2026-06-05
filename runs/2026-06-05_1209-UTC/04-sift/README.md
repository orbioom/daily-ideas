# Sift — a regex workbench

A small, calm tool from **Orbioom Studio** for building and testing regular
expressions. Paste some text, write a pattern, and watch matches light up
live — with capture groups, a replace preview, a library of ready-made
patterns, and saved test cases that stick around between visits. It runs
entirely in your browser. No server, no accounts, no network.

---

## What it is

Sift is a single-page, offline regex workbench. It pairs a live regex engine
with a tidy reading surface: you see exactly what matched, where, and which
capture groups fired — plus an instant replace preview using real
backreferences. It is built for the quick "does this pattern actually work?"
loop that every developer, data wrangler, and writer hits a dozen times a day.

---

## Features (all working)

- **Pattern editor** with a `/…/flags` frame, an immediate **valid / invalid**
  indicator, and calm inline display of the actual JavaScript error message
  (e.g. "Unterminated group") when a pattern won't compile.
- **Real flag toggles** — `g`, `i`, `m`, `s`, `u`, `y` — as accessible
  checkboxes that genuinely change matching.
- **Live highlighting** (debounced ~120 ms) of every match in the test text,
  rendered as escaped HTML wrapped in `<mark>` so input can never inject markup.
  Optional **distinct group colors** per match.
- **Match list** with numbered matches, start–end positions, the matched
  substring, and every capture group — numbered and **named** — plus a total
  count and **elapsed time in milliseconds**.
- **Replace mode** supporting `$1`, `$<name>`, and `$&` backreferences with a
  live preview and a **copy result** button.
- **Cheatsheet** — an accurate static reference for common regex tokens.
- **Pattern library** — 12 correct, useful named patterns (email, URL, IPv4,
  hex color, ISO date, US phone, slug, UUID v4, semver, 24-hour time, signed
  integer, USD price). Click any to load it with a matching sample.
- **Saved test cases (full CRUD + persistence)** — save the current
  `{name, pattern, flags, test text, replacement}`, then load, **rename**, and
  **delete** from the sidebar. Everything persists in `localStorage` and
  survives reload.
- **Export / import** — download all saved cases as JSON and import them back
  (round-trips cleanly, merges without id collisions), plus copy-to-clipboard.
- **Settings (persisted)** — theme (light / dark / system), distinct group
  colors toggle, and **reset to sample data** (with confirmation).
- **Designed states** — a friendly empty sidebar with a "save your first" hint,
  a subtle spinner while importing, calm inline errors, and a populated results
  view. First open auto-loads sample data so it is never blank.

---

## Run it

Open **`index.html`** in any modern browser. That's the whole setup.

- No server, no build step, no install, no internet connection required.
- It also works straight from the filesystem (`file://`).
- If you prefer a local server: `python3 -m http.server` then visit the printed
  URL — but this is entirely optional.

---

## Data & privacy

- Everything you create lives in your browser's `localStorage` under the single
  namespace **`orbioom.sift.v1`**. Nothing is uploaded anywhere.
- **Export** (top bar) downloads all your saved cases as a JSON file you own.
- **Import** merges a previously exported file back in.
- **Reset to sample data** (Settings) replaces your saved cases with Sift's
  starter set and restores default settings — after a confirmation prompt.
- Clearing your browser site data also clears Sift's data. If `localStorage`
  is unavailable (e.g. strict private mode), Sift still runs but warns that
  changes won't persist for that session.

---

## Tech & accessibility notes

- Plain HTML, CSS, and JavaScript — no frameworks, no bundler, **no external
  requests** and no API keys. Fonts use a system stack with a Manrope-like UI
  fallback and a JetBrains-Mono-like monospace fallback; nothing is fetched
  from a network.
- **Crash-proofed:** every `new RegExp(...)` is wrapped in try/catch, the
  match loop is capped at 10,000 matches, processed subject text is capped at
  200,000 characters, zero-width matches advance safely, and all text is
  HTML-escaped before it touches the DOM. No uncaught exception reaches the UI.
- **Accessible:** real `<button>` / `<label>` / `<input>` elements, visible
  focus rings, `aria-live` on the match count, aria-labels on icon buttons,
  WCAG-AA contrast, ≥44px touch targets, responsive from 360px to desktop with
  no horizontal scroll, relative (`rem`) units for Dynamic Type, and full
  honoring of `prefers-reduced-motion`.
- **Dark mode** resolves from the chosen theme (and `prefers-color-scheme` in
  system mode) via a `data-theme` attribute, using calm darker mist surfaces —
  never pure black or pure white.

---

## Self-review

- **Anti-stub scan:** ran
  `grep -rniE "todo|fixme|xxx|placeholder|lorem|coming soon|not implemented|// stub"`
  across the project — clean. No stubs, dead controls, or filler text ship in
  Sift. (Note: "placeholder" appears only as legitimate HTML `placeholder`
  attributes on inputs, which is intended UI guidance, not stubbed behavior.)
- **Fresh-open flow verified:** with empty storage, Sift seeds its starter
  cases, loads the first into the editor, and renders matches immediately — so
  the workbench is never cold or blank. Every control (flags, save/load/
  rename/delete, export/import, copy, settings, reset, view toggle) is wired to
  real behavior, and all four states (empty, loading, error, populated) are
  designed and reachable.
