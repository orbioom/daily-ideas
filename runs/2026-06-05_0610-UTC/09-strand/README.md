# Strand — FM-index exact matching for DNA

Build a **Burrows-Wheeler / FM-index** over a reference genome and find every
exact occurrence of a query read in **O(read length)** time — no re-scan of the
genome per query. This is the core data structure behind read aligners like
**BWA** and **Bowtie**, implemented here from first principles in pure Python so
every step is readable: suffix array → BWT → C/Occ tables → backward search.

No numpy, no Biopython, no internet.

## Why it's interesting

A naive `text.find` scan is O(genome × queries). The FM-index pays an
up-front cost to build, then answers each query in time proportional only to the
query length. On an 8 kbp reference with 2000 random 12-mers, the FM-index runs
**~9× faster** than naive scanning — and the gap widens with genome size. The
implementation is verified two ways: the inverse-BWT round-trips back to the
original reference, and every `locate()` result is checked against a brute-force
scan.

## Run it

```bash
cd 09-strand
python3 src/run.py                                   # demo on a generated reference
python3 src/run.py data/reference.fasta GATTACA ACGT # custom reference + queries
```

### Example result

```
reference  reference.fasta  (8,000 bp)
index built  28 ms
inverse-BWT round-trip  ok
GATTACA       3   [500, 2200, 6100]  match
ACGTACGT      2   [1000, 4500]       match
2000 random 12-mer counts  FM-index 6 ms vs naive 50 ms  (8.8x faster)
all checks passed
```

A reproducible reference (with motifs planted at known positions) is written to
`data/reference.fasta`; the report goes to `results/report.txt`.

## Files

| File | Role |
|---|---|
| `src/suffix_array.py` | prefix-doubling suffix array, O(n log²n) |
| `src/bwt.py` | BWT from SA + LF-mapping inverse transform |
| `src/fm_index.py` | C[]/Occ tables, backward search `count`/`locate`/`interval` |
| `src/run.py` | build, verify, query, benchmark, CLI |

## References

- Ferragina, P. & Manzini, G. (2000). *Opportunistic data structures with
  applications.* IEEE FOCS, 390–398.
- Burrows, M. & Wheeler, D. (1994). *A block-sorting lossless data compression
  algorithm.* DEC SRC Research Report 124.
- Li, H. & Durbin, R. (2009). *Fast and accurate short read alignment with
  Burrows-Wheeler transform.* Bioinformatics 25(14):1754–1760.

*Educational implementation: full (unsampled) suffix array is held in memory, so
it targets reference fragments rather than whole mammalian genomes.*
