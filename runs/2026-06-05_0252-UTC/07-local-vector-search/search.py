"""
Orbioom Local Vector Search
===========================
Search your Markdown notes folder by meaning, not just keywords.
Runs entirely offline — no API keys, no cloud. Uses TF-IDF vectors
with cosine similarity as the semantic engine.

Usage:
  python search.py "your query here" [--dir ./notes] [--top 5]

Requirements: Python 3.8+, no external packages needed.
"""

import os
import re
import sys
import math
import json
import time
import argparse
from pathlib import Path
from collections import defaultdict

# ── Orbioom terminal palette (ANSI) ──────────────────────────────────────────
RESET  = "\033[0m"
DIM    = "\033[2m"
BOLD   = "\033[1m"
GREEN  = "\033[38;5;114m"   # #86C79A approximation
MUTED  = "\033[38;5;102m"
WHITE  = "\033[38;5;253m"
RULE   = "\033[38;5;240m"


def _print_header():
    print(f"\n{RULE}{'─' * 56}{RESET}")
    print(f"  {BOLD}{WHITE}Orbioom{RESET} {DIM}local vector search{RESET}")
    print(f"{RULE}{'─' * 56}{RESET}\n")


def _print_result(rank, path, score, snippet):
    pct = int(score * 100)
    bar_len = max(1, int(score * 20))
    bar = "█" * bar_len + "░" * (20 - bar_len)
    rel = os.path.relpath(path)
    print(f"  {GREEN}{rank:>2}.{RESET}  {WHITE}{rel}{RESET}")
    print(f"      {DIM}{bar}{RESET}  {GREEN}{pct}%{RESET}")
    if snippet:
        # Wrap snippet to ~70 chars
        words = snippet.split()
        lines, cur = [], []
        for w in words:
            cur.append(w)
            if len(' '.join(cur)) > 66:
                lines.append(' '.join(cur[:-1]))
                cur = [w]
        if cur:
            lines.append(' '.join(cur))
        for i, line in enumerate(lines[:3]):
            prefix = "      " if i == 0 else "      "
            print(f"{prefix}{MUTED}{line}{RESET}")
    print()


# ── Text processing ───────────────────────────────────────────────────────────

STOP_WORDS = {
    'a','an','the','and','or','but','in','on','at','to','for','of','with',
    'by','from','up','about','into','through','during','is','are','was','were',
    'be','been','being','have','has','had','do','does','did','will','would',
    'could','should','may','might','shall','can','this','that','these','those',
    'i','you','he','she','it','we','they','me','him','her','us','them',
    'my','your','his','its','our','their','what','which','who','whom','when',
    'where','why','how','all','each','every','both','few','more','most',
    'other','some','such','no','not','only','same','so','than','too','very',
    'just','as','if','then','than','because','while','although','however',
}

def tokenize(text):
    text = re.sub(r'```.*?```', ' ', text, flags=re.DOTALL)
    text = re.sub(r'#+\s', ' ', text)
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
    text = re.sub(r'[^a-z0-9\s]', ' ', text.lower())
    return [w for w in text.split() if len(w) > 2 and w not in STOP_WORDS]


def read_markdown_files(directory):
    notes = {}
    p = Path(directory)
    for f in sorted(p.rglob('*.md')):
        try:
            text = f.read_text(encoding='utf-8', errors='ignore')
            notes[str(f)] = text
        except Exception:
            pass
    return notes


# ── TF-IDF ────────────────────────────────────────────────────────────────────

def build_index(notes):
    """Build TF-IDF index from {path: text} dict. Returns (tfidf_matrix, vocab, paths)."""
    paths = list(notes.keys())
    tokenized = [tokenize(notes[p]) for p in paths]

    # Build vocabulary
    df = defaultdict(int)
    for tokens in tokenized:
        for t in set(tokens):
            df[t] += 1

    N = len(paths)
    # For small collections keep all terms; for larger collections filter noise
    min_df = 1 if N < 20 else 2
    vocab = {t: i for i, t in enumerate(
        t for t, count in df.items()
        if min_df <= count < max(2, int(N * 0.8))
    )}

    # TF-IDF matrix: list of sparse {term_id: tfidf} dicts
    matrix = []
    for tokens in tokenized:
        tf = defaultdict(int)
        for t in tokens:
            tf[t] += 1
        total = max(len(tokens), 1)
        vec = {}
        for t, count in tf.items():
            if t in vocab:
                tid = vocab[t]
                tf_score = count / total
                idf = math.log(N / df[t])
                vec[tid] = tf_score * idf
        matrix.append(vec)

    return matrix, vocab, paths


def cosine_similarity(a, b):
    if not a or not b:
        return 0.0
    dot = sum(a.get(k, 0) * v for k, v in b.items())
    mag_a = math.sqrt(sum(v * v for v in a.values()))
    mag_b = math.sqrt(sum(v * v for v in b.values()))
    if mag_a == 0 or mag_b == 0:
        return 0.0
    return dot / (mag_a * mag_b)


def vectorize_query(query, vocab, idf_source_n, df):
    tokens = tokenize(query)
    if not tokens:
        return {}
    tf = defaultdict(int)
    for t in tokens:
        tf[t] += 1
    total = len(tokens)
    vec = {}
    for t, count in tf.items():
        if t in vocab:
            tid = vocab[t]
            tf_score = count / total
            idf = math.log(idf_source_n / max(df.get(t, 1), 1))
            vec[tid] = tf_score * idf
    return vec


def get_snippet(text, query_tokens, max_chars=180):
    """Find the paragraph most relevant to the query tokens."""
    paragraphs = [p.strip() for p in re.split(r'\n{2,}', text) if len(p.strip()) > 40]
    if not paragraphs:
        return text[:max_chars].replace('\n', ' ')
    best, best_score = paragraphs[0], 0
    for para in paragraphs:
        score = sum(1 for t in query_tokens if t in para.lower())
        if score > best_score:
            best_score = score
            best = para
    clean = re.sub(r'#+\s', '', best)
    clean = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', clean)
    clean = re.sub(r'\s+', ' ', clean).strip()
    return clean[:max_chars] + ('…' if len(clean) > max_chars else '')


def search(query, directory, top_k=5):
    t0 = time.time()
    notes = read_markdown_files(directory)
    if not notes:
        print(f"  {MUTED}No .md files found in {directory}{RESET}\n")
        return

    matrix, vocab, paths = build_index(notes)

    # Rebuild df for query vectorization
    df = defaultdict(int)
    for tokens in [tokenize(notes[p]) for p in paths]:
        for t in set(tokens):
            df[t] += 1

    q_vec = vectorize_query(query, vocab, len(paths), df)
    if not q_vec:
        print(f"  {MUTED}Query terms not found in index. Try different words.{RESET}\n")
        return

    scores = [(cosine_similarity(q_vec, matrix[i]), paths[i]) for i in range(len(paths))]
    scores = [(s, p) for s, p in scores if s > 0]
    scores.sort(key=lambda x: x[0], reverse=True)

    elapsed = (time.time() - t0) * 1000
    q_tokens = tokenize(query)

    print(f"  {DIM}query:{RESET} {WHITE}{query}{RESET}")
    print(f"  {DIM}indexed {len(notes)} notes · {len(vocab)} terms · {elapsed:.0f}ms{RESET}\n")

    if not scores:
        print(f"  {MUTED}No relevant notes found.{RESET}\n")
        return

    for rank, (score, path) in enumerate(scores[:top_k], 1):
        snippet = get_snippet(notes[path], q_tokens)
        _print_result(rank, path, score, snippet)

    print(f"{RULE}{'─' * 56}{RESET}\n")


def save_index(directory, out_path=None):
    """Pre-build and cache the index as JSON for faster repeated searches."""
    notes = read_markdown_files(directory)
    matrix, vocab, paths = build_index(notes)
    out = out_path or os.path.join(directory, '.orbioom-index.json')
    data = {'paths': paths, 'vocab': vocab, 'matrix': [dict(v) for v in matrix]}
    # Convert int keys back to strings for JSON
    data['matrix'] = [{str(k): v for k, v in vec.items()} for vec in matrix]
    with open(out, 'w') as f:
        json.dump(data, f)
    print(f"  {GREEN}✓{RESET} Index saved to {out} ({len(paths)} notes, {len(vocab)} terms)\n")


def main():
    parser = argparse.ArgumentParser(
        description='Search your Markdown notes by meaning.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Examples:\n  python search.py 'spaced repetition memory'\n  python search.py 'writing clarity' --dir ~/notes --top 8"
    )
    parser.add_argument('query', nargs='?', help='Your search query')
    parser.add_argument('--dir', default='./notes', help='Notes directory (default: ./notes)')
    parser.add_argument('--top', type=int, default=5, help='Number of results (default: 5)')
    parser.add_argument('--index', action='store_true', help='Pre-build and save index to .orbioom-index.json')
    args = parser.parse_args()

    _print_header()

    if args.index:
        save_index(args.dir)
        return

    if not args.query:
        parser.print_help()
        print()
        return

    if not os.path.isdir(args.dir):
        print(f"  {MUTED}Directory not found: {args.dir}{RESET}")
        print(f"  {DIM}Create a 'notes/' folder with .md files, or use --dir to point elsewhere.{RESET}\n")
        return

    search(args.query, args.dir, args.top)


if __name__ == '__main__':
    main()
