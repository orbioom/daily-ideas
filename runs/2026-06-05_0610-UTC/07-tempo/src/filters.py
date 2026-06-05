"""
Minimal DSP filter primitives in pure Python.

A second-order Butterworth band-pass is designed analytically (analog
prototype -> bilinear transform) so the pipeline is sample-rate independent,
rather than hard-coding the integer coefficients from the original 200 Hz
Pan-Tompkins paper.
"""

import math


def _biquad(b, a, x):
    """Apply a single biquad (Direct Form I) to signal x."""
    y = [0.0] * len(x)
    x1 = x2 = y1 = y2 = 0.0
    b0, b1, b2 = b
    a0, a1, a2 = a
    for n in range(len(x)):
        xn = x[n]
        yn = (b0 * xn + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) / a0
        y[n] = yn
        x2, x1 = x1, xn
        y2, y1 = y1, yn
    return y


def butter_bandpass(x, fs, lo, hi):
    """Second-order Butterworth band-pass via bilinear transform.

    Cascades a 2-pole high-pass and a 2-pole low-pass. Pan-Tompkins++ widens
    the classic 5-15 Hz band to roughly 5-18 Hz to better preserve the QRS
    upslope; pass lo/hi accordingly.
    """
    x = _butter2(x, fs, hi, kind="low")
    x = _butter2(x, fs, lo, kind="high")
    return x


def _butter2(x, fs, fc, kind):
    # Pre-warp the cutoff for the bilinear transform.
    w = math.tan(math.pi * fc / fs)
    k1 = math.sqrt(2.0) * w
    k2 = w * w
    a0 = 1.0 + k1 + k2
    if kind == "low":
        b0 = k2 / a0
        b1 = 2.0 * b0
        b2 = b0
    else:  # high-pass
        b0 = 1.0 / a0
        b1 = -2.0 * b0
        b2 = b0
    a1 = (2.0 * (k2 - 1.0)) / a0
    a2 = (1.0 - k1 + k2) / a0
    return _biquad((b0, b1, b2), (1.0, a1, a2), x)


def derivative5(x, fs):
    """5-point derivative (the classic Pan-Tompkins differentiator)."""
    y = [0.0] * len(x)
    for n in range(len(x)):
        def g(i):
            j = n + i
            return x[j] if 0 <= j < len(x) else 0.0
        y[n] = (2 * g(2) + g(1) - g(-1) - 2 * g(-2)) * (fs / 8.0)
    return y


def square(x):
    return [v * v for v in x]


def moving_window_integrate(x, fs, width_s=0.150):
    w = max(1, int(round(width_s * fs)))
    y = [0.0] * len(x)
    acc = 0.0
    from collections import deque
    q = deque()
    for n in range(len(x)):
        acc += x[n]
        q.append(x[n])
        if len(q) > w:
            acc -= q.popleft()
        y[n] = acc / w
    return y
