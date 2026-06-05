# Spectra — FFT Spectral Analyzer

## What it is

Spectra is an interactive, in-browser spectral analyzer: pick or build a
synthetic signal and instantly see its waveform, its power spectrum (with the
dominant frequencies detected and labelled), and a spectrogram showing how the
spectrum changes over time.

## The science, for a smart non-expert

A **signal** is just a number that changes over time — here, the height of a
wave sampled `Fs` times per second (the *sample rate*). The **waveform** plot
shows that signal in the *time domain*: amplitude versus seconds.

Most interesting signals are mixtures of simpler oscillations. A **spectrum**
re-describes the same signal in the *frequency domain*: instead of "what is the
value at each instant?", it answers "how much of each pure tone (frequency) is
present?" A 50 Hz hum and a 120 Hz whistle played together look tangled as a
waveform but appear as two clean spikes in the spectrum.

The **Fourier transform** is the mathematical machine that converts time into
frequency. Computing it directly costs on the order of N² operations; the
**Fast Fourier Transform (FFT)** does the same job in N·log₂N by cleverly
reusing partial results — fast enough to run live in a browser. Spectra
implements the classic **radix-2 Cooley–Tukey** FFT from scratch (no library).

**Windowing & spectral leakage.** The FFT assumes your finite chunk of signal
repeats forever. If the chunk doesn't contain a whole number of cycles, the
sudden jump at the seam smears energy across many frequencies — a single tone
"leaks" into its neighbours and the spectrum looks blurry. A **window** is a
smooth taper (Hann, Hamming, Blackman) multiplied into the signal so both ends
fade to near zero, suppressing that leakage at the cost of slightly wider peaks.
The **rectangular** window is "no taper". Try switching windows on the
tone-plus-noise preset to see leakage shrink.

**Spectrogram.** A single spectrum assumes the frequency content is constant.
For a sound that changes (like the chirp sweeping 20 → 200 Hz), we instead slide
a short window along the signal, take an FFT of each short frame, and stack the
results as a heatmap: time across, frequency up, colour = strength. This is the
**Short-Time Fourier Transform (STFT)**.

Jargon, defined: *Nyquist frequency* = Fs/2, the highest frequency that can be
represented; anything above it **aliases** (folds back) and appears at the wrong
place. *Frequency resolution* Δf = Fs/N — how finely the spectrum is sampled.
*PSD* = power spectral density, power per unit frequency. *Bin* = one discrete
frequency slot in the FFT output.

## Method & citations

- **FFT:** radix-2 iterative **Cooley–Tukey** — bit-reversal permutation
  followed by log₂N butterfly stages, decimation-in-time, in pure JavaScript
  (`js/fft.js`, `fftInPlace`).
  Cooley, J. W. & Tukey, J. W. (1965). "An algorithm for the machine
  calculation of complex Fourier series." *Mathematics of Computation* 19,
  297–301.
- **Windows:** rectangular, Hann, Hamming, Blackman.
  Harris, F. J. (1978). "On the use of windows for harmonic analysis with the
  discrete Fourier transform." *Proceedings of the IEEE* 66(1), 51–83.
- **Averaged periodogram / framing context:** Welch, P. D. (1967). "The use of
  fast Fourier transform for the estimation of power spectra." *IEEE Trans.
  Audio Electroacoust.* 15, 70–73. The STFT frames are the same windowed
  sub-records Welch averages.

**One-sided PSD formula** (`powerSpectrum`):

```
PSD[k] = |X[k]|² / (Fs · Σ w²)        (×2 for interior bins, not DC/Nyquist)
```

where `X = FFT(window · signal)` and `w` is the window. The displayed
**magnitude** is additionally amplitude-corrected by the window's coherent gain
(`Σ w`) so a pure tone of amplitude A reads ≈ A. Peaks are refined with
**parabolic interpolation** for sub-bin frequency accuracy.

**STFT** (`spectrogram`): window of the chosen size slides with `hop =
round(winSize·(1−overlap))`; each frame is windowed, FFT'd, and stored as
one-sided magnitude in dB; columns are time frames, rows are frequency bins,
rendered with a code-defined viridis-like colormap.

**Honest simplifications.** Radix-2 only (inputs are forced to a power of two,
256–8192; non-powers are rounded). The square-wave preset is a band-limited
Fourier series truncated below Nyquist, so very high harmonics are absent by
design. dB display is relative to the spectrum's own peak (not a calibrated
reference). No overlap-add averaging across the whole record for the main
spectrum (single periodogram); the spectrogram shows per-frame magnitude rather
than Welch-averaged PSD.

## How to open it

**Open `index.html` in any modern browser — sample data loads automatically; no
build, no server, no install.** Everything is static (HTML/CSS/JS), no CDN, no
network fonts. (The spectrogram uses a Web Worker when the page is served over
`http://`/`https://`; opened directly via `file://`, some browsers block
workers, in which case Spectra automatically falls back to computing the STFT on
the main thread with a "computing…" affordance.)

## Data

All signals are **synthetic** — generated by deterministic mathematics in
`js/signal.js`, never measured. Units: time in seconds, frequency in hertz,
amplitude is dimensionless. Generation process:

- **Two tones:** `sin(2π·50·t)·1.0 + sin(2π·120·t)·0.5`.
- **Linear chirp:** `sin(2π·(f0·t + ½·k·t²))`, f0 = 20 Hz → f1 = 200 Hz across
  the record (`k = (f1−f0)/T`).
- **Square wave:** odd-harmonic Fourier series of a 60 Hz square, truncated
  below Nyquist (band-limited to limit aliasing).
- **Tone + white noise:** `sin(2π·80·t)·1.0 + σ·n`, σ = 0.5, where `n` is
  standard-normal noise from Box–Muller driven by a **seeded mulberry32 PRNG**
  (fixed seed) — identical on every open.
- **Custom:** your own sum of sinusoids, `Σ aᵢ·sin(2π·fᵢ·t)`.

Sample interval is `1/Fs`; the record holds N samples spanning `N/Fs` seconds.

## Controls & export

- **Signal source:** preset dropdown, or "Custom sum of sines" with add/remove
  component rows (frequency Hz, amplitude). Adjustable **Fs** and **N** (power
  of two, 256–8192, clamped). "Regenerate & analyze" applies changes.
- **Window:** Rect / Hann / Hamming / Blackman — re-runs the analysis.
- **Spectrum scale:** Linear / dB toggle.
- **Spectrogram:** window size and overlap (0 / 50 / 75 / 87.5 %).
- **Readouts:** Δf, Nyquist, dominant frequency, peak bin, transform N, compute
  time (ms).
- **Export:** "Spectrum PNG" downloads the spectrum canvas; "Spectrum CSV"
  downloads `frequency_hz, magnitude, psd` for every bin.

## Accessibility & reproducibility

- **Keyboard:** all controls are native, focusable, and operable by keyboard;
  canvases are focusable with visible focus rings. Each plot canvas is
  `role="img"` with a live `aria-label` describing the current plot (axes,
  detected peaks, ranges).
- **Reduced motion:** `prefers-reduced-motion` disables the spinner animation
  and transitions; sizing uses relative units and `devicePixelRatio` so
  canvases stay crisp and never overflow on narrow screens.
- **Theme:** calm dark mode via `prefers-color-scheme` and an explicit toggle
  (auto / light / dark), persisted in `localStorage`.
- **Reproducibility:** randomness comes only from a **seeded mulberry32 PRNG**
  with a fixed seed, so the same defaults yield the same samples — and the same
  spectrum — on every open.

## Self-review

- **Anti-stub scan:** `grep -rniE "todo|fixme|xxx|placeholder|lorem|coming
  soon|not implemented|// stub"` over the project returns **clean**.
- **Open → correct spectrum:** verified. Opening `index.html` immediately loads
  the two-tone preset and renders waveform, spectrum (peaks detected at ≈50.0
  and ≈120.0 Hz with amplitudes ≈1.0 and ≈0.5), and spectrogram. The FFT and
  PSD math were cross-checked numerically (`js/fft.js`) against the known
  synthetic inputs.
- No placeholders, no TODOs, no external dependencies.
