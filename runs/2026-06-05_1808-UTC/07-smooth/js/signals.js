/**
 * signals.js — Seeded synthetic signal generators and user data parser.
 *
 * All synthetic signals use a seeded LCG (Linear Congruential Generator)
 * for reproducibility: every page load produces identical data.
 *
 * Seeded PRNG: LCG with parameters from Numerical Recipes (Press et al.):
 *   seed = (1664525 * seed + 1013904223) mod 2^32
 *   uniform = seed / 2^32
 */

"use strict";

var Signals = (function () {

  /* ------------------------------------------------------------------ */
  /* Seeded LCG PRNG                                                     */
  /* ------------------------------------------------------------------ */
  function makePRNG(seed) {
    var s = seed >>> 0; // ensure unsigned 32-bit
    return function () {
      s = ((Math.imul(1664525, s) + 1013904223) >>> 0);
      return s / 4294967296;
    };
  }

  /* gaussian approximation via Box-Muller */
  function makeGaussian(rng) {
    var spare = null;
    return function () {
      if (spare !== null) { var v = spare; spare = null; return v; }
      var u, v, s;
      do {
        u = rng() * 2 - 1;
        v = rng() * 2 - 1;
        s = u * u + v * v;
      } while (s >= 1 || s === 0);
      var factor = Math.sqrt(-2 * Math.log(s) / s);
      spare = v * factor;
      return u * factor;
    };
  }

  /* ------------------------------------------------------------------ */
  /* Signal generators                                                    */
  /* ------------------------------------------------------------------ */

  /**
   * Noisy Gaussian peak + sloped baseline
   * Resembles a single-peak spectroscopic feature.
   */
  function gaussianPeak(N) {
    if (N === undefined) N = 256;
    var rng = makePRNG(0xDEADBEEF);
    var gauss = makeGaussian(rng);
    var x = new Float64Array(N);
    var y = new Float64Array(N);
    for (var i = 0; i < N; i++) {
      x[i] = i;
      var t = (i - N / 2) / (N / 8);
      // Gaussian peak centred at N/2 with height 4, width sigma~N/8
      var signal = 4 * Math.exp(-0.5 * t * t);
      // Sloped baseline
      var baseline = 0.3 * i / N + 0.5;
      var noise = 0.15 * gauss();
      y[i] = signal + baseline + noise;
    }
    return { x: x, y: y, name: "Gaussian Peak + Baseline", unit: "arb. units", description: "Single Gaussian peak (σ = N/8) on a sloped baseline, σ_noise ≈ 0.15" };
  }

  /**
   * Noisy multi-peak "spectrum"
   * Resembles a mass or IR spectrum with 4 overlapping peaks.
   */
  function multiPeak(N) {
    if (N === undefined) N = 256;
    var rng = makePRNG(0xCAFEBABE);
    var gauss = makeGaussian(rng);
    // Peak definitions: [centre_fraction, height, width_fraction]
    var peaks = [
      [0.15, 2.0, 0.04],
      [0.35, 3.5, 0.06],
      [0.55, 1.5, 0.03],
      [0.75, 2.8, 0.05]
    ];
    var x = new Float64Array(N);
    var y = new Float64Array(N);
    for (var i = 0; i < N; i++) {
      x[i] = i;
      var sig = 0.1; // baseline
      for (var p = 0; p < peaks.length; p++) {
        var centre = peaks[p][0] * N;
        var height = peaks[p][1];
        var width = peaks[p][2] * N;
        var t = (i - centre) / width;
        sig += height * Math.exp(-0.5 * t * t);
      }
      var noise = 0.18 * gauss();
      y[i] = sig + noise;
    }
    return { x: x, y: y, name: "Multi-Peak Spectrum", unit: "arb. units", description: "Four overlapping Gaussian peaks, σ_noise ≈ 0.18" };
  }

  /**
   * Noisy sine wave — tests oscillatory smoothing.
   */
  function noisySine(N) {
    if (N === undefined) N = 256;
    var rng = makePRNG(0x13579BDF);
    var gauss = makeGaussian(rng);
    var x = new Float64Array(N);
    var y = new Float64Array(N);
    var freq = 4; // number of full cycles
    for (var i = 0; i < N; i++) {
      x[i] = i;
      var t = i / N;
      var signal = 2 * Math.sin(2 * Math.PI * freq * t) + 0.5 * Math.sin(2 * Math.PI * 13 * t);
      var noise = 0.4 * gauss();
      y[i] = signal + noise;
    }
    return { x: x, y: y, name: "Noisy Sine Wave", unit: "arb. units", description: "sin(2π·4·t) + 0.5·sin(2π·13·t) + Gaussian noise σ ≈ 0.4" };
  }

  /**
   * Step function + noise — tests edge behaviour and derivative detection.
   */
  function stepNoise(N) {
    if (N === undefined) N = 256;
    var rng = makePRNG(0x2468ACE0);
    var gauss = makeGaussian(rng);
    var x = new Float64Array(N);
    var y = new Float64Array(N);
    // Two steps: up at 25%, down at 60%, up at 80%
    var steps = [
      { pos: 0.25, rise: 2.0 },
      { pos: 0.60, rise: -1.5 },
      { pos: 0.80, rise: 1.0 }
    ];
    for (var i = 0; i < N; i++) {
      x[i] = i;
      var level = 0.5;
      var frac = i / N;
      for (var s = 0; s < steps.length; s++) {
        if (frac > steps[s].pos) level += steps[s].rise;
      }
      var noise = 0.12 * gauss();
      y[i] = level + noise;
    }
    return { x: x, y: y, name: "Step Function + Noise", unit: "arb. units", description: "Three step transitions on noisy baseline, σ_noise ≈ 0.12" };
  }

  /* ------------------------------------------------------------------ */
  /* User data parser                                                     */
  /* Accepts newline- or comma-separated numbers.                        */
  /* Returns { x, y, name, unit, description } or { error: string }.    */
  /* ------------------------------------------------------------------ */
  function parseUserData(text) {
    if (!text || text.trim() === "") {
      return { error: "No data provided. Paste newline- or comma-separated numbers." };
    }
    // Split on newlines, commas, semicolons, tabs
    var parts = text.split(/[\n\r,;\t]+/).map(function (s) { return s.trim(); }).filter(function (s) { return s.length > 0; });
    if (parts.length < 4) {
      return { error: "Too few values (" + parts.length + "). Need at least 4 data points." };
    }
    var nums = [];
    for (var i = 0; i < parts.length; i++) {
      var v = parseFloat(parts[i]);
      if (!isFinite(v)) {
        return { error: "Non-numeric value at position " + (i + 1) + ": \"" + parts[i] + "\"." };
      }
      nums.push(v);
    }
    var N = nums.length;
    var x = new Float64Array(N);
    var y = new Float64Array(N);
    for (var i = 0; i < N; i++) { x[i] = i; y[i] = nums[i]; }
    return {
      x: x, y: y,
      name: "User Data (" + N + " pts)",
      unit: "arb. units",
      description: "User-pasted data, " + N + " points"
    };
  }

  /* ------------------------------------------------------------------ */
  /* Parse sample.csv: header line then rows of x,y                      */
  /* ------------------------------------------------------------------ */
  function parseSampleCSV(text) {
    var lines = text.split('\n').map(function (l) { return l.trim(); }).filter(function (l) { return l.length > 0; });
    if (lines.length < 2) return { error: "CSV too short." };
    // Skip header
    var dataLines = lines.slice(1);
    var xs = [], ys = [];
    for (var i = 0; i < dataLines.length; i++) {
      var parts = dataLines[i].split(',');
      if (parts.length < 2) continue;
      var xi = parseFloat(parts[0]);
      var yi = parseFloat(parts[1]);
      if (isFinite(xi) && isFinite(yi)) { xs.push(xi); ys.push(yi); }
    }
    if (xs.length < 4) return { error: "Insufficient numeric rows in CSV." };
    var N = xs.length;
    var x = new Float64Array(N);
    var y = new Float64Array(N);
    for (var i = 0; i < N; i++) { x[i] = xs[i]; y[i] = ys[i]; }
    return { x: x, y: y, name: "Sample CSV", unit: "arb. units", description: "sample.csv — synthetic Gaussian peak, N=" + N };
  }

  /* catalogue */
  var SOURCES = [
    { id: "gaussian_peak", label: "Gaussian Peak + Baseline", gen: gaussianPeak },
    { id: "multi_peak",    label: "Multi-Peak Spectrum",       gen: multiPeak },
    { id: "noisy_sine",    label: "Noisy Sine Wave",           gen: noisySine },
    { id: "step_noise",    label: "Step Function + Noise",     gen: stepNoise }
  ];

  return {
    SOURCES: SOURCES,
    gaussianPeak: gaussianPeak,
    multiPeak: multiPeak,
    noisySine: noisySine,
    stepNoise: stepNoise,
    parseUserData: parseUserData,
    parseSampleCSV: parseSampleCSV
  };

})();
