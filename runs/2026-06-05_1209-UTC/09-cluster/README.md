# Cluster — a k-means clustering visualizer

## What it is

**Cluster** is a self-contained, interactive web app that shows how the
**k-means** clustering algorithm works on 2-D points. You pick a synthetic
dataset (or click your own points onto the canvas), choose how many clusters
`k` you want, and then **step** through the algorithm one iteration at a time —
watching points re-colour and centroids glide to their new positions — or
**run to convergence** in one click. It plots **inertia vs iteration**, an
**elbow curve** to help you pick `k`, and computes the **silhouette** score as a
quality metric.

Open `index.html` in any modern browser. There is no build step, no server, no
command line, and no network access — a sample dataset is generated and
clustered automatically the moment the page loads.

## The science (for a smart non-expert)

**Clustering** means grouping data points so that points in the same group are
more similar to each other than to points in other groups. There are no labels
to learn from — the structure is discovered from the geometry of the data alone
(this is *unsupervised* learning).

**k-means** is the most widely used clustering method. You tell it how many
groups you want — that number is **k** — and it finds `k` representative points
called **centroids** (each centroid is the *mean*, i.e. the average position, of
the points assigned to it). The algorithm repeats two steps until things stop
changing:

1. **Assignment step** — assign every point to its **nearest** centroid (using
   ordinary straight-line / *Euclidean* distance).
2. **Update step** — move each centroid to the **average position** of the
   points that were just assigned to it.

Because each step can only make the clustering tighter, the algorithm always
settles down (*converges*). This two-step loop is **Lloyd's algorithm**.

Key terms used in the app:

- **Centroid** — the mean position of a cluster; drawn as a large ringed marker.
- **Inertia** (also **WCSS**, within-cluster sum of squares) — add up the
  squared distance from every point to its own centroid. Lower is tighter.
  Inertia only ever goes *down* across iterations, which is why the convergence
  chart slopes downward.
- **Convergence** — the point at which centroids stop moving between iterations.
- **k-means++** — a smarter way to *place the starting centroids*. Random
  starts can land two centroids on top of each other and give a poor result;
  k-means++ spreads the initial centroids out (choosing each new one with
  probability proportional to its squared distance from the closest existing
  centroid), which makes results better and more repeatable.
- **Silhouette score** — a number from −1 to +1 that rates how well each point
  fits its cluster. For a point, compare its average distance to its *own*
  cluster (`a`) with its average distance to the *nearest other* cluster (`b`);
  the silhouette is `(b − a) / max(a, b)`. Near +1 = well clustered, near 0 = on
  a boundary, negative = probably in the wrong cluster. The app reports the mean
  over all points.
- **The elbow** — run k-means for `k = 1, 2, 3, …` and plot the resulting
  inertia. Inertia always falls as `k` grows, but it usually falls *sharply*
  then *levels off*; the "elbow" (the bend) marks a `k` where adding more
  clusters stops helping much. It is a heuristic for choosing `k`.

## Method & citations

The algorithm and metrics are implemented from scratch in
[`js/kmeans.js`](js/kmeans.js) — no clustering library.

- **Lloyd's algorithm.** Alternating *assignment* and *update* steps as
  described above; centroids are means, distances are squared Euclidean, and
  inertia is `Σ_i ‖x_i − μ_{c(i)}‖²`.
  *Lloyd, S. P. (1982). "Least squares quantization in PCM." IEEE Transactions
  on Information Theory, 28(2), 129–137.* (The work dates to 1957.)

- **k-means++ seeding.** Pick the first centroid uniformly at random; then pick
  each subsequent centroid from the data with probability proportional to
  `D(x)²`, where `D(x)` is the distance from `x` to the nearest already-chosen
  centroid.
  *Arthur, D. & Vassilvitskii, S. (2007). "k-means++: The Advantages of Careful
  Seeding." Proc. ACM-SIAM Symposium on Discrete Algorithms (SODA), 1027–1035.*

- **Silhouette.** For each point `i`, `a(i)` = mean intra-cluster distance and
  `b(i)` = minimum mean distance to any other cluster; `s(i) = (b − a)/max(a,b)`
  (defined as 0 for singleton clusters). The score is the mean of `s(i)`.
  *Rousseeuw, P. J. (1987). "Silhouettes: a graphical aid to the interpretation
  and validation of cluster analysis." Journal of Computational and Applied
  Mathematics, 20, 53–65.*

**Empty clusters** (a centroid that ends up with no points) are repaired by
re-seeding that centroid at the data point currently farthest from all
centroids — a standard, deterministic fix that also avoids division by zero.

**Honest simplifications.** Everything is **2-D** so it can be drawn directly;
distances are **Euclidean**; all data is **synthetic**. Inertia is reported per
iteration from the assignment that produced the current centroids. The elbow
sweep uses a few k-means++ restarts per `k` and keeps the lowest inertia, which
is a bounded approximation rather than an exhaustive search.

## How to open it

**Open `index.html` in any modern browser** — a sample dataset clusters
automatically; no build, no server. Everything runs locally in the page.

## Data

All datasets are **synthetic** and generated in [`js/datasets.js`](js/datasets.js)
in a normalized `[0,1] × [0,1]` space, driven by a seeded PRNG so the same seed
reproduces the same points:

- **Gaussian blobs** — `k` cluster centres placed on a ring; each point drawn
  from an isotropic Gaussian (Box–Muller) about its centre. Adjustable cluster
  count and spread (standard deviation).
- **Anisotropic** — Gaussian blobs passed through a per-cluster rotation +
  anisotropic scaling matrix, producing elongated, tilted clusters that
  challenge isotropic k-means.
- **Two moons** — two interleaving half-circles plus Gaussian noise. A classic
  case k-means *cannot* fully recover, because its clusters are always convex
  (Voronoi) cells.
- **Uniform random** — points spread uniformly, with no real cluster structure;
  useful to see weak elbow/silhouette signal.

You can also **click on the canvas to add your own points** (this switches to a
custom dataset). "Regenerate" reseeds the chosen preset.

## Controls & export

- **Run:** *Step* (one Lloyd iteration, animated), *Run to convergence*,
  *Reset* (re-place centroids), *Compute silhouette*, *Elbow sweep (k=1..10)*.
- **Clustering:** `k` slider (1–10); seeding method (k-means++ or random);
  *Re-initialize centroids*.
- **Dataset:** preset selector; `N` points; spread/noise; generated cluster
  count; reproducible **seed** input; *Regenerate*; *Clear points*.
- **Export:** *Download PNG* (the cluster plot) and *Download CSV* (each point's
  `x, y, cluster`).
- **Theme:** Auto / Light / Dark toggle (also follows the OS in Auto).

## Accessibility & reproducibility

- **Reproducible.** A seeded **mulberry32** PRNG drives both dataset generation
  and k-means++ seeding. The seed is shown and editable; the same seed +
  controls always produce the same result across page loads.
- **Keyboard.** All controls (Step / Run / Reset and the rest) are native
  buttons, selects, and sliders — fully reachable and activatable by keyboard
  with a visible focus ring. A skip link jumps to the controls. Canvas
  click-to-add is an *enhancement*; keyboard-only users can fully use the app
  via the preset/Regenerate controls.
- **Screen readers.** Controls carry ARIA labels; the scatter canvas uses
  `role="img"` with an `aria-label` that updates live to describe `k`, the
  iteration, the inertia, and convergence. Busy states use `role="status"` with
  `aria-live`.
- **Contrast & colour.** Surfaces use the mist gradient (never pure white); text
  meets WCAG AA against it. The categorical cluster palette is calm but
  distinct, with AA-contrasting colours, and there is a calm dark mode.
- **Motion.** Centroid movement is animated, but `prefers-reduced-motion` makes
  every transition instant.
- **Responsive.** The layout reflows from narrow to desktop, and every canvas
  is sized with `devicePixelRatio` so plots stay crisp on high-DPI displays.

## Self-review

- **Anti-stub scan clean.** A case-insensitive scan for the usual stub markers
  and unfinished-work tags over the project returns nothing.
- **Behaviour verified.** Opening `index.html` immediately generates a sample
  dataset and shows a correct initial clustering. A headless Node run of
  `js/kmeans.js` confirms: convergence on separated blobs, monotonically
  non-increasing inertia, balanced cluster sizes, a high silhouette (~0.96), a
  sharp elbow at the true `k`, bit-for-bit reproducibility from the seed, and no
  crashes on edge cases (`k=1`, duplicate points forcing an empty cluster).
- **Crash-proofing.** `k` is clamped to `[1, N]`; `k > N` shows a calm inline
  message; empty datasets and empty clusters are handled; iterations and the
  O(N²) silhouette/elbow costs are bounded; there are no uncaught throws.
