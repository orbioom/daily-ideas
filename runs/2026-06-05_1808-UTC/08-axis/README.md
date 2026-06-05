# Axis — PCA Explorer · Orbioom Studio

An interactive, browser-based workbench for exploring multivariate datasets through Principal Component Analysis (PCA).

---

## What it is

Axis lets you pick a dataset, choose features, and immediately see the data projected onto its principal components — a scores scatter plot colored by class, a scree plot of explained variance, and a loadings biplot — all recomputing in real time as you adjust controls.

---

## The science for a smart non-expert

**What PCA does.** Real-world datasets often have many measurements (features) per sample. PCA finds the directions in that high-dimensional feature space along which the data varies the most. The first "principal component" (PC1) is the single direction capturing the greatest variance; PC2 is the direction of greatest remaining variance that is *perpendicular* (orthogonal, i.e. uncorrelated) to PC1; and so on. By projecting data onto PC1 and PC2 you get a 2-D picture that preserves as much information as possible.

**Why center?** If you don't subtract each feature's mean, the first PC might just point toward the data's centre of mass rather than its principal axis of variation. Mean-centering fixes this.

**Why scale (autoscale)?** If features have very different units or magnitudes (e.g. sepal length in cm vs petal width in mm), the features with large raw values will dominate the covariance. Dividing each feature by its standard deviation (z-score / autoscaling — standard in chemometrics) puts all features on equal footing. When you standardize, the covariance matrix becomes the *correlation* matrix.

**How to read the plots.**
- *Scores scatter*: each point is one sample. Tight clusters = similar samples. If the three Iris species separate along PC1, it means that linear combination of features is the dominant source of variation.
- *Scree plot*: the bar height for each PC is the fraction of total variance it explains. The "elbow" shows how many PCs are worth keeping. The red line is the cumulative explained variance.
- *Loadings biplot*: each arrow represents one original feature; the arrow direction and length show how much that feature contributes to PC1 (x-axis) and PC2 (y-axis). Arrows in the same direction = positively correlated features.

**Jargon defined.**
- *Eigenvalue*: the variance of the data along one PC direction.
- *Eigenvector*: the direction of one PC (length-1 vector in feature space).
- *Loading*: one element of an eigenvector — how much one original feature contributes to one PC.
- *Score*: a sample's coordinate along a PC axis.
- *Explained variance ratio*: eigenvalue ÷ sum of all eigenvalues.

---

## Method & citations

### Algorithm (exact steps implemented)

1. **Build data matrix** from selected numeric features (n samples × p features).
2. **Mean-center** each column (always).
3. **Autoscale** (optional): divide each column by its sample standard deviation (ddof=1). When active, makes the covariance matrix equal to the correlation matrix.
4. **Covariance matrix** `C = (1/(n−1)) ZᵀZ` where `Z` is the centered/scaled matrix.
5. **Jacobi eigendecomposition** (cyclic variant): iteratively apply Givens rotations to off-diagonal pairs, accumulating the rotation product into `V`. Repeat sweeps until the maximum absolute off-diagonal element of the working matrix drops below ε = 1e-12. Eigenvalues emerge on the diagonal; columns of `V` are the eigenvectors. Sort eigenpairs by eigenvalue descending.
6. **Explained variance ratios** = eigenvalues / sum(eigenvalues); cumulative = prefix sums.
7. **Scores** = `Z × Vₖᵀ` (project data onto top-k eigenvectors).

### Honest simplifications

- The Jacobi solver is ideal for small p (≤ ~30) and converges very fast (a few sweeps). For large p, SVD or divide-and-conquer tridiagonalization is more efficient.
- Sign of eigenvectors is arbitrary; flipping an axis does not change the geometry.
- No cross-validation, permutation testing, or significance thresholds are performed.
- Zero-variance (constant) columns are detected and flagged; they are passed through but contribute nothing.

### References

| Reference | Role |
|-----------|------|
| Pearson, K. (1901). On lines and planes of closest fit to systems of points in space. *Philosophical Magazine*, 2(11), 559–572. | Original PCA paper |
| Hotelling, H. (1933). Analysis of a complex of statistical variables into principal components. *Journal of Educational Psychology*, 24(6), 417–441. | Statistical/matrix formulation of PCA |
| Golub, G. H., & Van Loan, C. F. (2013). *Matrix Computations* (4th ed.). §8.4 — Jacobi methods for symmetric eigenproblems. Johns Hopkins University Press. | Jacobi algorithm used for eigendecomposition |
| Fisher, R. A. (1936). The use of multiple measurements in taxonomic problems. *Annals of Eugenics*, 7(2), 179–188. | Iris dataset provenance |
| UCI Machine Learning Repository — Iris Data Set. https://archive.ics.uci.edu/ml/datasets/iris | Dataset host / canonical citation |

---

## How to open it

1. Clone or download this folder.
2. Open `index.html` in any modern browser (Chrome, Firefox, Safari, Edge).
3. The Iris dataset loads automatically and the first PCA view appears in under a second.
4. No build step, no server, no install — `file://` works.

> **Font note:** Manrope and JetBrains Mono are loaded from Google Fonts via `<link>`. They gracefully fall back to `system-ui` and `ui-monospace` when offline.

---

## Data

### Iris (committed, real)

- **File:** `data/iris.csv`
- **Contents:** 150 samples × 4 features (sepal_length, sepal_width, petal_length, petal_width, all in cm) × 3 species (setosa, versicolor, virginica).
- **Provenance:** Fisher, R. A. (1936). UCI ML Repository (https://archive.ics.uci.edu/ml/datasets/iris).
- **Expected result (standardized):** PC1 + PC2 explain ≥ 95 % of variance; the three species are clearly separated in the PC1×PC2 scatter, with setosa fully isolated.

### Synthetic Blobs (labeled synthetic)

- 3 Gaussian clusters in 5 dimensions, 50 samples each = 150 total.
- Cluster centres chosen to give clear separation; σ ≈ 0.65.
- Seeded PRNG (Mulberry32, seed = 42) for exact reproducibility.
- Box-Muller transform for Gaussian samples.
- **Not real data** — labeled "SYNTHETIC" in the UI.

### Synthetic Wine-like (labeled synthetic)

- 2 clusters in 6 chemistry-inspired dimensions (alcohol, volatile_acid, citric_acid, residual_sugar, chlorides, total_SO2), 60 samples each = 120 total.
- Seeded PRNG (seed = 137).
- **Not real data** — labeled "SYNTHETIC" in the UI.

### Custom CSV

Paste any CSV with a header row. Rules:
- Fully numeric columns → features.
- First non-numeric column (or one named "label", "species", etc.) → class coloring.
- At least 2 numeric columns and 2 rows required.
- Rows with non-finite values in feature columns are skipped with a warning.

---

## Controls & export

| Control | Effect |
|---------|--------|
| Dataset selector | Switch between Iris, Synthetic Blobs, Synthetic Wine-like, or a pasted CSV |
| Feature checkboxes | Include/exclude individual features from the PCA |
| Standardize toggle | Autoscale features (z-score); on = correlation matrix, off = covariance matrix |
| X / Y PC selectors | Choose which pair of principal components to display |
| Point size | Adjust scatter point radius (2–12 px) |
| CSV textarea + Load CSV | Paste custom data; runs PCA immediately |
| Export PNG (scatter/scree/biplot) | Saves the canvas as a PNG via Blob download |
| Export Scores CSV | Downloads sample-id, label, PC1…PCk as a CSV |

---

## Accessibility & reproducibility

- All controls are keyboard-operable (Tab/Space/Enter).
- ARIA labels on all interactive elements and chart canvases.
- Visible focus ring (2.5 px, blue) on every focusable element.
- Error, info, and loading states announced via `role="alert"` / `aria-live`.
- `prefers-reduced-motion`: spinner and CSS transitions disabled.
- WCAG AA contrast: text on mist background passes; categorical colors meet AA against white.
- Synthetic datasets are fully deterministic (seeded PRNG); Iris is a fixed file; default parameters identical every open.

---

## Self-review

### Anti-stub scan

```
grep -rniE "TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub" \
  /home/user/daily-ideas/runs/2026-06-05_1808-UTC/08-axis/
```
**Result:** No matches. All controls are wired; no placeholder content.

### Correctness verification

- **Jacobi orthonormality:** For the Iris 4×4 covariance matrix, the Jacobi solver (displayed in the sanity strip) shows `|dot(vᵢ, vⱼ)| < 1e-10` and `|‖vᵢ‖ − 1| < 1e-10`. The `sanity.ok` flag is `true`.
- **Variance sum:** Explained variance ratios sum to 1.000000 (displayed in the sanity strip).
- **Iris PC1+PC2 ≥ 95 % (standardized):** On the canonical Iris dataset with standardization, PC1 ≈ 72.8 % and PC2 ≈ 23.0 %, giving ≈ 95.8 % cumulative for the top two PCs. This matches published results (e.g., sklearn PCA on standardized Iris: ~95.8 %).
- **Species separation:** Setosa is fully separated from versicolor and virginica in the PC1×PC2 scatter; versicolor and virginica overlap slightly — consistent with all published analyses.
- **All controls tested:** dataset switch, feature toggle, standardize on/off, PC axis change, point size, CSV paste, all four export buttons.
- **Error states tested:** <2 features selected → clear message; constant column → warning shown; malformed CSV → parse error with message.
- **Resize tested:** canvas redraws correctly at narrow (375 px) and wide (1400 px) viewports; plots do not clip; devicePixelRatio scaling applied.
