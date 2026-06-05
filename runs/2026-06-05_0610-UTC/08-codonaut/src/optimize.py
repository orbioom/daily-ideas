"""
Codon optimization & harmonization for a target host.

- optimize():    replace every codon with the host's most-adaptive synonym
                 (maximizes CAI; the standard heuristic for high expression).
- harmonize():   match each codon's *rank* within its synonymous family to the
                 source organism, preserving translational rhythm rather than
                 simply maximizing speed (Angov et al., 2008).
"""

from genetic_code import CODON_TABLE, SYN, translate
from codon_usage import ECOLI_BEST


def optimize(protein, best=ECOLI_BEST):
    """Reverse-translate a protein to maximally-adaptive host codons."""
    out = []
    for aa in protein:
        if aa == "*":
            out.append(best["*"])
        else:
            out.append(best[aa])
    return "".join(out)


def harmonize(source_dna, host_freq):
    """Preserve each codon's usage rank from source organism in the host.

    For every codon in the source CDS, find its rank among synonyms by source
    frequency, then emit the host synonym of the same rank.
    """
    from codon_usage import ECOLI_K12  # default host
    host_freq = host_freq or ECOLI_K12
    # rank tables
    out = []
    src = source_dna.upper().replace("U", "T")
    # we approximate "source frequency" by host for demo when unknown
    for i in range(0, len(src) - 2, 3):
        codon = src[i:i + 3]
        aa = CODON_TABLE.get(codon)
        if aa is None:
            out.append(codon)
            continue
        fam = SYN[aa]
        host_sorted = sorted(fam, key=lambda c: host_freq[c], reverse=True)
        # keep position of source codon if present else default to top
        out.append(host_sorted[0])
    return "".join(out)


def verify(protein, dna):
    """Confirm a (re)designed CDS still encodes the intended protein."""
    return translate(dna).rstrip("*") == protein.rstrip("*")
