/**
 * maze.js — Seeded maze & terrain generators for Compass
 *
 * Algorithms:
 *   - Seeded PRNG: Mulberry32 (fast, high quality, 32-bit state)
 *     Reproducible: same seed + same grid size = identical output.
 *   - Maze: Recursive Division (walls with single gap per chamber)
 *   - Maze (alt): Randomized DFS (iterative stack, perfect maze — carves passages)
 *   - Terrain: Random weighted fill with 4 terrain levels
 *
 * All generators accept a numeric seed so the same seed + size
 * always produces the exact same result (reproducible).
 */

'use strict';

// ---------------------------------------------------------------------------
// Seeded PRNG — Mulberry32
// A fast, high-quality 32-bit PRNG by Tommy Ettinger.
// Returns floats in [0, 1). Deterministic for any given seed.
// ---------------------------------------------------------------------------
function createPRNG(seed) {
  let s = (seed | 0) >>> 0; // treat as uint32
  return function mulberry32() {
    s = (s + 0x6D2B79F5) >>> 0;
    let t = Math.imul(s ^ (s >>> 15), s | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// ---------------------------------------------------------------------------
// Shuffle array in-place using Fisher-Yates with the given PRNG
// ---------------------------------------------------------------------------
function shuffle(arr, rng) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    const tmp = arr[i]; arr[i] = arr[j]; arr[j] = tmp;
  }
  return arr;
}

// ---------------------------------------------------------------------------
// Recursive Division Maze
// Creates rooms by drawing walls across chambers, leaving exactly one gap.
// Result: a maze with walls and open corridors (not a perfect maze, but
// interesting and traversable).
// ---------------------------------------------------------------------------

/**
 * Generate a maze via recursive division.
 * @param {number} rows
 * @param {number} cols
 * @param {number} seed  - integer seed for reproducibility
 * @returns {Int8Array}  walls[r*cols+c] = 1 if wall
 */
function generateMazeRecursiveDivision(rows, cols, seed) {
  const walls = new Int8Array(rows * cols); // start open
  const rng = createPRNG(seed);

  // Outer border walls
  for (let c = 0; c < cols; c++) {
    walls[0 * cols + c] = 1;
    walls[(rows - 1) * cols + c] = 1;
  }
  for (let r = 0; r < rows; r++) {
    walls[r * cols + 0] = 1;
    walls[r * cols + (cols - 1)] = 1;
  }

  function divide(r1, c1, r2, c2) {
    // r1,c1 = top-left corner (inclusive), r2,c2 = bottom-right (inclusive)
    const height = r2 - r1 + 1;
    const width  = c2 - c1 + 1;

    // Stop when chamber is too small to meaningfully divide
    if (height < 3 || width < 3) return;

    // Choose orientation based on aspect ratio; tiebreak with PRNG
    let horizontal;
    if (height > width)       horizontal = true;
    else if (width > height)  horizontal = false;
    else                      horizontal = rng() < 0.5;

    if (horizontal) {
      // Draw horizontal wall; gap at a random column
      // Wall row is interior: between r1+1 and r2-1 (exclusive of edges)
      const wallRow = r1 + 1 + Math.floor(rng() * (height - 2));
      const gapCol  = c1 + Math.floor(rng() * width);
      for (let c = c1; c <= c2; c++) {
        if (c !== gapCol) walls[wallRow * cols + c] = 1;
      }
      divide(r1, c1, wallRow - 1, c2);
      divide(wallRow + 1, c1, r2, c2);
    } else {
      // Draw vertical wall; gap at a random row
      const wallCol = c1 + 1 + Math.floor(rng() * (width - 2));
      const gapRow  = r1 + Math.floor(rng() * height);
      for (let r = r1; r <= r2; r++) {
        if (r !== gapRow) walls[r * cols + wallCol] = 1;
      }
      divide(r1, c1, r2, wallCol - 1);
      divide(r1, wallCol + 1, r2, c2);
    }
  }

  // Divide the interior (excluding border)
  divide(1, 1, rows - 2, cols - 2);
  return walls;
}

// ---------------------------------------------------------------------------
// Randomized DFS (iterative) — Perfect Maze
// Carves passages through a fully-walled grid. Every pair of cells has
// exactly one path between them (perfect maze = no loops, no isolated areas).
// Works on a "room" grid where rooms are at odd-indexed cells and walls
// are at even-indexed cells between rooms.
// ---------------------------------------------------------------------------

/**
 * Generate a perfect maze using iterative randomized DFS.
 * @param {number} rows
 * @param {number} cols
 * @param {number} seed
 * @returns {Int8Array} walls[r*cols+c] = 1 if wall
 */
function generateMazeDFS(rows, cols, seed) {
  const walls = new Int8Array(rows * cols).fill(1); // start: everything walled
  const rng = createPRNG(seed);

  // Rooms live at odd indices; walls are between them at even indices
  const roomRows = Math.floor((rows - 1) / 2);
  const roomCols = Math.floor((cols - 1) / 2);

  if (roomRows < 1 || roomCols < 1) return walls; // grid too small

  const visited = new Uint8Array(roomRows * roomCols);
  const stack = [];

  // Map room (rr, rc) to grid cell
  function roomToGrid(rr, rc) {
    return { r: rr * 2 + 1, c: rc * 2 + 1 };
  }

  // Open a room cell in the wall grid
  function openRoom(rr, rc) {
    const { r, c } = roomToGrid(rr, rc);
    walls[r * cols + c] = 0;
  }

  // Open the wall between two adjacent rooms
  function openWall(rr1, rc1, rr2, rc2) {
    const g1 = roomToGrid(rr1, rc1);
    const g2 = roomToGrid(rr2, rc2);
    const wr = (g1.r + g2.r) >> 1;
    const wc = (g1.c + g2.c) >> 1;
    walls[wr * cols + wc] = 0;
  }

  const dirs = [[-1,0],[1,0],[0,-1],[0,1]];

  // Start DFS from room (0, 0)
  visited[0] = 1;
  openRoom(0, 0);
  stack.push([0, 0]);

  while (stack.length > 0) {
    const [rr, rc] = stack[stack.length - 1];

    // Find unvisited neighbors (shuffled for randomness)
    const candidates = [];
    for (const [drr, drc] of dirs) {
      const nrr = rr + drr, nrc = rc + drc;
      if (nrr >= 0 && nrr < roomRows && nrc >= 0 && nrc < roomCols &&
          !visited[nrr * roomCols + nrc]) {
        candidates.push([nrr, nrc]);
      }
    }
    shuffle(candidates, rng);

    if (candidates.length > 0) {
      const [nrr, nrc] = candidates[0]; // pick first shuffled candidate
      visited[nrr * roomCols + nrc] = 1;
      openRoom(nrr, nrc);
      openWall(rr, rc, nrr, nrc);
      stack.push([nrr, nrc]);
    } else {
      stack.pop(); // backtrack
    }
  }

  return walls;
}

// ---------------------------------------------------------------------------
// Random terrain weights (seeded)
// Assigns one of four terrain cost tiers to non-wall cells.
// ---------------------------------------------------------------------------

/**
 * Fill a terrain array with seeded random weights.
 * Terrain cost multipliers: 1.0 (normal), 2.0 (moderate), 3.0 (heavy), 5.0 (swamp)
 * @param {number}   rows
 * @param {number}   cols
 * @param {number}   seed
 * @param {Int8Array} [walls]  - optional; walls are left at 1.0 (irrelevant)
 * @returns {Float32Array}
 */
function generateRandomTerrain(rows, cols, seed, walls) {
  const terrain = new Float32Array(rows * cols).fill(1.0);
  const rng = createPRNG(seed);

  for (let i = 0; i < rows * cols; i++) {
    if (walls && walls[i]) continue; // don't overwrite walls
    const v = rng();
    if (v < 0.08)       terrain[i] = 5.0; // swamp      8%
    else if (v < 0.22)  terrain[i] = 3.0; // heavy     14%
    else if (v < 0.42)  terrain[i] = 2.0; // moderate  20%
    // else normal        terrain[i] = 1.0   58%
  }
  return terrain;
}

/**
 * Flat terrain — all cells weight 1.0 (no terrain variation).
 * @param {number} rows
 * @param {number} cols
 * @returns {Float32Array}
 */
function generateFlatTerrain(rows, cols) {
  return new Float32Array(rows * cols).fill(1.0);
}

// ---------------------------------------------------------------------------
// Export for classic <script> tag usage (file:// compatible, no bundler)
// ---------------------------------------------------------------------------
if (typeof window !== 'undefined') {
  window.MazeLib = {
    createPRNG,
    shuffle,
    generateMazeRecursiveDivision,
    generateMazeDFS,
    generateRandomTerrain,
    generateFlatTerrain
  };
}
