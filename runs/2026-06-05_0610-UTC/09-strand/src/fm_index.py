"""
FM-index: backward-search exact pattern matching over the BWT.

Given the BWT L of a text T$, the C[] array (number of symbols
lexicographically smaller than c) and an Occ table (Occ(c, i) = occurrences of
c in L[0..i]), the set of suffixes prefixed by a pattern P is found by scanning
P right-to-left and shrinking an SA interval [lo, hi] in O(|P|) time -- no
re-scan of the text.

References:
    Ferragina, P. & Manzini, G. (2000). Opportunistic data structures with
    applications. FOCS 2000, 390-398.
    Li, H. & Durbin, R. (2009). Fast and accurate short read alignment with
    Burrows-Wheeler transform (BWA). Bioinformatics 25(14):1754-1760.
"""

from bwt import transform


class FMIndex:
    def __init__(self, text):
        if not text.endswith("$"):
            text = text + "$"
        self.n = len(text)
        self.bwt, self.sa = transform(text)
        self._build_tables()

    def _build_tables(self):
        alphabet = sorted(set(self.bwt))
        self.alphabet = alphabet
        # C[c] = number of symbols in text smaller than c
        total = 0
        counts = {c: self.bwt.count(c) for c in alphabet}
        self.C = {}
        for c in alphabet:
            self.C[c] = total
            total += counts[c]
        # Occ prefix-sum table: occ[c][i] = count of c in bwt[0..i-1]
        self.occ = {c: [0] * (self.n + 1) for c in alphabet}
        for i, ch in enumerate(self.bwt):
            for c in alphabet:
                self.occ[c][i + 1] = self.occ[c][i] + (1 if ch == c else 0)

    def _occ(self, c, i):
        """Occurrences of c in bwt[0..i] inclusive; i == -1 -> 0."""
        if c not in self.occ:
            return 0
        return self.occ[c][i + 1]

    def count(self, pattern):
        """Number of exact occurrences of pattern in the text."""
        lo, hi = self.interval(pattern)
        return 0 if lo > hi else hi - lo + 1

    def interval(self, pattern):
        lo, hi = 0, self.n - 1
        for c in reversed(pattern):
            if c not in self.C:
                return 1, 0  # empty interval
            lo = self.C[c] + self._occ(c, lo - 1)
            hi = self.C[c] + self._occ(c, hi) - 1
            if lo > hi:
                return 1, 0
        return lo, hi

    def locate(self, pattern):
        """Sorted text positions (0-based) of every exact occurrence."""
        lo, hi = self.interval(pattern)
        if lo > hi:
            return []
        return sorted(self.sa[i] for i in range(lo, hi + 1))
