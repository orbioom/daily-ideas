#!/usr/bin/env python3
"""
Codonaut -- codon-optimize a protein for expression in E. coli, and measure
the improvement with the Codon Adaptation Index (CAI).

Usage:
    python3 src/run.py                       # demo on GFP (data/gfp_protein.fasta)
    python3 src/run.py path/to/protein.fasta

Pure standard library. No internet, no dependencies.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from genetic_code import SYN, translate, gc_content
from codon_usage import ECOLI_W, ECOLI_K12
from cai import cai
from optimize import optimize, verify

GREEN = "\033[38;5;115m"
INK = "\033[38;5;250m"
DIM = "\033[38;5;245m"
RESET = "\033[0m"


def read_fasta_protein(path):
    seq = []
    with open(path) as f:
        for line in f:
            if line.startswith(">"):
                continue
            seq.append(line.strip())
    return "".join(seq).upper()


def worst_codons():
    """Least-adaptive synonym per amino acid (a naive starting sequence)."""
    worst = {}
    for aa, codons in SYN.items():
        worst[aa] = min(codons, key=lambda c: ECOLI_K12[c])
    return worst


def reverse_translate(protein, table):
    return "".join(table[aa] for aa in protein)


def bar(value, width=28):
    fill = int(round(value * width))
    return GREEN + "#" * fill + RESET + DIM + "." * (width - fill) + RESET


def main():
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        here, "data", "gfp_protein.fasta")

    protein = read_fasta_protein(path).rstrip("*")
    print(f"{DIM}codonaut{RESET}  {INK}codon optimization for E. coli K-12{RESET}")
    print(f"{DIM}CAI after Sharp & Li (1987){RESET}\n")
    print(f"{INK}protein{RESET}  {os.path.basename(path)}  ({len(protein)} aa)\n")

    # naive AT-biased starting CDS vs. fully optimized CDS
    naive = reverse_translate(protein, worst_codons())
    opt = optimize(protein)

    cai_naive = cai(naive, ECOLI_W)
    cai_opt = cai(opt, ECOLI_W)

    assert verify(protein, naive), "naive CDS does not back-translate!"
    assert verify(protein, opt), "optimized CDS does not back-translate!"

    changed = sum(1 for i in range(0, len(naive), 3)
                  if naive[i:i+3] != opt[i:i+3])
    total = len(naive) // 3

    rows = [
        ("naive (rare codons)", cai_naive, gc_content(naive)),
        ("E. coli optimized", cai_opt, gc_content(opt)),
    ]
    print(f"{DIM}{'sequence':<22}{'CAI':>7}   {'GC%':>5}{RESET}")
    for name, c, gc in rows:
        print(f"{INK}{name:<22}{RESET}{GREEN}{c:>7.3f}{RESET}   {gc:>5.1f}   "
              f"{bar(c)}")

    fold = (cai_opt / cai_naive) if cai_naive else float('inf')
    print(f"\n{GREEN}CAI improved {fold:.1f}x{RESET}  "
          f"{INK}({changed}/{total} codons rewritten, "
          f"protein identity preserved){RESET}")

    # write outputs
    os.makedirs(os.path.join(here, "results"), exist_ok=True)
    with open(os.path.join(here, "results", "optimized_cds.fasta"), "w") as f:
        f.write(">optimized_for_Ecoli_K12 CAI=%.3f\n" % cai_opt)
        for i in range(0, len(opt), 60):
            f.write(opt[i:i+60] + "\n")

    with open(os.path.join(here, "results", "report.txt"), "w") as f:
        f.write("Codonaut - codon optimization report\n")
        f.write("=" * 40 + "\n")
        f.write(f"protein length : {len(protein)} aa\n")
        f.write(f"host           : E. coli K-12\n\n")
        f.write(f"{'sequence':<24}{'CAI':>7}{'GC%':>8}\n")
        for name, c, gc in rows:
            f.write(f"{name:<24}{c:>7.3f}{gc:>8.1f}\n")
        f.write(f"\nCAI improvement : {fold:.2f}x\n")
        f.write(f"codons rewritten: {changed}/{total}\n")
        f.write(f"protein identity: preserved\n")
    print(f"\n{DIM}optimized CDS -> results/optimized_cds.fasta{RESET}")
    print(f"{DIM}report        -> results/report.txt{RESET}")


if __name__ == "__main__":
    main()
