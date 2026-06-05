#!/usr/bin/env python3
"""
Strand -- build an FM-index over a DNA reference and find exact matches of
query reads in O(read length) per query, with no re-scan of the genome.

Usage:
    python3 src/run.py                      # demo on data/reference.fasta
    python3 src/run.py data/reference.fasta GATTACA ACGTACGT

Pure standard library. No internet, no dependencies.
"""

import os
import random
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fm_index import FMIndex
from bwt import inverse

GREEN = "\033[38;5;115m"
INK = "\033[38;5;250m"
DIM = "\033[38;5;245m"
RED = "\033[38;5;174m"
RESET = "\033[0m"


def make_reference(path, length=8000, seed=11):
    """Deterministic DNA reference with a few planted motifs for verification."""
    rng = random.Random(seed)
    bases = "ACGT"
    seq = [rng.choice(bases) for _ in range(length)]
    motifs = {"GATTACA": [500, 2200, 6100], "ACGTACGT": [1000, 4500]}
    for m, locs in motifs.items():
        for p in locs:
            seq[p:p + len(m)] = list(m)
    s = "".join(seq)
    with open(path, "w") as f:
        f.write(">synthetic_reference len=%d seed=%d\n" % (length, seed))
        for i in range(0, len(s), 70):
            f.write(s[i:i + 70] + "\n")
    return s


def read_fasta(path):
    seq = []
    with open(path) as f:
        for line in f:
            if not line.startswith(">"):
                seq.append(line.strip())
    return "".join(seq).upper()


def naive_find_all(text, pat):
    out, start = [], 0
    while True:
        i = text.find(pat, start)
        if i < 0:
            break
        out.append(i)
        start = i + 1
    return out


def main():
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    args = sys.argv[1:]
    ref_path = os.path.join(here, "data", "reference.fasta")
    queries = ["GATTACA", "ACGTACGT"]

    if args and os.path.exists(args[0]):
        ref_path = args[0]
        if len(args) > 1:
            queries = args[1:]
        text = read_fasta(ref_path)
    else:
        text = make_reference(ref_path)
        if args:
            queries = args

    print(f"{DIM}strand{RESET}  {INK}FM-index exact matching over a DNA reference{RESET}")
    print(f"{DIM}Ferragina-Manzini (2000) - pure Python{RESET}\n")
    print(f"{INK}reference{RESET}  {os.path.basename(ref_path)}  ({len(text):,} bp)")

    t0 = time.time()
    fm = FMIndex(text)
    build_ms = (time.time() - t0) * 1000
    print(f"{GREEN}index built{RESET}  {build_ms:.0f} ms  "
          f"(suffix array + BWT + Occ table)\n")

    # ---- integrity: inverse BWT must reconstruct the reference ----
    recon_ok = inverse(fm.bwt) == text
    tag = f"{GREEN}ok{RESET}" if recon_ok else f"{RED}FAIL{RESET}"
    print(f"{INK}inverse-BWT round-trip{RESET}  {tag}\n")

    # ---- queries: locate + verify against naive scan ----
    report = ["Strand - FM-index query report", "=" * 40,
              f"reference : {len(text)} bp", f"build     : {build_ms:.0f} ms",
              f"round-trip: {'ok' if recon_ok else 'FAIL'}", ""]
    print(f"{DIM}{'query':<14}{'hits':>5}   positions / verification{RESET}")
    all_ok = recon_ok
    for q in queries:
        q = q.upper()
        hits = fm.locate(q)
        truth = naive_find_all(text, q)
        ok = hits == truth
        all_ok = all_ok and ok
        vtag = f"{GREEN}match{RESET}" if ok else f"{RED}MISMATCH{RESET}"
        shown = ", ".join(map(str, hits[:6])) + (" ..." if len(hits) > 6 else "")
        print(f"{INK}{q:<14}{RESET}{GREEN}{len(hits):>5}{RESET}   "
              f"[{shown}]  {vtag}")
        report.append(f"{q:<14} hits={len(hits):<4} verified={'ok' if ok else 'MISMATCH'}")

    # ---- benchmark: 2000 random 12-mers, FM-index vs naive scan ----
    rng = random.Random(3)
    probes = ["".join(rng.choice("ACGT") for _ in range(12)) for _ in range(2000)]
    t0 = time.time()
    for p in probes:
        fm.count(p)
    fm_ms = (time.time() - t0) * 1000
    t0 = time.time()
    for p in probes:
        len(naive_find_all(text, p))
    naive_ms = (time.time() - t0) * 1000
    speedup = naive_ms / fm_ms if fm_ms else float("inf")
    print(f"\n{DIM}2000 random 12-mer counts{RESET}  "
          f"FM-index {GREEN}{fm_ms:.0f} ms{RESET} vs "
          f"naive {INK}{naive_ms:.0f} ms{RESET}  "
          f"({GREEN}{speedup:.1f}x faster{RESET})")
    report += ["", f"benchmark (2000x 12-mer): FM={fm_ms:.0f}ms naive={naive_ms:.0f}ms "
               f"speedup={speedup:.1f}x"]

    os.makedirs(os.path.join(here, "results"), exist_ok=True)
    with open(os.path.join(here, "results", "report.txt"), "w") as f:
        f.write("\n".join(report) + "\n")

    final = f"{GREEN}all checks passed{RESET}" if all_ok else f"{RED}checks failed{RESET}"
    print(f"\n{final}  {DIM}- report -> results/report.txt{RESET}")
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
