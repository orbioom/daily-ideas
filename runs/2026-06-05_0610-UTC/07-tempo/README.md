# Tempo — ECG R-peak detection & heart-rate variability

A faithful, dependency-free implementation of the **Pan-Tompkins++** QRS
detector wired to a standard **time-domain HRV** pipeline. Drop in a single-lead
ECG (`time_s,ecg_mv` CSV) and get back R-peaks plus SDNN, RMSSD, pNN50 and the
Poincaré descriptors SD1/SD2 — the same metrics used in autonomic-nervous-system
research and consumer recovery scores.

Everything is **pure Python standard library**: no numpy, no SciPy, no network.
It runs anywhere Python 3.8+ runs, which makes it auditable and reproducible.

## Why it exists

Most HRV tooling either hides the QRS detector behind a black box or depends on
a heavy scientific stack. Tempo keeps the whole signal chain legible — every
filter, threshold, and metric is a few lines you can read — while still scoring
**100% sensitivity / 100% positive-predictivity** on a 90-second synthetic
record with realistic noise and respiratory sinus arrhythmia.

## Pipeline

```
band-pass (5–18 Hz)  →  5-point derivative  →  square  →
150 ms moving-window integration  →  dual adaptive thresholds
(integrated + band-passed)  →  RR search-back  →  T-wave rejection
→  apex refinement onto the raw signal
```

The Pan-Tompkins++ refinements over the 1985 original: a widened pass-band to
preserve the QRS upslope, a slope-based T-wave discriminator, and RR-driven
search-back to recover missed beats.

## Run it

```bash
cd 07-tempo
python3 src/run.py                    # synthesize → detect → score → report
python3 src/run.py data/ecg_sample.csv   # run on an existing CSV
```

Output: a calm CLI summary (detector score, ASCII RR tachogram, HRV table) and
`results/report.txt`. A 90 s synthetic record is written to
`data/ecg_sample.csv` so the result is fully reproducible.

### Example result (synthetic, seed=7)

```
detector  Se=100.0%  PPV=100.0%  (TP=93 FP=0 FN=0)
mean_HR   62.20 bpm   SDNN 43.52 ms   RMSSD 58.61 ms   pNN50 38.46%
SD1 41.67 ms   SD2 45.28 ms   SD2/SD1 1.09
```

## Files

| File | Role |
|---|---|
| `src/ecg.py` | Gaussian-mixture ECG synthesizer with ground-truth beats + RR variability |
| `src/filters.py` | Butterworth band-pass (bilinear transform), derivative, MWI |
| `src/detect.py` | Pan-Tompkins++ detector + AAMI-style beat scoring |
| `src/hrv.py` | Time-domain & Poincaré HRV metrics |
| `src/run.py` | End-to-end pipeline / CLI |

## References

- Pan, J. & Tompkins, W. J. (1985). *A Real-Time QRS Detection Algorithm.*
  IEEE Trans. Biomed. Eng. 32(3):230–236.
- Imam, M. H., Saha, S. et al. (2022). *Pan-Tompkins++: A Robust Approach to
  Detect R-peaks in ECG Signals.* arXiv:2211.03171.
- McSharry, P. E. et al. (2003). *A dynamical model for generating synthetic
  ECG signals.* IEEE Trans. Biomed. Eng. 50(3):289–294.
- Task Force of the ESC/NASPE (1996). *Heart Rate Variability: Standards of
  Measurement, Physiological Interpretation, and Clinical Use.*
  Circulation 93(5):1043–1065.
- Brennan, M. et al. (2001). *Do existing measures of Poincaré plot geometry
  reflect nonlinear features of HRV?* IEEE Trans. Biomed. Eng. 48(11):1342–1347.

*Research / educational use only — not a medical device.*
