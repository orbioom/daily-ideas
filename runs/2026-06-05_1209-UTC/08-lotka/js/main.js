/*
 * main.js — UI wiring, canvas rendering and animation for Lotka.
 * Depends on window.Lotka (js/ode.js). No external libraries.
 */

(function () {
  'use strict';

  var L = window.Lotka;

  // ----- DOM helpers --------------------------------------------------------
  function $(id) { return document.getElementById(id); }

  var reduceMotion = window.matchMedia &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // Parameters that have a slider + numeric twin.
  var FIELDS = ['alpha', 'beta', 'gamma', 'delta', 'K', 'x0', 'y0', 'T', 'dt'];

  // Defaults — produce a clean classic oscillation on first open.
  var DEFAULTS = {
    alpha: 1.0, beta: 0.1, gamma: 1.5, delta: 0.075,
    x0: 10, y0: 5, T: 50, dt: 0.01, K: 50, logistic: false
  };

  var PRESETS = [
    {
      name: 'Classic oscillation',
      vals: { alpha: 1.0, beta: 0.1, gamma: 1.5, delta: 0.075,
        x0: 10, y0: 5, T: 50, dt: 0.01, logistic: false }
    },
    {
      name: 'High amplitude',
      vals: { alpha: 1.1, beta: 0.4, gamma: 0.4, delta: 0.1,
        x0: 10, y0: 10, T: 40, dt: 0.005, logistic: false }
    },
    {
      name: 'Predator extinction',
      vals: { alpha: 0.5, beta: 0.12, gamma: 2.2, delta: 0.01,
        x0: 4, y0: 16, T: 20, dt: 0.01, logistic: false }
    },
    {
      name: 'Damped (logistic prey)',
      vals: { alpha: 1.0, beta: 0.1, gamma: 1.0, delta: 0.05,
        x0: 18, y0: 4, T: 120, dt: 0.01, logistic: true, K: 40 }
    }
  ];

  // Current integration result and bookkeeping.
  var sim = null;       // {t, prey, pred, V, n, blewUp}
  var clean = null;     // sanitized params/ctrl
  var bounds = null;    // plot bounds {tMax, popMax, ppXMax, ppYMax}

  // Animation state.
  var playing = false;
  var animIndex = 0;
  var lastFrameTs = 0;
  var rafId = null;

  // ----- read current control values ---------------------------------------
  function readControls() {
    var raw = { logistic: $('logistic').checked };
    FIELDS.forEach(function (f) {
      var el = $(f);
      if (el) raw[f] = parseFloat(el.value);
    });
    return raw;
  }

  // Sync the matching number input + the inline value label.
  function syncDisplay(f) {
    var slider = $(f);
    if (!slider) return;
    var num = $(f + '-num');
    if (num && document.activeElement !== num) num.value = slider.value;
    var lbl = $(f + '-val');
    if (lbl) lbl.textContent = formatVal(f, parseFloat(slider.value));
  }

  function formatVal(f, v) {
    if (f === 'dt') return v.toFixed(3);
    if (f === 'beta' || f === 'delta') return v.toFixed(3);
    if (f === 'T' || f === 'x0' || f === 'y0' || f === 'K') return String(v);
    return v.toFixed(2);
  }

  function syncAll() { FIELDS.forEach(syncDisplay); }

  // ----- the core: re-integrate + render ------------------------------------
  var recomputeTimer = null;
  function scheduleRecompute() {
    // Show loading affordance only when the job is potentially heavy.
    var raw = readControls();
    var approxSteps = raw.dt > 0 ? raw.T / raw.dt : 0;
    if (approxSteps > 40000) $('loadingTs').classList.add('show');
    if (recomputeTimer) clearTimeout(recomputeTimer);
    recomputeTimer = setTimeout(recompute, 16);
  }

  function recompute() {
    var raw = readControls();
    clean = L.sanitize(raw);

    // Reflect any clamping back into the UI (dt may have grown, etc.).
    applyClamps(clean);

    sim = L.integrate(clean);
    computeBounds();
    animIndex = sim.n - 1; // static = fully drawn
    render();
    updateReadouts();
    showWarnings(clean.warnings);
    $('loadingTs').classList.remove('show');
  }

  // Push sanitized dt / T back if they were clamped, without firing loops.
  function applyClamps(c) {
    setSilently('dt', c.ctrl.dt);
    setSilently('T', c.ctrl.T);
    if (c.params.logistic) setSilently('K', c.params.K);
  }

  function setSilently(f, value) {
    var slider = $(f);
    var num = $(f + '-num');
    if (slider && Math.abs(parseFloat(slider.value) - value) > 1e-9) {
      // Keep within the slider's own range.
      var mn = parseFloat(slider.min), mx = parseFloat(slider.max);
      var clampedForSlider = Math.min(Math.max(value, mn), mx);
      slider.value = clampedForSlider;
    }
    if (num) num.value = trimNum(value);
    var lbl = $(f + '-val');
    if (lbl) lbl.textContent = formatVal(f, value);
  }

  function trimNum(v) {
    if (Math.abs(v - Math.round(v)) < 1e-9) return String(Math.round(v));
    return String(parseFloat(v.toPrecision(5)));
  }

  function showWarnings(warnings) {
    var el = $('liveStatus');
    if (playing) return; // playing status takes precedence
    if (warnings && warnings.length) {
      el.className = 'status warn';
      el.textContent = '⚠ ' + warnings.join(' ');
    } else {
      el.className = 'status';
      el.textContent = '';
    }
  }

  // ----- bounds for plotting -------------------------------------------------
  function computeBounds() {
    var pr = L.range(sim.prey);
    var pd = L.range(sim.pred);
    var popMax = Math.max(pr.max, pd.max, 1) * 1.08;
    var eq = L.equilibrium(clean.params);
    var ppXMax = Math.max(pr.max, eq ? eq.x : 0, 1) * 1.15;
    var ppYMax = Math.max(pd.max, eq ? eq.y : 0, 1) * 1.15;
    bounds = {
      tMax: sim.t[sim.n - 1] || clean.ctrl.T,
      popMax: popMax,
      ppXMax: ppXMax,
      ppYMax: ppYMax,
      eq: eq
    };
  }

  // ----- canvas setup with devicePixelRatio ---------------------------------
  function setupCanvas(canvas, cssHeight) {
    var dpr = window.devicePixelRatio || 1;
    var rect = canvas.getBoundingClientRect();
    var cssW = rect.width || canvas.parentElement.clientWidth || 600;
    canvas.style.height = cssHeight + 'px';
    canvas.width = Math.max(1, Math.round(cssW * dpr));
    canvas.height = Math.max(1, Math.round(cssHeight * dpr));
    var ctx = canvas.getContext('2d');
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    return { ctx: ctx, w: cssW, h: cssHeight };
  }

  function cssVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  }

  // ----- render both plots ---------------------------------------------------
  function render() {
    if (!sim) return;
    drawTimeSeries();
    drawPhasePortrait();
    updateCanvasAria();
  }

  var PAD = { l: 52, r: 14, t: 14, b: 34 };

  function drawTimeSeries() {
    var c = setupCanvas($('tsCanvas'), 240);
    var ctx = c.ctx, w = c.w, h = c.h;
    ctx.clearRect(0, 0, w, h);

    var ink = cssVar('--text');
    var ink2 = cssVar('--text-2');
    var grid = cssVar('--panel-grid-line');
    var preyColor = cssVar('--prey-line');
    var predColor = cssVar('--pred-line');

    var x0 = PAD.l, x1 = w - PAD.r, y0 = PAD.t, y1 = h - PAD.b;
    var tMax = bounds.tMax || 1;
    var pMax = bounds.popMax || 1;

    function sx(t) { return x0 + (t / tMax) * (x1 - x0); }
    function sy(p) { return y1 - (p / pMax) * (y1 - y0); }

    drawGridAndAxes(ctx, x0, x1, y0, y1, grid, ink2, tMax, pMax, 'time t', 'population');

    // Series.
    drawSeries(ctx, sim.t, sim.prey, sx, sy, preyColor, sim.n);
    drawSeries(ctx, sim.t, sim.pred, sx, sy, predColor, sim.n);

    // Play cursor (moving point + vertical guide).
    if (animIndex < sim.n - 1 || playing) {
      var ti = sim.t[animIndex];
      var live = cssVar('--live');
      ctx.strokeStyle = live;
      ctx.globalAlpha = 0.7;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(sx(ti), y0); ctx.lineTo(sx(ti), y1);
      ctx.stroke();
      ctx.globalAlpha = 1;
      dot(ctx, sx(ti), sy(sim.prey[animIndex]), 4, live);
      dot(ctx, sx(ti), sy(sim.pred[animIndex]), 4, live);
    }
  }

  function drawSeries(ctx, xs, ys, sx, sy, color, n) {
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.lineJoin = 'round';
    ctx.beginPath();
    var upto = playing ? animIndex : n - 1;
    if (upto < 1) upto = n - 1; // when static, draw all
    for (var i = 0; i <= upto; i++) {
      var px = sx(xs[i]), py = sy(ys[i]);
      if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
    }
    ctx.stroke();
  }

  function drawGridAndAxes(ctx, x0, x1, y0, y1, grid, ink2, xMax, yMax, xLabel, yLabel) {
    ctx.strokeStyle = grid;
    ctx.fillStyle = ink2;
    ctx.lineWidth = 1;
    ctx.font = '11px ' + monoFont();
    ctx.textBaseline = 'middle';

    var ticks = 5;
    // Horizontal grid + y labels.
    for (var i = 0; i <= ticks; i++) {
      var gy = y1 - (i / ticks) * (y1 - y0);
      ctx.globalAlpha = i === 0 ? 0.9 : 0.5;
      ctx.beginPath(); ctx.moveTo(x0, gy); ctx.lineTo(x1, gy); ctx.stroke();
      ctx.globalAlpha = 1;
      ctx.textAlign = 'right';
      ctx.fillText(fmtTick((i / ticks) * yMax), x0 - 6, gy);
    }
    // Vertical grid + x labels.
    for (var j = 0; j <= ticks; j++) {
      var gx = x0 + (j / ticks) * (x1 - x0);
      ctx.globalAlpha = j === 0 ? 0.9 : 0.5;
      ctx.beginPath(); ctx.moveTo(gx, y0); ctx.lineTo(gx, y1); ctx.stroke();
      ctx.globalAlpha = 1;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';
      ctx.fillText(fmtTick((j / ticks) * xMax), gx, y1 + 6);
      ctx.textBaseline = 'middle';
    }
    // Axis titles.
    ctx.save();
    ctx.fillStyle = ink2;
    ctx.font = '12px ' + uiFont();
    ctx.textAlign = 'center';
    ctx.textBaseline = 'alphabetic';
    ctx.fillText(xLabel, (x0 + x1) / 2, y1 + 28);
    ctx.translate(14, (y0 + y1) / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillText(yLabel, 0, 0);
    ctx.restore();
  }

  function drawPhasePortrait() {
    var c = setupCanvas($('ppCanvas'), 320);
    var ctx = c.ctx, w = c.w, h = c.h;
    ctx.clearRect(0, 0, w, h);

    var ink2 = cssVar('--text-2');
    var ink3 = cssVar('--text-3');
    var grid = cssVar('--panel-grid-line');
    var preyColor = cssVar('--prey-line');
    var predColor = cssVar('--pred-line');

    var x0 = PAD.l, x1 = w - PAD.r, y0 = PAD.t, y1 = h - PAD.b;
    var xMax = bounds.ppXMax || 1;
    var yMax = bounds.ppYMax || 1;

    function sx(p) { return x0 + (p / xMax) * (x1 - x0); }
    function sy(p) { return y1 - (p / yMax) * (y1 - y0); }

    drawGridAndAxes(ctx, x0, x1, y0, y1, grid, ink2, xMax, yMax,
      'prey x', 'predator y');

    var p = clean.params;

    // Vector field (normalized arrows) on a coarse grid.
    var gridN = 11;
    ctx.strokeStyle = ink3;
    ctx.fillStyle = ink3;
    ctx.globalAlpha = 0.35;
    ctx.lineWidth = 1;
    for (var gi = 1; gi < gridN; gi++) {
      for (var gj = 1; gj < gridN; gj++) {
        var xx = (gi / gridN) * xMax;
        var yy = (gj / gridN) * yMax;
        var f = L.vectorField([xx, yy], p);
        var mag = Math.hypot(f[0], f[1]);
        if (mag < 1e-9) continue;
        var ux = f[0] / mag, uy = f[1] / mag;
        var len = 9;
        var ax = sx(xx), ay = sy(yy);
        var bx = ax + ux * len, by = ay - uy * len;
        arrow(ctx, ax, ay, bx, by);
      }
    }
    ctx.globalAlpha = 1;

    // Nullclines (classic model). Prey nullcline: y = alpha/beta (and x=0).
    // Predator nullcline: x = gamma/delta (and y=0).
    if (!p.logistic) {
      if (p.beta > 0) {
        var yNull = p.alpha / p.beta;
        dashedLine(ctx, sx(0), sy(yNull), sx(xMax), sy(yNull), predColor);
      }
      if (p.delta > 0) {
        var xNull = p.gamma / p.delta;
        dashedLine(ctx, sx(xNull), sy(0), sx(xNull), sy(yMax), preyColor);
      }
    } else if (p.beta > 0 && p.K > 0) {
      // Prey nullcline for logistic: y = (alpha/beta)(1 - x/K).
      ctx.strokeStyle = predColor;
      ctx.setLineDash([4, 4]);
      ctx.lineWidth = 1.25;
      ctx.beginPath();
      var first = true;
      for (var xn = 0; xn <= xMax; xn += xMax / 80) {
        var yn = (p.alpha / p.beta) * (1 - xn / p.K);
        var px = sx(xn), py = sy(yn);
        if (first) { ctx.moveTo(px, py); first = false; } else ctx.lineTo(px, py);
      }
      ctx.stroke();
      ctx.setLineDash([]);
      if (p.delta > 0) {
        var xN2 = p.gamma / p.delta;
        dashedLine(ctx, sx(xN2), sy(0), sx(xN2), sy(yMax), preyColor);
      }
    }

    // Trajectory.
    ctx.strokeStyle = preyColor;
    ctx.lineWidth = 2;
    ctx.lineJoin = 'round';
    ctx.beginPath();
    var upto = playing ? animIndex : sim.n - 1;
    if (upto < 1) upto = sim.n - 1;
    for (var i = 0; i <= upto; i++) {
      var tx = sx(sim.prey[i]), ty = sy(sim.pred[i]);
      if (i === 0) ctx.moveTo(tx, ty); else ctx.lineTo(tx, ty);
    }
    ctx.stroke();

    // Equilibrium point.
    if (bounds.eq) {
      var ex = sx(bounds.eq.x), ey = sy(bounds.eq.y);
      dot(ctx, ex, ey, 5, ink2);
      ctx.strokeStyle = ink2;
      ctx.globalAlpha = 0.6;
      ctx.beginPath();
      ctx.arc(ex, ey, 8, 0, Math.PI * 2);
      ctx.stroke();
      ctx.globalAlpha = 1;
    }

    // Initial point + moving cursor.
    dot(ctx, sx(sim.prey[0]), sy(sim.pred[0]), 3.5, predColor);
    if (animIndex < sim.n - 1 || playing) {
      var live = cssVar('--live');
      dot(ctx, sx(sim.prey[animIndex]), sy(sim.pred[animIndex]), 5, live);
    }
  }

  // ----- small canvas primitives --------------------------------------------
  function dot(ctx, x, y, r, color) {
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fill();
  }

  function arrow(ctx, ax, ay, bx, by) {
    ctx.beginPath();
    ctx.moveTo(ax, ay); ctx.lineTo(bx, by);
    var ang = Math.atan2(by - ay, bx - ax);
    var head = 3;
    ctx.lineTo(bx - head * Math.cos(ang - Math.PI / 6), by - head * Math.sin(ang - Math.PI / 6));
    ctx.moveTo(bx, by);
    ctx.lineTo(bx - head * Math.cos(ang + Math.PI / 6), by - head * Math.sin(ang + Math.PI / 6));
    ctx.stroke();
  }

  function dashedLine(ctx, x1, y1, x2, y2, color) {
    ctx.save();
    ctx.strokeStyle = color;
    ctx.setLineDash([4, 4]);
    ctx.lineWidth = 1.25;
    ctx.globalAlpha = 0.7;
    ctx.beginPath();
    ctx.moveTo(x1, y1); ctx.lineTo(x2, y2);
    ctx.stroke();
    ctx.restore();
  }

  function fmtTick(v) {
    if (Math.abs(v) >= 100) return v.toFixed(0);
    if (Math.abs(v) >= 10) return v.toFixed(0);
    if (Math.abs(v) >= 1) return v.toFixed(1);
    return v.toFixed(2);
  }

  function monoFont() {
    return 'ui-monospace, "JetBrains Mono", Menlo, Consolas, monospace';
  }
  function uiFont() {
    return 'Manrope, system-ui, -apple-system, sans-serif';
  }

  // ----- readouts -----------------------------------------------------------
  function updateReadouts() {
    var p = clean.params;
    var eq = bounds.eq;
    var preyR = L.range(sim.prey);
    var predR = L.range(sim.pred);
    var period = L.estimatePeriod(sim.t, sim.prey);

    var vInfo = conservedInfo();

    var items = [
      ['Equilibrium (x*, y*)',
        eq ? '(' + eq.x.toFixed(3) + ', ' + eq.y.toFixed(3) + ')' : '—'],
      ['Period estimate',
        isFinite(period) ? period.toFixed(3) + ' <small>time units</small>' :
          '<small>not periodic / too few peaks</small>'],
      ['Prey min / max',
        preyR.min.toFixed(2) + ' / ' + preyR.max.toFixed(2)],
      ['Predator min / max',
        predR.min.toFixed(2) + ' / ' + predR.max.toFixed(2)],
      ['Steps integrated', sim.n.toLocaleString() +
        (sim.blewUp ? ' <small>(stopped: blow-up)</small>' : '')],
      ['Conserved V', vInfo]
    ];

    var html = items.map(function (it) {
      return '<div class="readout"><div class="k">' + it[0] +
        '</div><div class="v">' + it[1] + '</div></div>';
    }).join('');
    $('readouts').innerHTML = html;
  }

  function conservedInfo() {
    if (clean.params.logistic) {
      return '<small>n/a for logistic model</small>';
    }
    // Drift of V across the (defined) series.
    var first = NaN, mn = Infinity, mx = -Infinity, count = 0;
    for (var i = 0; i < sim.n; i++) {
      var v = sim.V[i];
      if (!isFinite(v)) continue;
      if (count === 0) first = v;
      if (v < mn) mn = v;
      if (v > mx) mx = v;
      count++;
    }
    if (count === 0) return '<small>undefined (population reached 0)</small>';
    var drift = mx - mn;
    var rel = Math.abs(first) > 1e-9 ? (drift / Math.abs(first)) * 100 : drift;
    return first.toFixed(4) +
      ' <small>drift ' + drift.toExponential(2) +
      ' (' + rel.toFixed(3) + '%)</small>';
  }

  // ----- ARIA descriptions on canvases --------------------------------------
  function updateCanvasAria() {
    var period = L.estimatePeriod(sim.t, sim.prey);
    var preyR = L.range(sim.prey);
    var predR = L.range(sim.pred);
    var model = clean.params.logistic ? 'logistic-prey' : 'classic';
    var dyn;
    if (sim.blewUp) {
      dyn = 'numerically diverged';
    } else if (isFinite(period)) {
      dyn = 'oscillating with period about ' + period.toFixed(1) + ' time units';
    } else if (predR.max < 1e-3) {
      dyn = 'predators extinct';
    } else {
      dyn = 'settling toward equilibrium';
    }
    var tsAria = 'Time series of the ' + model + ' Lotka–Volterra model, ' + dyn +
      '. Prey ranges ' + preyR.min.toFixed(1) + ' to ' + preyR.max.toFixed(1) +
      ', predator ' + predR.min.toFixed(1) + ' to ' + predR.max.toFixed(1) + '.';
    $('tsCanvas').setAttribute('aria-label', tsAria);

    var eq = bounds.eq;
    var ppAria = 'Phase portrait of predator versus prey, ' + dyn +
      (eq ? ', equilibrium at prey ' + eq.x.toFixed(2) +
        ' and predator ' + eq.y.toFixed(2) : '') +
      '. Nullclines and a normalized vector field are overlaid.';
    $('ppCanvas').setAttribute('aria-label', ppAria);
  }

  // ----- animation ----------------------------------------------------------
  function setPlaying(on) {
    playing = on;
    var btn = $('playBtn');
    btn.setAttribute('aria-pressed', on ? 'true' : 'false');
    btn.querySelector('.play-label').textContent = on ? 'Pause' : 'Play';
    btn.setAttribute('aria-label',
      on ? 'Pause animation' : 'Play animation of the trajectory');
    var status = $('liveStatus');
    if (on) {
      status.className = 'status live';
      status.textContent = '● playing — tracing trajectory';
      if (animIndex >= sim.n - 1) animIndex = 0;
      lastFrameTs = 0;
      rafId = requestAnimationFrame(tick);
    } else {
      if (rafId) cancelAnimationFrame(rafId);
      rafId = null;
      showWarnings(clean ? clean.warnings : []);
      render();
    }
  }

  function tick(ts) {
    if (!playing) return;
    if (!lastFrameTs) lastFrameTs = ts;
    var dtMs = ts - lastFrameTs;
    lastFrameTs = ts;
    var speed = parseFloat($('speed').value) || 1;
    // Advance proportional to time so speed is frame-rate independent.
    // Aim to traverse the whole series in ~6s at speed 1.
    var perMs = (sim.n / 6000) * speed;
    animIndex += Math.max(1, Math.round(dtMs * perMs));
    if (animIndex >= sim.n - 1) {
      animIndex = sim.n - 1;
      render();
      setPlaying(false);
      return;
    }
    render();
    rafId = requestAnimationFrame(tick);
  }

  // ----- exports ------------------------------------------------------------
  function exportPng() {
    var ts = $('tsCanvas'), pp = $('ppCanvas');
    var gap = 16, pad = 16;
    var dpr = window.devicePixelRatio || 1;
    var W = Math.max(ts.width, pp.width) + pad * 2 * dpr;
    var H = ts.height + pp.height + gap * dpr + pad * 2 * dpr;
    var out = document.createElement('canvas');
    out.width = W; out.height = H;
    var ctx = out.getContext('2d');
    ctx.fillStyle = cssVar('--mist-2') || '#E7E9F0';
    ctx.fillRect(0, 0, W, H);
    ctx.drawImage(ts, pad * dpr, pad * dpr);
    ctx.drawImage(pp, pad * dpr, pad * dpr + ts.height + gap * dpr);
    triggerDownload(out.toDataURL('image/png'), 'lotka-plots.png');
  }

  function exportCsv() {
    var lines = ['t,prey,predator'];
    for (var i = 0; i < sim.n; i++) {
      lines.push(sim.t[i].toFixed(6) + ',' +
        sim.prey[i].toFixed(6) + ',' + sim.pred[i].toFixed(6));
    }
    var blob = new Blob([lines.join('\n')], { type: 'text/csv' });
    var url = URL.createObjectURL(blob);
    triggerDownload(url, 'lotka-series.csv');
    setTimeout(function () { URL.revokeObjectURL(url); }, 4000);
  }

  function triggerDownload(href, name) {
    var a = document.createElement('a');
    a.href = href; a.download = name;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  }

  // ----- presets -------------------------------------------------------------
  function buildPresets() {
    var host = $('presets');
    PRESETS.forEach(function (preset) {
      var b = document.createElement('button');
      b.type = 'button';
      b.textContent = preset.name;
      b.addEventListener('click', function () { applyPreset(preset.vals); });
      host.appendChild(b);
    });
  }

  function applyPreset(vals) {
    if (playing) setPlaying(false);
    $('logistic').checked = !!vals.logistic;
    toggleKField();
    FIELDS.forEach(function (f) {
      if (vals[f] === undefined) return;
      var slider = $(f), num = $(f + '-num');
      if (slider) {
        var mn = parseFloat(slider.min), mx = parseFloat(slider.max);
        slider.value = Math.min(Math.max(vals[f], mn), mx);
      }
      if (num) num.value = vals[f];
    });
    syncAll();
    recompute();
  }

  function toggleKField() {
    var on = $('logistic').checked;
    $('K-field').hidden = !on;
  }

  // ----- wiring -------------------------------------------------------------
  function wire() {
    FIELDS.forEach(function (f) {
      var slider = $(f);
      var num = $(f + '-num');
      if (slider) {
        slider.addEventListener('input', function () {
          if (num && document.activeElement !== num) num.value = slider.value;
          var lbl = $(f + '-val');
          if (lbl) lbl.textContent = formatVal(f, parseFloat(slider.value));
          scheduleRecompute();
        });
      }
      if (num) {
        num.addEventListener('input', function () {
          var v = parseFloat(num.value);
          if (isFinite(v) && slider) {
            var mn = parseFloat(slider.min), mx = parseFloat(slider.max);
            slider.value = Math.min(Math.max(v, mn), mx);
            var lbl = $(f + '-val');
            if (lbl) lbl.textContent = formatVal(f, v);
          }
          scheduleRecompute();
        });
      }
    });

    $('logistic').addEventListener('change', function () {
      toggleKField();
      scheduleRecompute();
    });

    $('playBtn').addEventListener('click', function () {
      if (!sim) return;
      setPlaying(!playing);
    });
    $('speed').addEventListener('input', function () { /* read live in tick */ });

    $('exportPng').addEventListener('click', exportPng);
    $('exportCsv').addEventListener('click', exportCsv);
    $('resetBtn').addEventListener('click', function () {
      applyPreset(DEFAULTS);
    });

    $('themeToggle').addEventListener('click', toggleTheme);

    var resizeTimer = null;
    window.addEventListener('resize', function () {
      if (resizeTimer) clearTimeout(resizeTimer);
      resizeTimer = setTimeout(function () { if (sim) render(); }, 120);
    });

    // If the OS reduced-motion preference flips, stop any animation.
    if (window.matchMedia) {
      var mq = window.matchMedia('(prefers-reduced-motion: reduce)');
      var onChange = function () {
        reduceMotion = mq.matches;
        if (reduceMotion && playing) setPlaying(false);
      };
      if (mq.addEventListener) mq.addEventListener('change', onChange);
      else if (mq.addListener) mq.addListener(onChange);
    }
  }

  // ----- theme --------------------------------------------------------------
  function toggleTheme() {
    var root = document.documentElement;
    var current = root.getAttribute('data-theme');
    var prefersDark = window.matchMedia &&
      window.matchMedia('(prefers-color-scheme: dark)').matches;
    var next;
    if (!current) {
      next = prefersDark ? 'light' : 'dark';
    } else {
      next = current === 'dark' ? 'light' : 'dark';
    }
    root.setAttribute('data-theme', next);
    if (sim) render(); // recolor canvases
  }

  // ----- boot ---------------------------------------------------------------
  function boot() {
    if (!L) {
      $('liveStatus').className = 'status warn';
      $('liveStatus').textContent = 'Failed to load the math module (js/ode.js).';
      return;
    }
    buildPresets();
    toggleKField();
    syncAll();
    wire();
    recompute();           // default sim runs immediately on open
    if (!reduceMotion) {
      // Leave static by default; user presses play. (Spec: reduced-motion ⇒ no auto.)
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
