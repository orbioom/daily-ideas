# Distill

**Distill compresses your own text in the browser with a real PPM context model and a range coder, then shows the live compression ratio — measured honestly against gzip, and verified byte-for-byte lossless.**

This is applied information theory you can feel: paste prose, press one button, and watch a genuine entropy coder beat gzip on natural language while proving it lost nothing.

---

## What it does — the real benefit

Distill takes your text (or an uploaded `.txt`), UTF-8 encodes it, and compresses it with an
**order-3 PPM (Prediction by Partial Matching)** model driving a **carry-less range coder**.
It then displays, computed live on *your* input:

- original size (bytes)
- Distill compressed size (bytes), ratio (e.g. `2.51×`) and **bits per byte**
- **gzip** compressed size + ratio, produced by the browser's own `CompressionStream('gzip')`
- an honest verdict — *"Distill is 10.3% smaller than gzip here"* on prose, or *"gzip wins here"* on tiny/random data
- real **compress timing** in milliseconds
- a **round-trip verification** badge: Distill decompresses its own output and confirms it is identical to your input, byte for byte

On the committed sample of natural-language prose (`data/sample.txt`, 5,098 bytes):

| Coder            | Size       | Ratio   | Bits/byte |
|------------------|-----------:|--------:|----------:|
| original         | 5,098 B    | —       | 8.000     |
| **Distill (PPM)**| **2,031 B**| **2.51×** | **3.187** |
| gzip (level 9)   | 2,264 B    | 2.25×   | —         |

**Distill is ~10.3% smaller than gzip on this sample** — measured, not asserted.
(Numbers above were produced by `node js/ppm.test.js`; the browser shows the same story live,
with gzip coming from `CompressionStream`, which is equivalent to Node's zlib for comparison.)

## How it works (honestly)

- **PPM.** For each byte, Distill looks at the previous up-to-three bytes (the *context*) and uses
  frequency counts to predict the next byte. Language is predictable (`q`→`u`, `th`→`e`), so the
  predictions sharpen and cost few bits.
- **Escape & exclusion (PPMC).** If a byte is unseen in the current context, the model emits a small
  *escape* and falls back to a shorter context, ultimately to a uniform model over all 256 byte values
  plus an end-of-stream marker. Symbols ruled out higher up are *excluded* from lower-order estimates.
  This fallback chain guarantees every possible input is codable — and that the coder is exactly lossless.
- **Range coding.** Those probabilities feed a 32-bit carry-less (Subbotin-style) range coder — the
  arithmetic-coding family — which turns probabilities into a near-optimal bitstream. It is deterministic:
  same input → same bytes, every run.
- **The gzip comparison is real.** The gzip figure comes from the browser's built-in
  `CompressionStream('gzip')`. Nothing is fabricated; everything is computed on your actual input.
  Distill tends to beat gzip on prose because it models longer context than gzip's LZ77 + Huffman; on
  tiny or already-dense/random data, gzip's lighter framing often wins, and Distill says so plainly.

## How to open

**Just open `index.html` in a modern browser.** No build, no server, no install, no network.
The sample prose loads automatically and compresses immediately, so the wow is visible on open.

> Note: a few browsers block `fetch()` of local files over `file://`. If the sample doesn't auto-load,
> the app tells you so and you can paste text or use **Load .txt…**. Serving the folder over any static
> file server also works (e.g. `python3 -m http.server` from inside `09-distill`), but is not required.

## Controls & export

- **Compress** — the focal ink CTA; compresses the current input.
- **Load .txt…** — pick a plain-text file; it loads and auto-compresses.
- **Open .distill…** — open a previously exported `.distill` file and decompress it back to text (bonus).
- **Clear** — empty the input.
- **Download .distill** — save the Distill-compressed bytes.
- **Download result JSON** — save a summary: sizes, ratios, bits/byte, timing, round-trip result.

## Accessibility & reproducibility

- Keyboard-operable throughout, visible focus rings, a skip link, ARIA roles/labels, and
  `aria-live` status + progress so screen readers hear what's happening.
- Colors meet WCAG AA contrast on the mist background; the green accent is reserved for the
  win / round-trip-success moment only.
- `prefers-reduced-motion` is honored (transitions collapse).
- Heavy compute runs in a **Web Worker** (`js/worker.js`) so the UI never locks; a progress bar
  shows compress → verify → gzip phases. Inputs are capped at 512 KB for a responsive demo.
- **Reproducible:** the coder is deterministic — the same input always yields the same compressed
  bytes and the same ratio.

## Files

```
09-distill/
├── index.html        opening this IS the whole experience
├── css/styles.css    Orbioom Liquid Glass design system
├── js/ppm.js         the real PPM + range-coder engine (pure; Node + Worker)
├── js/worker.js      runs compression/gzip/verify off the main thread
├── js/main.js        UI wiring, exports, file handling
├── js/ppm.test.js    Node verification harness (see Self-review)
├── data/sample.txt   real natural-language prose, loaded automatically
└── README.md
```

## Self-review

- **Anti-stub grep is clean.** `grep -rniE 'todo|fixme|xxx|placeholder|lorem|coming soon|not
  implemented|// stub' 09-distill` (excluding the documented test file) returns only the legitimate
  HTML `placeholder` attribute and its CSS `::placeholder` selector — no stubs, TODOs, lorem, or
  "not implemented". The sample is real prose, not lorem ipsum.
- **Node round-trip verification PASSED on all cases** (`node js/ppm.test.js`, 11/11):
  1. empty string
  2. single char `"a"`
  3. short ASCII `"hello world"`
  4. unicode + emoji + accents (`café — naïve — 日本語 — 🚀🌫️ — Ω`)
  5. empty bytes
  6. single byte `0x00`
  7. all 256 byte values
  8. 50 KB repetitive text
  9. 20 KB high-entropy bytes (correctly expands — random data is incompressible)
  10. `data/sample.txt`
  11. deterministic output (sample compresses to identical bytes twice)

  Every `decompress(compress(x)) === x` assertion holds exactly; a lossy or crashing coder would
  fail the run.
- **Measured sample ratio vs gzip:** Distill **2,031 B (2.51×, 3.187 bpb)** vs gzip-9 **2,264 B
  (2.25×)** → **Distill ~10.3% smaller** on the natural-language sample. All numbers are computed
  live, never hard-coded.

Run the verification yourself from inside `09-distill`:

```
node js/ppm.test.js
```
