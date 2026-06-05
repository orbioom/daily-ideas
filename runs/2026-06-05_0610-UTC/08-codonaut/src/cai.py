"""
Codon Adaptation Index (CAI).

CAI is the geometric mean of the relative adaptiveness (w) of every codon in a
sequence, excluding Met, Trp (single-codon families) and stop codons:

    CAI = ( product_i w_i ) ^ (1/L)   computed in log space.

Reference:
    Sharp, P. M. & Li, W.-H. (1987). The codon adaptation index — a measure of
    directional synonymous codon usage bias and its potential applications.
    Nucleic Acids Research 15(3):1281-1295.
"""

import math
from genetic_code import CODON_TABLE


def cai(dna, w):
    dna = dna.upper().replace("U", "T")
    logsum = 0.0
    n = 0
    for i in range(0, len(dna) - 2, 3):
        codon = dna[i:i + 3]
        aa = CODON_TABLE.get(codon)
        if aa in (None, "*", "M", "W"):  # skip stops + single-codon AAs
            continue
        wi = w.get(codon)
        if wi is None or wi <= 0:
            continue
        logsum += math.log(wi)
        n += 1
    if n == 0:
        return 0.0
    return math.exp(logsum / n)
