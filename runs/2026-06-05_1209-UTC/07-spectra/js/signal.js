// signal.js — Spectra
// Synthetic signal generators. Everything here is SYNTHETIC: deterministic
// mathematics, no measured/real-world data. Randomness (noise) uses a seeded
// PRNG so the same defaults reproduce the same samples on every open.

'use strict';

/**
 * mulberry32 — a tiny, fast, deterministic PRNG.
 * Given the same 32-bit seed it always yields the same stream of floats in
 * [0, 1). Used so "tone + noise" looks identical across page loads.
 * @param {number} seed unsigned 32-bit integer
 * @returns {() => number} generator returning floats in [0,1)
 */
function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a |= 0;
    a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * Standard-normal sample via Box–Muller, driven by a [0,1) generator.
 * @param {() => number} rng
 * @returns {number}
 */
function gaussian(rng) {
  let u = 0;
  let v = 0;
  // avoid log(0)
  while (u === 0) u = rng();
  while (v === 0) v = rng();
  return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
}

/**
 * Sum of sinusoids: x(t) = Σ aᵢ·sin(2π·fᵢ·t + φᵢ).
 * @param {Array<{freq:number, amp:number, phase?:number}>} components
 * @param {number} Fs sample rate (Hz)
 * @param {number} N number of samples
 * @returns {Float64Array}
 */
function sumOfSines(components, Fs, N) {
  const x = new Float64Array(N);
  for (let n = 0; n < N; n++) {
    const t = n / Fs;
    let s = 0;
    for (let c = 0; c < components.length; c++) {
      const comp = components[c];
      const ph = comp.phase || 0;
      s += comp.amp * Math.sin(2 * Math.PI * comp.freq * t + ph);
    }
    x[n] = s;
  }
  return x;
}

/**
 * Linear chirp sweeping instantaneous frequency from f0 to f1 across the whole
 * record. x(t) = amp·sin(2π·(f0·t + (k/2)·t²)), k = (f1−f0)/T.
 * @param {number} f0 start frequency (Hz)
 * @param {number} f1 end frequency (Hz)
 * @param {number} amp amplitude
 * @param {number} Fs sample rate (Hz)
 * @param {number} N number of samples
 * @returns {Float64Array}
 */
function chirp(f0, f1, amp, Fs, N) {
  const x = new Float64Array(N);
  const T = N / Fs;
  const k = T > 0 ? (f1 - f0) / T : 0;
  for (let n = 0; n < N; n++) {
    const t = n / Fs;
    x[n] = amp * Math.sin(2 * Math.PI * (f0 * t + 0.5 * k * t * t));
  }
  return x;
}

/**
 * Band-limited-ish square wave built from a Fourier series (odd harmonics)
 * truncated below Nyquist to limit aliasing.
 * @param {number} freq fundamental (Hz)
 * @param {number} amp amplitude of the square
 * @param {number} Fs sample rate (Hz)
 * @param {number} N number of samples
 * @returns {Float64Array}
 */
function squareWave(freq, amp, Fs, N) {
  const x = new Float64Array(N);
  const nyq = Fs / 2;
  for (let n = 0; n < N; n++) {
    const t = n / Fs;
    let s = 0;
    for (let h = 1; h * freq < nyq; h += 2) {
      s += Math.sin(2 * Math.PI * h * freq * t) / h;
    }
    x[n] = amp * (4 / Math.PI) * s;
  }
  return x;
}

/**
 * A pure tone plus additive white Gaussian noise (seeded, reproducible).
 * @param {number} freq tone frequency (Hz)
 * @param {number} amp tone amplitude
 * @param {number} noiseStd noise standard deviation
 * @param {number} Fs sample rate (Hz)
 * @param {number} N number of samples
 * @param {number} seed PRNG seed
 * @returns {Float64Array}
 */
function tonePlusNoise(freq, amp, noiseStd, Fs, N, seed) {
  const x = new Float64Array(N);
  const rng = mulberry32(seed >>> 0);
  for (let n = 0; n < N; n++) {
    const t = n / Fs;
    x[n] = amp * Math.sin(2 * Math.PI * freq * t) + noiseStd * gaussian(rng);
  }
  return x;
}

/**
 * Preset definitions. Each preset is a factory that, given (Fs, N, seed),
 * returns the time-domain samples plus a short human description. All presets
 * are clearly synthetic.
 */
const PRESETS = {
  twoTones: {
    label: 'Two tones — 50 Hz + 120 Hz',
    description: 'Sum of two sinusoids at 50 Hz (amp 1.0) and 120 Hz (amp 0.5).',
    make: (Fs, N) => sumOfSines(
      [
        { freq: 50, amp: 1.0 },
        { freq: 120, amp: 0.5 },
      ], Fs, N),
  },
  chirp: {
    label: 'Linear chirp — 20 → 200 Hz',
    description: 'Frequency sweeps linearly from 20 Hz to 200 Hz over the record.',
    make: (Fs, N) => chirp(20, 200, 1.0, Fs, N),
  },
  square: {
    label: 'Square wave — 60 Hz',
    description: 'Band-limited 60 Hz square wave (odd-harmonic Fourier series).',
    make: (Fs, N) => squareWave(60, 1.0, Fs, N),
  },
  toneNoise: {
    label: 'Tone + white noise — 80 Hz',
    description: '80 Hz sinusoid (amp 1.0) plus seeded white Gaussian noise (σ = 0.5).',
    make: (Fs, N, seed) => tonePlusNoise(80, 1.0, 0.5, Fs, N, seed),
  },
};

const SpectraSignal = {
  mulberry32,
  gaussian,
  sumOfSines,
  chirp,
  squareWave,
  tonePlusNoise,
  PRESETS,
};

if (typeof self !== 'undefined') self.SpectraSignal = SpectraSignal;
if (typeof window !== 'undefined') window.SpectraSignal = SpectraSignal;
