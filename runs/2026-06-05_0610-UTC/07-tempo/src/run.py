#!/usr/bin/env python3
"""
Tempo -- end-to-end ECG -> R-peaks -> HRV pipeline.

Usage:
    python3 src/run.py                 # synthesize, detect, score, report
    python3 src/run.py data/ecg.csv    # run on a CSV with columns time_s,ecg_mv

Pure standard library. No numpy, no SciPy, no internet.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from ecg import synth_ecg, write_csv, read_csv
from detect import detect, score
from hrv import rr_intervals_ms, metrics

# --- Orbioom CLI palette: calm, monospace, green only for "live" ---
GREEN = "\033[38;5;115m"   # ~#86c79a live green
INK = "\033[38;5;250m"
DIM = "\033[38;5;245m"
RESET = "\033[0m"


def banner():
    print(f"{DIM}tempo{RESET}  {INK}ECG -> R-peaks -> heart-rate variability{RESET}")
    print(f"{DIM}Pan-Tompkins++ (arXiv:2211.03171) - pure Python{RESET}\n")


def ascii_tachogram(rr, width=58, rows=9):
    if not rr:
        return
    lo, hi = min(rr), max(rr)
    span = (hi - lo) or 1.0
    step = max(1, len(rr) // width)
    cols = rr[::step][:width]
    print(f"{DIM}RR tachogram  ({lo:.0f}-{hi:.0f} ms){RESET}")
    for r in range(rows, 0, -1):
        line = []
        for v in cols:
            level = (v - lo) / span * rows
            line.append(GREEN + "*" + RESET if level >= r - 0.5 else " ")
        print("  " + "".join(line))
    print("  " + "-" * len(cols) + f"  {DIM}time ->{RESET}\n")


def main():
    banner()
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    truth = None

    if len(sys.argv) > 1:
        sig, fs = read_csv(sys.argv[1])
        print(f"{INK}loaded{RESET} {len(sig)} samples @ {fs} Hz from {sys.argv[1]}\n")
    else:
        sig, fs, truth = synth_ecg(duration_s=90.0, fs=250.0,
                                   mean_hr=62.0, sdnn_ms=55.0)
        os.makedirs(os.path.join(here, "data"), exist_ok=True)
        write_csv(os.path.join(here, "data", "ecg_sample.csv"), sig, fs)
        print(f"{INK}synthesized{RESET} {len(sig)} samples @ {fs:.0f} Hz, "
              f"{len(truth)} ground-truth beats\n")

    peaks = detect(sig, fs)
    print(f"{GREEN}detected{RESET} {len(peaks)} R-peaks")

    lines = []
    lines.append("Tempo - HRV analysis report")
    lines.append("=" * 40)
    lines.append(f"samples         : {len(sig)} @ {fs:.0f} Hz "
                 f"({len(sig)/fs:.1f} s)")
    lines.append(f"R-peaks         : {len(peaks)}")

    if truth is not None:
        sc = score(peaks, truth, fs)
        print(f"{GREEN}detector{RESET}  Se={sc['Se']*100:.1f}%  "
              f"PPV={sc['PPV']*100:.1f}%  "
              f"(TP={sc['TP']} FP={sc['FP']} FN={sc['FN']})\n")
        lines.append("")
        lines.append("Detector vs. ground truth (75 ms tolerance)")
        lines.append("-" * 40)
        lines.append(f"  Sensitivity   : {sc['Se']*100:.2f}%")
        lines.append(f"  Pos. Predict. : {sc['PPV']*100:.2f}%")
        lines.append(f"  TP/FP/FN      : {sc['TP']}/{sc['FP']}/{sc['FN']}")

    rr = rr_intervals_ms(peaks, fs)
    m = metrics(rr)
    ascii_tachogram(rr)

    lines.append("")
    lines.append("HRV metrics (time-domain + Poincare)")
    lines.append("-" * 40)
    order = ["mean_HR_bpm", "mean_RR_ms", "SDNN_ms", "RMSSD_ms",
             "pNN50_pct", "SD1_ms", "SD2_ms", "SD2_SD1"]
    for k in order:
        if k in m:
            print(f"  {INK}{k:<12}{RESET} {GREEN}{m[k]:8.2f}{RESET}")
            lines.append(f"  {k:<14}: {m[k]:.3f}")

    os.makedirs(os.path.join(here, "results"), exist_ok=True)
    with open(os.path.join(here, "results", "report.txt"), "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"\n{DIM}report written to results/report.txt{RESET}")


if __name__ == "__main__":
    main()
