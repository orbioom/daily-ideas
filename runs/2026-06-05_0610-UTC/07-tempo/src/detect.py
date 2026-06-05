"""
Pan-Tompkins++ QRS detector (pure Python).

Implements the classic real-time QRS detection pipeline of
    Pan & Tompkins (1985), "A Real-Time QRS Detection Algorithm",
    IEEE Trans. Biomed. Eng. 32(3):230-236,
with the robustness refinements introduced in
    Imam, Saha et al. (2022), "Pan-Tompkins++: A Robust Approach to Detect
    R-peaks in ECG Signals", arXiv:2211.03171.

Pipeline:  band-pass -> derivative -> square -> moving-window integration
           -> dual adaptive thresholding on the integrated signal AND the
           band-passed signal, with RR-based search-back and T-wave
           discrimination.
"""

from filters import (butter_bandpass, derivative5, square,
                     moving_window_integrate)


def _local_peaks(x):
    """Indices of local maxima in x."""
    peaks = []
    for i in range(1, len(x) - 1):
        if x[i - 1] < x[i] >= x[i + 1]:
            peaks.append(i)
    return peaks


def detect(sig, fs):
    """Return detected R-peak sample indices (refined onto the raw signal)."""
    bp = butter_bandpass(sig, fs, lo=5.0, hi=18.0)
    der = derivative5(bp, fs)
    sq = square(der)
    mwi = moving_window_integrate(sq, fs, width_s=0.150)

    # --- threshold initialisation from a 2 s learning phase ---
    learn = int(2 * fs)
    seg = mwi[:learn] if learn < len(mwi) else mwi
    spki = (sum(seg) / len(seg)) * 0.5 if seg else 0.0   # running signal peak
    npki = (sum(seg) / len(seg)) * 0.25 if seg else 0.0  # running noise peak
    thr_i1 = npki + 0.25 * (spki - npki)

    bp_abs = [abs(v) for v in bp]
    seg_b = bp_abs[:learn] if learn < len(bp_abs) else bp_abs
    spkf = (max(seg_b) if seg_b else 0.0) * 0.25
    npkf = (sum(seg_b) / len(seg_b)) * 0.25 if seg_b else 0.0
    thr_f1 = npkf + 0.25 * (spkf - npkf)

    refractory = int(0.20 * fs)   # 200 ms physiological refractory period
    twave_win = int(0.36 * fs)    # T-wave discrimination window

    qrs = []           # confirmed QRS sample indices (on mwi)
    rr_recent = []     # last 8 RR intervals (samples)
    rr_avg2 = None
    last_qrs = -10 * fs
    last_slope = 0.0

    cand = _local_peaks(mwi)

    def slope_at(idx, x, half=5):
        a = x[max(0, idx - half):idx + 1]
        if len(a) < 2:
            return 0.0
        return max(a[k] - a[k - 1] for k in range(1, len(a)))

    i = 0
    while i < len(cand):
        n = cand[i]
        peak = mwi[n]

        is_qrs = False
        if n - last_qrs > refractory and peak > thr_i1:
            # corresponding peak must also clear the band-pass threshold
            lo = max(0, n - int(0.10 * fs))
            hi = min(len(bp_abs), n + int(0.05 * fs))
            bp_peak = max(bp_abs[lo:hi]) if hi > lo else 0.0
            if bp_peak > thr_f1:
                # ---- T-wave discrimination (Pan-Tompkins++ slope test) ----
                if qrs and (n - last_qrs) < twave_win:
                    s_now = slope_at(n, mwi)
                    if s_now < 0.5 * last_slope:
                        # too shallow + too soon -> a T wave, not a QRS
                        npki = 0.125 * peak + 0.875 * npki
                        thr_i1 = npki + 0.25 * (spki - npki)
                        i += 1
                        continue
                    last_slope = s_now
                else:
                    last_slope = slope_at(n, mwi)
                is_qrs = True

        if is_qrs:
            spki = 0.125 * peak + 0.875 * spki
            spkf = 0.125 * bp_peak + 0.875 * spkf
            if qrs:
                rr = n - qrs[-1]
                rr_recent.append(rr)
                if len(rr_recent) > 8:
                    rr_recent.pop(0)
                rr_avg2 = sum(rr_recent) / len(rr_recent)
            qrs.append(n)
            last_qrs = n
        else:
            npki = 0.125 * peak + 0.875 * npki

        thr_i1 = npki + 0.25 * (spki - npki)
        thr_f1 = npkf + 0.25 * (spkf - npkf)

        # ---- search-back: if no QRS for 166% of mean RR, lower thresholds ----
        if rr_avg2 and qrs and (n - qrs[-1]) > 1.66 * rr_avg2:
            window = [(c, mwi[c]) for c in cand
                      if qrs[-1] + refractory < c < n and mwi[c] > 0.5 * thr_i1]
            if window:
                bn, bpk = max(window, key=lambda t: t[1])
                spki = 0.25 * bpk + 0.75 * spki
                rr = bn - qrs[-1]
                rr_recent.append(rr)
                if len(rr_recent) > 8:
                    rr_recent.pop(0)
                rr_avg2 = sum(rr_recent) / len(rr_recent)
                qrs.append(bn)
                qrs.sort()
                last_qrs = bn
                thr_i1 = npki + 0.25 * (spki - npki)
        i += 1

    # ---- refine each detection onto the true R apex in the raw signal ----
    # The band-pass + 150 ms integration window delay the MWI peak well after
    # the QRS, so search a wide, mostly-backward window for the raw apex.
    refined = []
    back = int(0.20 * fs)
    fwd = int(0.03 * fs)
    for n in qrs:
        lo = max(0, n - back)
        hi = min(len(sig), n + fwd)
        if hi <= lo:
            continue
        apex = max(range(lo, hi), key=lambda k: sig[k])
        refined.append(apex)
    # de-duplicate after refinement
    out = []
    for r in sorted(refined):
        if not out or r - out[-1] > refractory:
            out.append(r)
    return out


def score(detected, truth, fs, tol_s=0.075):
    """Beat-matching sensitivity / positive-predictivity (AAMI-style)."""
    tol = int(tol_s * fs)
    truth = sorted(truth)
    used = [False] * len(truth)
    tp = 0
    j = 0
    for d in sorted(detected):
        # advance to candidate truth beats near d
        best = -1
        bestdist = tol + 1
        for k in range(len(truth)):
            if used[k]:
                continue
            dist = abs(truth[k] - d)
            if dist <= tol and dist < bestdist:
                best, bestdist = k, dist
        if best >= 0:
            used[best] = True
            tp += 1
    fp = len(detected) - tp
    fn = len(truth) - tp
    se = tp / (tp + fn) if (tp + fn) else 0.0
    pp = tp / (tp + fp) if (tp + fp) else 0.0
    return {"TP": tp, "FP": fp, "FN": fn, "Se": se, "PPV": pp}
