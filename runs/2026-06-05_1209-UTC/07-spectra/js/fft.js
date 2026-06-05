// fft.js — Spectra
// Real, dependency-free DSP core.
//
// Implements:
//   - Radix-2 iterative Cooley–Tukey FFT (Cooley & Tukey, 1965).
//   - Window functions: rectangular, Hann, Hamming, Blackman (Harris, 1978).
//   - One-sided power spectral density (periodogram).
//
// All routines are pure functions over Float64Array so they are testable in
// isolation (no DOM, no globals).

'use strict';

/**
 * Return true if n is a positive power of two.
 * @param {number} n
 * @returns {boolean}
 */
function isPowerOfTwo(n) {
  return Number.isInteger(n) && n > 0 && (n & (n - 1)) === 0;
}

/**
 * Round n to the nearest power of two, clamped to [min, max].
 * Both bounds are assumed to be powers of two.
 * @param {number} n
 * @param {number} min
 * @param {number} max
 * @returns {number}
 */
function clampToPowerOfTwo(n, min, max) {
  if (!Number.isFinite(n) || n < 1) n = min;
  // nearest power of two in log space
  let p = Math.round(Math.log2(n));
  let v = Math.pow(2, p);
  if (v < min) v = min;
  if (v > max) v = max;
  return v;
}

/**
 * In-place iterative radix-2 Cooley–Tukey FFT.
 *
 * Decimation-in-time with bit-reversal permutation followed by log2(N)
 * butterfly stages. Operates on separate real/imag arrays. Length MUST be a
 * power of two; the caller is responsible for zero-padding.
 *
 * Reference: J. W. Cooley & J. W. Tukey, "An algorithm for the machine
 * calculation of complex Fourier series", Math. Comp. 19 (1965) 297–301.
 *
 * @param {Float64Array} re real parts (modified in place)
 * @param {Float64Array} im imaginary parts (modified in place)
 */
function fftInPlace(re, im) {
  const n = re.length;
  if (n <= 1) return;
  if (!isPowerOfTwo(n)) {
    throw new Error('fftInPlace: length must be a power of two, got ' + n);
  }

  // --- Bit-reversal permutation ---
  for (let i = 1, j = 0; i < n; i++) {
    let bit = n >> 1;
    for (; j & bit; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      const tr = re[i]; re[i] = re[j]; re[j] = tr;
      const ti = im[i]; im[i] = im[j]; im[j] = ti;
    }
  }

  // --- Butterfly stages ---
  for (let len = 2; len <= n; len <<= 1) {
    const ang = (-2 * Math.PI) / len; // forward transform (negative exponent)
    const wpr = Math.cos(ang);
    const wpi = Math.sin(ang);
    for (let i = 0; i < n; i += len) {
      let wr = 1;
      let wi = 0;
      const half = len >> 1;
      for (let k = 0; k < half; k++) {
        const a = i + k;
        const b = i + k + half;
        const xr = re[b] * wr - im[b] * wi;
        const xi = re[b] * wi + im[b] * wr;
        re[b] = re[a] - xr;
        im[b] = im[a] - xi;
        re[a] = re[a] + xr;
        im[a] = im[a] + xi;
        // advance twiddle: w *= wp
        const nwr = wr * wpr - wi * wpi;
        wi = wr * wpi + wi * wpr;
        wr = nwr;
      }
    }
  }
}

/**
 * Compute window coefficients of the given type and length.
 *
 * Symmetric (periodic-friendly) windows per Harris (1978). For N === 1 the
 * window is simply [1].
 *
 * Reference: F. J. Harris, "On the use of windows for harmonic analysis with
 * the discrete Fourier transform", Proc. IEEE 66 (1978) 51–83.
 *
 * @param {string} type one of 'rect' | 'hann' | 'hamming' | 'blackman'
 * @param {number} N window length (>= 1)
 * @returns {Float64Array}
 */
function makeWindow(type, N) {
  const w = new Float64Array(N);
  if (N === 1) { w[0] = 1; return w; }
  const Nm1 = N - 1;
  switch (type) {
    case 'hann':
      for (let i = 0; i < N; i++) {
        w[i] = 0.5 - 0.5 * Math.cos((2 * Math.PI * i) / Nm1);
      }
      break;
    case 'hamming':
      for (let i = 0; i < N; i++) {
        w[i] = 0.54 - 0.46 * Math.cos((2 * Math.PI * i) / Nm1);
      }
      break;
    case 'blackman':
      for (let i = 0; i < N; i++) {
        const x = (2 * Math.PI * i) / Nm1;
        w[i] = 0.42 - 0.5 * Math.cos(x) + 0.08 * Math.cos(2 * x);
      }
      break;
    case 'rect':
    default:
      w.fill(1);
      break;
  }
  return w;
}

/**
 * Coherent power gain of a window = (1/N) * sum(w)^2 / N ... we instead use the
 * normalization sum(w^2) for PSD scaling. Returns sum of squared coefficients.
 * @param {Float64Array} w
 * @returns {number}
 */
function windowPowerSum(w) {
  let s = 0;
  for (let i = 0; i < w.length; i++) s += w[i] * w[i];
  return s;
}

/**
 * Compute the one-sided power spectral density of a real signal.
 *
 * Steps:
 *   1. Apply the chosen window (Harris 1978) to a copy of the signal.
 *   2. Zero-pad to the next power of two if needed (caller usually passes 2^k).
 *   3. FFT via radix-2 Cooley–Tukey (1965).
 *   4. PSD[k] = |X[k]|^2 / (Fs * sum(w^2)), doubled for the one-sided bins
 *      (all bins except DC and Nyquist) so total power is preserved.
 *
 * @param {Float64Array|number[]} signal time-domain samples
 * @param {number} Fs sample rate in Hz (> 0)
 * @param {string} windowType window name
 * @returns {{freqs: Float64Array, psd: Float64Array, mag: Float64Array, N: number, df: number}}
 *   freqs: bin centre frequencies (Hz), length N/2+1
 *   psd:   power spectral density (linear units^2/Hz)
 *   mag:   linear magnitude spectrum (units), one-sided, amplitude-corrected
 *   N:     transform length used
 *   df:    frequency resolution Fs/N
 */
function powerSpectrum(signal, Fs, windowType) {
  if (!(Fs > 0)) throw new Error('powerSpectrum: Fs must be > 0');
  const Nin = signal.length;
  let N = 1;
  while (N < Nin) N <<= 1; // next power of two
  if (N < 1) N = 1;

  const win = makeWindow(windowType, Nin);
  const wsum2 = windowPowerSum(win) || 1; // guard divide-by-zero
  // Coherent gain for amplitude correction = sum(w)
  let wsum = 0;
  for (let i = 0; i < win.length; i++) wsum += win[i];
  if (wsum === 0) wsum = 1;

  const re = new Float64Array(N);
  const im = new Float64Array(N);
  for (let i = 0; i < Nin; i++) re[i] = signal[i] * win[i];
  // remaining samples are already zero (zero-padding)

  fftInPlace(re, im);

  const half = N >> 1;
  const freqs = new Float64Array(half + 1);
  const psd = new Float64Array(half + 1);
  const mag = new Float64Array(half + 1);
  const df = Fs / N;

  for (let k = 0; k <= half; k++) {
    const power = re[k] * re[k] + im[k] * im[k];
    let p = power / (Fs * wsum2);
    if (k !== 0 && k !== half) p *= 2; // one-sided doubling
    psd[k] = p;
    freqs[k] = k * df;
    // amplitude-corrected single-sided magnitude (peak of a pure tone ~ its amplitude)
    let amp = Math.sqrt(power) / wsum;
    if (k !== 0 && k !== half) amp *= 2;
    mag[k] = amp;
  }

  return { freqs, psd, mag, N, df };
}

/**
 * Detect the strongest spectral peaks in a magnitude array.
 *
 * A local maximum is a bin strictly greater than both neighbours and above a
 * fraction of the global maximum. Returns up to maxPeaks peaks sorted by
 * descending magnitude. Optionally refines each peak with parabolic
 * interpolation for sub-bin frequency accuracy.
 *
 * @param {Float64Array} mag magnitude spectrum
 * @param {Float64Array} freqs matching frequency axis
 * @param {number} maxPeaks maximum number of peaks to return
 * @param {number} relThreshold fraction (0..1) of global max a peak must exceed
 * @returns {Array<{freq:number, mag:number, bin:number}>}
 */
function detectPeaks(mag, freqs, maxPeaks, relThreshold) {
  const peaks = [];
  let gmax = 0;
  for (let i = 0; i < mag.length; i++) if (mag[i] > gmax) gmax = mag[i];
  if (gmax <= 0) return peaks;
  const thresh = gmax * (relThreshold || 0.05);

  for (let i = 1; i < mag.length - 1; i++) {
    const m = mag[i];
    if (m > thresh && m > mag[i - 1] && m >= mag[i + 1]) {
      // parabolic interpolation around the peak bin
      const a = mag[i - 1];
      const b = mag[i];
      const c = mag[i + 1];
      const denom = a - 2 * b + c;
      let delta = 0;
      if (denom !== 0) delta = (0.5 * (a - c)) / denom;
      if (delta < -1 || delta > 1) delta = 0;
      const df = freqs.length > 1 ? freqs[1] - freqs[0] : 0;
      peaks.push({ freq: freqs[i] + delta * df, mag: m, bin: i });
    }
  }
  peaks.sort((x, y) => y.mag - x.mag);
  return peaks.slice(0, maxPeaks);
}

/**
 * Convert a linear value to decibels relative to a reference, floored to avoid
 * log(0). dB = 10*log10(value/ref).
 * @param {number} value
 * @param {number} ref reference (> 0)
 * @param {number} floorDb minimum dB returned
 * @returns {number}
 */
function toDb(value, ref, floorDb) {
  const r = ref > 0 ? ref : 1;
  const v = value / r;
  if (!(v > 0)) return floorDb;
  const d = 10 * Math.log10(v);
  return d < floorDb ? floorDb : d;
}

/**
 * Compute a Short-Time Fourier Transform magnitude matrix (spectrogram).
 *
 * Slides a window of length winSize across the signal with the given hop,
 * applies the window, FFTs each frame, and stores the one-sided magnitude in
 * dB. Columns are time frames, rows are frequency bins.
 *
 * @param {Float64Array|number[]} signal
 * @param {number} Fs sample rate (Hz)
 * @param {number} winSize STFT window length (power of two)
 * @param {number} hop samples advanced between frames (>= 1)
 * @param {string} windowType
 * @returns {{cols:number, rows:number, data:Float64Array, times:Float64Array, freqs:Float64Array, minDb:number, maxDb:number}}
 *   data is column-major: data[col*rows + row].
 */
function spectrogram(signal, Fs, winSize, hop, windowType) {
  if (!(Fs > 0)) throw new Error('spectrogram: Fs must be > 0');
  if (!isPowerOfTwo(winSize)) throw new Error('spectrogram: winSize must be power of two');
  if (!(hop >= 1)) hop = Math.max(1, winSize >> 1);

  const Nsig = signal.length;
  const rows = (winSize >> 1) + 1;
  const win = makeWindow(windowType, winSize);
  let wsum2 = windowPowerSum(win) || 1;

  const cols = Math.max(1, Math.floor((Nsig - winSize) / hop) + 1);
  const data = new Float64Array(cols * rows);
  const times = new Float64Array(cols);
  const freqs = new Float64Array(rows);
  const df = Fs / winSize;
  for (let r = 0; r < rows; r++) freqs[r] = r * df;

  const re = new Float64Array(winSize);
  const im = new Float64Array(winSize);
  let minDb = Infinity;
  let maxDb = -Infinity;
  const floorDb = -120;

  for (let c = 0; c < cols; c++) {
    const start = c * hop;
    times[c] = start / Fs;
    for (let i = 0; i < winSize; i++) {
      const idx = start + i;
      re[i] = idx < Nsig ? signal[idx] * win[i] : 0;
      im[i] = 0;
    }
    fftInPlace(re, im);
    for (let r = 0; r < rows; r++) {
      let power = re[r] * re[r] + im[r] * im[r];
      power = power / (Fs * wsum2);
      if (r !== 0 && r !== rows - 1) power *= 2;
      const d = toDb(power, 1, floorDb);
      data[c * rows + r] = d;
      if (d < minDb) minDb = d;
      if (d > maxDb) maxDb = d;
    }
  }
  if (!isFinite(minDb)) minDb = floorDb;
  if (!isFinite(maxDb)) maxDb = 0;
  if (maxDb - minDb < 1) maxDb = minDb + 1; // guard flat spectrograms

  return { cols, rows, data, times, freqs, minDb, maxDb };
}

// Expose as a global namespace so plain <script> tags (no modules) and the Web
// Worker (importScripts) can both reach these functions.
const SpectraFFT = {
  isPowerOfTwo,
  clampToPowerOfTwo,
  fftInPlace,
  makeWindow,
  windowPowerSum,
  powerSpectrum,
  detectPeaks,
  toDb,
  spectrogram,
};

if (typeof self !== 'undefined') self.SpectraFFT = SpectraFFT;
if (typeof window !== 'undefined') window.SpectraFFT = SpectraFFT;
