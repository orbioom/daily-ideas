"""Burrows-Wheeler transform from a suffix array, and its inverse."""

from suffix_array import suffix_array


def bwt_from_sa(s, sa):
    """L = last column of the sorted rotation matrix; s must end in '$'."""
    return "".join(s[i - 1] if i > 0 else s[-1] for i in sa)


def transform(s):
    if not s.endswith("$"):
        s = s + "$"
    sa = suffix_array(s)
    return bwt_from_sa(s, sa), sa


def inverse(bwt):
    """Reconstruct the original string from its BWT (LF-mapping walk)."""
    n = len(bwt)
    # rank of each char occurrence + first column via counting sort
    counts = {}
    ranks = [0] * n
    for i, c in enumerate(bwt):
        ranks[i] = counts.get(c, 0)
        counts[c] = counts.get(c, 0) + 1
    first_start = {}
    total = 0
    for c in sorted(counts):
        first_start[c] = total
        total += counts[c]
    # walk from the '$' row back to front
    row = bwt.index("$")
    out = []
    for _ in range(n):
        c = bwt[row]
        out.append(c)
        row = first_start[c] + ranks[row]
    return "".join(reversed(out)).rstrip("$")
