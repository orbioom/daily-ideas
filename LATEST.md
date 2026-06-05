# Orbioom Daily Ideas — Latest Run

---

## Run: 2026-06-05 02:52 UTC
**Folder:** `runs/2026-06-05_0252-UTC/`

### Research Signals

Scanned Product Hunt (April 2026 leaderboard), HN "Show HN" threads, GitHub trending, arXiv, Reddit
discussions. Key observations:

- **Second-brain saturation**: every product is "AI for your notes." Gap is in non-AI, non-cloud, considered tools.
- **Local-first resurgence**: Obsidian-style local Markdown is thriving; people want data they own.
- **Breath / attention tools**: clearspace, Unpluq, voice-first writing (Wispr Flow) signal anxiety about digital overload.
- **Single-codebase understanding** (nanochat: 54k stars): people crave tools that are legible and learnable, not black boxes.
- **Canvas thinking**: spatial note tools (Heptabase, Arky) show demand for non-linear knowledge work.
- **Terminal culture moment**: lazygit, Ghostty, Neovim agents are thriving — developers want calm terminal tools.

---

### Ideas — 9 selected

| # | Title | Status | Folder | What's interesting |
|---|-------|--------|--------|-------------------|
| 01 | **Decay Notes** | **built** | `01-decay-notes/` | Notes that literally fade over time — opacity decreases as days pass; refresh what matters, let the rest go |
| 02 | **Breath Writer** | **built** | `02-breath-writer/` | Writing environment synced to a breathing guide; glass panel glows on exhale; five breathing patterns |
| 03 | **Quiet Counter** | **built** | `03-quiet-counter/` | Track exactly one metric per day — big beautiful number + 30-day heatmap in live green |
| 04 | **Etymology Trail** | **built** | `04-etymology-trail/` | Animated word etymology timeline; 15 words traced back through Latin, Greek, Arabic, Sanskrit |
| 05 | **Sentence Observatory** | **built** | `05-sentence-observatory/` | Paste text, each sentence becomes a star — size = length, color = type; hover to read; dark observatory stage |
| 06 | **Diffusion Canvas** | **built** | `06-diffusion-canvas/` | Real-time Gray-Scott reaction-diffusion in-browser; six named presets; click to seed; save PNG |
| 07 | **Local Vector Search** | **built** | `07-local-vector-search/` | Python stdlib TF-IDF search for Markdown notes — no API keys, no cloud, no packages; tested working |
| 08 | **Polyphonic Text** | **built** | `08-polyphonic-text/` | Prose rendered as a musical score — each word is a note; pitch = word length; plays via Web Audio API |
| 09 | **Lexical Distance Map** | **built** | `09-lexical-distance-map/` | 38 world languages force-positioned by linguistic family; hover for speaker count and notes; draggable |

**All 9 built and working.** No stubs.

---

### Top Recommendation

**Decay Notes** (`01-decay-notes/`).

It's the most behaviorally interesting of the batch. The core mechanic — notes that literally age
and become transparent — is a fundamentally different relationship with writing than any existing
tool offers. It externalizes how real memory works without quizzes or scores: you see what you've
tended and what you've abandoned. The "refresh" gesture (resetting a note's timestamp because you
still care about it) is a new kind of interaction. The vitality bar using live green is restrained
and beautiful.

With a small SQLite backend and a native macOS app, this could be a quiet landmark product.

Runner-up: **Diffusion Canvas** — the science is genuinely interesting and the visual output is
extraordinary. The Gray-Scott simulation produces patterns indistinguishable from biology. Worth
developing into a proper generative art tool with WebGL at 1024×1024 resolution.

---

### Follow-up for Next Run

- **Lexical Distance Map V2**: load real ASJP pairwise distance matrix; use t-SNE to compute
  positions automatically rather than hand-placing. Add historical timeline animation.
- **Decay Notes mobile**: explore the mechanic on iOS with haptic feedback on refresh.
- **Polyphonic Text + real pitch mapping**: map average word complexity to musical scale (diatonic
  or pentatonic) so the audio output sounds intentionally musical, not just parametric.
- **Local Vector Search V2**: add `sentence-transformers` (small ONNX model) for true semantic
  similarity; add `rich` TUI for interactive browsing.
- Watch: `r/somebodymakethis` and `r/InternetIsBeautiful` for specific pain points around
  personal knowledge management and calm software.
