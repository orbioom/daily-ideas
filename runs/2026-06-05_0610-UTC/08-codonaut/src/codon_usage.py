"""
Host codon-usage tables and relative-adaptiveness (w) values.

Frequencies are codon usage per 1000 codons for *Escherichia coli* K-12,
as compiled by the Kazusa Codon Usage Database from GenBank CDS. These are
the de-facto reference values used throughout the codon-optimization
literature.

The relative adaptiveness w_i of a codon i is its frequency divided by the
frequency of the most-used synonymous codon for the same amino acid
(Sharp & Li, 1987).
"""

from genetic_code import CODON_TABLE, SYN

# codon -> frequency per 1000 (E. coli K-12)
ECOLI_K12 = {
    "TTT": 22.4, "TTC": 16.6, "TTA": 13.9, "TTG": 13.7,
    "CTT": 11.0, "CTC": 11.0, "CTA": 3.9, "CTG": 52.6,
    "ATT": 30.5, "ATC": 25.1, "ATA": 4.4, "ATG": 27.9,
    "GTT": 18.3, "GTC": 15.3, "GTA": 10.9, "GTG": 26.4,
    "TCT": 8.5, "TCC": 8.6, "TCA": 7.2, "TCG": 8.9,
    "CCT": 7.0, "CCC": 5.5, "CCA": 8.4, "CCG": 23.2,
    "ACT": 9.0, "ACC": 23.4, "ACA": 7.1, "ACG": 14.4,
    "GCT": 15.3, "GCC": 25.5, "GCA": 20.1, "GCG": 33.6,
    "TAT": 16.2, "TAC": 12.2, "TAA": 2.0, "TAG": 0.3,
    "CAT": 12.9, "CAC": 9.7, "CAA": 15.3, "CAG": 28.8,
    "AAT": 17.7, "AAC": 21.7, "AAA": 33.6, "AAG": 10.3,
    "GAT": 32.1, "GAC": 19.1, "GAA": 39.4, "GAG": 17.8,
    "TGT": 5.2, "TGC": 6.4, "TGA": 0.9, "TGG": 15.2,
    "CGT": 20.9, "CGC": 22.0, "CGA": 3.6, "CGG": 5.4,
    "AGT": 8.8, "AGC": 16.1, "AGA": 2.1, "AGG": 1.2,
    "GGT": 24.7, "GGC": 29.6, "GGA": 8.0, "GGG": 11.1,
}


def relative_adaptiveness(freq):
    """w_i for every codon: freq_i / max(freq in synonymous family)."""
    w = {}
    for aa, codons in SYN.items():
        if aa == "*":
            continue
        fmax = max(freq[c] for c in codons)
        for c in codons:
            # guard against zero with the conventional small floor
            w[c] = (freq[c] / fmax) if fmax > 0 else 0.01
            if w[c] == 0:
                w[c] = 0.01
    return w


def best_codon_per_aa(freq):
    """The maximally-adaptive codon for each amino acid."""
    best = {}
    for aa, codons in SYN.items():
        if aa == "*":
            best[aa] = max(codons, key=lambda c: freq[c])
            continue
        best[aa] = max(codons, key=lambda c: freq[c])
    return best


ECOLI_W = relative_adaptiveness(ECOLI_K12)
ECOLI_BEST = best_codon_per_aa(ECOLI_K12)
