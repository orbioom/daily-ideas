// main.js — Spectra
// UI wiring, control state, and canvas rendering of the waveform, power
// spectrum and spectrogram. Depends on js/fft.js and js/signal.js (global
// namespaces SpectraFFT and SpectraSignal).

'use strict';

(function () {
  const FFT = window.SpectraFFT;
  const SIG = window.SpectraSignal;

  // ---------- constants ----------
  const N_MIN = 256;
  const N_MAX = 8192;
  const SEED = 0x53504543; // "SPEC" — fixed seed for reproducible noise
  const DB_FLOOR = -120;

  // ---------- state ----------
  const state = {
    preset: 'twoTones',
    Fs: 1000,
    N: 1024,
    windowType: 'hann',
    scale: 'db', // 'db' | 'lin'
    stftWin: 256,
    overlap: 0.5,
    components: [
      { freq: 50, amp: 1.0 },
      { freq: 120, amp: 0.5 },
    ],
    // computed
    signal: null,
    spectrum: null, // {freqs, mag, psd, N, df}
    peaks: [],
  };

  // ---------- element refs ----------
  const $ = (id) => document.getElementById(id);
  const els = {
    preset: $('preset'),
    customEditor: $('customEditor'),
    components: $('components'),
    addComp: $('addComp'),
    fs: $('fs'),
    nsamp: $('nsamp'),
    run: $('run'),
    signalErr: $('signalErr'),
    aliasWarn: $('aliasWarn'),
    window: $('window'),
    scaleLin: $('scaleLin'),
    scaleDb: $('scaleDb'),
    stftWin: $('stftWin'),
    stftOverlap: $('stftOverlap'),
    roDf: $('roDf'), roNyq: $('roNyq'), roPeak: $('roPeak'),
    roBin: $('roBin'), roN: $('roN'), roTime: $('roTime'),
    exportPng: $('exportPng'), exportCsv: $('exportCsv'),
    waveCanvas: $('waveCanvas'), waveDesc: $('waveDesc'),
    specCanvas: $('specCanvas'), specDesc: $('specDesc'),
    spectroCanvas: $('spectroCanvas'), spectroDesc: $('spectroDesc'),
    spectroLoading: $('spectroLoading'),
    cbMin: $('cbMin'), cbMax: $('cbMax'), colorbar: $('colorbar'),
    themeToggle: $('themeToggle'),
  };

  // ---------- viridis-like colormap ----------
  // Sampled stops from the viridis colormap (data, not chrome).
  const VIRIDIS = [
    [68, 1, 84], [71, 44, 122], [59, 81, 139], [44, 113, 142],
    [33, 144, 141], [39, 173, 129], [92, 200, 99], [170, 220, 50],
    [253, 231, 37],
  ];
  function viridis(t) {
    if (t < 0) t = 0; else if (t > 1) t = 1;
    const x = t * (VIRIDIS.length - 1);
    const i = Math.floor(x);
    const f = x - i;
    const a = VIRIDIS[i];
    const b = VIRIDIS[Math.min(i + 1, VIRIDIS.length - 1)];
    const r = Math.round(a[0] + (b[0] - a[0]) * f);
    const g = Math.round(a[1] + (b[1] - a[1]) * f);
    const bl = Math.round(a[2] + (b[2] - a[2]) * f);
    return [r, g, bl];
  }

  function cssVar(name) {
    return getComputedStyle(document.body).getPropertyValue(name).trim();
  }

  // ---------- HiDPI canvas sizing ----------
  function sizeCanvas(canvas, heightPx) {
    const dpr = window.devicePixelRatio || 1;
    const cssW = canvas.clientWidth || canvas.parentElement.clientWidth || 600;
    const cssH = heightPx;
    canvas.style.height = cssH + 'px';
    canvas.width = Math.max(1, Math.round(cssW * dpr));
    canvas.height = Math.max(1, Math.round(cssH * dpr));
    const ctx = canvas.getContext('2d');
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    return { ctx, w: cssW, h: cssH };
  }

  // ---------- number formatting ----------
  function fmt(v, d) {
    if (!isFinite(v)) return '—';
    return v.toFixed(d === undefined ? 2 : d);
  }

  // ========================================================
  //  SIGNAL GENERATION
  // ========================================================
  function buildSignal() {
    const Fs = state.Fs;
    const N = state.N;
    if (state.preset === 'custom') {
      return SIG.sumOfSines(state.components, Fs, N);
    }
    const preset = SIG.PRESETS[state.preset];
    return preset.make(Fs, N, SEED);
  }

  // ========================================================
  //  VALIDATION
  // ========================================================
  function readControls() {
    let errors = [];
    let warns = [];

    // Fs
    let Fs = parseFloat(els.fs.value);
    if (!isFinite(Fs) || Fs <= 0) {
      errors.push('Sample rate Fs must be a positive number.');
      Fs = state.Fs;
    }

    // N
    let N = parseInt(els.nsamp.value, 10);
    N = FFT.clampToPowerOfTwo(N, N_MIN, N_MAX);

    state.Fs = Fs;
    state.N = N;
    state.windowType = els.window.value;
    state.stftWin = Math.min(N, parseInt(els.stftWin.value, 10) || 256);
    state.overlap = parseFloat(els.stftOverlap.value) || 0;
    state.preset = els.preset.value;

    const nyq = Fs / 2;

    if (state.preset === 'custom') {
      const comps = [];
      const rows = els.components.querySelectorAll('.comp-row');
      if (rows.length === 0) {
        errors.push('Add at least one component for a custom signal.');
      }
      rows.forEach((row, idx) => {
        const f = parseFloat(row.querySelector('.f').value);
        const a = parseFloat(row.querySelector('.a').value);
        if (!isFinite(f)) {
          errors.push('Component ' + (idx + 1) + ': frequency must be numeric.');
          return;
        }
        if (!isFinite(a)) {
          errors.push('Component ' + (idx + 1) + ': amplitude must be numeric.');
          return;
        }
        if (f < 0) {
          errors.push('Component ' + (idx + 1) + ': frequency must be ≥ 0.');
          return;
        }
        if (f >= nyq) {
          warns.push('Component ' + (idx + 1) + ' at ' + fmt(f, 1) +
            ' Hz is at/above Nyquist (' + fmt(nyq, 1) + ' Hz) — it will alias.');
        }
        comps.push({ freq: f, amp: a });
      });
      if (comps.length > 0) state.components = comps;
    }

    return { errors, warns };
  }

  // ========================================================
  //  PLOTTING HELPERS
  // ========================================================
  function clearCanvas(ctx, w, h) {
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = cssVar('--plot-bg') || 'rgba(255,255,255,0.55)';
    ctx.fillRect(0, 0, w, h);
  }

  function drawAxes(ctx, m, opts) {
    const { x0, y0, x1, y1 } = m;
    const ink = cssVar('--plot-axis');
    const grid = cssVar('--plot-grid');
    ctx.save();
    ctx.font = '11px ui-monospace, monospace';
    ctx.fillStyle = ink;
    ctx.strokeStyle = grid;
    ctx.lineWidth = 1;

    // x ticks
    const xt = opts.xTicks || 6;
    for (let i = 0; i <= xt; i++) {
      const frac = i / xt;
      const px = x0 + (x1 - x0) * frac;
      ctx.beginPath();
      ctx.moveTo(px, y0); ctx.lineTo(px, y1);
      ctx.stroke();
      const val = opts.xMin + (opts.xMax - opts.xMin) * frac;
      ctx.textAlign = i === 0 ? 'left' : (i === xt ? 'right' : 'center');
      ctx.fillText(opts.xFmt(val), px, y0 + 14);
    }
    // y ticks
    const yt = opts.yTicks || 4;
    for (let i = 0; i <= yt; i++) {
      const frac = i / yt;
      const py = y0 - (y0 - y1) * frac;
      ctx.beginPath();
      ctx.moveTo(x0, py); ctx.lineTo(x1, py);
      ctx.stroke();
      const val = opts.yMin + (opts.yMax - opts.yMin) * frac;
      ctx.textAlign = 'right';
      ctx.textBaseline = 'middle';
      ctx.fillText(opts.yFmt(val), x0 - 6, py);
    }
    ctx.textBaseline = 'alphabetic';

    // axis labels
    ctx.fillStyle = cssVar('--plot-axis');
    ctx.textAlign = 'center';
    ctx.fillText(opts.xLabel, (x0 + x1) / 2, y0 + 30);
    ctx.save();
    ctx.translate(12, (y0 + y1) / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillText(opts.yLabel, 0, 0);
    ctx.restore();
    ctx.restore();
  }

  // ========================================================
  //  WAVEFORM
  // ========================================================
  function renderWaveform() {
    const c = els.waveCanvas;
    const { ctx, w, h } = sizeCanvas(c, 180);
    clearCanvas(ctx, w, h);
    const sig = state.signal;
    if (!sig) return;

    const pad = { l: 52, r: 14, t: 12, b: 40 };
    const m = { x0: pad.l, x1: w - pad.r, y0: h - pad.b, y1: pad.t };

    // amplitude range
    let amax = 1e-9;
    for (let i = 0; i < sig.length; i++) {
      const a = Math.abs(sig[i]);
      if (a > amax) amax = a;
    }
    amax *= 1.1;
    const T = sig.length / state.Fs;

    drawAxes(ctx, m, {
      xMin: 0, xMax: T, yMin: -amax, yMax: amax,
      xTicks: 6, yTicks: 4,
      xLabel: 'time (s)', yLabel: 'amplitude',
      xFmt: (v) => v.toFixed(T < 1 ? 3 : 2),
      yFmt: (v) => v.toFixed(1),
    });

    // signal line
    ctx.save();
    ctx.beginPath();
    ctx.rect(m.x0, m.y1, m.x1 - m.x0, m.y0 - m.y1);
    ctx.clip();
    ctx.strokeStyle = cssVar('--plot-line');
    ctx.lineWidth = 1.25;
    ctx.beginPath();
    const n = sig.length;
    const xspan = m.x1 - m.x0;
    for (let i = 0; i < n; i++) {
      const px = m.x0 + (i / (n - 1)) * xspan;
      const py = m.y0 - ((sig[i] + amax) / (2 * amax)) * (m.y0 - m.y1);
      if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
    }
    ctx.stroke();
    ctx.restore();

    setAria(c, els.waveDesc,
      'Waveform of synthetic ' + presetLabel() + '. Duration ' + fmt(T, 3) +
      ' seconds, ' + n + ' samples at ' + fmt(state.Fs, 0) +
      ' hertz, peak amplitude ' + fmt(amax / 1.1, 2) + '.');
  }

  // ========================================================
  //  POWER SPECTRUM
  // ========================================================
  function renderSpectrum() {
    const c = els.specCanvas;
    const { ctx, w, h } = sizeCanvas(c, 240);
    clearCanvas(ctx, w, h);
    const sp = state.spectrum;
    if (!sp) return;

    const pad = { l: 56, r: 14, t: 12, b: 40 };
    const m = { x0: pad.l, x1: w - pad.r, y0: h - pad.b, y1: pad.t };
    const nyq = state.Fs / 2;

    // y values per scale
    const useDb = state.scale === 'db';
    let yvals;
    let yMin, yMax, yLabel, yFmt;
    if (useDb) {
      // dB relative to global max magnitude
      let ref = 1e-12;
      for (let i = 0; i < sp.mag.length; i++) if (sp.mag[i] > ref) ref = sp.mag[i];
      yvals = new Float64Array(sp.mag.length);
      for (let i = 0; i < sp.mag.length; i++) {
        yvals[i] = FFT.toDb(sp.mag[i] * sp.mag[i], ref * ref, DB_FLOOR);
      }
      yMin = -80; yMax = 3;
      yLabel = 'magnitude (dB)';
      yFmt = (v) => v.toFixed(0);
    } else {
      yvals = sp.mag;
      let mx = 1e-9;
      for (let i = 0; i < sp.mag.length; i++) if (sp.mag[i] > mx) mx = sp.mag[i];
      yMin = 0; yMax = mx * 1.1;
      yLabel = 'magnitude';
      yFmt = (v) => v.toFixed(2);
    }

    drawAxes(ctx, m, {
      xMin: 0, xMax: nyq, yMin, yMax,
      xTicks: 6, yTicks: 4,
      xLabel: 'frequency (Hz)', yLabel,
      xFmt: (v) => v.toFixed(0),
      yFmt,
    });

    // spectrum line (filled under)
    ctx.save();
    ctx.beginPath();
    ctx.rect(m.x0, m.y1, m.x1 - m.x0, m.y0 - m.y1);
    ctx.clip();

    const xspan = m.x1 - m.x0;
    const yspan = m.y0 - m.y1;
    const toPx = (k) => m.x0 + (sp.freqs[k] / nyq) * xspan;
    const toPy = (val) => m.y0 - ((val - yMin) / (yMax - yMin)) * yspan;

    ctx.beginPath();
    for (let k = 0; k < yvals.length; k++) {
      const px = toPx(k);
      const py = toPy(yvals[k]);
      if (k === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
    }
    ctx.lineTo(m.x1, m.y0);
    ctx.lineTo(m.x0, m.y0);
    ctx.closePath();
    ctx.fillStyle = 'rgba(58,62,76,0.10)';
    ctx.fill();

    ctx.beginPath();
    for (let k = 0; k < yvals.length; k++) {
      const px = toPx(k);
      const py = toPy(yvals[k]);
      if (k === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
    }
    ctx.strokeStyle = cssVar('--plot-line');
    ctx.lineWidth = 1.3;
    ctx.stroke();
    ctx.restore();

    // peak annotations
    ctx.save();
    ctx.font = '11px ui-monospace, monospace';
    const peakColor = cssVar('--live') || '#86C79A';
    state.peaks.forEach((pk) => {
      const px = m.x0 + (pk.freq / nyq) * xspan;
      const yval = useDb
        ? FFT.toDb(pk.mag * pk.mag, (function () {
            let ref = 1e-12;
            for (let i = 0; i < sp.mag.length; i++) if (sp.mag[i] > ref) ref = sp.mag[i];
            return ref * ref;
          })(), DB_FLOOR)
        : pk.mag;
      const py = toPy(yval);
      ctx.fillStyle = peakColor;
      ctx.beginPath();
      ctx.arc(px, py, 3, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = peakColor;
      ctx.setLineDash([3, 3]);
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(px, py); ctx.lineTo(px, m.y0);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.textAlign = px > (m.x0 + m.x1) / 2 ? 'right' : 'left';
      ctx.fillText(fmt(pk.freq, 1) + ' Hz', px + (ctx.textAlign === 'right' ? -4 : 4), py - 6);
    });
    ctx.restore();

    const peakTxt = state.peaks.length
      ? state.peaks.map((p) => fmt(p.freq, 1) + ' Hz').join(', ')
      : 'none';
    setAria(c, els.specDesc,
      'Power spectrum, ' + (useDb ? 'decibel' : 'linear') + ' scale, ' +
      'frequency axis 0 to ' + fmt(nyq, 0) + ' hertz. Detected peaks at ' +
      peakTxt + '.');
  }

  // ========================================================
  //  SPECTROGRAM (STFT) — worker if available, else main thread
  // ========================================================
  let worker = null;
  let workerOk = false;
  let stftReqId = 0;
  try {
    worker = new Worker('js/worker.js');
    workerOk = true;
    worker.onmessage = (e) => {
      const d = e.data || {};
      if (d.type === 'stft-result' && d.id === stftReqId) {
        showLoading(false);
        drawSpectrogram(d.result);
      } else if (d.type === 'stft-error') {
        showLoading(false);
        drawSpectrogramError(d.error);
      }
    };
    worker.onerror = () => { workerOk = false; };
  } catch (err) {
    workerOk = false;
  }

  function showLoading(on) {
    els.spectroLoading.classList.toggle('hidden', !on);
  }

  function computeSpectrogram() {
    const sig = state.signal;
    if (!sig) return;
    const winSize = Math.min(state.stftWin, state.N);
    const hop = Math.max(1, Math.round(winSize * (1 - state.overlap)));
    showLoading(true);

    if (workerOk && worker) {
      stftReqId++;
      // Copy signal so we don't detach state.signal's buffer.
      const copy = Float64Array.from(sig);
      worker.postMessage(
        { type: 'stft', id: stftReqId, signal: copy, Fs: state.Fs,
          winSize, hop, windowType: state.windowType },
        [copy.buffer]
      );
    } else {
      // main-thread fallback with a yield so the spinner can paint
      setTimeout(() => {
        try {
          const result = FFT.spectrogram(sig, state.Fs, winSize, hop, state.windowType);
          showLoading(false);
          drawSpectrogram(result);
        } catch (err) {
          showLoading(false);
          drawSpectrogramError(String(err && err.message || err));
        }
      }, 20);
    }
  }

  function drawSpectrogramError(msg) {
    const c = els.spectroCanvas;
    const { ctx, w, h } = sizeCanvas(c, 220);
    clearCanvas(ctx, w, h);
    ctx.fillStyle = cssVar('--plot-axis');
    ctx.font = '12px ui-monospace, monospace';
    ctx.textAlign = 'center';
    ctx.fillText('spectrogram unavailable: ' + msg, w / 2, h / 2);
  }

  function drawSpectrogram(result) {
    const c = els.spectroCanvas;
    const { ctx, w, h } = sizeCanvas(c, 220);
    clearCanvas(ctx, w, h);
    const { cols, rows, data, minDb, maxDb } = result;

    const pad = { l: 56, r: 14, t: 12, b: 40 };
    const m = { x0: pad.l, x1: w - pad.r, y0: h - pad.b, y1: pad.t };
    const plotW = m.x1 - m.x0;
    const plotH = m.y0 - m.y1;
    const nyq = state.Fs / 2;
    const range = (maxDb - minDb) || 1;

    // render heatmap to an offscreen buffer then scale into the plot rect
    const off = document.createElement('canvas');
    off.width = cols; off.height = rows;
    const octx = off.getContext('2d');
    const img = octx.createImageData(cols, rows);
    for (let col = 0; col < cols; col++) {
      for (let r = 0; r < rows; r++) {
        const d = data[col * rows + r];
        const t = (d - minDb) / range;
        const [cr, cg, cb] = viridis(t);
        // flip vertically: row 0 (DC) at bottom
        const py = rows - 1 - r;
        const idx = (py * cols + col) * 4;
        img.data[idx] = cr;
        img.data[idx + 1] = cg;
        img.data[idx + 2] = cb;
        img.data[idx + 3] = 255;
      }
    }
    octx.putImageData(img, 0, 0);

    ctx.imageSmoothingEnabled = true;
    ctx.drawImage(off, 0, 0, cols, rows, m.x0, m.y1, plotW, plotH);

    // axes overlay (no grid over the heatmap for clarity)
    ctx.save();
    ctx.font = '11px ui-monospace, monospace';
    ctx.fillStyle = cssVar('--plot-axis');
    const totalTime = state.N / state.Fs;
    // x ticks (time)
    for (let i = 0; i <= 6; i++) {
      const frac = i / 6;
      const px = m.x0 + plotW * frac;
      ctx.textAlign = i === 0 ? 'left' : (i === 6 ? 'right' : 'center');
      ctx.fillText((totalTime * frac).toFixed(totalTime < 1 ? 3 : 2), px, m.y0 + 14);
    }
    // y ticks (freq)
    ctx.textAlign = 'right';
    ctx.textBaseline = 'middle';
    for (let i = 0; i <= 4; i++) {
      const frac = i / 4;
      const py = m.y0 - plotH * frac;
      ctx.fillText((nyq * frac).toFixed(0), m.x0 - 6, py);
    }
    ctx.textBaseline = 'alphabetic';
    ctx.textAlign = 'center';
    ctx.fillText('time (s)', (m.x0 + m.x1) / 2, m.y0 + 30);
    ctx.save();
    ctx.translate(12, (m.y0 + m.y1) / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillText('frequency (Hz)', 0, 0);
    ctx.restore();
    ctx.restore();

    // colorbar legend
    paintColorbar();
    els.cbMin.textContent = fmt(minDb, 0);
    els.cbMax.textContent = fmt(maxDb, 0);

    setAria(c, els.spectroDesc,
      'Spectrogram heatmap of synthetic ' + presetLabel() + '. Horizontal axis ' +
      'time 0 to ' + fmt(totalTime, 3) + ' seconds, vertical axis frequency 0 to ' +
      fmt(nyq, 0) + ' hertz. Colour is magnitude in decibels from ' +
      fmt(minDb, 0) + ' to ' + fmt(maxDb, 0) + ', viridis colormap. ' + cols +
      ' time frames.');
  }

  function paintColorbar() {
    // build a CSS gradient from viridis stops
    const stops = [];
    for (let i = 0; i < VIRIDIS.length; i++) {
      const [r, g, b] = VIRIDIS[i];
      stops.push('rgb(' + r + ',' + g + ',' + b + ') ' +
        Math.round((i / (VIRIDIS.length - 1)) * 100) + '%');
    }
    els.colorbar.style.background = 'linear-gradient(90deg,' + stops.join(',') + ')';
  }

  // ========================================================
  //  ARIA helper
  // ========================================================
  function setAria(canvas, descEl, text) {
    canvas.setAttribute('aria-label', text);
    if (descEl) descEl.textContent = text;
  }

  function presetLabel() {
    if (state.preset === 'custom') {
      return 'custom sum of ' + state.components.length + ' sinusoids';
    }
    return (SIG.PRESETS[state.preset] || {}).label || state.preset;
  }

  // ========================================================
  //  PIPELINE
  // ========================================================
  function analyze() {
    const t0 = performance.now();
    state.signal = buildSignal();
    state.spectrum = FFT.powerSpectrum(state.signal, state.Fs, state.windowType);
    state.peaks = FFT.detectPeaks(state.spectrum.mag, state.spectrum.freqs, 4, 0.08);
    const t1 = performance.now();

    // readouts
    els.roDf.textContent = fmt(state.spectrum.df, 3) + ' Hz';
    els.roNyq.textContent = fmt(state.Fs / 2, 1) + ' Hz';
    els.roN.textContent = String(state.spectrum.N);
    els.roTime.textContent = fmt(t1 - t0, 2) + ' ms';
    if (state.peaks.length) {
      els.roPeak.textContent = fmt(state.peaks[0].freq, 2) + ' Hz';
      els.roBin.textContent = '#' + state.peaks[0].bin;
    } else {
      els.roPeak.textContent = '—';
      els.roBin.textContent = '—';
    }

    renderWaveform();
    renderSpectrum();
    computeSpectrogram();
  }

  function run() {
    const { errors, warns } = readControls();
    if (errors.length) {
      els.signalErr.textContent = errors[0];
      els.signalErr.classList.remove('hidden');
      return; // keep last good plots; do not crash
    }
    els.signalErr.classList.add('hidden');
    if (warns.length) {
      els.aliasWarn.textContent = warns.join(' ');
      els.aliasWarn.classList.remove('hidden');
    } else {
      els.aliasWarn.classList.add('hidden');
    }
    analyze();
  }

  // re-render only the spectrum-dependent plots (no signal rebuild needed
  // for scale change)
  function rerenderSpectrumOnly() {
    if (!state.spectrum) return;
    renderSpectrum();
  }

  // ========================================================
  //  CUSTOM COMPONENT EDITOR
  // ========================================================
  function addComponentRow(freq, amp) {
    const row = document.createElement('div');
    row.className = 'comp-row';
    row.innerHTML =
      '<input class="f mono" type="number" step="any" inputmode="decimal" aria-label="component frequency in hertz" value="' +
      (freq === undefined ? '' : freq) + '" />' +
      '<input class="a mono" type="number" step="any" inputmode="decimal" aria-label="component amplitude" value="' +
      (amp === undefined ? '' : amp) + '" />' +
      '<button class="rm" type="button" aria-label="remove component">×</button>';
    row.querySelector('.rm').addEventListener('click', () => {
      row.remove();
    });
    els.components.appendChild(row);
  }

  function rebuildComponentEditor() {
    els.components.innerHTML = '';
    state.components.forEach((c) => addComponentRow(c.freq, c.amp));
    if (state.components.length === 0) addComponentRow(60, 1);
  }

  // ========================================================
  //  EXPORT
  // ========================================================
  function exportPng() {
    if (!state.spectrum) return;
    const url = els.specCanvas.toDataURL('image/png');
    const a = document.createElement('a');
    a.href = url;
    a.download = 'spectra_spectrum.png';
    a.click();
  }

  function exportCsv() {
    if (!state.spectrum) return;
    const sp = state.spectrum;
    let lines = ['frequency_hz,magnitude,psd'];
    for (let k = 0; k < sp.freqs.length; k++) {
      lines.push(sp.freqs[k].toFixed(6) + ',' + sp.mag[k].toExponential(6) +
        ',' + sp.psd[k].toExponential(6));
    }
    const blob = new Blob([lines.join('\n')], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'spectra_spectrum.csv';
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }

  // ========================================================
  //  THEME
  // ========================================================
  function applyTheme(mode) {
    if (mode === 'auto') {
      document.documentElement.removeAttribute('data-theme');
      els.themeToggle.textContent = 'Theme: auto';
    } else {
      document.documentElement.setAttribute('data-theme', mode);
      els.themeToggle.textContent = 'Theme: ' + mode;
    }
    try { localStorage.setItem('spectra-theme', mode); } catch (e) { /* ignore */ }
    // repaint plots so canvas ink picks up new tokens
    if (state.spectrum) {
      renderWaveform();
      renderSpectrum();
      computeSpectrogram();
    }
  }

  function cycleTheme() {
    const cur = document.documentElement.getAttribute('data-theme') || 'auto';
    const next = cur === 'auto' ? 'light' : (cur === 'light' ? 'dark' : 'auto');
    applyTheme(next);
  }

  // ========================================================
  //  WIRING
  // ========================================================
  function setScale(scale) {
    state.scale = scale;
    els.scaleLin.setAttribute('aria-pressed', String(scale === 'lin'));
    els.scaleDb.setAttribute('aria-pressed', String(scale === 'db'));
    rerenderSpectrumOnly();
  }

  function wire() {
    els.preset.addEventListener('change', () => {
      const isCustom = els.preset.value === 'custom';
      els.customEditor.classList.toggle('hidden', !isCustom);
      state.preset = els.preset.value;
      run();
    });
    els.addComp.addEventListener('click', () => addComponentRow(100, 0.5));
    els.run.addEventListener('click', run);
    els.window.addEventListener('change', () => {
      state.windowType = els.window.value;
      // window affects spectrum + spectrogram, so re-run analysis
      run();
    });
    els.scaleLin.addEventListener('click', () => setScale('lin'));
    els.scaleDb.addEventListener('click', () => setScale('db'));
    els.stftWin.addEventListener('change', () => {
      state.stftWin = parseInt(els.stftWin.value, 10);
      computeSpectrogram();
    });
    els.stftOverlap.addEventListener('change', () => {
      state.overlap = parseFloat(els.stftOverlap.value);
      computeSpectrogram();
    });
    els.exportPng.addEventListener('click', exportPng);
    els.exportCsv.addEventListener('click', exportCsv);
    els.themeToggle.addEventListener('click', cycleTheme);

    // Enter inside Fs triggers a run
    els.fs.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') run();
    });

    // debounced responsive redraw
    let rT = null;
    window.addEventListener('resize', () => {
      if (rT) clearTimeout(rT);
      rT = setTimeout(() => {
        if (state.spectrum) {
          renderWaveform();
          renderSpectrum();
          computeSpectrogram();
        }
      }, 150);
    });
  }

  // ========================================================
  //  INIT — sample data loads immediately on open
  // ========================================================
  function init() {
    // restore theme
    let saved = 'auto';
    try { saved = localStorage.getItem('spectra-theme') || 'auto'; } catch (e) { /* ignore */ }
    if (saved !== 'auto') document.documentElement.setAttribute('data-theme', saved);
    els.themeToggle.textContent = 'Theme: ' + saved;

    rebuildComponentEditor();
    wire();
    setScale('db');
    paintColorbar();
    // First analysis — shows a correct spectrum instantly.
    run();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
