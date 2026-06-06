# Limpid

**A calm writing clarity workbench.** Write or paste prose and Limpid scores and
X-rays it as you type — readability metrics, sentence-level difficulty, and
concrete spans to fix. It works like a local, private, no-account writing coach:
everything runs in your browser, nothing leaves your device.

> The hook: a calm editor that scores and X-rays your prose as you type, with
> concrete spans to fix — like a local, private, no-account writing coach.

---

## What it is

Limpid is a small multi-document prose editor with a real readability engine.
As you type (debounced), it computes six readability scores, breaks your writing
down sentence by sentence, and paints inline highlights over the exact spans that
hurt clarity — long sentences, passive voice, adverbs, filler/weasel words, and
complex (3+ syllable) words. A stats panel shows counts, sentence-length
distribution, reading time, the longest sentence, and a ranked list of your
hardest-to-read sentences.

It is built for calm focus: a mist background, Liquid Glass panels, comfortable
line length and line-height, and a single ink call-to-action. Highlights are
always coded by **color + underline + a text-labeled legend with counts**, never
by color alone.

## Features

- **Six readability scores**, computed correctly from your text:
  Flesch Reading Ease, Flesch–Kincaid Grade Level, Gunning Fog, SMOG,
  Automated Readability Index, Coleman–Liau. A real heuristic syllable counter
  and sentence/word tokenizers power them.
- **Inline highlights** (overlay-highlight technique — a transparent textarea
  over a rendered highlight layer, so highlights line up exactly and editing
  stays smooth):
  - Very long sentences (configurable word threshold)
  - Passive voice (be-verb + past participle, with an irregular-participle list)
  - Adverbs (-ly heuristic with a stoplist for false positives like *only*)
  - Filler / weasel words (curated list + multi-word phrases like *in order to*)
  - Complex words (3+ syllables)
  - Each category is **toggleable** with a legend, swatch, label, and live count.
- **Stats panel**: word / sentence / paragraph counts, average sentence length,
  sentence-length variance, a small histogram of sentence lengths, reading time,
  the longest sentence, and the hardest sentences ranked by grade level.
- **Per-sentence readability**: hover or focus a ranked sentence to see its grade
  and ease; click to jump to and select it in the editor.
- **Documents**: create, rename, delete, and switch between documents; each is
  persisted in `localStorage`.
- **Goal setting**: choose a target reading grade; a calm green indicator appears
  when your Flesch–Kincaid grade is at or under it.
- **Export**: current document as `.txt` or `.md`, and the full analysis as
  `.json`. Plus copy-to-clipboard. (`Ctrl`/`Cmd`+`S` exports `.txt`.)
- **Load sample** and **Clear**, with a designed empty state.
- **Settings (persisted)**: long-sentence word threshold, which highlight
  categories are on by default, target reading grade, and a light/dark theme
  toggle — each actually changes behavior.

## Run

No build, server, accounts, or keys. Just open the file:

```
open index.html      # macOS
# or double-click index.html in your file manager
```

It runs fully offline as a static page. On first open it seeds three sample
documents of varying clarity so you can see analysis immediately.

## Data & privacy

- **Local only.** Documents and settings live in your browser's `localStorage`.
  Nothing is sent anywhere — there is no network code and no account.
- **Export** any document (`.txt` / `.md`) and its analysis (`.json`) at any time.
- **Reset** wipes all stored documents and settings and reloads the samples
  (Reset all → confirm). If `localStorage` is unavailable, Limpid falls back to
  in-memory storage for the session so it never crashes.

## Tech & accessibility

- **Static** HTML / CSS / JS. Files:
  - `index.html` — markup and panels
  - `styles.css` — Orbioom design system, light + dark themes
  - `app.js` — editor, overlay highlights, document CRUD, settings, export, modals
  - `analysis.js` — **pure** text-analysis engine (tokenizers, syllables, all six
    formulas, span detectors). Node-loadable via a `module.exports` guard.
  - `storage.js` — `localStorage` wrapper for documents + settings (safe fallback)
  - `seed.js` — three realistic sample documents
  - `analysis.test.js` — documented Node verification harness (not shipped to the
    browser)
- **Readability formulas used:**
  - Flesch Reading Ease: `206.835 − 1.015·(words/sentences) − 84.6·(syllables/words)`
  - Flesch–Kincaid Grade: `0.39·(words/sentences) + 11.8·(syllables/words) − 15.59`
  - Gunning Fog: `0.4·((words/sentences) + 100·(complex/words))`
  - SMOG: `1.0430·√(polysyllables·30/sentences) + 3.1291`
  - Automated Readability Index: `4.71·(chars/words) + 0.5·(words/sentences) − 21.43`
  - Coleman–Liau: `0.0588·L − 0.296·S − 15.8` (L,S per 100 words)
  - Degenerate input (0 words / 0 sentences) yields `null`, shown as `—` (no
    divide-by-zero).
- **Accessibility:** semantic landmarks, `aria-live="polite"` for score/stat
  updates (debounced, not spammy), focus-visible outlines, modals trap focus and
  close on `Esc`, color contrast ≥ 4.5:1, touch targets ≥ 44px, responsive from
  360px to desktop, and `prefers-reduced-motion` honored (no animated highlight
  pulsing). Highlights never rely on color alone.
- **Design:** Orbioom — mist background (never pure white), Liquid Glass panels
  (`backdrop-filter: blur(22px) saturate(180%)`), one focal ink CTA, Manrope UI
  with JetBrains Mono for numbers, restrained green only for "clear/good" states,
  slow `cubic-bezier(0.16, 1, 0.3, 1)` easing.

## Self-review

- **Clean anti-stub grep.** Running
  `grep -rniE 'todo|fixme|xxx|placeholder|lorem|coming soon|not implemented|// stub' .`
  over the shipped files returns no matches. (The documented `analysis.test.js`
  is the only test file and contains no stub markers either.)
- **Node verification of the analysis engine** (`node analysis.test.js`, all
  checks pass). Cited computed scores:
  - *"The cat sat on the mat. The dog ran fast. We had fun."* →
    **Flesch Reading Ease ≈ 117.8** (very easy), **FK grade ≈ −2.1**.
  - A dense policy sentence
    (*"…necessitates a comprehensive reconceptualization of fundamental
    methodological presuppositions."*) →
    **Flesch Reading Ease ≈ −143.7**, **FK grade ≈ 36.3** — correctly far harder.
  - Reference line *"The quick brown fox jumps over the lazy dog."* →
    **Flesch Reading Ease ≈ 94.3**, in the expected easy band.
  - Syllable counter hand-verified: `syllable`=3, `queue`=1, `create`=2,
    `table`=2, `people`=2, `reality`=4, `university`=5.
  - Detectors verified on crafted input: passive → *"was written"*, *"was
    opened"*; adverbs → *quickly / carefully / barely* (excludes *only*);
    filler → *very / really / just / basically / in order to*; complex →
    *extraordinary / committee / deliberated*.
- **Highlights align.** Detectors return character offsets into the original
  text; the test asserts `text.slice(span.start, span.end) === span.text`, and the
  overlay highlight layer shares the textarea's exact font, size, line-height,
  padding, and wrapping so painted spans line up with the typed characters.
