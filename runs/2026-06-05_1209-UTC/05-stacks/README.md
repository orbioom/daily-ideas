# Stacks

A personal library catalog by the Orbioom studio. Catalog the books you own and read, organize them into shelves, track reading status and sessions, rate and review, and watch your reading stats build over time. Entirely local, entirely private — no accounts, no servers, no network.

## What it is

Stacks is a static web app for tracking a real book collection. It models three related entities — **Books**, **Shelves** (collections), and **Reading Sessions** — and ties them together so the catalog behaves like a tool you would actually use day to day. Every book is rendered with a brand-tinted faux spine/cover (no external images), so the library reads at a glance.

## Full feature list

- **Library view** — books as glass cards with a colored spine, title, author, year, status badge, shelf chips, star rating (for finished books), and a live progress bar for books you're reading. Grid or list layout; comfortable or compact density.
- **Search, filter, sort** — search by title/author; filter by status, shelf, and genre; sort by recently added, title, author, year, or rating. A one-tap Clear resets everything.
- **Add / edit / delete books** — a validated form (title and author required and trimmed; year and pages numeric and bounded; rating 0–5). Pick a cover color from the brand palette and assign shelves inline. Delete with a confirm step.
- **Book detail** — full metadata, review, progress, and the complete list of that book's reading sessions. Quick actions: change status, update progress (which can auto-log a session), log a session, edit, or delete.
- **Shelves** — create, rename, recolor, and delete shelves (color picker from the brand palette). Assign/unassign books, filter the library by shelf, and jump straight from a shelf to its books. Deleting a shelf unassigns its books cleanly — it never deletes books.
- **Reading sessions** — log pages read, optional minutes, optional note, on any date up to today. Updating progress can create a session automatically. Reaching the last page prompts you to mark the book finished. List and delete sessions per book.
- **Stats dashboard** — total books, finished this year, total pages read (summed from sessions), time logged, average rating, a books-by-status bar chart, an inline-SVG status donut, and your current reading streak (consecutive days with a session, with a special accent at the one-week milestone). All computed live from your data.
- **Export / import** — export the whole library as formatted JSON (round-trips back via import with shape validation) and export the book list as CSV for spreadsheets.
- **Settings (persisted)** — theme (light / dark / system), default library sort, view density, plus "reset to sample library" and "clear all data," each behind a confirm.
- **Designed states** — purpose-built empty states per view, a subtle loading affordance on import, inline human validation messages, and calm error handling for bad imports (no crashes).

## Run

No build, no dependencies, no server. Just open the file:

1. Open `index.html` in any modern browser (Chrome, Firefox, Safari, Edge).
2. On first open, Stacks seeds a realistic sample library so it's never blank.

That's it. You can also serve the folder with any static file server, but it isn't required.

## Data & privacy

- All data lives in your browser's `localStorage` under the key `orbioom.stacks.v1`. Nothing is ever sent anywhere — there is no network code, no analytics, no accounts.
- Because data is per-browser and per-device, use **Settings → Export JSON** to back up or move your library. **Import JSON** restores it (and validates the shape before replacing anything).
- **Reset to sample** restores the starter collection; **Clear all data** wipes every book, shelf, and session (settings are kept). Both ask for confirmation first.
- Clearing your browser's site data will erase your library, so keep a JSON export if it matters to you.

## Tech & accessibility

- Plain HTML, CSS, and vanilla JavaScript — `index.html`, `styles.css`, `app.js`, `storage.js`, `seed.js`. No frameworks, no CDNs, no API keys. Fully offline.
- Fonts use a system stack (Manrope-like sans for UI, JetBrains-Mono-like mono for numbers, years, pages, IDs, and dates) with no network `@import`.
- Storage layer decodes tolerantly: missing or legacy fields fall back to sane defaults, dangling references are pruned, and reads never throw.
- Accessibility: semantic landmarks, a skip link, `aria-live` on counts and stats, `aria-label`s on icon buttons, visible focus rings, modals that trap and restore focus and close on Esc, ≥44px touch targets, WCAG-AA contrast in both themes, responsive from 360px to desktop, relative units for Dynamic Type, and `prefers-reduced-motion` honored. All user text is escaped before it enters the DOM.
- Real dark mode via `[data-theme]` plus `prefers-color-scheme`, with calm dark surfaces and light text; every brand token resolves in both modes.

## Self-review

- **Anti-stub scan clean.** A case-insensitive scan for `todo`, `fixme`, `xxx`, `placeholder`, `lorem`, `coming soon`, `not implemented`, and `// stub` across all source files returns nothing. There are no dead buttons, no unfinished branches, and no fake data beyond the intentional starter library in `seed.js`.
- **Flow verified.** Add → edit → assign to shelf → update progress (auto-logs a session) → reach the last page → finish prompt → rate/review → stats update; shelf delete unassigns without deleting books; export → clear → import round-trips; theme/sort/density/view persist across reloads; bad import is handled with a calm message and no crash; every division guards against a zero page count.
