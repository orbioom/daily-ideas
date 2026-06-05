/*
 * main.js — UI wiring, canvas rendering, and interaction for Cluster.
 *
 * Responsibilities:
 *   - hold the application state (points, centroids, assignments, history)
 *   - render the scatter, centroids, nearest-centroid region shading, and the
 *     inertia-vs-iteration and elbow charts directly to <canvas>
 *   - drive Lloyd iterations (Step / Run to convergence) with optional
 *     animation honoring prefers-reduced-motion
 *   - dataset generation, click-to-add, export (PNG/CSV), elbow, silhouette
 *   - keep ARIA labels / live metrics in sync; guard every edge case
 *
 * Depends on globals: KMeans (js/kmeans.js), Datasets (js/datasets.js).
 */
(function () {
  'use strict';

  const KM = window.KMeans;
  const DS = window.Datasets;

  /* Categorical palette read from CSS variables so dark mode swaps colours. */
  function clusterColors() {
    const styles = getComputedStyle(document.documentElement);
    const out = [];
    for (let i = 0; i < 10; i++) {
      out.push(styles.getPropertyValue('--c' + i).trim() || '#888');
    }
    return out;
  }

  /* ---------------- DOM refs ---------------- */
  const $ = (id) => document.getElementById(id);
  const scatter = $('scatter');
  const inertiaChart = $('inertia-chart');
  const elbowChart = $('elbow-chart');
  const emptyOverlay = $('empty-overlay');
  const busyOverlay = $('busy-overlay');
  const busyText = $('busy-text');
  const inlineMsg = $('inline-msg');

  const sctx = scatter.getContext('2d');
  const ictx = inertiaChart.getContext('2d');
  const ectx = elbowChart.getContext('2d');

  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const MAX_ITER = 100;
  const SILHOUETTE_CAP = 1500; // O(n^2) guard

  /* ---------------- Application state ---------------- */
  const state = {
    points: [],            // array of [x, y] in [0,1]
    centroids: [],         // array of [x, y]
    renderCentroids: [],    // animated positions
    assignments: null,     // Int32Array
    k: 3,
    method: 'kmeans++',
    iteration: 0,
    converged: false,
    inertia: null,
    history: [],           // inertia per iteration
    counts: [],
    silhouette: null,
    elbowData: null,
    seed: 1,
    dataset: 'blobs',
    isCustom: false,       // user added points by clicking
    computeMs: null,
    animating: false,
  };

  /* ---------------- DPR-aware canvas sizing ---------------- */
  function fitCanvas(canvas, ctx) {
    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.getBoundingClientRect();
    const w = Math.max(1, Math.round(rect.width));
    const h = Math.max(1, Math.round(rect.height));
    canvas.width = Math.round(w * dpr);
    canvas.height = Math.round(h * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    return { w: w, h: h };
  }

  /* Map normalized [0,1] data coords to canvas pixels with a margin. */
  function makeProjector(w, h, margin) {
    const m = margin;
    return {
      x: (nx) => m + nx * (w - 2 * m),
      y: (ny) => m + ny * (h - 2 * m),
      invX: (px) => (px - m) / (w - 2 * m),
      invY: (py) => (py - m) / (h - 2 * m),
    };
  }

  /* ---------------- Rendering: scatter ---------------- */
  function drawScatter() {
    const { w, h } = fitCanvas(scatter, sctx);
    const colors = clusterColors();
    const styles = getComputedStyle(document.documentElement);
    const bg = styles.getPropertyValue('--canvas-bg').trim() || '#ECEEF2';
    const grid = styles.getPropertyValue('--grid').trim() || 'rgba(0,0,0,0.1)';

    sctx.clearRect(0, 0, w, h);
    sctx.fillStyle = bg;
    sctx.fillRect(0, 0, w, h);

    const margin = Math.max(10, Math.min(w, h) * 0.04);
    const proj = makeProjector(w, h, margin);

    // Region shading: sample a coarse grid, colour each cell by nearest
    // centroid. Kept coarse (cellsize ~ 14px) to stay performant.
    const cents = state.renderCentroids.length ? state.renderCentroids : state.centroids;
    if (cents.length > 0) {
      const cell = 14;
      sctx.globalAlpha = 0.12;
      for (let py = margin; py < h - margin; py += cell) {
        for (let px = margin; px < w - margin; px += cell) {
          const nx = proj.invX(px + cell / 2);
          const ny = proj.invY(py + cell / 2);
          let best = 0;
          let bestD = Infinity;
          for (let c = 0; c < cents.length; c++) {
            const dx = nx - cents[c][0];
            const dy = ny - cents[c][1];
            const d = dx * dx + dy * dy;
            if (d < bestD) { bestD = d; best = c; }
          }
          sctx.fillStyle = colors[best % colors.length];
          sctx.fillRect(px, py, cell, cell);
        }
      }
      sctx.globalAlpha = 1;
    }

    // Grid lines (light).
    sctx.strokeStyle = grid;
    sctx.lineWidth = 1;
    sctx.beginPath();
    for (let g = 0; g <= 4; g++) {
      const gx = proj.x(g / 4);
      const gy = proj.y(g / 4);
      sctx.moveTo(gx, margin); sctx.lineTo(gx, h - margin);
      sctx.moveTo(margin, gy); sctx.lineTo(w - margin, gy);
    }
    sctx.stroke();

    // Points.
    const r = state.points.length > 400 ? 2.2 : 3;
    for (let i = 0; i < state.points.length; i++) {
      const p = state.points[i];
      const c = state.assignments ? state.assignments[i] : -1;
      sctx.beginPath();
      sctx.arc(proj.x(p[0]), proj.y(p[1]), r, 0, Math.PI * 2);
      if (c >= 0) {
        sctx.fillStyle = colors[c % colors.length];
        sctx.globalAlpha = 0.9;
      } else {
        sctx.fillStyle = styles.getPropertyValue('--text-3').trim() || '#888';
        sctx.globalAlpha = 0.7;
      }
      sctx.fill();
    }
    sctx.globalAlpha = 1;

    // Centroids: large ringed markers.
    for (let c = 0; c < cents.length; c++) {
      const cx = proj.x(cents[c][0]);
      const cy = proj.y(cents[c][1]);
      const col = colors[c % colors.length];
      // White halo
      sctx.beginPath();
      sctx.arc(cx, cy, 9, 0, Math.PI * 2);
      sctx.fillStyle = 'rgba(255,255,255,0.9)';
      sctx.fill();
      // Filled core
      sctx.beginPath();
      sctx.arc(cx, cy, 6.5, 0, Math.PI * 2);
      sctx.fillStyle = col;
      sctx.fill();
      // Ring
      sctx.beginPath();
      sctx.arc(cx, cy, 11, 0, Math.PI * 2);
      sctx.strokeStyle = col;
      sctx.lineWidth = 2;
      sctx.stroke();
      // Cross-hair center
      sctx.beginPath();
      sctx.moveTo(cx - 3, cy); sctx.lineTo(cx + 3, cy);
      sctx.moveTo(cx, cy - 3); sctx.lineTo(cx, cy + 3);
      sctx.strokeStyle = 'rgba(255,255,255,0.95)';
      sctx.lineWidth = 1.5;
      sctx.stroke();
    }

    updateCanvasAria();
  }

  function updateCanvasAria() {
    const inertia = state.inertia == null ? 'not computed' : state.inertia.toFixed(2);
    scatter.setAttribute(
      'aria-label',
      'Cluster scatter plot. ' + state.points.length + ' points, k=' + state.k +
      ', iteration ' + state.iteration + ', inertia ' + inertia +
      (state.converged ? ', converged.' : '.')
    );
  }

  /* ---------------- Rendering: inertia chart ---------------- */
  function drawInertiaChart() {
    const { w, h } = fitCanvas(inertiaChart, ictx);
    const styles = getComputedStyle(document.documentElement);
    const bg = styles.getPropertyValue('--canvas-bg').trim() || '#ECEEF2';
    const axis = styles.getPropertyValue('--axis').trim() || '#888';
    const text3 = styles.getPropertyValue('--text-3').trim() || '#888';
    const accent = styles.getPropertyValue('--c0').trim() || '#2F6FB0';

    ictx.clearRect(0, 0, w, h);
    ictx.fillStyle = bg;
    ictx.fillRect(0, 0, w, h);

    const pad = 26;
    const data = state.history;
    if (data.length === 0) {
      ictx.fillStyle = text3;
      ictx.font = '12px ' + monoFont();
      ictx.textAlign = 'center';
      ictx.fillText('Step to populate', w / 2, h / 2);
      return;
    }

    const maxV = Math.max.apply(null, data);
    const minV = Math.min.apply(null, data);
    const range = maxV - minV || 1;
    const n = data.length;

    // Axes.
    ictx.strokeStyle = axis;
    ictx.lineWidth = 1;
    ictx.beginPath();
    ictx.moveTo(pad, pad * 0.4);
    ictx.lineTo(pad, h - pad * 0.7);
    ictx.lineTo(w - pad * 0.4, h - pad * 0.7);
    ictx.stroke();

    const plotW = w - pad - pad * 0.4;
    const plotH = h - pad * 0.7 - pad * 0.4;
    const x = (i) => pad + (n === 1 ? plotW / 2 : (i / (n - 1)) * plotW);
    const y = (v) => pad * 0.4 + (1 - (v - minV) / range) * plotH;

    // Line.
    ictx.strokeStyle = accent;
    ictx.lineWidth = 2;
    ictx.beginPath();
    for (let i = 0; i < n; i++) {
      const px = x(i), py = y(data[i]);
      if (i === 0) ictx.moveTo(px, py); else ictx.lineTo(px, py);
    }
    ictx.stroke();
    // Points.
    ictx.fillStyle = accent;
    for (let i = 0; i < n; i++) {
      ictx.beginPath();
      ictx.arc(x(i), y(data[i]), 2.5, 0, Math.PI * 2);
      ictx.fill();
    }

    // Labels.
    ictx.fillStyle = text3;
    ictx.font = '10px ' + monoFont();
    ictx.textAlign = 'left';
    ictx.fillText(maxV.toFixed(1), pad + 3, pad * 0.4 + 9);
    ictx.fillText(minV.toFixed(1), pad + 3, h - pad * 0.7 - 3);
    ictx.textAlign = 'right';
    ictx.fillText('iter ' + (n - 1), w - pad * 0.4, h - 3);
  }

  /* ---------------- Rendering: elbow chart ---------------- */
  function drawElbowChart() {
    const { w, h } = fitCanvas(elbowChart, ectx);
    const styles = getComputedStyle(document.documentElement);
    const bg = styles.getPropertyValue('--canvas-bg').trim() || '#ECEEF2';
    const axis = styles.getPropertyValue('--axis').trim() || '#888';
    const text3 = styles.getPropertyValue('--text-3').trim() || '#888';
    const accent = styles.getPropertyValue('--c2').trim() || '#4B8B5A';

    ectx.clearRect(0, 0, w, h);
    ectx.fillStyle = bg;
    ectx.fillRect(0, 0, w, h);

    const data = state.elbowData;
    if (!data || data.length === 0) {
      ectx.fillStyle = text3;
      ectx.font = '12px ' + monoFont();
      ectx.textAlign = 'center';
      ectx.fillText('Run elbow sweep', w / 2, h / 2);
      return;
    }

    const pad = 26;
    const vals = data.map((d) => d.inertia);
    const maxV = Math.max.apply(null, vals);
    const minV = Math.min.apply(null, vals);
    const range = maxV - minV || 1;
    const n = data.length;

    ectx.strokeStyle = axis;
    ectx.lineWidth = 1;
    ectx.beginPath();
    ectx.moveTo(pad, pad * 0.4);
    ectx.lineTo(pad, h - pad * 0.7);
    ectx.lineTo(w - pad * 0.4, h - pad * 0.7);
    ectx.stroke();

    const plotW = w - pad - pad * 0.4;
    const plotH = h - pad * 0.7 - pad * 0.4;
    const x = (i) => pad + (n === 1 ? plotW / 2 : (i / (n - 1)) * plotW);
    const y = (v) => pad * 0.4 + (1 - (v - minV) / range) * plotH;

    ectx.strokeStyle = accent;
    ectx.lineWidth = 2;
    ectx.beginPath();
    for (let i = 0; i < n; i++) {
      const px = x(i), py = y(data[i].inertia);
      if (i === 0) ectx.moveTo(px, py); else ectx.lineTo(px, py);
    }
    ectx.stroke();

    ectx.fillStyle = accent;
    ectx.font = '9px ' + monoFont();
    ectx.textAlign = 'center';
    for (let i = 0; i < n; i++) {
      const px = x(i), py = y(data[i].inertia);
      ectx.beginPath();
      ectx.arc(px, py, 2.5, 0, Math.PI * 2);
      ectx.fill();
      ectx.fillStyle = text3;
      ectx.fillText('k' + data[i].k, px, h - 5);
      ectx.fillStyle = accent;
    }
  }

  function monoFont() {
    return "'JetBrains Mono', ui-monospace, Menlo, Consolas, monospace";
  }

  /* ---------------- Metrics panel ---------------- */
  function updateMetrics() {
    $('m-iter').textContent = String(state.iteration);
    const conv = $('m-converged');
    conv.textContent = state.converged ? 'yes' : 'no';
    conv.classList.toggle('live', state.converged);
    $('m-inertia').textContent = state.inertia == null ? '—' : state.inertia.toFixed(3);
    $('m-silhouette').textContent = state.silhouette == null ? '—' : state.silhouette.toFixed(4);
    $('m-n').textContent = String(state.points.length);
    $('m-time').textContent = state.computeMs == null ? '—' : state.computeMs.toFixed(1) + ' ms';

    const sizes = $('cluster-sizes');
    sizes.innerHTML = '';
    if (state.assignments && state.points.length > 0) {
      const counts = new Array(state.k).fill(0);
      for (let i = 0; i < state.assignments.length; i++) counts[state.assignments[i]]++;
      const colors = clusterColors();
      for (let c = 0; c < state.k; c++) {
        const chip = document.createElement('span');
        chip.className = 'size-chip';
        const dot = document.createElement('span');
        dot.className = 'size-dot';
        dot.style.background = colors[c % colors.length];
        chip.appendChild(dot);
        chip.appendChild(document.createTextNode('C' + c + ': ' + counts[c]));
        sizes.appendChild(chip);
      }
    }
  }

  function showMessage(msg) {
    if (!msg) { inlineMsg.hidden = true; inlineMsg.textContent = ''; return; }
    inlineMsg.hidden = false;
    inlineMsg.textContent = msg;
  }

  function setBusy(on, text) {
    busyOverlay.hidden = !on;
    if (text) busyText.textContent = text;
  }

  function updateEmptyState() {
    emptyOverlay.hidden = state.points.length > 0;
  }

  /* ---------------- Algorithm control ---------------- */

  /* Clamp k into [1, N] and reflect it in the UI. Returns the effective k. */
  function effectiveK() {
    const n = state.points.length;
    if (n === 0) return 0;
    return Math.max(1, Math.min(state.k, n));
  }

  function reinitCentroids() {
    showMessage('');
    const n = state.points.length;
    if (n === 0) {
      state.centroids = [];
      state.renderCentroids = [];
      state.assignments = null;
      resetRunState();
      drawScatter();
      updateMetrics();
      return;
    }
    const k = effectiveK();
    if (state.k > n) {
      showMessage('k (' + state.k + ') exceeds the number of points (' + n +
        '). Using k=' + n + '.');
    }
    const rng = KM.mulberry32(state.seed);
    state.centroids = KM.initCentroids(state.points, k, state.method, rng);
    state.renderCentroids = state.centroids.map((c) => c.slice());
    resetRunState();
    // Do an initial assignment so the very first view is a real clustering.
    const a = KM.assign(state.points, state.centroids);
    state.assignments = a.assignments;
    state.inertia = a.inertia;
    state.history = [a.inertia];
    state.silhouette = null;
    drawScatter();
    drawInertiaChart();
    updateMetrics();
  }

  function resetRunState() {
    state.iteration = 0;
    state.converged = false;
    state.history = [];
    state.silhouette = null;
    state.computeMs = null;
  }

  /* One Lloyd iteration, with optional animation of centroid movement. */
  function doStep(onDone) {
    if (state.points.length === 0) { showMessage('No points to cluster.'); return; }
    if (state.converged) { if (onDone) onDone(); return; }
    if (state.centroids.length === 0) reinitCentroids();
    if (state.animating) return;

    const t0 = performance.now();
    const prev = state.centroids.map((c) => c.slice());
    const res = KM.step(state.points, state.centroids);
    state.computeMs = performance.now() - t0;

    state.assignments = res.assignments;
    state.inertia = res.inertia;
    state.counts = res.counts;
    state.iteration += 1;
    state.history.push(res.inertia);
    state.silhouette = null;
    if (res.moved <= 1e-9) state.converged = true;

    animateCentroids(prev, res.centroids, () => {
      state.centroids = res.centroids;
      state.renderCentroids = res.centroids.map((c) => c.slice());
      drawScatter();
      drawInertiaChart();
      updateMetrics();
      if (onDone) onDone();
    });
  }

  function animateCentroids(from, to, done) {
    if (reducedMotion) {
      state.renderCentroids = to.map((c) => c.slice());
      done();
      return;
    }
    state.animating = true;
    const dur = 380;
    const t0 = performance.now();
    function frame(now) {
      const t = Math.min(1, (now - t0) / dur);
      const e = 1 - Math.pow(1 - t, 3); // easeOutCubic
      state.renderCentroids = from.map((f, i) => [
        f[0] + (to[i][0] - f[0]) * e,
        f[1] + (to[i][1] - f[1]) * e,
      ]);
      // Recolor points partway through for a smooth feel.
      drawScatter();
      if (t < 1) {
        requestAnimationFrame(frame);
      } else {
        state.animating = false;
        done();
      }
    }
    requestAnimationFrame(frame);
  }

  function runToConvergence() {
    if (state.points.length === 0) { showMessage('No points to cluster.'); return; }
    if (state.centroids.length === 0) reinitCentroids();
    let guard = 0;
    function next() {
      if (state.converged || state.iteration >= MAX_ITER || guard >= MAX_ITER) {
        if (!state.converged && state.iteration >= MAX_ITER) {
          showMessage('Reached max iterations (' + MAX_ITER + ') without full convergence.');
        }
        return;
      }
      guard++;
      doStep(() => {
        // Chain next iteration; with reduced motion this is effectively a loop.
        requestAnimationFrame(next);
      });
    }
    next();
  }

  function computeSilhouette() {
    if (state.points.length === 0 || !state.assignments) {
      showMessage('Cluster the points first.');
      return;
    }
    const k = effectiveK();
    if (k <= 1) { showMessage('Silhouette needs k ≥ 2.'); return; }
    if (state.points.length > SILHOUETTE_CAP) {
      showMessage('Silhouette skipped: N > ' + SILHOUETTE_CAP +
        ' is too costly (O(N²)). Reduce N to evaluate.');
      return;
    }
    setBusy(true, 'Computing silhouette…');
    // Defer so the busy overlay paints before the blocking computation.
    setTimeout(() => {
      const t0 = performance.now();
      state.silhouette = KM.silhouette(state.points, state.assignments, k);
      state.computeMs = performance.now() - t0;
      setBusy(false);
      updateMetrics();
    }, 20);
  }

  function runElbow() {
    if (state.points.length < 2) { showMessage('Need at least 2 points for the elbow.'); return; }
    setBusy(true, 'Running elbow sweep…');
    $('elbow-hint').textContent = 'Computing…';
    setTimeout(() => {
      const kMax = Math.min(10, state.points.length);
      state.elbowData = KM.elbow(state.points, kMax, {
        restarts: 4,
        seed: state.seed,
        maxIter: 50,
      });
      setBusy(false);
      $('elbow-hint').textContent = 'Lower-left bend suggests a good k.';
      drawElbowChart();
    }, 20);
  }

  /* ---------------- Dataset generation ---------------- */
  function regenerate() {
    showMessage('');
    state.isCustom = false;
    const n = parseInt($('n-slider').value, 10);
    const spread = parseFloat($('spread-slider').value);
    const genk = parseInt($('genk-slider').value, 10);
    const preset = $('preset').value;
    state.dataset = preset;
    state.points = DS.generate(preset, {
      n: n,
      k: genk,
      spread: spread,
      noise: spread,
      seed: state.seed,
    });
    state.assignments = null;
    state.elbowData = null;
    updateEmptyState();
    reinitCentroids();
    drawElbowChart();
  }

  function clearPoints() {
    state.points = [];
    state.centroids = [];
    state.renderCentroids = [];
    state.assignments = null;
    state.elbowData = null;
    state.isCustom = true;
    resetRunState();
    state.inertia = null;
    updateEmptyState();
    drawScatter();
    drawInertiaChart();
    drawElbowChart();
    updateMetrics();
    showMessage('');
  }

  /* Click-to-add points (canvas enhancement). */
  function onCanvasClick(evt) {
    const rect = scatter.getBoundingClientRect();
    const px = evt.clientX - rect.left;
    const py = evt.clientY - rect.top;
    const margin = Math.max(10, Math.min(rect.width, rect.height) * 0.04);
    const proj = makeProjector(rect.width, rect.height, margin);
    const nx = Math.max(0, Math.min(1, proj.invX(px)));
    const ny = Math.max(0, Math.min(1, proj.invY(py)));
    state.points.push([nx, ny]);
    state.isCustom = true;
    updateEmptyState();
    showMessage('');
    // Re-cluster lightly: keep centroids but reassign so the new point colours.
    if (state.centroids.length > 0) {
      const a = KM.assign(state.points, state.centroids);
      state.assignments = a.assignments;
      state.inertia = a.inertia;
    } else if (state.points.length >= state.k) {
      reinitCentroids();
      return;
    }
    drawScatter();
    updateMetrics();
  }

  /* ---------------- Export ---------------- */
  function exportPNG() {
    if (state.points.length === 0) { showMessage('Nothing to export.'); return; }
    // Re-render at a higher resolution onto an offscreen canvas for crisp PNG.
    const link = document.createElement('a');
    link.download = 'cluster-plot.png';
    link.href = scatter.toDataURL('image/png');
    link.click();
  }

  function exportCSV() {
    if (state.points.length === 0) { showMessage('Nothing to export.'); return; }
    const lines = ['x,y,cluster'];
    for (let i = 0; i < state.points.length; i++) {
      const c = state.assignments ? state.assignments[i] : -1;
      lines.push(
        state.points[i][0].toFixed(6) + ',' +
        state.points[i][1].toFixed(6) + ',' + c
      );
    }
    const blob = new Blob([lines.join('\n')], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.download = 'cluster-points.csv';
    link.href = url;
    link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }

  /* ---------------- Theme ---------------- */
  function cycleTheme() {
    const order = ['auto', 'light', 'dark'];
    const cur = document.documentElement.getAttribute('data-theme') || 'auto';
    const next = order[(order.indexOf(cur) + 1) % order.length];
    document.documentElement.setAttribute('data-theme', next);
    $('theme-label').textContent = 'Theme: ' + next.charAt(0).toUpperCase() + next.slice(1);
    // Redraw so canvas colours pick up the new theme.
    drawScatter();
    drawInertiaChart();
    drawElbowChart();
    updateMetrics();
  }

  /* ---------------- Spread/gen-k field visibility ---------------- */
  function updateFieldVisibility() {
    const preset = $('preset').value;
    const spreadField = $('spread-field');
    const genkField = $('gen-k-field');
    // Uniform has neither spread nor generated-k; moons has noise (reuse spread) but no k.
    if (preset === 'uniform') {
      spreadField.style.display = 'none';
      genkField.style.display = 'none';
    } else if (preset === 'moons') {
      spreadField.style.display = '';
      genkField.style.display = 'none';
    } else {
      spreadField.style.display = '';
      genkField.style.display = '';
    }
  }

  /* ---------------- Wiring ---------------- */
  function wire() {
    $('btn-step').addEventListener('click', () => doStep());
    $('btn-run').addEventListener('click', runToConvergence);
    $('btn-reset').addEventListener('click', () => { reinitCentroids(); showMessage(''); });
    $('btn-reinit').addEventListener('click', () => reinitCentroids());
    $('btn-silhouette').addEventListener('click', computeSilhouette);
    $('btn-elbow').addEventListener('click', runElbow);
    $('btn-regen').addEventListener('click', regenerate);
    $('btn-clear').addEventListener('click', clearPoints);
    $('btn-png').addEventListener('click', exportPNG);
    $('btn-csv').addEventListener('click', exportCSV);
    $('theme-toggle').addEventListener('click', cycleTheme);

    $('k-slider').addEventListener('input', (e) => {
      state.k = parseInt(e.target.value, 10);
      $('k-val').textContent = String(state.k);
      reinitCentroids();
    });
    $('seed-method').addEventListener('change', (e) => {
      state.method = e.target.value;
      reinitCentroids();
    });
    $('preset').addEventListener('change', () => { updateFieldVisibility(); regenerate(); });
    $('n-slider').addEventListener('input', (e) => {
      $('n-val').textContent = e.target.value;
    });
    $('n-slider').addEventListener('change', regenerate);
    $('spread-slider').addEventListener('input', (e) => {
      $('spread-val').textContent = parseFloat(e.target.value).toFixed(2);
    });
    $('spread-slider').addEventListener('change', regenerate);
    $('genk-slider').addEventListener('input', (e) => {
      $('genk-val').textContent = e.target.value;
    });
    $('genk-slider').addEventListener('change', regenerate);
    $('seed-input').addEventListener('change', (e) => {
      let v = parseInt(e.target.value, 10);
      if (!isFinite(v) || v < 0) v = 0;
      state.seed = v;
      e.target.value = String(v);
      regenerate();
    });

    scatter.addEventListener('click', onCanvasClick);

    // Resize handling (debounced via rAF).
    let resizePending = false;
    window.addEventListener('resize', () => {
      if (resizePending) return;
      resizePending = true;
      requestAnimationFrame(() => {
        resizePending = false;
        drawScatter();
        drawInertiaChart();
        drawElbowChart();
      });
    });

    // Re-render canvases when the OS theme changes while in auto mode.
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      if ((document.documentElement.getAttribute('data-theme') || 'auto') === 'auto') {
        drawScatter(); drawInertiaChart(); drawElbowChart(); updateMetrics();
      }
    });
  }

  /* ---------------- Init ---------------- */
  function init() {
    state.k = parseInt($('k-slider').value, 10);
    state.seed = parseInt($('seed-input').value, 10) || 1;
    state.method = $('seed-method').value;
    wire();
    updateFieldVisibility();
    // Preload a sample dataset and show an initial clustering immediately.
    regenerate();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
