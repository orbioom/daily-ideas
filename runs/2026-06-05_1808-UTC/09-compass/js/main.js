/**
 * main.js — Compass: A* Pathfinding Visualizer
 * UI wiring, canvas rendering, animation loop, paint tools, export.
 *
 * Depends on: AStarLib (js/astar.js), MazeLib (js/maze.js)
 * No external dependencies. Works with file:// URLs.
 */

'use strict';

// ============================================================
// Constants & Configuration
// ============================================================
const GRID_ROWS = 28;
const GRID_COLS = 40;
const MIN_CELL  = 10; // minimum cell size in px
const MAX_CELL  = 32;

// Terrain visual tiers
const TERRAIN_COLORS = {
  1.0: null,           // normal — use cell base color
  2.0: '#C8B9A2',      // moderate — warm sandy
  3.0: '#A89270',      // heavy — medium brown
  5.0: '#7A6A55',      // swamp — dark muddy
};

// Color palette (Orbioom brand)
const COLORS = {
  bg:            '#EDEEF3',
  empty:         '#F4F5F8',
  emptyStroke:   '#D8DAE5',
  wall:          '#23262F',
  wallStroke:    '#1B1D2A',
  visited:       '#C5CBE8',   // closed/expanded — cool lavender
  visitedStroke: '#A8B0D8',
  frontier:      '#E8C96A',   // open set — warm amber
  frontierStroke:'#D4AE40',
  path:          '#86C79A',   // final path — Orbioom green (success)
  pathStroke:    '#5AAA78',
  pathGlow:      '#5EF0B0',   // magic flash moment
  start:         '#3A3E4C',   // ink dark
  startLabel:    '#FFFFFF',
  goal:          '#5EF0B0',   // magic green
  goalLabel:     '#1B1D2A',
  cursor:        '#5599FF',
};

// ============================================================
// State
// ============================================================
let state = {
  rows: GRID_ROWS,
  cols: GRID_COLS,

  // Grid data (flat arrays, row-major)
  walls:   null,  // Int8Array: 1 = wall
  terrain: null,  // Float32Array: cost multiplier

  startRow: 2,
  startCol: 2,
  goalRow:  GRID_ROWS - 3,
  goalCol:  GRID_COLS - 3,

  // Search results
  result: null,          // last full search result
  compareResults: null,  // { astar, dijkstra, greedy }

  // Animation state
  animFrame: null,
  animIndex: 0,          // current expansion step being shown
  animRunning: false,
  animDone: false,
  animPathShown: false,
  pathFlashT: 0,         // for path glow animation

  // What's drawn on canvas right now
  drawnExpanded: new Set(),
  drawnFrontier: new Set(),
  drawnPath: [],

  // Tool state
  activeTool: 'wall',    // 'start'|'goal'|'wall'|'terrain'|'erase'
  isPainting: false,
  lastPainted: null,
  terrainLevel: 3.0,     // terrain weight to paint

  // Settings
  heuristic:         'manhattan',
  eightConnected:    false,
  preventCornerCut:  true,
  animSpeed:         20,   // cells per frame
  compareMode:       false,

  // Keyboard cursor
  cursorRow: 2,
  cursorCol: 2,
  cursorVisible: false,

  // Seed state
  mazeSeed:    42,
  terrainSeed: 99,

  // Reduced motion
  prefersReducedMotion: false,

  // Status message
  statusMsg: '',
  statusOk:  true,

  // Sanity check result
  sanityOk: false,
};

// ============================================================
// DOM references (filled after DOMContentLoaded)
// ============================================================
let canvas, ctx;
let cellSize = 20;

const $ = id => document.getElementById(id);

// ============================================================
// Grid initialization
// ============================================================
function initGrid(rows, cols) {
  state.rows = rows;
  state.cols = cols;
  state.walls   = new Int8Array(rows * cols);
  state.terrain  = new Float32Array(rows * cols).fill(1.0);
}

function resetSearchState() {
  state.result = null;
  state.compareResults = null;
  state.animRunning = false;
  state.animDone = false;
  state.animPathShown = false;
  state.animIndex = 0;
  state.drawnExpanded = new Set();
  state.drawnFrontier = new Set();
  state.drawnPath = [];
  state.pathFlashT = 0;
  if (state.animFrame) {
    cancelAnimationFrame(state.animFrame);
    state.animFrame = null;
  }
}

// ============================================================
// Default scene: a visually interesting preloaded grid
// ============================================================
function loadDefaultScene() {
  const { rows, cols } = state;
  initGrid(rows, cols);

  // Place some walls to create an interesting maze-like structure
  const wl = [
    // Upper barrier with gap
    ...range(3, 8).map(c => [4, c]),
    ...range(10, 18).map(c => [4, c]),
    // Middle S-curve
    ...range(0, 22).map(r => [r, 12]).filter(([r]) => r !== 8 && r !== 9),
    ...range(14, 36).map(c => [14, c]).filter(([,c]) => c !== 25 && c !== 26),
    ...range(15, 28).map(r => [r, 25]),
    // Lower barrier
    ...range(20, 30).map(c => [22, c]).filter(([,c]) => c !== 21),
  ];

  for (const [r, c] of wl) {
    if (r >= 0 && r < rows && c >= 0 && c < cols) {
      state.walls[r * cols + c] = 1;
    }
  }

  // Random terrain clusters (seeded)
  const rng = MazeLib.createPRNG(state.terrainSeed);
  // A few terrain patches
  const patches = [
    { r:6,  c:14, w:6, h:5, cost:2.0 },
    { r:15, c:2,  w:8, h:6, cost:3.0 },
    { r:20, c:32, w:6, h:5, cost:5.0 },
    { r:10, c:28, w:5, h:4, cost:2.0 },
  ];
  for (const p of patches) {
    for (let r = p.r; r < Math.min(p.r + p.h, rows); r++) {
      for (let c = p.c; c < Math.min(p.c + p.w, cols); c++) {
        if (!state.walls[r * cols + c]) {
          state.terrain[r * cols + c] = p.cost;
        }
      }
    }
  }

  // Ensure start/goal are clear
  clearCell(state.startRow, state.startCol);
  clearCell(state.goalRow,  state.goalCol);

  resetSearchState();
}

function range(a, b) {
  const arr = [];
  for (let i = a; i < b; i++) arr.push(i);
  return arr;
}

function clearCell(r, c) {
  state.walls[r * state.cols + c] = 0;
  state.terrain[r * state.cols + c] = 1.0;
}

// ============================================================
// Canvas sizing
// ============================================================
function computeCellSize() {
  const panel = canvas.parentElement;
  const availW = panel.clientWidth  - 4;
  const availH = panel.clientHeight - 4;
  const byW = Math.floor(availW / state.cols);
  const byH = Math.floor(availH / state.rows);
  cellSize = Math.max(MIN_CELL, Math.min(MAX_CELL, byW, byH));
}

function resizeCanvas() {
  computeCellSize();
  const dpr = window.devicePixelRatio || 1;
  const w = state.cols * cellSize;
  const h = state.rows * cellSize;
  // Setting canvas.width resets the context transform completely
  canvas.width  = w * dpr;
  canvas.height = h * dpr;
  canvas.style.width  = w + 'px';
  canvas.style.height = h + 'px';
  // Re-apply DPR scale after the reset (safe to call once per resize)
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
}

// ============================================================
// Canvas rendering
// ============================================================
function render() {
  const { rows, cols, walls, terrain,
          startRow, startCol, goalRow, goalCol,
          drawnExpanded, drawnFrontier, drawnPath,
          cursorVisible, cursorRow, cursorCol } = state;

  // Build fast Set for path cell lookup (avoids O(path*cells) via Array.some)
  const pathSet = new Set(drawnPath.map(p => p.row * cols + p.col));

  // Clear logical area (ctx already has DPR scale applied)
  ctx.clearRect(0, 0, state.cols * cellSize, state.rows * cellSize);

  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const id = r * cols + c;
      const x = c * cellSize, y = r * cellSize;
      const cs = cellSize, cs1 = cellSize - 1;

      const isStart = r === startRow && c === startCol;
      const isGoal  = r === goalRow  && c === goalCol;
      const isWall  = walls[id];
      const isPath  = pathSet.has(id);
      const isFront = drawnFrontier.has(id);
      const isVis   = drawnExpanded.has(id);
      const terr    = terrain[id];

      // Background fill
      if (isWall) {
        ctx.fillStyle = COLORS.wall;
        ctx.fillRect(x, y, cs, cs);
        // Wall texture: subtle inner shadow
        ctx.fillStyle = 'rgba(0,0,0,0.18)';
        ctx.fillRect(x + 1, y + 1, cs - 2, cs - 2);
      } else if (isPath) {
        // Path cells — green gradient
        const grad = ctx.createLinearGradient(x, y, x, y + cs);
        grad.addColorStop(0, '#9FD4B0');
        grad.addColorStop(1, COLORS.path);
        ctx.fillStyle = grad;
        ctx.fillRect(x, y, cs, cs);
        // Glow flash if fresh path
        if (state.pathFlashT > 0) {
          ctx.fillStyle = `rgba(94,240,176,${state.pathFlashT * 0.4})`;
          ctx.fillRect(x, y, cs, cs);
        }
        ctx.strokeStyle = COLORS.pathStroke;
        ctx.lineWidth = 0.5;
        ctx.strokeRect(x + 0.5, y + 0.5, cs1, cs1);
      } else if (isFront) {
        ctx.fillStyle = COLORS.frontier;
        ctx.fillRect(x, y, cs, cs);
        ctx.strokeStyle = COLORS.frontierStroke;
        ctx.lineWidth = 0.5;
        ctx.strokeRect(x + 0.5, y + 0.5, cs1, cs1);
      } else if (isVis) {
        ctx.fillStyle = COLORS.visited;
        ctx.fillRect(x, y, cs, cs);
        ctx.strokeStyle = COLORS.visitedStroke;
        ctx.lineWidth = 0.5;
        ctx.strokeRect(x + 0.5, y + 0.5, cs1, cs1);
      } else {
        // Empty cell — terrain shading
        const terrColor = TERRAIN_COLORS[terr];
        ctx.fillStyle = terrColor || COLORS.empty;
        ctx.fillRect(x, y, cs, cs);
        ctx.strokeStyle = COLORS.emptyStroke;
        ctx.lineWidth = 0.5;
        ctx.strokeRect(x + 0.5, y + 0.5, cs1, cs1);
      }

      // Start marker
      if (isStart) {
        drawMarker(x, y, cs, COLORS.start, COLORS.startLabel, 'S');
      }
      // Goal marker
      if (isGoal) {
        drawMarker(x, y, cs, COLORS.goal, COLORS.goalLabel, 'G');
      }
    }
  }

  // Keyboard cursor
  if (cursorVisible) {
    const x = cursorCol * cellSize, y = cursorRow * cellSize;
    ctx.strokeStyle = COLORS.cursor;
    ctx.lineWidth = 2.5;
    ctx.strokeRect(x + 1.5, y + 1.5, cellSize - 3, cellSize - 3);
  }
}

function drawMarker(x, y, cs, bg, textColor, label) {
  const pad = Math.max(2, cs * 0.12);
  const r = Math.max(3, cs * 0.25);

  ctx.fillStyle = bg;
  ctx.beginPath();
  roundRect(ctx, x + pad, y + pad, cs - 2 * pad, cs - 2 * pad, r);
  ctx.fill();

  if (cs >= 14) {
    ctx.fillStyle = textColor;
    ctx.font = `bold ${Math.round(cs * 0.55)}px "JetBrains Mono", monospace`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(label, x + cs / 2, y + cs / 2 + 0.5);
  }
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}

// ============================================================
// Animation loop
// ============================================================
function startAnimation(result) {
  state.result = result;
  state.animIndex = 0;
  state.animDone = false;
  state.animPathShown = false;
  state.drawnExpanded = new Set();
  state.drawnFrontier = new Set(result.openAtEnd);
  state.drawnPath = [];
  state.pathFlashT = 0;
  state.animRunning = true;

  // If reduced motion, skip to end immediately
  if (state.prefersReducedMotion) {
    finishAnimation(result);
    return;
  }

  scheduleFrame();
}

function scheduleFrame() {
  state.animFrame = requestAnimationFrame(animStep);
}

function animStep() {
  if (!state.animRunning) return;

  const result = state.result;
  const order  = result.expansionOrder;
  const speed  = Math.max(1, state.animSpeed);

  // Advance by `speed` steps
  for (let i = 0; i < speed && state.animIndex < order.length; i++, state.animIndex++) {
    const id = order[state.animIndex];
    state.drawnExpanded.add(id);
    state.drawnFrontier.delete(id); // frontier cells become visited when expanded
  }

  render();

  if (state.animIndex >= order.length) {
    finishAnimation(result);
    return;
  }

  scheduleFrame();
}

function finishAnimation(result) {
  state.animRunning = false;
  state.animDone = true;

  // Show all expanded
  for (const id of result.expansionOrder) state.drawnExpanded.add(id);
  // Show remaining frontier
  state.drawnFrontier = new Set(result.openAtEnd);

  if (result.found) {
    state.drawnPath = result.path;
    state.pathFlashT = 1.0;
    // Animate path flash briefly
    animatePathFlash();
  } else {
    state.drawnPath = [];
    render();
    setStatus('No path exists — goal is unreachable.', false);
  }

  updateMetrics(result);
  if (state.compareMode) updateComparePanel();
}

function animatePathFlash() {
  render();
  state.pathFlashT = Math.max(0, state.pathFlashT - 0.06);
  if (state.pathFlashT > 0) {
    requestAnimationFrame(animatePathFlash);
  } else {
    render();
    const r = state.result;
    if (r && r.found) {
      setStatus(
        `Path found! Cost: ${r.pathCost.toFixed(2)}, Steps: ${r.path.length - 1}, ` +
        `Nodes expanded: ${r.nodesExpanded}, Time: ${r.searchTimeMs.toFixed(1)} ms`,
        true
      );
    }
  }
}

// ============================================================
// Run search
// ============================================================
function buildSearchParams(mode, heuristic) {
  return {
    rows:            state.rows,
    cols:            state.cols,
    walls:           state.walls,
    terrain:         state.terrain,
    startRow:        state.startRow,
    startCol:        state.startCol,
    goalRow:         state.goalRow,
    goalCol:         state.goalCol,
    heuristic:       heuristic || state.heuristic,
    eightConnected:  state.eightConnected,
    preventCornerCut: state.preventCornerCut,
    mode:            mode || 'astar',
  };
}

function validateGrid() {
  const { startRow, startCol, goalRow, goalCol, rows, cols, walls } = state;

  if (startRow === goalRow && startCol === goalCol) {
    setStatus('Start and goal are the same cell.', false);
    return false;
  }
  if (walls[startRow * cols + startCol]) {
    setStatus('Start cell is a wall — please move it.', false);
    return false;
  }
  if (walls[goalRow * cols + goalCol]) {
    setStatus('Goal cell is a wall — please move it.', false);
    return false;
  }
  return true;
}

function runFull() {
  if (!validateGrid()) return;
  resetSearchState();
  render();

  const params = buildSearchParams('astar', state.heuristic);
  const result = AStarLib.runSearch(params);

  if (state.compareMode) {
    const dResult = AStarLib.runDijkstra(buildSearchParams('dijkstra', 'zero'));
    const gResult = AStarLib.runGreedy(buildSearchParams('greedy', state.heuristic));
    state.compareResults = { astar: result, dijkstra: dResult, greedy: gResult };
  }

  startAnimation(result);
}

function stepOnce() {
  if (state.animDone) return;

  if (!state.result) {
    if (!validateGrid()) return;
    const params = buildSearchParams('astar', state.heuristic);
    state.result = AStarLib.runSearch(params);
    state.animIndex = 0;
    state.drawnExpanded = new Set();
    state.drawnFrontier = new Set(state.result.openAtEnd);
    state.drawnPath = [];
  }

  const result = state.result;
  const order  = result.expansionOrder;
  const id = order[state.animIndex];
  if (id !== undefined) {
    state.drawnExpanded.add(id);
    state.drawnFrontier.delete(id);
    state.animIndex++;
  }

  if (state.animIndex >= order.length) {
    finishAnimation(result);
  } else {
    render();
    updateMetrics({ ...result, nodesExpanded: state.animIndex });
  }
}

function pauseAnim() {
  state.animRunning = false;
  if (state.animFrame) {
    cancelAnimationFrame(state.animFrame);
    state.animFrame = null;
  }
}

function resumeAnim() {
  if (state.animDone || !state.result) { runFull(); return; }
  state.animRunning = true;
  scheduleFrame();
}

function resetAll() {
  resetSearchState();
  loadDefaultScene();
  resizeCanvas();
  render();
  clearMetrics();
  setStatus('Grid reset. Click Run to search.', true);
  if (state.compareMode) clearComparePanel();
}

// ============================================================
// Metrics display
// ============================================================
function updateMetrics(result) {
  const fmt = v => typeof v === 'number' ? (Number.isFinite(v) ? v.toFixed(2) : '—') : '—';

  $('metric-expanded').textContent  = result.nodesExpanded ?? '—';
  $('metric-cost').textContent      = result.found ? fmt(result.pathCost) : '—';
  $('metric-steps').textContent     = result.found ? (result.path.length - 1) : '—';
  $('metric-time').textContent      = fmt(result.searchTimeMs) + ' ms';
  $('metric-found').textContent     = result.found ? 'Yes' : 'No';
  $('metric-admissible').textContent = isAdmissible() ? 'Yes (optimal)' : 'No (may not be optimal)';

  // Screen-reader live region
  const srMsg = result.found
    ? `Path found. Cost ${result.pathCost.toFixed(2)}, ${result.path.length - 1} steps, ${result.nodesExpanded} nodes expanded.`
    : 'No path found. Goal is unreachable.';
  $('sr-result').textContent = srMsg;
}

function clearMetrics() {
  ['metric-expanded','metric-cost','metric-steps','metric-time','metric-found','metric-admissible']
    .forEach(id => { $(id).textContent = '—'; });
  $('sr-result').textContent = '';
}

function isAdmissible() {
  const h = state.heuristic;
  if (h === 'zero') return true;
  if (!state.eightConnected && h === 'manhattan') return true;
  if (!state.eightConnected && h === 'euclidean') return true;
  if (state.eightConnected && (h === 'octile' || h === 'euclidean')) return true;
  return false;
}

// ============================================================
// Compare panel
// ============================================================
function updateComparePanel() {
  const cr = state.compareResults;
  if (!cr) return;
  const panel = $('compare-panel');
  panel.style.display = 'block';

  function row(label, res) {
    const cost = res.found ? res.pathCost.toFixed(2) : '—';
    const exp  = res.nodesExpanded;
    const time = res.searchTimeMs.toFixed(1);
    const note = res.found ? '' : ' (no path)';
    return `<tr>
      <td class="cmp-label">${label}</td>
      <td>${exp}</td>
      <td>${cost}${note}</td>
      <td>${time} ms</td>
    </tr>`;
  }

  const html = `<table class="compare-table" aria-label="Algorithm comparison">
    <thead><tr><th>Algorithm</th><th>Expanded</th><th>Path Cost</th><th>Time</th></tr></thead>
    <tbody>
      ${row('A* (' + state.heuristic + ')', cr.astar)}
      ${row('Dijkstra', cr.dijkstra)}
      ${row('Greedy BFS', cr.greedy)}
    </tbody>
  </table>`;

  $('compare-table-wrap').innerHTML = html;

  // Admissibility note
  const note = isAdmissible()
    ? 'A* and Dijkstra costs match — heuristic is admissible (optimal).'
    : 'Heuristic may overestimate — A* may not match Dijkstra cost.';
  $('compare-note').textContent = note;
}

function clearComparePanel() {
  $('compare-table-wrap').innerHTML = '';
  $('compare-note').textContent = '';
}

// ============================================================
// Status bar
// ============================================================
function setStatus(msg, ok) {
  state.statusMsg = msg;
  state.statusOk  = ok;
  const el = $('status-bar');
  el.textContent = msg;
  el.className = 'status-bar ' + (ok ? 'status-ok' : 'status-error');
}

// ============================================================
// Paint tools
// ============================================================
function canvasEventToCell(e) {
  const rect = canvas.getBoundingClientRect();
  const clientX = e.touches ? e.touches[0].clientX : e.clientX;
  const clientY = e.touches ? e.touches[0].clientY : e.clientY;
  const x = clientX - rect.left;
  const y = clientY - rect.top;
  const col = Math.floor(x / cellSize);
  const row = Math.floor(y / cellSize);
  if (row < 0 || row >= state.rows || col < 0 || col >= state.cols) return null;
  return { row, col };
}

function applyTool(row, col) {
  const key = `${row},${col}`;
  if (key === state.lastPainted) return;
  state.lastPainted = key;

  const id = row * state.cols + col;

  switch (state.activeTool) {
    case 'start':
      state.startRow = row; state.startCol = col;
      state.walls[id] = 0; state.terrain[id] = 1.0;
      break;
    case 'goal':
      state.goalRow = row; state.goalCol = col;
      state.walls[id] = 0; state.terrain[id] = 1.0;
      break;
    case 'wall':
      if (!(row === state.startRow && col === state.startCol) &&
          !(row === state.goalRow  && col === state.goalCol)) {
        state.walls[id] = 1;
        state.terrain[id] = 1.0;
      }
      break;
    case 'terrain':
      if (!state.walls[id]) {
        state.terrain[id] = state.terrainLevel;
      }
      break;
    case 'erase':
      state.walls[id] = 0;
      state.terrain[id] = 1.0;
      break;
  }

  resetSearchState();
  render();
}

function onCanvasMouseDown(e) {
  e.preventDefault();
  state.isPainting = true;
  state.lastPainted = null;
  const cell = canvasEventToCell(e);
  if (cell) applyTool(cell.row, cell.col);
}

function onCanvasMouseMove(e) {
  if (!state.isPainting) return;
  e.preventDefault();
  const cell = canvasEventToCell(e);
  if (cell) applyTool(cell.row, cell.col);
}

function onCanvasMouseUp() {
  state.isPainting = false;
  state.lastPainted = null;
}

// ============================================================
// Keyboard navigation
// ============================================================
function onKeyDown(e) {
  const tag = document.activeElement.tagName.toLowerCase();
  if (tag === 'input' || tag === 'select' || tag === 'button' || tag === 'textarea') {
    // Don't steal from controls
    if (e.key !== 'Escape') return;
  }

  const arrowKeys = ['ArrowUp','ArrowDown','ArrowLeft','ArrowRight'];
  if (arrowKeys.includes(e.key)) {
    e.preventDefault();
    state.cursorVisible = true;
    const moves = { ArrowUp:[-1,0], ArrowDown:[1,0], ArrowLeft:[0,-1], ArrowRight:[0,1] };
    const [dr, dc] = moves[e.key];
    state.cursorRow = Math.max(0, Math.min(state.rows - 1, state.cursorRow + dr));
    state.cursorCol = Math.max(0, Math.min(state.cols - 1, state.cursorCol + dc));
    render();
    return;
  }

  if (e.key === 'Enter' || e.key === ' ') {
    if (state.cursorVisible) {
      e.preventDefault();
      applyTool(state.cursorRow, state.cursorCol);
    }
    return;
  }

  if (e.key === 'Escape') {
    state.cursorVisible = false;
    render();
  }
}

// ============================================================
// Maze / terrain generators
// ============================================================
function genMazeRecDiv() {
  const seed = parseInt($('seed-input').value, 10) || state.mazeSeed;
  state.mazeSeed = seed;
  initGrid(state.rows, state.cols);
  state.walls = MazeLib.generateMazeRecursiveDivision(state.rows, state.cols, seed);
  clearCell(state.startRow, state.startCol);
  clearCell(state.goalRow,  state.goalCol);
  resetSearchState();
  render();
  setStatus(`Recursive Division maze (seed ${seed}) generated.`, true);
}

function genMazeDFS() {
  const seed = parseInt($('seed-input').value, 10) || state.mazeSeed;
  state.mazeSeed = seed;
  initGrid(state.rows, state.cols);
  state.walls = MazeLib.generateMazeDFS(state.rows, state.cols, seed);
  clearCell(state.startRow, state.startCol);
  clearCell(state.goalRow,  state.goalCol);
  resetSearchState();
  render();
  setStatus(`Randomized DFS maze (seed ${seed}) generated.`, true);
}

function genRandomTerrain() {
  const seed = parseInt($('terrain-seed-input').value, 10) || state.terrainSeed;
  state.terrainSeed = seed;
  state.terrain = MazeLib.generateRandomTerrain(state.rows, state.cols, seed, state.walls);
  resetSearchState();
  render();
  setStatus(`Random terrain (seed ${seed}) applied.`, true);
}

function clearWalls() {
  state.walls = new Int8Array(state.rows * state.cols);
  resetSearchState();
  render();
  setStatus('Walls cleared.', true);
}

function clearTerrain() {
  state.terrain = MazeLib.generateFlatTerrain(state.rows, state.cols);
  resetSearchState();
  render();
  setStatus('Terrain cleared.', true);
}

// ============================================================
// Export: PNG
// ============================================================
function exportPNG() {
  // Render to current canvas and export
  render();

  // Create a temporary canvas with labels
  const margin = 40;
  const dpr = window.devicePixelRatio || 1;
  const tmp = document.createElement('canvas');
  const tw = canvas.width / dpr;
  const th = canvas.height / dpr;
  tmp.width  = (tw + margin * 2) * dpr;
  tmp.height = (th + margin * 2 + 30) * dpr;
  const tc = tmp.getContext('2d');
  tc.scale(dpr, dpr);

  // Background
  tc.fillStyle = '#EDEEF3';
  tc.fillRect(0, 0, tw + margin * 2, th + margin * 2 + 30);

  // Grid
  tc.drawImage(canvas, 0, 0, canvas.width, canvas.height,
    margin, margin, tw, th);

  // Title
  tc.fillStyle = '#1B1D2A';
  tc.font = 'bold 14px Manrope, system-ui, sans-serif';
  tc.textAlign = 'left';
  tc.fillText('Compass — A* Pathfinding Visualizer', margin, margin - 10);

  // Metrics footer
  const r = state.result;
  let footer = 'No search run yet.';
  if (r) {
    footer = r.found
      ? `A* | Cost: ${r.pathCost.toFixed(2)} | Steps: ${r.path.length - 1} | Expanded: ${r.nodesExpanded} | ${r.searchTimeMs.toFixed(1)} ms`
      : 'No path found.';
  }
  tc.fillStyle = '#565A70';
  tc.font = '11px "JetBrains Mono", monospace';
  tc.fillText(footer, margin, th + margin + 18);

  tmp.toBlob(blob => {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'compass-astar.png';
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 2000);
  }, 'image/png');
}

// ============================================================
// Export: CSV path
// ============================================================
function exportCSV() {
  const r = state.result;
  if (!r || !r.found || !r.path.length) {
    setStatus('No path to export — run the search first.', false);
    return;
  }
  const lines = ['step,row,col'];
  r.path.forEach((p, i) => lines.push(`${i},${p.row},${p.col}`));
  const blob = new Blob([lines.join('\n')], { type: 'text/csv' });
  const url  = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'compass-path.csv';
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 2000);
  setStatus('Path exported as CSV.', true);
}

// ============================================================
// UI wiring
// ============================================================
function wireControls() {
  // Tool buttons
  for (const btn of document.querySelectorAll('.tool-btn')) {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.tool-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      state.activeTool = btn.dataset.tool;
      if (btn.dataset.tool === 'terrain') {
        $('terrain-weight-row').style.display = 'flex';
      } else {
        $('terrain-weight-row').style.display = 'none';
      }
    });
  }

  // Terrain weight selector
  $('terrain-weight').addEventListener('change', () => {
    state.terrainLevel = parseFloat($('terrain-weight').value);
  });

  // Heuristic
  $('heuristic-select').addEventListener('change', () => {
    state.heuristic = $('heuristic-select').value;
    // Show/hide octile note
    const note = $('heuristic-note');
    if (state.heuristic === 'octile' && !state.eightConnected) {
      note.textContent = 'Octile works best with 8-connectivity.';
      note.style.display = 'block';
    } else {
      note.style.display = 'none';
    }
    resetSearchState();
    render();
  });

  // Connectivity
  $('connectivity-select').addEventListener('change', () => {
    state.eightConnected = $('connectivity-select').value === '8';
    resetSearchState();
    render();
  });

  // Corner-cutting
  $('corner-cut-toggle').addEventListener('change', () => {
    state.preventCornerCut = $('corner-cut-toggle').checked;
    resetSearchState();
    render();
  });

  // Animation speed
  $('speed-slider').addEventListener('input', () => {
    const v = parseInt($('speed-slider').value, 10);
    state.animSpeed = v;
    $('speed-label').textContent = v + (v >= 100 ? ' (instant)' : ' cells/frame');
  });

  // Run / Step / Pause / Reset
  $('btn-run').addEventListener('click', runFull);
  $('btn-step').addEventListener('click', () => {
    if (state.animRunning) pauseAnim();
    stepOnce();
  });
  $('btn-pause').addEventListener('click', () => {
    if (state.animRunning) pauseAnim();
    else resumeAnim();
  });
  $('btn-reset').addEventListener('click', resetAll);

  // Compare toggle
  $('compare-toggle').addEventListener('change', () => {
    state.compareMode = $('compare-toggle').checked;
    $('compare-panel').style.display = state.compareMode ? 'block' : 'none';
    if (!state.compareMode) clearComparePanel();
  });

  // Maze generators
  $('btn-maze-div').addEventListener('click', genMazeRecDiv);
  $('btn-maze-dfs').addEventListener('click', genMazeDFS);
  $('btn-terrain').addEventListener('click', genRandomTerrain);
  $('btn-clear-walls').addEventListener('click', clearWalls);
  $('btn-clear-terrain').addEventListener('click', clearTerrain);

  // Export
  $('btn-export-png').addEventListener('click', exportPNG);
  $('btn-export-csv').addEventListener('click', exportCSV);

  // Canvas mouse events
  canvas.addEventListener('mousedown', onCanvasMouseDown);
  canvas.addEventListener('mousemove', onCanvasMouseMove);
  canvas.addEventListener('mouseup',   onCanvasMouseUp);
  canvas.addEventListener('mouseleave', onCanvasMouseUp);

  // Touch events
  canvas.addEventListener('touchstart', onCanvasMouseDown, { passive: false });
  canvas.addEventListener('touchmove',  onCanvasMouseMove, { passive: false });
  canvas.addEventListener('touchend',   onCanvasMouseUp);

  // Keyboard
  document.addEventListener('keydown', onKeyDown);

  // Method panel toggle
  $('btn-method').addEventListener('click', () => {
    const panel = $('method-panel');
    const isOpen = panel.style.display !== 'none';
    panel.style.display = isOpen ? 'none' : 'block';
    $('btn-method').setAttribute('aria-expanded', String(!isOpen));
  });

  // Resize — debounced, fires after layout settles
  let _resizeTimer = null;
  const resObs = new ResizeObserver(() => {
    clearTimeout(_resizeTimer);
    _resizeTimer = setTimeout(() => {
      if (state.walls) { // only after grid is initialized
        resizeCanvas();
        render();
      }
    }, 60);
  });
  resObs.observe(canvas.parentElement);
}

// ============================================================
// Sanity check display
// ============================================================
function displaySanityCheck() {
  const sc = AStarLib.runSanityCheck();
  state.sanityOk = sc.allPass;

  const el = $('sanity-result');
  if (!el) return;

  const lines = sc.results.map(r =>
    `${r.pass ? '✓' : '✗'} ${r.name}: ${r.detail}`
  );
  el.textContent = lines.join('\n') + '\n' + (sc.allPass ? '\nAll checks PASSED.' : '\nSome checks failed.');
  el.className = sc.allPass ? 'sanity-pass' : 'sanity-fail';
}

// ============================================================
// Initialization
// ============================================================
function init() {
  canvas = $('grid-canvas');
  ctx = canvas.getContext('2d');

  // Check reduced motion preference
  const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
  state.prefersReducedMotion = mq.matches;
  mq.addEventListener('change', e => { state.prefersReducedMotion = e.matches; });

  // Set first tool active
  const firstTool = document.querySelector('.tool-btn[data-tool="wall"]');
  if (firstTool) firstTool.classList.add('active');

  // Load default scene
  loadDefaultScene();
  resizeCanvas();
  wireControls();
  render();

  // Run sanity check
  displaySanityCheck();

  // Auto-run on load (with small delay for layout)
  setTimeout(() => {
    setStatus('Default grid loaded. Running A* search…', true);
    runFull();
  }, 300);
}

document.addEventListener('DOMContentLoaded', init);
