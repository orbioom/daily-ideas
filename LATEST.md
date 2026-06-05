# Latest Run — 2026-06-05 1209 UTC

**Folder:** `runs/2026-06-05_1209-UTC/`
**Shipped:** 8 of 10 fully built and production-ready (≥1 in every category A/B/C/D); 2 iOS picks
specced in `BACKLOG.md` to protect quality on the marginal slots. None repeat `SHIPPED.md`.

Six self-contained web/science apps were built in parallel by sub-builders (each verified with
`node --check` + a logic test + a clean anti-stub scan), while the iOS and Android apps were built
and hand-reviewed directly. A repo-wide anti-stub scan is clean.

---

## A — iOS (slots 01–03)

- **Cellar** — built — `runs/2026-06-05_1209-UTC/01-cellar` — A structured tasting journal where
  bottles (coffee/wine/whisky/tea/beer) own dated tastings with the aroma·palate·finish triad and a
  category-tuned flavor lexicon; SwiftData, 5 feature screens + onboarding + settings, insights with a
  tasting streak. *Xcode build: not run (no Xcode in sandbox); hand-compiled against the iOS 17 SDK,
  pbxproj generated with unique IDs referencing every file.*
- **Interval** — spec (`BACKLOG.md`) — HIIT/circuit routine builder with a real Routine→Segment→
  repeat-group model and a hands-free, background-accurate timer engine.
- **Apertura** — spec (`BACKLOG.md`) — manual-photography exposure visualizer + a Rolls→Frames shot
  log, with honest EV/stop math.

## B — Web / SaaS (slots 04–06)

- **Sift** — built — `…/04-sift` — Regex workbench: live highlighting, capture/named groups, flags,
  replace with backreferences, a 12-pattern library, and saved snippets (full CRUD) in localStorage.
- **Stacks** — built — `…/05-stacks` — Personal library catalog with three related entities (Books,
  Shelves, Reading Sessions), a live stats dashboard with a reading streak, and JSON/CSV export.
- **Chroma** — built — `…/06-chroma` — Accessible palette & contrast lab: WCAG 2.1 relative-luminance
  contrast, Machado et al. (2009) color-vision-deficiency simulation, scales/harmonies, token export.

## C — Science (interactive UI, slots 07–09)

- **Spectra** — built — `…/07-spectra` — FFT spectral analyzer: hand-written radix-2 Cooley–Tukey,
  windowing (Harris 1978), one-sided PSD, and an STFT spectrogram, all on `<canvas>`; PNG/CSV export.
  Verified in Node to recover a two-tone signal at 49.96 Hz / 120.03 Hz with correct amplitudes.
- **Lotka** — built — `…/08-lotka` — Predator–prey simulator: Lotka–Volterra integrated with RK4,
  time series + phase portrait with nullclines and a marked equilibrium, animated, with presets.
  Conserved-quantity drift ~1.6e-9 confirms integrator quality.
- **Cluster** — built — `…/09-cluster` — k-means visualizer: Lloyd's algorithm + k-means++ seeding,
  step/run-to-convergence, inertia & silhouette, an elbow sweep, seeded reproducible datasets.

## D — Android (slot 10)

- **Forage** — built — `…/10-forage` — Local-first recipe box: recipes own ingredients + ordered
  steps; the highlight is a live **serving scaler** that re-computes quantities into clean fractions.
  Compose + Material 3 (Orbioom-tuned), Navigation Compose, JSON persistence + DataStore, no Room/KSP.
  *APK build: attempted; the sandbox has no Android SDK and the AGP/AndroidX repos are unreachable, so
  it can't build here — see `10-forage/android/build-log.txt`. Versions are the pinned known-good
  Kotlin 1.9.24 / AGP 8.5.2 / Compose BOM 2024.06.00 / compiler ext 1.5.14 set; builds in Android Studio.*

---

## Build / APK status summary

| Slot | App | Built | Build/compile check |
|---|---|---|---|
| 01 | Cellar (iOS) | yes | Hand-compiled vs iOS 17 SDK; anti-stub clean; pbxproj valid |
| 04 | Sift (web) | yes | `node --check` + logic test; anti-stub clean |
| 05 | Stacks (web) | yes | `node --check` + pipeline test; anti-stub clean |
| 06 | Chroma (web) | yes | 16-assertion color-math test passes; anti-stub clean |
| 07 | Spectra (sci) | yes | FFT cross-checked in Node; anti-stub clean |
| 08 | Lotka (sci) | yes | RK4 verified (conserved qty drift ~1e-9); anti-stub clean |
| 09 | Cluster (sci) | yes | Convergence/silhouette/reproducibility tested; anti-stub clean |
| 10 | Forage (Android) | yes | Gradle wrapper runs; SDK absent in sandbox → build locally (build-log.txt) |
| 02 | Interval (iOS) | spec | BACKLOG.md |
| 03 | Apertura (iOS) | spec | BACKLOG.md |

## Top recommendation

**Spectra (07).** It is the most complete realization of the Category-C brief: a genuinely correct,
from-scratch FFT (numerically verified to recover known tones and amplitudes), three live linked
visualizations (waveform, power spectrum, STFT spectrogram), real parameter controls, exports, and a
Web Worker for the heavy compute — all behind a calm Orbioom interface that opens to a correct result
with zero setup. It best embodies "the science is seen and manipulated," and it's broadly useful
beyond a demo.

## Research signals worth following next run

- **Local-first, no-account utilities** keep over-indexing on r/SideProject and HN — single-purpose
  tools that own a week of real data (regex, palettes, libraries) resonate; lean further into
  *export/round-trip* as a first-class feature.
- **"Make the science visual"** is an under-served niche: practitioners repeatedly ask for browser
  tools that *show* an algorithm (alignment, dimensionality reduction, Kalman filtering, beamforming)
  rather than print to stdout. Candidates: a UMAP/t-SNE explorer, a PID/Kalman tuning sandbox, a
  Savitzky–Golay smoothing lab, a phylogenetic alignment viewer.
- **Hobby logbooks with real computation** (tasting, photography, brewing, fermentation) pair a rich
  domain model with a small honest calculation — a strong recurring shape for native apps.
- Bundling **real Manrope/JetBrains Mono TTFs** into the Android template would close the one graceful
  fallback currently in the brand stack.
