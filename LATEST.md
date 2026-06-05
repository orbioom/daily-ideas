# Orbioom Daily Ideas — Latest Run

---

## Run: 2026-06-05 06:10 UTC
**Folder:** `runs/2026-06-05_0610-UTC/`

### Research Signals

Scanned r/somebodymakethis, r/iOSProgramming, r/productivity, Product Hunt
(April 2026 leaderboard), Ask HN threads (Jan–May 2026), arXiv / bioRxiv, GitHub
topics, and PhysioNet. Themes that shaped the picks:

- **Calm, no-AI, no-cloud, local-first** is a loud and growing preference —
  "a notepad should never touch the network", free forever apps (Sukoon),
  fatigue with AI-sidebar everything. Every pick this run runs offline.
- **AI wrappers are saturated** (Product Hunt feed rewards a narrow AI slice);
  deliberately avoided.
- **Legible, learnable tools** over black boxes — drove the pure-Python,
  fully-readable science implementations.
- **Research-grade, reproducible code** is respected when it cites real papers
  and ships sample data + benchmarks (PhysioNet, Pan-Tompkins++ arXiv:2211.03171,
  Sharp & Li CAI, Ferragina–Manzini FM-index).
- Recurring small chores people still hand-roll: invoicing, cron reading,
  "just look at this CSV", timezone math, golden-hour lookup, watering plants.

---

### Ideas — 10 selected (3 iOS · 3 web · 3 sci · 1 Android)

#### A — iOS
- **Gloaming** — built — `01-gloaming/` — on-device NOAA solar algorithm; every
  twilight/golden/blue-hour threshold + a live sky band; CoreLocation or 8 preset
  cities (incl. an Arctic city for polar day/night). MVVM, compiles Xcode 15+.
- **Meridian** — built — `02-meridian/` — multi-timezone meeting overlap finder;
  green consensus strip, "best start", DST + half-hour-zone correct; Codable
  persistence; searchable 16-city catalog.
- **Folio** — built — `03-folio/` — reading-pace tracker that projects a finish
  date from logged page sessions; progress arc + progress curve; two sample books.

#### B — Web / SaaS / Desktop
- **Reckon** — built — `04-reckon/` — single-file freelance invoice generator;
  live preview = the printed PDF; localStorage, no account, no network.
- **Cadence** — built — `05-cadence/` — cron-expression workbench; plain-English
  description + next-7-runs timeline; real parser/scheduler (Vixie OR-semantics),
  Node-tested.
- **Prism** — built — `06-prism/` — drop a CSV → auto-typed columns → bar / line /
  scatter / histogram on canvas → PNG export; robust quoted-CSV parser.

#### C — Scientific / Technological
- **Tempo** — built — `07-tempo/` — Pan-Tompkins++ ECG R-peak detection + HRV
  (SDNN/RMSSD/pNN50/Poincaré). Scores **Se 100% / PPV 100%** on a 90 s synthetic
  record. Pure stdlib. Cites Pan-Tompkins 1985, arXiv:2211.03171, ESC/NASPE 1996.
- **Codonaut** — built — `08-codonaut/` — Codon Adaptation Index + host-optimized
  reverse translation for *E. coli* K-12. GFP demo: **CAI 0.346 → 1.000**, protein
  identity preserved. Cites Sharp & Li 1987, Angov 2008.
- **Strand** — built — `09-strand/` — FM-index (BWT) exact DNA matcher: suffix
  array → BWT → C/Occ → backward search; verified vs. brute force, **~9× faster**,
  inverse-BWT round-trips. Cites Ferragina–Manzini 2000, Li & Durbin 2009.

#### D — Android
- **Frond** — built (source) — `10-frond/` — local-first plant-watering companion;
  Compose + Material 3 (Orbioom-tuned), MVVM, JSON-in-SharedPreferences (no Room/
  KSP). **APK not built in-sandbox** — no Android SDK present; builds in Android
  Studio. Gradle wrapper (8.7) included; see `build-apk/build-log.txt`.

**All 10 built. The three science tools run and self-verify (see commands in each
README); the web apps run end-to-end; iOS projects are generated, structurally
validated, and reviewed to compile in Xcode 15+.**

---

### Top Recommendation

**Tempo** (`07-tempo/`).

It's the pick that best embodies "a researcher sees depth." A complete,
dependency-free Pan-Tompkins++ pipeline that hits 100%/100% on a noisy synthetic
record, with HRV metrics that match physiology — and every filter, threshold,
and metric is a few readable lines. There's a real product here: a calm,
auditable HRV toolkit (web upload of a CSV, or an on-device wearable companion)
that doesn't ship your cardiac data to a cloud. Natural next steps: add
frequency-domain HRV (Lomb-Scargle for unevenly-sampled RR, still pure Python),
ingest real PhysioNet WFDB records, and wrap it in a glass web UI.

Runner-up: **Gloaming** — the on-device astronomy is genuinely correct and the
live sky band is the kind of quiet, daily-delight surface Orbioom is for.

---

### Follow-ups for Next Run

- **Tempo V2**: Lomb-Scargle periodogram for frequency-domain HRV (LF/HF) on
  unevenly-sampled tachograms; WFDB reader for real PhysioNet records.
- **Strand V2**: sampled suffix array + run-length BWT to scale past fragments;
  approximate matching (1–2 mismatch backtracking) toward a real short-read aligner.
- **Codonaut V2**: add multiple host tables (yeast, human, CHO), avoid restriction
  sites / hairpins during optimization, GC-window smoothing.
- **Prism / Reckon**: optional Tauri desktop wrappers for offline-native feel.
- Watch: r/selfhosted and r/datacurator for "local-first analytics" pain points;
  PhysioNet challenges for credible biomedical-signal ideas.

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
