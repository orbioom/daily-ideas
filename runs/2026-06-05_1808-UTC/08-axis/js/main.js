/**
 * main.js — Axis PCA Explorer
 * UI wiring, controls, canvas rendering (scatter, scree, biplot)
 *
 * Coordinates:
 *   - Uses PCA (window.PCA) from pca.js
 *   - Uses DATASETS (window.DATASETS) from datasets.js
 */

'use strict';

// ─── CanvasRenderingContext2D.roundRect polyfill (pre-2022 browsers) ──────────
if (!CanvasRenderingContext2D.prototype.roundRect) {
  CanvasRenderingContext2D.prototype.roundRect = function (x, y, w, h, r) {
    const rad = Math.min(r, w / 2, h / 2);
    this.moveTo(x + rad, y);
    this.arcTo(x + w, y,     x + w, y + h, rad);
    this.arcTo(x + w, y + h, x,     y + h, rad);
    this.arcTo(x,     y + h, x,     y,     rad);
    this.arcTo(x,     y,     x + w, y,     rad);
    this.closePath();
  };
}

// ─── Constants ────────────────────────────────────────────────────────────────

const CLASS_COLORS = [
  '#4E79A7', '#F28E2B', '#E15759', '#76B7B2',
  '#59A14F', '#EDC948', '#B07AA1', '#FF9DA7',
  '#9C755F', '#BAB0AC',
];

// ─── State ────────────────────────────────────────────────────────────────────

const State = {
  datasets: {},        // { id: datasetObj }
  currentDataset: null,
  pcaResult: null,
  selectedFeatures: [],
  standardize: true,
  pcX: 0,             // 0-indexed PC indices
  pcY: 1,
  pointSize: 5,
  hoveredPoint: null,
  csvWarnings: [],
};

// ─── DOM refs ─────────────────────────────────────────────────────────────────

const $ = id => document.getElementById(id);

// ─── Categorical color lookup ─────────────────────────────────────────────────

function buildColorMap(labels) {
  const unique = [...new Set(labels)].sort();
  const map = {};
  unique.forEach((lbl, i) => { map[lbl] = CLASS_COLORS[i % CLASS_COLORS.length]; });
  return map;
}

// ─── Canvas helpers ───────────────────────────────────────────────────────────

/**
 * Set canvas physical resolution = CSS size × devicePixelRatio.
 * Returns the 2-D rendering context.
 */
function setupCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width  = Math.round(rect.width  * dpr);
  canvas.height = Math.round(rect.height * dpr);
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return ctx;
}

/**
 * Draw a text label with optional background pill.
 */
function drawLabel(ctx, text, x, y, opts = {}) {
  const { fill = '#1B1D2A', font = '11px Manrope, system-ui, sans-serif', align = 'center' } = opts;
  ctx.save();
  ctx.font = font;
  ctx.fillStyle = fill;
  ctx.textAlign = align;
  ctx.textBaseline = 'middle';
  ctx.fillText(text, x, y);
  ctx.restore();
}

// ─── Scatter plot ─────────────────────────────────────────────────────────────

function renderScatter() {
  const canvas = $('scatter-canvas');
  if (!canvas) return;

  const ctx = setupCanvas(canvas);
  const W = canvas.getBoundingClientRect().width;
  const H = canvas.getBoundingClientRect().height;

  ctx.clearRect(0, 0, W, H);

  const result = State.pcaResult;
  if (!result) {
    drawEmptyState(ctx, W, H, 'No data — select a dataset and features.');
    return;
  }

  const pcX = State.pcX;
  const pcY = State.pcY;

  if (pcX >= result.scores[0].length || pcY >= result.scores[0].length) {
    drawEmptyState(ctx, W, H, 'Select valid PC axes.');
    return;
  }

  const margin = { top: 28, right: 20, bottom: 52, left: 58 };
  const plotW = W - margin.left - margin.right;
  const plotH = H - margin.top - margin.bottom;

  // Extract score columns
  const xs = result.scores.map(r => r[pcX]);
  const ys = result.scores.map(r => r[pcY]);

  const xMin = Math.min(...xs), xMax = Math.max(...xs);
  const yMin = Math.min(...ys), yMax = Math.max(...ys);
  const xPad = (xMax - xMin) * 0.08 || 0.5;
  const yPad = (yMax - yMin) * 0.08 || 0.5;

  const xL = xMin - xPad, xR = xMax + xPad;
  const yB = yMin - yPad, yT = yMax + yPad;

  function toCanvasX(v) { return margin.left + (v - xL) / (xR - xL) * plotW; }
  function toCanvasY(v) { return margin.top  + (1 - (v - yB) / (yT - yB)) * plotH; }

  // Background
  ctx.fillStyle = 'rgba(255,255,255,0.25)';
  ctx.beginPath();
  ctx.roundRect(margin.left, margin.top, plotW, plotH, 6);
  ctx.fill();

  // Grid lines
  ctx.strokeStyle = 'rgba(91,95,115,0.10)';
  ctx.lineWidth = 1;
  const nGrid = 5;
  for (let i = 0; i <= nGrid; i++) {
    const gx = margin.left + i * plotW / nGrid;
    const gy = margin.top + i * plotH / nGrid;
    ctx.beginPath(); ctx.moveTo(gx, margin.top);    ctx.lineTo(gx, margin.top + plotH); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(margin.left, gy);   ctx.lineTo(margin.left + plotW, gy); ctx.stroke();
  }

  // Zero axes
  const zeroX = toCanvasX(0);
  const zeroY = toCanvasY(0);
  ctx.strokeStyle = 'rgba(91,95,115,0.28)';
  ctx.lineWidth = 1;
  if (zeroX >= margin.left && zeroX <= margin.left + plotW) {
    ctx.beginPath(); ctx.moveTo(zeroX, margin.top); ctx.lineTo(zeroX, margin.top + plotH); ctx.stroke();
  }
  if (zeroY >= margin.top && zeroY <= margin.top + plotH) {
    ctx.beginPath(); ctx.moveTo(margin.left, zeroY); ctx.lineTo(margin.left + plotW, zeroY); ctx.stroke();
  }

  // Points
  const colorMap = buildColorMap(result.labels);
  const r = State.pointSize;

  result.scores.forEach((row, i) => {
    const x = toCanvasX(row[pcX]);
    const y = toCanvasY(row[pcY]);
    const col = colorMap[result.labels[i]] || '#4E79A7';
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fillStyle = col + 'CC'; // alpha
    ctx.fill();
    ctx.strokeStyle = col;
    ctx.lineWidth = 0.8;
    ctx.stroke();
  });

  // Highlight hovered point
  if (State.hoveredPoint !== null) {
    const i = State.hoveredPoint;
    const x = toCanvasX(result.scores[i][pcX]);
    const y = toCanvasY(result.scores[i][pcY]);
    const col = colorMap[result.labels[i]] || '#4E79A7';
    ctx.beginPath();
    ctx.arc(x, y, r + 3, 0, Math.PI * 2);
    ctx.strokeStyle = col;
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fillStyle = col;
    ctx.fill();
  }

  // Axis ticks + labels
  ctx.fillStyle = '#565A70';
  ctx.font = '10px "JetBrains Mono", monospace';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';
  for (let i = 0; i <= nGrid; i++) {
    const val = xL + i * (xR - xL) / nGrid;
    const px = margin.left + i * plotW / nGrid;
    ctx.fillText(val.toFixed(1), px, margin.top + plotH + 5);
  }

  ctx.textAlign = 'right';
  ctx.textBaseline = 'middle';
  for (let i = 0; i <= nGrid; i++) {
    const val = yB + i * (yT - yB) / nGrid;
    const py = margin.top + (1 - i / nGrid) * plotH;
    ctx.fillText(val.toFixed(1), margin.left - 6, py);
  }

  // Axis titles
  const varX = (result.explainedVariance[pcX] * 100).toFixed(1);
  const varY = (result.explainedVariance[pcY] * 100).toFixed(1);

  ctx.fillStyle = '#1B1D2A';
  ctx.font = '11px Manrope, system-ui, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'bottom';
  ctx.fillText(`PC${pcX + 1} (${varX}% variance)`, margin.left + plotW / 2, H - 6);

  ctx.save();
  ctx.translate(13, margin.top + plotH / 2);
  ctx.rotate(-Math.PI / 2);
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';
  ctx.fillText(`PC${pcY + 1} (${varY}% variance)`, 0, 0);
  ctx.restore();

  // Store mapping for hover
  canvas._plotState = { toCanvasX, toCanvasY, margin, plotW, plotH, xL, xR, yB, yT };
}

function drawEmptyState(ctx, W, H, msg) {
  ctx.fillStyle = 'rgba(139,143,163,0.35)';
  ctx.font = '13px Manrope, system-ui, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(msg, W / 2, H / 2);
}

// ─── Scree plot ───────────────────────────────────────────────────────────────

function renderScree() {
  const canvas = $('scree-canvas');
  if (!canvas) return;

  const ctx = setupCanvas(canvas);
  const W = canvas.getBoundingClientRect().width;
  const H = canvas.getBoundingClientRect().height;
  ctx.clearRect(0, 0, W, H);

  const result = State.pcaResult;
  if (!result) {
    drawEmptyState(ctx, W, H, 'No data');
    return;
  }

  const evr = Array.from(result.explainedVariance);
  const cum = Array.from(result.cumulative);
  const k = evr.length;

  const margin = { top: 24, right: 20, bottom: 44, left: 44 };
  const plotW = W - margin.left - margin.right;
  const plotH = H - margin.top - margin.bottom;

  // Background
  ctx.fillStyle = 'rgba(255,255,255,0.22)';
  ctx.beginPath();
  ctx.roundRect(margin.left, margin.top, plotW, plotH, 6);
  ctx.fill();

  const barW = Math.max(6, plotW / k - 4);
  const barGap = plotW / k;

  function toY(v) { return margin.top + (1 - v) * plotH; }

  // Grid
  ctx.strokeStyle = 'rgba(91,95,115,0.10)';
  ctx.lineWidth = 1;
  [0.25, 0.5, 0.75, 1.0].forEach(v => {
    const y = toY(v);
    ctx.beginPath(); ctx.moveTo(margin.left, y); ctx.lineTo(margin.left + plotW, y); ctx.stroke();
    ctx.fillStyle = '#8B8FA3';
    ctx.font = '9px "JetBrains Mono", monospace';
    ctx.textAlign = 'right';
    ctx.textBaseline = 'middle';
    ctx.fillText((v * 100).toFixed(0) + '%', margin.left - 5, y);
  });

  // Bars
  for (let i = 0; i < k; i++) {
    const cx = margin.left + i * barGap + barGap / 2;
    const barH = evr[i] * plotH;
    const y = toY(evr[i]);

    const grad = ctx.createLinearGradient(0, y, 0, toY(0));
    grad.addColorStop(0, '#4E79A7CC');
    grad.addColorStop(1, '#4E79A730');
    ctx.fillStyle = grad;
    ctx.fillRect(cx - barW / 2, y, barW, barH);

    ctx.strokeStyle = '#4E79A7';
    ctx.lineWidth = 1;
    ctx.strokeRect(cx - barW / 2, y, barW, barH);

    // Percentage label above bar
    ctx.fillStyle = '#1B1D2A';
    ctx.font = '8px "JetBrains Mono", monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'bottom';
    if (barH > 12) {
      ctx.fillText((evr[i] * 100).toFixed(1) + '%', cx, y - 1);
    }

    // X-axis label
    ctx.fillStyle = '#565A70';
    ctx.font = '9px "JetBrains Mono", monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillText('PC' + (i + 1), cx, margin.top + plotH + 5);
  }

  // Cumulative line
  ctx.strokeStyle = '#E15759';
  ctx.lineWidth = 1.8;
  ctx.lineJoin = 'round';
  ctx.beginPath();
  for (let i = 0; i < k; i++) {
    const cx = margin.left + i * barGap + barGap / 2;
    const cy = toY(cum[i]);
    if (i === 0) ctx.moveTo(cx, cy); else ctx.lineTo(cx, cy);
  }
  ctx.stroke();

  // Cumulative dots
  ctx.fillStyle = '#E15759';
  for (let i = 0; i < k; i++) {
    const cx = margin.left + i * barGap + barGap / 2;
    const cy = toY(cum[i]);
    ctx.beginPath();
    ctx.arc(cx, cy, 3, 0, Math.PI * 2);
    ctx.fill();
  }

  // Legend
  ctx.fillStyle = '#4E79A7';
  ctx.fillRect(margin.left, margin.top - 18, 10, 9);
  ctx.fillStyle = '#565A70';
  ctx.font = '9px Manrope, system-ui, sans-serif';
  ctx.textAlign = 'left';
  ctx.textBaseline = 'middle';
  ctx.fillText('Explained variance', margin.left + 13, margin.top - 13);

  ctx.strokeStyle = '#E15759';
  ctx.lineWidth = 1.8;
  ctx.beginPath();
  ctx.moveTo(W - 120, margin.top - 13);
  ctx.lineTo(W - 104, margin.top - 13);
  ctx.stroke();
  ctx.fillStyle = '#E15759';
  ctx.beginPath();
  ctx.arc(W - 112, margin.top - 13, 3, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#565A70';
  ctx.fillText('Cumulative', W - 101, margin.top - 13);

  // Y-axis title
  ctx.save();
  ctx.translate(10, margin.top + plotH / 2);
  ctx.rotate(-Math.PI / 2);
  ctx.fillStyle = '#565A70';
  ctx.font = '9px Manrope, system-ui, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';
  ctx.fillText('Explained Variance', 0, 0);
  ctx.restore();

  // Highlight selected PCs
  [State.pcX, State.pcY].forEach(pc => {
    if (pc < k) {
      const cx = margin.left + pc * barGap + barGap / 2;
      ctx.strokeStyle = '#1B1D2ACC';
      ctx.lineWidth = 1.5;
      ctx.setLineDash([3, 3]);
      ctx.beginPath();
      ctx.moveTo(cx, margin.top);
      ctx.lineTo(cx, margin.top + plotH);
      ctx.stroke();
      ctx.setLineDash([]);
    }
  });
}

// ─── Loadings biplot ──────────────────────────────────────────────────────────

function renderLoadingsBiplot() {
  const canvas = $('biplot-canvas');
  if (!canvas) return;

  const ctx = setupCanvas(canvas);
  const W = canvas.getBoundingClientRect().width;
  const H = canvas.getBoundingClientRect().height;
  ctx.clearRect(0, 0, W, H);

  const result = State.pcaResult;
  if (!result) { drawEmptyState(ctx, W, H, 'No data'); return; }

  const pcX = State.pcX;
  const pcY = State.pcY;

  if (pcX >= result.loadings.length || pcY >= result.loadings.length) {
    drawEmptyState(ctx, W, H, 'Select valid PCs'); return;
  }

  const margin = { top: 20, right: 20, bottom: 32, left: 32 };
  const plotW = W - margin.left - margin.right;
  const plotH = H - margin.top - margin.bottom;
  const cx = margin.left + plotW / 2;
  const cy = margin.top + plotH / 2;
  const scale = Math.min(plotW, plotH) / 2 * 0.82;

  // Background
  ctx.fillStyle = 'rgba(255,255,255,0.18)';
  ctx.beginPath();
  ctx.roundRect(margin.left, margin.top, plotW, plotH, 6);
  ctx.fill();

  // Axes
  ctx.strokeStyle = 'rgba(91,95,115,0.18)';
  ctx.lineWidth = 1;
  ctx.beginPath(); ctx.moveTo(margin.left, cy); ctx.lineTo(margin.left + plotW, cy); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(cx, margin.top); ctx.lineTo(cx, margin.top + plotH); ctx.stroke();

  // Circle guide
  ctx.strokeStyle = 'rgba(91,95,115,0.10)';
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.arc(cx, cy, scale, 0, Math.PI * 2);
  ctx.stroke();

  // Feature arrows
  const featureNames = result.featureNames;
  result.loadings[0].forEach((_, fi) => {
    if (fi >= featureNames.length) return;
    const lx = pcX < result.loadings.length ? result.loadings[pcX][fi] : 0;
    const ly = pcY < result.loadings.length ? result.loadings[pcY][fi] : 0;
    const ex = cx + lx * scale;
    const ey = cy - ly * scale;
    const col = CLASS_COLORS[fi % CLASS_COLORS.length];

    // Arrow shaft
    ctx.strokeStyle = col + 'BB';
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(ex, ey);
    ctx.stroke();

    // Arrowhead
    const ang = Math.atan2(ey - cy, ex - cx);
    const al = 8;
    ctx.fillStyle = col + 'BB';
    ctx.beginPath();
    ctx.moveTo(ex, ey);
    ctx.lineTo(ex - al * Math.cos(ang - 0.38), ey - al * Math.sin(ang - 0.38));
    ctx.lineTo(ex - al * Math.cos(ang + 0.38), ey - al * Math.sin(ang + 0.38));
    ctx.closePath();
    ctx.fill();

    // Label
    const lblX = cx + lx * scale * 1.18;
    const lblY = cy - ly * scale * 1.18;
    ctx.fillStyle = col;
    ctx.font = 'bold 9px "JetBrains Mono", monospace';
    ctx.textAlign = lx >= 0 ? 'left' : 'right';
    ctx.textBaseline = ly >= 0 ? 'bottom' : 'top';
    ctx.fillText(featureNames[fi], lblX, lblY);
  });

  // Axis labels
  ctx.fillStyle = '#565A70';
  ctx.font = '9px Manrope, system-ui, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';
  ctx.fillText(`PC${pcX + 1}`, margin.left + plotW / 2, margin.top + plotH + 4);
  ctx.save();
  ctx.translate(8, margin.top + plotH / 2);
  ctx.rotate(-Math.PI / 2);
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';
  ctx.fillText(`PC${pcY + 1}`, 0, 0);
  ctx.restore();
}

// ─── Loadings table ───────────────────────────────────────────────────────────

function renderLoadingsTable() {
  const tbody = $('loadings-tbody');
  const thead = $('loadings-thead');
  if (!tbody || !thead) return;

  const result = State.pcaResult;
  if (!result) { tbody.innerHTML = ''; return; }

  const k = result.loadings.length;
  const pcX = State.pcX;
  const pcY = State.pcY;

  // Header
  let hdr = '<tr><th>Feature</th>';
  for (let i = 0; i < k; i++) {
    const cls = (i === pcX || i === pcY) ? 'style="color:#1B1D2A;font-weight:700"' : '';
    hdr += `<th ${cls}>PC${i + 1}</th>`;
  }
  hdr += '<th>|PC' + (pcX + 1) + '|</th><th>|PC' + (pcY + 1) + '|</th></tr>';
  thead.innerHTML = hdr;

  // Body
  let rows = '';
  const featureNames = result.featureNames;
  featureNames.forEach((name, fi) => {
    rows += `<tr><td class="mono" style="color:${CLASS_COLORS[fi % CLASS_COLORS.length]}">${escHtml(name)}</td>`;
    for (let pc = 0; pc < k; pc++) {
      const v = result.loadings[pc][fi];
      const bold = (pc === pcX || pc === pcY) ? 'font-weight:700' : '';
      rows += `<td style="${bold}">${v.toFixed(4)}</td>`;
    }
    // Mini bar for chosen PCs
    const vx = result.loadings[pcX][fi];
    const vy = result.loadings[pcY][fi];
    rows += `<td>${miniBar(vx)}</td><td>${miniBar(vy)}</td>`;
    rows += '</tr>';
  });
  tbody.innerHTML = rows;
}

function miniBar(v) {
  const pct = Math.abs(v) * 100;
  const col = v >= 0 ? '#4E79A7' : '#E15759';
  return `<div class="loading-bar-track" title="${v.toFixed(4)}">
    <div class="loading-bar-fill" style="width:${pct.toFixed(1)}%;background:${col}"></div>
  </div>`;
}

function escHtml(s) {
  return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

// ─── Stats strip ──────────────────────────────────────────────────────────────

function updateStats() {
  const result = State.pcaResult;

  $('stat-n').textContent       = result ? result.nSamples   : '—';
  $('stat-p').textContent       = result ? result.nFeatures  : '—';
  $('stat-time').textContent    = result ? result.computeTimeMs.toFixed(2) + ' ms' : '—';

  if (result) {
    const varX = (result.explainedVariance[State.pcX] * 100).toFixed(2);
    const varY = (result.explainedVariance[State.pcY] * 100).toFixed(2);
    const cum12 = ((result.explainedVariance[State.pcX] + result.explainedVariance[State.pcY]) * 100).toFixed(2);
    $('stat-pc1').textContent = `PC${State.pcX + 1}: ${varX}%`;
    $('stat-pc2').textContent = `PC${State.pcY + 1}: ${varY}%`;
    $('stat-cum').textContent = `Σ: ${cum12}%`;

    // Sanity
    const sanity = result.sanity;
    $('sanity-ortho').textContent  = sanity.orthonormal ? 'orthonormal ✓' : 'orthonormal FAIL';
    $('sanity-ortho').className    = 'sanity-item ' + (sanity.orthonormal ? 'sanity-pass' : 'sanity-fail');
    const varSumOk = Math.abs(sanity.varianceSum - 1) < 1e-6;
    $('sanity-varsum').textContent = `var-sum ${sanity.varianceSum.toFixed(6)}` + (varSumOk ? ' ✓' : ' FAIL');
    $('sanity-varsum').className   = 'sanity-item ' + (varSumOk ? 'sanity-pass' : 'sanity-fail');
  } else {
    $('stat-pc1').textContent = '—';
    $('stat-pc2').textContent = '—';
    $('stat-cum').textContent = '—';
    $('sanity-ortho').textContent  = '';
    $('sanity-varsum').textContent = '';
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────────

function updateLegend() {
  const wrap = $('legend-wrap');
  if (!wrap) return;
  wrap.innerHTML = '';
  const result = State.pcaResult;
  if (!result) return;
  const colorMap = buildColorMap(result.labels);
  Object.entries(colorMap).forEach(([lbl, col]) => {
    const item = document.createElement('div');
    item.className = 'legend-item';
    item.innerHTML = `<div class="legend-dot" style="background:${col}"></div><span>${escHtml(lbl)}</span>`;
    wrap.appendChild(item);
  });
}

// ─── PC axis selectors ────────────────────────────────────────────────────────

function populatePCSelectors() {
  const selX = $('sel-pcx');
  const selY = $('sel-pcy');
  if (!selX || !selY) return;

  const result = State.pcaResult;
  const k = result ? result.loadings.length : 0;

  selX.innerHTML = '';
  selY.innerHTML = '';

  for (let i = 0; i < k; i++) {
    const pct = result ? (result.explainedVariance[i] * 100).toFixed(1) : '';
    const label = `PC${i + 1}${pct ? ' (' + pct + '%)' : ''}`;
    selX.add(new Option(label, i, false, i === State.pcX));
    selY.add(new Option(label, i, false, i === State.pcY));
  }

  if (k === 0) {
    selX.add(new Option('—', 0));
    selY.add(new Option('—', 0));
  }
}

// ─── Feature checkboxes ───────────────────────────────────────────────────────

function populateFeatureList(dataset) {
  const container = $('feature-list');
  if (!container) return;
  container.innerHTML = '';

  if (!dataset) return;

  State.selectedFeatures = dataset.featureNames.slice(); // all selected by default

  dataset.featureNames.forEach((name, i) => {
    const id = `feat-${i}`;
    const item = document.createElement('label');
    item.className = 'feature-item';
    item.htmlFor = id;

    const cb = document.createElement('input');
    cb.type = 'checkbox';
    cb.id = id;
    cb.checked = true;
    cb.setAttribute('aria-label', `Include feature ${name}`);
    cb.addEventListener('change', () => {
      if (cb.checked) {
        if (!State.selectedFeatures.includes(name)) State.selectedFeatures.push(name);
      } else {
        State.selectedFeatures = State.selectedFeatures.filter(f => f !== name);
      }
      runAndRender();
    });

    const span = document.createElement('span');
    span.className = 'feature-name';
    span.textContent = name;

    item.appendChild(cb);
    item.appendChild(span);
    container.appendChild(item);
  });
}

// ─── Error / status display ───────────────────────────────────────────────────

function showStatus(msg, type = 'info') {
  const el = $('status-banner');
  if (!el) return;
  el.className = `status-banner ${type} visible`;
  if (type === 'loading') {
    el.innerHTML = `<div class="spinner" aria-hidden="true"></div><span>${escHtml(msg)}</span>`;
  } else {
    el.textContent = msg;
  }
}

function clearStatus() {
  const el = $('status-banner');
  if (el) el.className = 'status-banner';
}

// ─── Core: run PCA and re-render everything ───────────────────────────────────

function runAndRender() {
  const dataset = State.currentDataset;
  if (!dataset) { clearStatus(); renderAll(null); return; }

  // Validate selected features
  const featNames = State.selectedFeatures;
  if (featNames.length < 2) {
    showStatus('Select at least 2 features to compute PCA.', 'error');
    State.pcaResult = null;
    renderAll(null);
    return;
  }

  // Build feature index map
  const allNames = dataset.featureNames;
  const featureIndices = featNames
    .map(n => allNames.indexOf(n))
    .filter(i => i >= 0);

  if (featureIndices.length < 2) {
    showStatus('At least 2 valid features required.', 'error');
    State.pcaResult = null;
    renderAll(null);
    return;
  }

  // Build matrix
  const X = dataset.X.map(row => featureIndices.map(i => row[i]));

  // Check for constant columns
  const constantWarnings = [];
  featureIndices.forEach((origIdx, colIdx) => {
    const col = X.map(r => r[colIdx]);
    const mean = col.reduce((a, b) => a + b, 0) / col.length;
    const variance = col.reduce((a, v) => a + (v - mean) ** 2, 0);
    if (variance === 0) {
      constantWarnings.push(`Feature "${featNames[colIdx]}" is constant (zero variance) — it carries no information.`);
    }
  });

  if (constantWarnings.length > 0) {
    showStatus(constantWarnings.join(' ') + ' It will be present but contribute nothing.', 'error');
  } else {
    clearStatus();
  }

  showStatus('Computing PCA…', 'loading');

  // Use setTimeout so loading spinner renders before sync compute
  setTimeout(() => {
    try {
      const result = PCA.run(X, dataset.labels, featNames, {
        standardize: State.standardize,
        nComponents: featNames.length,
      });
      State.pcaResult = result;

      // Clamp PC indices if needed
      const k = result.loadings.length;
      if (State.pcX >= k) State.pcX = 0;
      if (State.pcY >= k) State.pcY = Math.min(1, k - 1);

      clearStatus();
      if (result.sanity && !result.sanity.ok) {
        showStatus('Warning: internal sanity check did not fully pass. Results may be imprecise for this dataset.', 'error');
      }

      renderAll(result);
    } catch (err) {
      State.pcaResult = null;
      showStatus('PCA error: ' + err.message, 'error');
      renderAll(null);
    }
  }, 10);
}

function renderAll(result) {
  populatePCSelectors();
  renderScatter();
  renderScree();
  renderLoadingsBiplot();
  renderLoadingsTable();
  updateStats();
  updateLegend();
}

// ─── Hover / tooltip ─────────────────────────────────────────────────────────

function onScatterMouseMove(e) {
  const canvas = $('scatter-canvas');
  if (!canvas || !State.pcaResult) return;

  const ps = canvas._plotState;
  if (!ps) return;

  const rect = canvas.getBoundingClientRect();
  const mx = e.clientX - rect.left;
  const my = e.clientY - rect.top;

  const result = State.pcaResult;
  const pcX = State.pcX, pcY = State.pcY;
  const r = State.pointSize + 5;

  let closest = null;
  let closestDist = r;

  result.scores.forEach((row, i) => {
    const cx = ps.toCanvasX(row[pcX]);
    const cy = ps.toCanvasY(row[pcY]);
    const d = Math.hypot(mx - cx, my - cy);
    if (d < closestDist) { closestDist = d; closest = i; }
  });

  const tooltip = $('tooltip');
  if (closest !== null) {
    State.hoveredPoint = closest;
    const row = result.scores[closest];
    const lbl = result.labels[closest];
    tooltip.innerHTML = `<b>Sample ${closest + 1}</b><br>Label: ${escHtml(lbl)}<br>PC${pcX + 1}: ${row[pcX].toFixed(4)}<br>PC${pcY + 1}: ${row[pcY].toFixed(4)}`;
    tooltip.className = 'visible';
    tooltip.style.left = (e.clientX + 12) + 'px';
    tooltip.style.top  = (e.clientY - 10) + 'px';
  } else {
    State.hoveredPoint = null;
    tooltip.className = '';
  }

  renderScatter(); // re-render for highlight
}

function onScatterMouseLeave() {
  State.hoveredPoint = null;
  $('tooltip').className = '';
  renderScatter();
}

// ─── Export functions ─────────────────────────────────────────────────────────

function exportScatterPNG() {
  const canvas = $('scatter-canvas');
  if (!canvas) return;
  const link = document.createElement('a');
  link.download = 'axis-scatter.png';
  link.href = canvas.toDataURL('image/png');
  link.click();
}

function exportScreePNG() {
  const canvas = $('scree-canvas');
  if (!canvas) return;
  const link = document.createElement('a');
  link.download = 'axis-scree.png';
  link.href = canvas.toDataURL('image/png');
  link.click();
}

function exportBiplotPNG() {
  const canvas = $('biplot-canvas');
  if (!canvas) return;
  const link = document.createElement('a');
  link.download = 'axis-biplot.png';
  link.href = canvas.toDataURL('image/png');
  link.click();
}

function exportScoresCSV() {
  const result = State.pcaResult;
  if (!result) return;

  const k = result.loadings.length;
  const headers = ['sample_id', 'label', ...Array.from({ length: k }, (_, i) => `PC${i + 1}`)];
  const rows = result.scores.map((row, i) => [
    i + 1,
    `"${result.labels[i].replace(/"/g, '""')}"`,
    ...Array.from(row).map(v => v.toFixed(6)),
  ]);

  const csv = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.download = 'axis-scores.csv';
  link.href = url;
  link.click();
  URL.revokeObjectURL(url);
}

// ─── CSV paste ────────────────────────────────────────────────────────────────

function handleCSVPaste() {
  const textarea = $('csv-input');
  if (!textarea) return;
  const text = textarea.value.trim();
  if (!text) { showStatus('Paste CSV text above, then click Load CSV.', 'info'); return; }

  try {
    const parsed = DATASETS.parseCSV(text, null);
    State.csvWarnings = parsed.warnings || [];

    const dataset = {
      id: 'custom',
      name: 'Custom CSV',
      description: 'User-pasted CSV data.',
      featureNames: parsed.featureNames,
      labelColumn: parsed.labelColumn,
      X: parsed.X,
      labels: parsed.labels,
    };

    // Add/update in registry
    State.datasets['custom'] = dataset;

    // Update dataset selector
    const sel = $('dataset-sel');
    let opt = sel.querySelector('option[value="custom"]');
    if (!opt) {
      opt = new Option('Custom CSV', 'custom');
      sel.appendChild(opt);
    }
    sel.value = 'custom';

    switchDataset('custom');

    if (State.csvWarnings.length > 0) {
      showStatus('Loaded with warnings: ' + State.csvWarnings.join(' | '), 'info');
    }
  } catch (err) {
    showStatus('CSV parse error: ' + err.message, 'error');
  }
}

// ─── Dataset switch ───────────────────────────────────────────────────────────

function switchDataset(id) {
  const dataset = State.datasets[id];
  if (!dataset) { showStatus('Dataset not available.', 'error'); return; }

  State.currentDataset = dataset;
  State.pcX = 0;
  State.pcY = 1;
  State.hoveredPoint = null;
  State.pcaResult = null;

  populateFeatureList(dataset);
  runAndRender();
}

// ─── Resize handling ──────────────────────────────────────────────────────────

let resizeTimer;
function onResize() {
  clearTimeout(resizeTimer);
  resizeTimer = setTimeout(() => {
    if (State.pcaResult) {
      renderScatter();
      renderScree();
      renderLoadingsBiplot();
    }
  }, 120);
}

// ─── Method panel toggle ──────────────────────────────────────────────────────

function toggleMethod() {
  const body = $('method-body');
  const btn  = $('method-toggle');
  if (!body || !btn) return;
  const isHidden = body.classList.toggle('hidden');
  btn.textContent = isHidden ? 'Show details' : 'Hide details';
  btn.setAttribute('aria-expanded', String(!isHidden));
}

// ─── Init ─────────────────────────────────────────────────────────────────────

async function init() {
  showStatus('Loading datasets…', 'loading');

  // Load all datasets (iris is async)
  try {
    const registry = await DATASETS.loadAll();
    State.datasets = {};
    Object.entries(registry).forEach(([id, ds]) => {
      if (ds) State.datasets[id] = ds;
    });
  } catch (err) {
    showStatus('Failed to load datasets: ' + err.message, 'error');
    return;
  }

  // Populate dataset selector
  const sel = $('dataset-sel');
  sel.innerHTML = '';
  Object.values(State.datasets).forEach(ds => {
    sel.add(new Option(ds.name, ds.id));
  });

  // Wire controls
  sel.addEventListener('change', () => {
    if (sel.value !== 'custom') switchDataset(sel.value);
  });

  $('standardize-toggle').addEventListener('change', e => {
    State.standardize = e.target.checked;
    runAndRender();
  });
  // Set initial state
  $('standardize-toggle').checked = State.standardize;

  $('sel-pcx').addEventListener('change', e => {
    State.pcX = +e.target.value;
    renderAll(State.pcaResult);
  });

  $('sel-pcy').addEventListener('change', e => {
    State.pcY = +e.target.value;
    renderAll(State.pcaResult);
  });

  $('point-size').addEventListener('input', e => {
    State.pointSize = +e.target.value;
    $('point-size-val').textContent = e.target.value;
    renderScatter();
  });

  // Scatter hover
  const scatterCanvas = $('scatter-canvas');
  scatterCanvas.addEventListener('mousemove', onScatterMouseMove);
  scatterCanvas.addEventListener('mouseleave', onScatterMouseLeave);

  // Export buttons
  $('btn-export-scatter').addEventListener('click', exportScatterPNG);
  $('btn-export-scree').addEventListener('click', exportScreePNG);
  $('btn-export-biplot').addEventListener('click', exportBiplotPNG);
  $('btn-export-csv').addEventListener('click', exportScoresCSV);

  // CSV paste
  $('btn-load-csv').addEventListener('click', handleCSVPaste);

  // Method panel
  $('method-toggle').addEventListener('click', toggleMethod);

  // Resize
  window.addEventListener('resize', onResize);

  // Hide loading overlay
  const overlay = $('loading-overlay');
  if (overlay) overlay.className = 'hidden';

  // Load default dataset (Iris)
  switchDataset('iris');
}

// ─── Kick off ─────────────────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', init);
