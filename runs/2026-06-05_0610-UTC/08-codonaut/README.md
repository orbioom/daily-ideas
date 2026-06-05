# Codonaut — codon optimization with the Codon Adaptation Index

Reverse-translate a protein into a DNA coding sequence tuned for high
expression in *E. coli*, and **measure** the result with the Codon Adaptation
Index (CAI) — the standard quantitative measure of synonymous-codon bias used
across molecular biology and synthetic-biology pipelines.

Pure Python standard library. Real, published *E. coli* K-12 codon-usage
frequencies. No internet, no Biopython, no NCBI calls.

## What it does

- **CAI** (Sharp & Li, 1987): geometric mean of each codon's relative
  adaptiveness, excluding Met/Trp/stop. CAI ∈ (0, 1]; closer to 1 ⇒ codons
  match the host's preferred, highly-expressed set.
- **Optimize**: rewrite every codon to the host's most-adaptive synonym while
  provably preserving the encoded protein.
- **Harmonize**: a rank-preserving alternative that keeps translational rhythm
  rather than maximizing speed (Angov et al., 2008).
- **GC content** before/after, and a back-translation **identity check** that
  asserts the redesigned CDS encodes exactly the input protein.

## Run it

```bash
cd 08-codonaut
python3 src/run.py                      # demo on GFP (data/gfp_protein.fasta)
python3 src/run.py data/gfp_protein.fasta
```

### Example result — GFP (238 aa)

```
sequence                  CAI     GC%
naive (rare codons)     0.346    44.0
E. coli optimized       1.000    48.6
CAI improved 2.9x   (231/238 codons rewritten, protein identity preserved)
```

The optimized CDS is written to `results/optimized_cds.fasta` and a summary to
`results/report.txt`.

## Files

| File | Role |
|---|---|
| `src/genetic_code.py` | NCBI table 1, translation, GC content |
| `src/codon_usage.py` | *E. coli* K-12 usage table + relative adaptiveness w |
| `src/cai.py` | Codon Adaptation Index (log-space geometric mean) |
| `src/optimize.py` | optimize / harmonize / back-translation verifier |
| `src/run.py` | CLI demo + report |
| `data/gfp_protein.fasta` | sample protein (Aequorea victoria GFP, P42212) |

## References

- Sharp, P. M. & Li, W.-H. (1987). *The codon adaptation index — a measure of
  directional synonymous codon usage bias.* Nucleic Acids Res. 15(3):1281–1295.
- Angov, E. et al. (2008). *Heterologous protein expression is enhanced by
  harmonizing the codon usage frequencies of the target gene with those of the
  expression host.* PLoS ONE 3(5):e2189.
- Codon frequencies: Kazusa Codon Usage Database, *E. coli* K-12 (GenBank CDS).

*Educational / research tooling — validate any construct experimentally before
synthesis.*
