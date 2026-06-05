"""
Synthetic ECG generator (pure Python, no dependencies).

Produces a physiologically plausible single-lead ECG by summing Gaussian
wavelets for the P, Q, R, S, and T deflections of each cardiac cycle, with
beat-to-beat RR-interval variation (so there is *real* heart-rate variability
to recover downstream), baseline wander, and additive measurement noise.

The generator returns both the signal and the ground-truth R-peak sample
indices, which lets us score the detector quantitatively.

Wave morphology follows the dynamical ECG model of
    McSharry, Clifford, Tarassenko & Smith (2003),
    "A dynamical model for generating synthetic electrocardiogram signals",
    IEEE Trans. Biomed. Eng. 50(3):289-294,
simplified here to a fixed-time Gaussian mixture rather than the full ODE.
"""

import math
import random

# (label, center offset [s] from R, amplitude [mV], width [s])
_WAVES = [
    ("P", -0.20, 0.10, 0.025),
    ("Q", -0.025, -0.13, 0.0125),
    ("R", 0.0, 1.10, 0.0125),
    ("S", 0.025, -0.28, 0.0140),
    ("T", 0.18, 0.30, 0.040),
]


def _gauss(t, mu, amp, sigma):
    return amp * math.exp(-((t - mu) ** 2) / (2.0 * sigma * sigma))


def synth_ecg(duration_s=60.0, fs=250.0, mean_hr=62.0, sdnn_ms=55.0,
              noise_mv=0.02, seed=7):
    """Generate (signal, fs, r_peaks).

    mean_hr  -- mean heart rate in beats/min
    sdnn_ms  -- target standard deviation of RR intervals in ms (drives HRV)
    noise_mv -- std of additive white noise in mV
    """
    rng = random.Random(seed)
    n = int(duration_s * fs)
    sig = [0.0] * n

    # --- build an RR-interval tachogram with realistic LF/HF structure ---
    mean_rr = 60.0 / mean_hr  # seconds
    # Respiratory sinus arrhythmia ~0.25 Hz + a slower 0.1 Hz Mayer wave.
    r_times = []
    t = 0.6  # first beat a little after the start
    while t < duration_s - 0.6:
        r_times.append(t)
        rsa = 0.7 * math.sin(2 * math.pi * 0.25 * t)
        mayer = 0.3 * math.sin(2 * math.pi * 0.10 * t + 1.3)
        jitter = rng.gauss(0.0, 1.0)
        rr = mean_rr + (sdnn_ms / 1000.0) * (rsa + mayer + 0.6 * jitter)
        rr = max(0.33, rr)  # clamp to >180 bpm ceiling
        t += rr

    r_peaks = [int(round(rt * fs)) for rt in r_times]

    # --- render each beat as a Gaussian mixture ---
    win = int(0.45 * fs)
    for rt in r_times:
        c = int(round(rt * fs))
        for k in range(c - win, c + win):
            if 0 <= k < n:
                local = (k - c) / fs
                v = 0.0
                for _, mu, amp, sigma in _WAVES:
                    v += _gauss(local, mu, amp, sigma)
                sig[k] += v

    # --- baseline wander (0.15 Hz) + powerline-ish + white noise ---
    for k in range(n):
        tk = k / fs
        sig[k] += 0.06 * math.sin(2 * math.pi * 0.15 * tk + 0.5)
        sig[k] += 0.01 * math.sin(2 * math.pi * 0.33 * tk)
        sig[k] += rng.gauss(0.0, noise_mv)

    return sig, fs, r_peaks


def write_csv(path, sig, fs):
    with open(path, "w") as f:
        f.write("time_s,ecg_mv\n")
        for k, v in enumerate(sig):
            f.write(f"{k / fs:.5f},{v:.5f}\n")


def read_csv(path):
    sig = []
    fs = None
    prev_t = None
    with open(path) as f:
        next(f)
        for line in f:
            ts, v = line.strip().split(",")
            sig.append(float(v))
            t = float(ts)
            if prev_t is not None and fs is None:
                fs = 1.0 / (t - prev_t)
            prev_t = t
    return sig, round(fs)


if __name__ == "__main__":
    s, fs, peaks = synth_ecg()
    write_csv("data/ecg_sample.csv", s, fs)
    print(f"wrote {len(s)} samples at {fs:.0f} Hz, {len(peaks)} ground-truth beats")
