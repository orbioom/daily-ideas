# Chroma — Accessible Color Palette & Contrast Lab

An Orbioom studio tool for building color palettes and verifying their
accessibility. Define swatches, check WCAG contrast ratios between any
foreground/background pair, preview live text and a mock UI in those colors,
simulate color-vision deficiencies, generate harmonious scales, and export
design tokens.

Chroma is a single static page: no build step, no server, no network calls,
no CDN. Open the file and it works.

---

## The method (the real math)

The substance of Chroma is correct color science. All math lives in
`color.js` and is dependency-free.

### WCAG 2.1 relative luminance & contrast ratio

Per the W3C definitions
(<https://www.w3.org/TR/WCAG21/#dfn-relative-luminance>,
<https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio>):

1. Each 8-bit sRGB channel is normalized to `c ∈ [0,1]` then linearized:

   ```
   c_lin = c / 12.92                      if c ≤ 0.03928
   c_lin = ((c + 0.055) / 1.055) ^ 2.4    otherwise
   ```

2. Relative luminance:

   ```
   L = 0.2126·R_lin + 0.7152·G_lin + 0.0722·B_lin
   ```

3. Contrast ratio between two colors, with `L1` the lighter and `L2` the
   darker luminance:

   ```
   ratio = (L1 + 0.05) / (L2 + 0.05)
   ```

   The ratio ranges from 1:1 to 21:1. Chroma reports it formatted as
   `4.73:1` and evaluates the four WCAG thresholds:

   | Level         | Threshold |
   |---------------|-----------|
   | AA normal     | ≥ 4.5     |
   | AA large      | ≥ 3       |
   | AAA normal    | ≥ 7       |
   | AAA large     | ≥ 4.5     |

### Color-vision-deficiency simulation

CVD simulation uses the model of **Machado, Oliveira & Fernandes (2009),
"A Physiologically-based Model for Simulation of Color Vision Deficiency,"
IEEE Transactions on Visualization and Computer Graphics 15(6):1291–1298**.

Chroma applies the published **severity = 1.0 (dichromat)** 3×3 transformation
matrices for protanopia, deuteranopia, and tritanopia. The transform is
applied in **linear RGB**: each color is converted sRGB → linear (same
linearization as above), multiplied by the deficiency matrix, then converted
linear → sRGB for display. The exact matrices are in `color.js`
(`CVD_MATRICES`). This is the substance behind the "Simulate" mode — every
swatch, the contrast preview, and the live UI mock are re-rendered through the
selected matrix.

### Scale & harmony generation

- **Tint/shade scale (50–900):** the base color is converted to HSL and its
  hue and saturation are held fixed while lightness is mapped to fixed targets
  per step (96% down to 14%).
- **Harmonies:** computed by hue rotation in HSL — complementary (+180°),
  analogous (−30° / base / +30°), triadic (+120° / +240°).

---

## Features

1. **Palette builder (CRUD + persistence).** Add swatches by hex or by RGB and
   HSL sliders that stay in sync; name each, assign a UI role, reorder, edit,
   and delete. Manage multiple named palettes: create, rename, delete, switch.
   Everything persists to `localStorage` and survives reload.
2. **Contrast checker.** Pick any foreground/background from swatches (FG/BG
   buttons) or type custom hex; see a large monospace ratio (with an
   `aria-live` announcement), all four WCAG pass/fail badges, and a live text
   preview ("The quick brown fox") at normal and large sizes in those colors.
3. **CVD simulator.** Toggle protanopia / deuteranopia / tritanopia / none; the
   whole palette, contrast preview, and mock UI re-render through the selected
   matrix, with a one-line description of the deficiency.
4. **Scale & harmony generator.** Choose a base swatch; get a 50–900 tint/shade
   scale and complementary/analogous/triadic harmony sets. Click any generated
   color to add it to the palette.
5. **Live UI preview.** A glass mock card (heading, body, button) painted from
   the palette's `bg` / `surface` / `text` / `accent` roles, with its text
   contrast auto-checked and flagged if any pair fails AA.
6. **Export & import.** Copy or download CSS custom properties or JSON tokens,
   and download a PNG swatch sheet rendered to canvas. Import a JSON palette
   back — round-trips with the JSON export.
7. **Settings (persisted).** Theme light/dark/system, default export format,
   hex-vs-HSL display notation, "reset to sample palettes," and "clear all
   data" (both confirmed).

### States

- **Empty** (after Clear all): a designed empty state with "add a swatch" and
  "load sample palettes" paths. On a truly first open, sample palettes seed
  automatically.
- **Loading:** the PNG export button shows a "Rendering…" state while the
  canvas is drawn.
- **Error:** invalid hex shows an inline calm message and never crashes; bad
  import JSON gives a human-readable explanation.
- **Success:** copy/add/import actions show a confirmation toast.

---

## Run

Open `index.html` in any modern browser. That's it — no install, no build, no
server.

---

## Data & privacy

All data lives in your browser's `localStorage` under the key
`orbioom.chroma.v1`. Nothing is sent anywhere; there are no network requests,
analytics, or accounts. "Clear all data" removes the key entirely. If
`localStorage` is unavailable (e.g. private mode), Chroma falls back to an
in-memory store for the session and tells you so in the footer.

---

## Tech & accessibility

- **Stack:** vanilla HTML/CSS/JS in four modules — `color.js` (math),
  `storage.js` (persistence), `seed.js` (starter palettes), `app.js` (UI).
  No frameworks, no dependencies, no fonts fetched over the network (system
  font stack with Manrope-style UI and JetBrains-Mono-style fallback).
- **Accessibility:** real labelled inputs/buttons, visible focus rings,
  `aria-live` on the contrast ratio and status messages, `aria-label`s on every
  swatch control, full keyboard operation including a focus-trapped settings
  dialog, touch targets ≥ 44px, responsive from 360px to desktop, relative
  units throughout, and `prefers-reduced-motion` honored. The app's own chrome
  meets WCAG AA in both light and dark modes (real dark mode via `[data-theme]`
  plus `prefers-color-scheme`). Note: your palette colors are your own data —
  the brand tokens style the app chrome, not your swatches.

---

## Self-review

- **Anti-stub scan:** `grep -rniE "todo|fixme|xxx|placeholder|lorem|coming
  soon|not implemented|// stub"` over this directory is clean. (The word
  "placeholder" appears only as HTML `placeholder=` input hints, which are real
  UX, not stubs.)
- **Verified:** color math checked against known references — black on white is
  21.00:1, and `#777` on white ≈ 4.48:1 (just under AA), matching the WCAG
  formula. RGB↔HSL↔hex conversions round-trip. CVD matrices are the published
  Machado et al. severity-1.0 values applied in linear RGB. Invalid hex, empty
  palettes, corrupt stored JSON, bad import JSON, and unavailable storage are
  all handled without throwing. Every control in the UI is wired to real
  behavior and persistence; there are no placeholders or dead buttons.
