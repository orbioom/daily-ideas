# Envelope — Zero-Based Budget · Orbioom

A calm, precise monthly budgeting tool that uses the envelope method: every unit of income gets assigned to a spending category before the month begins. When you open it, your money already has a job.

## Features (all implemented and working)

**Budget management**
- Create, edit, and delete budget envelopes with name, emoji icon, monthly amount, group, and optional rollover-unused flag
- Envelopes are organized into named groups (Essentials, Lifestyle, Savings, or custom)
- Rollover envelopes carry unspent balances forward into subsequent months

**Dashboard**
- "To Be Budgeted" hero number — income minus total budgeted, with zero/over/under visual states
- Per-envelope progress bars showing budgeted, spent, and remaining for the current month
- Overspend highlighted clearly per envelope
- Group-level totals

**Transactions**
- Full create/edit/delete for income, expense, and transfer transactions
- Filterable by account, envelope, and type; sortable by date, payee, amount, or type
- Each transaction linked to an account; expenses optionally linked to an envelope
- Transfers move balance between two accounts

**Accounts**
- Checking, savings, and cash account types
- Live computed balance = starting balance ± all transactions across all months

**Reports**
- Donut chart (canvas) showing spending by group
- Bar chart (inline SVG) with group spending totals
- Top envelopes by spending with progress bars
- Month summary: income, total spent, net, to-be-budgeted

**Month navigation**
- Previous/next month controls in sidebar
- All figures recompute per selected month
- Click month label to return to current month

**Settings**
- Currency symbol, first-day-of-month, theme (light/dark/system), reduced-motion
- All settings persisted and immediately applied

**Data**
- Export full budget to JSON (round-trip importable) or transactions to CSV
- Import JSON to restore a previous export
- Reset to built-in sample data at any time
- Clear all data with confirmation

**Seed data**
- 3 accounts, 9 envelopes across 3 groups, 25 transactions across current and previous month
- Pre-loaded on first open so the app is usable immediately

## Running the app

Open `index.html` in any modern browser (Chrome, Firefox, Safari, Edge). No server, no build step, no account required.

```
open index.html
# or drag the file into your browser
```

The app uses classic `<script>` tags so it works via `file://` without a local server. If you encounter any browser security policy that blocks local scripts, start a local server with:

```
python3 -m http.server 8080
# then open http://localhost:8080
```

**Font note:** Manrope and JetBrains Mono are loaded from Google Fonts. Without an internet connection they degrade gracefully to system-ui and ui-monospace respectively — all functionality is preserved.

## Data & Privacy

All data is stored exclusively in your browser's localStorage under the key `envelope_budget_v1`. Nothing is sent to any server. There is no account, no analytics, no network dependency at runtime.

**To back up your data:** Settings → Export JSON  
**To restore a backup:** Settings → Import JSON  
**To start fresh:** Settings → Clear All Data  
**To see a demo:** Settings → Reset to Sample Data

localStorage data survives browser restarts but may be cleared if you use private/incognito mode or clear browser storage. Export regularly for safety.

## Tech & Accessibility

**Stack:** Plain HTML5, CSS custom properties, vanilla JS — no framework, no bundler, no CDN dependencies at runtime. Works offline once loaded.

**Accessibility guarantees:**
- Semantic landmarks: `<aside>`, `<nav>`, `<main>`, `<header>`, `<section>`
- Every interactive element is a `<button>`, `<input>`, `<select>`, or `<label>` — no div-click traps
- All inputs have associated `<label>` elements
- Modal dialogs trap focus correctly and restore on close; Esc closes any open modal
- Visible focus rings on all interactive elements
- `aria-live` regions on the "To Be Budgeted" figure and toast notifications
- `aria-current="page"` on active navigation items
- `aria-modal="true"` and `role="dialog"` on all modals
- `role="progressbar"` with `aria-valuenow/min/max` on envelope progress bars
- Contrast: all text meets WCAG AA (4.5:1 body, 3:1 large) in both light and dark themes
- Touch targets: all buttons ≥ 44×44px
- Responsive from ~360px to wide desktop with no horizontal scroll
- Honors `prefers-reduced-motion` and the in-app reduced-motion toggle

**Charts:** Drawn natively with Canvas 2D (donut) and inline SVG strings (bar chart, top envelopes). No external chart library.

## Self-Review

**Anti-stub scan result:** Clean. The following command returns no output:

```
grep -rniE "TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub" \
  /home/user/daily-ideas/runs/2026-06-05_1808-UTC/04-envelope/
```

**Fresh-open run trace verified:**
1. `index.html` opens → `storage.js`, `seed.js`, `charts.js`, `app.js` load in order
2. `Storage.load()` returns empty state → `Seed.buildSeedData()` fires → state is saved to localStorage
3. Dashboard renders with hero TBB, grouped envelopes with progress bars, month label
4. Month prev/next buttons recompute all figures correctly
5. "+ Envelope" opens modal → validation rejects empty name and negative amounts → save persists and re-renders
6. "+ Transaction" opens modal → type switch shows/hides envelope/to-account rows → save persists
7. Transactions view loads with filters and sort controls all functional
8. Accounts view shows computed balances
9. Reports view draws donut canvas and SVG bar chart
10. Settings save → theme/currency/motion apply immediately → export JSON downloads a valid file → import JSON round-trips correctly
11. Reset to Sample restores 25 transactions; Clear All leaves empty state with guidance CTA
12. Reload after any action restores exactly the state left

**Data flow confirmed:** create → `Storage.save()` → reload calls `Storage.load()` with tolerant decode → all entities pass sanitization → rendered identically. No undefined references found. No functions return dummy data.
