"""Standard genetic code (NCBI translation table 1) and helpers."""

CODON_TABLE = {
    "TTT": "F", "TTC": "F", "TTA": "L", "TTG": "L",
    "CTT": "L", "CTC": "L", "CTA": "L", "CTG": "L",
    "ATT": "I", "ATC": "I", "ATA": "I", "ATG": "M",
    "GTT": "V", "GTC": "V", "GTA": "V", "GTG": "V",
    "TCT": "S", "TCC": "S", "TCA": "S", "TCG": "S",
    "CCT": "P", "CCC": "P", "CCA": "P", "CCG": "P",
    "ACT": "T", "ACC": "T", "ACA": "T", "ACG": "T",
    "GCT": "A", "GCC": "A", "GCA": "A", "GCG": "A",
    "TAT": "Y", "TAC": "Y", "TAA": "*", "TAG": "*",
    "CAT": "H", "CAC": "H", "CAA": "Q", "CAG": "Q",
    "AAT": "N", "AAC": "N", "AAA": "K", "AAG": "K",
    "GAT": "D", "GAC": "D", "GAA": "E", "GAG": "E",
    "TGT": "C", "TGC": "C", "TGA": "*", "TGG": "W",
    "CGT": "R", "CGC": "R", "CGA": "R", "CGG": "R",
    "AGT": "S", "AGC": "S", "AGA": "R", "AGG": "R",
    "GGT": "G", "GGC": "G", "GGA": "G", "GGG": "G",
}

# amino acid -> list of synonymous codons
SYN = {}
for _codon, _aa in CODON_TABLE.items():
    SYN.setdefault(_aa, []).append(_codon)


def translate(dna):
    """Translate a DNA coding sequence to a protein string (stop -> '*')."""
    dna = dna.upper().replace("U", "T")
    aa = []
    for i in range(0, len(dna) - 2, 3):
        aa.append(CODON_TABLE.get(dna[i:i + 3], "X"))
    return "".join(aa)


def gc_content(dna):
    dna = dna.upper()
    g = sum(1 for c in dna if c in "GC")
    return 100.0 * g / len(dna) if dna else 0.0
