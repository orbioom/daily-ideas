# Quiet Counter

Track exactly one metric per day — one number, beautifully displayed, with a 30-day heatmap.

## The Idea

Most productivity dashboards overwhelm you with metrics. Quiet Counter enforces a strict one-thing
philosophy: one number, one day, one name. You choose what you're counting (words written, focus
minutes, pages read — or anything custom), and the screen gives you a large, unhurried number that
fills your attention without demanding anything.

The 30-day heatmap appears below, rendered in the Orbioom live green, showing density but never
lecturing. A good day glows a little more. A missed day is just absence, not failure.

## How to Run

Open `index.html` in any browser. All data persists in `localStorage`.

**Controls:**
- `+` button / `=` key: increment by 1
- `−` button / `-` key: decrement by 1
- **set**: enter any number directly
- Click the metric name to rename it
- Switch between presets (words / focus minutes / pages / custom) using the chips

## Orbioom Feeling

Large ink number dominates the glass panel — the number IS the product. Heatmap uses live green
(#86C79A) with opacity-mapped intensity: no legend, no axis, no numbers. Just presence and absence.
Click the metric name to rename it inline, no modal, no form. Everything is considered, nothing shouts.
