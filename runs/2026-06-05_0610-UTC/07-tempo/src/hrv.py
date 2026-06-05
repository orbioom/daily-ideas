"""
Time-domain & non-linear Heart Rate Variability metrics (pure Python).

Definitions follow the Task Force standard:
    Task Force of the European Society of Cardiology and the North American
    Society of Pacing and Electrophysiology (1996),
    "Heart Rate Variability: Standards of Measurement, Physiological
    Interpretation, and Clinical Use", Circulation 93(5):1043-1065.

Poincare SD1/SD2 follow Brennan, Palaniswami & Kamen (2001),
    "Do existing measures of Poincare plot geometry reflect nonlinear
    features of HRV?", IEEE Trans. Biomed. Eng. 48(11):1342-1347.
"""

import math


def rr_intervals_ms(r_peaks, fs):
    """Successive RR intervals in milliseconds."""
    return [1000.0 * (r_peaks[i] - r_peaks[i - 1]) / fs
            for i in range(1, len(r_peaks))]


def _mean(x):
    return sum(x) / len(x) if x else 0.0


def _std(x):
    if len(x) < 2:
        return 0.0
    m = _mean(x)
    return math.sqrt(sum((v - m) ** 2 for v in x) / (len(x) - 1))


def metrics(rr):
    """Return a dict of standard HRV metrics from RR intervals (ms)."""
    if len(rr) < 2:
        return {}
    diffs = [rr[i] - rr[i - 1] for i in range(1, len(rr))]
    mean_rr = _mean(rr)
    sdnn = _std(rr)
    rmssd = math.sqrt(_mean([d * d for d in diffs]))
    nn50 = sum(1 for d in diffs if abs(d) > 50.0)
    pnn50 = 100.0 * nn50 / len(diffs)
    mean_hr = 60000.0 / mean_rr
    # Poincare descriptors
    sd1 = math.sqrt(0.5) * _std(diffs)
    sd2 = math.sqrt(max(0.0, 2.0 * sdnn * sdnn - sd1 * sd1))
    return {
        "n_beats": len(rr) + 1,
        "mean_RR_ms": mean_rr,
        "mean_HR_bpm": mean_hr,
        "SDNN_ms": sdnn,
        "RMSSD_ms": rmssd,
        "pNN50_pct": pnn50,
        "SD1_ms": sd1,
        "SD2_ms": sd2,
        "SD2_SD1": (sd2 / sd1) if sd1 else 0.0,
    }
