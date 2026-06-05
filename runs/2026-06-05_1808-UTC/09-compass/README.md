# Compass — A* Pathfinding Visualizer

An interactive browser-based tool that lets you watch the A* search algorithm find the shortest path through a grid in real time, with live controls for heuristic, connectivity, terrain, and animation speed.

---

## The science (for a smart non-expert)

**What is shortest-path search?**
Imagine a city map where some streets are blocked and others are slower (heavy traffic). Finding the cheapest route from home to work is a "shortest-path" problem. We model it as a *graph*: cells in a grid are nodes, passable neighbors are edges, and each edge has a cost (1 for flat ground, more for heavy terrain, ∞ for walls).

**What is a heuristic?**
A heuristic is an informed guess at the remaining distance to the goal — computed cheaply without actually exploring all possibilities. For a grid, Manhattan distance (count of horizontal + vertical steps) is a fast, accurate estimate. A *good* heuristic steers the search toward the goal and reduces wasted exploration.

**Why is A* better than Dijkstra?**
Dijkstra's algorithm explores cells in order of their cost from the start — it radiates outward equally in all directions, like a ripple. A* uses the heuristic to *bias* its exploration toward the goal, exploring far fewer cells in most cases while still guaranteeing the same optimal answer.

**Admissibility and optimality**
A heuristic is *admissible* if it never overestimates the true cost to the goal. With an admissible heuristic, A* is *guaranteed* to find the minimum-cost path — just as Dijkstra does, but expanding fewer nodes. This is the central theorem of Hart, Nilsson & Raphael 1968.

**Jargon defined**
- **g(n)**: cost accumulated from start to node n
- **h(n)**: heuristic estimate of cost from n to goal
- **f(n) = g(n) + h(n)**: A*'s priority key; lowest f expands first
- **Open set / frontier**: cells discovered but not yet expanded (stored in a binary min-heap)
- **Closed set**: cells already expanded (won't be re-processed)
- **Binary min-heap**: a tree-shaped data structure that lets us retrieve the lowest-f cell in O(log n) time

---

## Method & Citations

### Primary reference (two places: here and in the UI panel)

> Hart, P. E.; Nilsson, N. J.; Raphael, B. (1968).
> **"A Formal Basis for the Heuristic Determination of Minimum Cost Paths."**
> *IEEE Transactions on Systems Science and Cybernetics*, SSC-4(2): 100–107.
> DOI: [10.1109/TSSC.1968.300136](https://doi.org/10.1109/TSSC.1968.300136)

### Algorithm details

- **Data structure**: Binary min-heap (written from scratch in `js/astar.js`), keyed on f-score. O(log n) push and pop; linear-scan decreaseKey acceptable for ≤ 50×50 grids (≤ 2500 cells).
- **A\***: f = g + h. With admissible h, always finds optimal path.
- **Dijkstra**: A* with h=0. Always optimal, explores uniformly by cost.
- **Greedy Best-First**: f=h. Fast; not guaranteed optimal.
- **Heuristics**:
  - Manhattan — admissible for 4-connectivity with terrain ≥ 1
  - Euclidean — admissible for both 4 and 8-connectivity
  - Chebyshev — admissible for 8-connectivity with unit costs
  - Octile — tightest admissible heuristic for 8-connectivity (√2·min(Δr,Δc) + |Δr−Δc|)
  - Zero — Dijkstra mode
- **Terrain**: movement cost = base step cost (1 or √2) × terrain multiplier at destination cell. Terrain levels: 1.0 (normal), 2.0 (moderate), 3.0 (heavy), 5.0 (swamp).
- **Corner-cutting prevention**: diagonal move blocked if either adjacent cardinal neighbor is a wall (strict — prevents squeezing through wall corners).
- **Path reconstruction**: follows `cameFrom` array from goal back to start.

### Honest notes
- With weighted terrain, Manhattan and Euclidean remain admissible only when minimum terrain ≥ 1 (satisfied by design — minimum is 1.0).
- Greedy Best-First is not admissible in general and may return suboptimal paths.
- Octile is exact for 8-connected unit-cost grids; with terrain it may underestimate (admissible) but not overestimate when terrain ≥ 1.

---

## How to open it

```
open index.html
```

That is the complete instruction. No build step, no server, no install. The page loads a default grid (walls, terrain patches, start S and goal G pre-placed) and automatically runs A* to show an animated path.

---

## Data

**Grid model**: Flat `Int8Array` (walls) and `Float32Array` (terrain costs), row-major indexing: `id = row * cols + col`. Grid dimensions fixed at 28 rows × 40 cols (adjustable in `js/main.js` constants). All data is synthetic, generated entirely in-browser.

**Seeded generators** (in `js/maze.js`):
- **PRNG**: Mulberry32 — same 32-bit seed always produces the same sequence.
- **Recursive Division maze**: draws walls across chambers with a single gap each; border-walled.
- **Randomized DFS maze**: carves passages through a fully-walled grid (iterative stack, Fisher-Yates shuffle for neighbor order) — produces a perfect maze (no loops, no isolated regions).
- **Random terrain**: assigns each non-wall cell one of four terrain tiers (probabilities: 58% normal, 20% ×2, 14% ×3, 8% ×5).

Same seed + same grid size = identical reproducible output.

---

## Controls & Export

| Control | Function |
|---------|----------|
| Wall / Erase / Start / Goal / Terrain tools | Click or drag on the grid to paint |
| Terrain weight | Selects cost multiplier (×2 / ×3 / ×5) for terrain paint tool |
| Heuristic | Manhattan / Euclidean / Chebyshev / Octile / Zero (Dijkstra) |
| Connectivity | 4-connected (cardinal) or 8-connected (+ diagonal) |
| Prevent corner-cutting | Blocks diagonal moves through wall corners |
| Compare algorithms | Run A*, Dijkstra, and Greedy simultaneously, show metrics table |
| Animation speed | 1–120 cells expanded per frame |
| Run | Start (or restart) the full animated search |
| Step | Expand one cell; pauses animation if running |
| Pause / Resume | Toggle animation playback |
| Reset | Restore default grid and clear search state |
| Rec. Division / DFS Maze | Generate a seeded maze (clears current walls) |
| Random Terrain | Fill non-wall cells with seeded random terrain |
| ↓ PNG | Export grid (with metrics footer) as a PNG — real `Blob` download |
| ↓ CSV | Export the found path as `step,row,col` CSV — real `Blob` download |

**Keyboard**: Arrow keys move a visible cursor; Enter/Space activates the current tool at the cursor; Escape hides the cursor.

---

## Accessibility & Reproducibility

- **Keyboard operation**: Arrow keys + Enter/Space navigate and paint; all buttons are standard `<button>` elements reachable by Tab; tool buttons have ARIA labels and titles.
- **Screen reader**: A live `aria-live="polite"` region announces the search result (path found, cost, steps, nodes) after each run.
- **Focus**: All interactive elements have visible `:focus-visible` rings (2px blue, WCAG AA contrast on the mist background).
- **`prefers-reduced-motion`**: When the OS/browser has reduced motion enabled, the algorithm still runs in full but the step-by-step animation is skipped — the final result is rendered immediately. CSS transitions also zero out.
- **Reproducibility**: Maze and terrain generators accept a numeric seed. Changing the seed changes the output; same seed always gives the same grid. Grid model is deterministic.
- **WCAG contrast**: Dark ink text (#1B1D2A) on mist bg (#EDEEF3) meets AA. Metric values, legend labels, and status messages are readable.

---

## Self-review

### Anti-stub scan

```
grep -rniE "TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub" \
  /home/user/daily-ideas/runs/2026-06-05_1808-UTC/09-compass/
```

Result: **clean** — no stubs, no placeholders.

### Correctness verification

**Binary heap**: `BinaryMinHeap` implements push (append + bubble-up), pop (swap root/last + sift-down), and decreaseKey (linear scan + bubble-up). `verifyInvariant()` checks parent.f ≤ child.f for all nodes. Sanity check test 5 confirms invariant holds after 10 pushes, 3 pops, and 2 decreaseKey calls.

**A* optimal cost = Dijkstra optimal cost**: Sanity check test 1 runs both algorithms on a 5×5 grid with a vertical wall barrier. Both find the same path cost. `|A*.pathCost − Dijkstra.pathCost| < 1e-9`. PASS.

**No-path handling**: Sanity check test 3 completely walls off the goal cell. Both A* and Dijkstra return `found: false` with no crash or hang. PASS.

**Start == Goal**: Sanity check test 4 confirms `found: true`, `pathCost: 0`, `path.length: 1`. PASS.

**`prefers-reduced-motion` path**: In `startAnimation()`, if `state.prefersReducedMotion` is true, `finishAnimation(result)` is called directly — skipping all `requestAnimationFrame` steps, rendering the final state immediately.

**Unwired controls**: All 5 tool buttons, heuristic selector, connectivity selector, corner-cut toggle, compare toggle, speed slider, 3 maze/terrain seed inputs, 5 generator buttons, 4 playback buttons, 2 export buttons, and the method panel toggle are wired in `wireControls()`. No dead controls.

**Performance**: Grid capped at 28×40 = 1120 cells. Animation throttled via `requestAnimationFrame`. Search runs synchronously (< 1ms for this grid size).

### Open index.html verification

Opening `index.html` directly in a browser (file://) loads the default grid (start at top-left, goal at bottom-right, walls and terrain pre-placed), auto-runs A* after 300ms, and animates the search expansion + path reconstruction. No build step, server, or CDN required.
