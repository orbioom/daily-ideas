# Local Vector Search

Search your Markdown notes by meaning — entirely offline, no API keys, no cloud, no external packages.

## The Idea

Most note-search is keyword search: it finds files containing the exact words you type. This tool
uses TF-IDF vector similarity to find notes that are *about the same thing* as your query, even if
they use different words.

"memory decay review" finds your spaced repetition notes.  
"focus interruption cognitive" finds your attention notes.  
"prose revision style" finds your writing notes.

All computed locally in Python stdlib, in milliseconds, over a folder of .md files.

## How to Run

**Requirements:** Python 3.8+, no packages needed.

```bash
# Search your notes folder
python search.py "spaced repetition memory" --dir ./demo_notes

# Show top 8 results
python search.py "creativity constraints play" --dir ./demo_notes --top 8

# Pre-build and cache the index for faster repeated searches
python search.py --index --dir ./demo_notes
```

A demo `notes/` folder is included with 5 sample notes.

## Algorithm

1. **Tokenize**: strip Markdown syntax, lowercase, remove stop words
2. **TF-IDF**: term frequency × inverse document frequency for each term in each note
3. **Cosine similarity**: dot product of query vector and each note vector, normalized by magnitude
4. **Snippet extraction**: find the paragraph in the top result most relevant to query tokens

Deliberately simple. No ML models, no embeddings. Pure math on term frequencies.
Accurate enough for personal note collections of thousands of files.

## Architecture for V2

To improve semantic understanding without an internet connection:
- Use `sentence-transformers` with a small ONNX model (e.g. all-MiniLM-L6-v2, 22MB)
- Build FAISS or sqlite-vec index for nearest-neighbor search
- Cache embeddings to avoid recomputing unchanged files
- Add a TUI built with `rich` or `textual` for interactive search

## Orbioom Feeling

CLI output uses ANSI color in the Orbioom palette: dim rule lines, live green (#86C79A approximate)
for scores and success states, white for result paths, muted gray for snippets. No ASCII art banners.
Calm, precise, monospace. The tool disappears; only your notes remain.
