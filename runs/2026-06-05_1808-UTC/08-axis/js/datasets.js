/**
 * datasets.js — Dataset definitions and loaders for Axis PCA Explorer
 *
 * Provides:
 *   1. Iris dataset  — Fisher 1936 / UCI ML Repository (embedded from data/iris.csv
 *      which is committed; fetched async on load).
 *   2. Synthetic "Blobs" dataset  — 3 clearly-separated clusters in 5D, seeded PRNG.
 *   3. Synthetic "Wine-like" dataset — 2 clusters in 6D, seeded PRNG.
 *   4. CSV parser for user-pasted data.
 *
 * All synthetic datasets use a seedable LCG (Linear Congruential Generator)
 * so results are 100% reproducible across every open.
 *
 * Provenance:
 *   Fisher, R.A. (1936). The use of multiple measurements in taxonomic problems.
 *     Annals of Eugenics, 7(2), 179–188.
 *   UCI Machine Learning Repository: https://archive.ics.uci.edu/ml/datasets/iris
 */

'use strict';

const DATASETS = (() => {

  // ─── Seeded PRNG (LCG) ────────────────────────────────────────────────────

  /**
   * Mulberry32 — fast, seedable 32-bit PRNG.
   * Returns a function that produces uniform [0,1) floats.
   */
  function seededRng(seed) {
    let s = seed >>> 0;
    return function () {
      s |= 0; s = s + 0x6D2B79F5 | 0;
      let t = Math.imul(s ^ s >>> 15, 1 | s);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }

  /**
   * Box-Muller transform: produces two independent N(0,1) samples.
   */
  function boxMuller(rng) {
    const u1 = Math.max(rng(), 1e-14);
    const u2 = rng();
    const mag = Math.sqrt(-2 * Math.log(u1));
    return [
      mag * Math.cos(2 * Math.PI * u2),
      mag * Math.sin(2 * Math.PI * u2),
    ];
  }

  /**
   * Generate n samples from N(mu, sigma) using seeded rng.
   */
  function normalSamples(rng, n, mu, sigma) {
    const out = [];
    for (let i = 0; i < n; i += 2) {
      const [z0, z1] = boxMuller(rng);
      out.push(mu + sigma * z0);
      if (i + 1 < n) out.push(mu + sigma * z1);
    }
    return out;
  }

  // ─── Synthetic Blobs (5-D, 3 clusters) ────────────────────────────────────

  /**
   * Generate a 3-cluster blob dataset in 5D.
   * LABELED SYNTHETIC — not real measurement data.
   * Seed: 42 (fixed for reproducibility).
   */
  function generateBlobs() {
    const rng = seededRng(42);
    const nPerCluster = 50; // 150 total
    const rows = [];
    const labels = [];

    // Cluster centers and scales
    const clusters = [
      { mu: [0, 0, 0, 0, 0], sigma: 0.6, label: 'cluster-A' },
      { mu: [4, 3, 0, -2, 1], sigma: 0.7, label: 'cluster-B' },
      { mu: [-3, 1, 4, 2, -1], sigma: 0.65, label: 'cluster-C' },
    ];

    for (const cl of clusters) {
      for (let i = 0; i < nPerCluster; i++) {
        const row = cl.mu.map(m => {
          const [z] = boxMuller(rng);
          return m + cl.sigma * z;
        });
        rows.push(row);
        labels.push(cl.label);
      }
    }

    return {
      id: 'blobs',
      name: 'Synthetic Blobs (3-cluster, 5D)',
      description: 'SYNTHETIC. Three clearly-separated Gaussian clusters in 5 dimensions. Seed 42. Reproducible.',
      featureNames: ['feat_1', 'feat_2', 'feat_3', 'feat_4', 'feat_5'],
      labelColumn: 'cluster',
      X: rows,
      labels,
    };
  }

  /**
   * Generate a 2-cluster wine-like synthetic dataset in 6D.
   * LABELED SYNTHETIC — not real measurement data.
   * Seed: 137.
   */
  function generateWineLike() {
    const rng = seededRng(137);
    const nPerCluster = 60; // 120 total
    const rows = [];
    const labels = [];

    const clusters = [
      { mu: [13.5, 2.1, 2.5, 18, 100, 2.8], sigma: [0.4, 0.5, 0.3, 3, 15, 0.4], label: 'type-I' },
      { mu: [12.2, 2.9, 2.1, 20, 95, 2.2], sigma: [0.5, 0.6, 0.4, 4, 18, 0.5], label: 'type-II' },
    ];

    for (const cl of clusters) {
      for (let i = 0; i < nPerCluster; i++) {
        const row = cl.mu.map((m, d) => {
          const [z] = boxMuller(rng);
          return m + cl.sigma[d] * z;
        });
        rows.push(row);
        labels.push(cl.label);
      }
    }

    return {
      id: 'wine',
      name: 'Synthetic Wine-like (2-class, 6D)',
      description: 'SYNTHETIC. Two wine-type clusters across 6 chemistry-inspired dimensions. Seed 137. Reproducible.',
      featureNames: ['alcohol', 'volatile_acid', 'citric_acid', 'residual_sugar', 'chlorides', 'total_SO2'],
      labelColumn: 'type',
      X: rows,
      labels,
    };
  }

  // ─── CSV parser ───────────────────────────────────────────────────────────

  /**
   * parseCSV(text, labelCol) — parse CSV text into a dataset object.
   *
   * Rules:
   *   - First row is header.
   *   - Columns that are fully numeric become features.
   *   - If labelCol is specified and exists, use it as the label column.
   *   - Otherwise the last non-numeric column (or the first string column) is used.
   *   - At least 2 numeric columns and 2 rows are required.
   *   - Rows where any feature column is non-finite are skipped with a warning.
   *
   * Returns { featureNames, labelColumn, X, labels, warnings } or throws.
   */
  function parseCSV(text, labelColHint) {
    const lines = text.trim().split(/\r?\n/);
    if (lines.length < 2) throw new Error('CSV needs at least a header row and one data row.');

    // Parse header
    const headers = splitCSVLine(lines[0]);
    if (headers.length < 2) throw new Error('CSV needs at least 2 columns.');

    // Parse all data rows
    const allRows = [];
    for (let li = 1; li < lines.length; li++) {
      const raw = lines[li].trim();
      if (!raw) continue;
      allRows.push(splitCSVLine(raw));
    }
    if (allRows.length < 2) throw new Error('CSV needs at least 2 data rows.');

    // Determine which columns are numeric
    const numericCol = headers.map((_, ci) => {
      return allRows.every(row => {
        const v = row[ci] !== undefined ? row[ci].trim() : '';
        return v !== '' && isFinite(+v);
      });
    });

    // Find label column
    let labelColIdx = -1;
    if (labelColHint) {
      labelColIdx = headers.findIndex(h => h.trim().toLowerCase() === labelColHint.trim().toLowerCase());
    }
    if (labelColIdx < 0) {
      // Use first non-numeric column if any
      labelColIdx = headers.findIndex((_, ci) => !numericCol[ci]);
    }

    // Feature columns = numeric and not the label col
    const featureCols = headers.reduce((acc, _, ci) => {
      if (numericCol[ci] && ci !== labelColIdx) acc.push(ci);
      return acc;
    }, []);

    if (featureCols.length < 2) {
      throw new Error(`CSV needs at least 2 numeric feature columns. Found ${featureCols.length}.`);
    }

    const featureNames = featureCols.map(ci => headers[ci].trim());
    const warnings = [];
    const X = [];
    const labels = [];

    for (let ri = 0; ri < allRows.length; ri++) {
      const row = allRows[ri];
      const featureVals = featureCols.map(ci => +(row[ci] !== undefined ? row[ci].trim() : NaN));
      if (featureVals.some(v => !isFinite(v))) {
        warnings.push(`Row ${ri + 2}: skipped (non-finite value in feature column).`);
        continue;
      }
      X.push(featureVals);
      const lbl = labelColIdx >= 0 && row[labelColIdx] !== undefined
        ? row[labelColIdx].trim()
        : `row${ri + 2}`;
      labels.push(lbl || `row${ri + 2}`);
    }

    if (X.length < 2) throw new Error('After filtering, fewer than 2 valid rows remain.');

    return {
      featureNames,
      labelColumn: labelColIdx >= 0 ? headers[labelColIdx].trim() : null,
      X,
      labels,
      warnings,
    };
  }

  /**
   * Split a single CSV line respecting quoted fields (simple, handles "" escapes).
   */
  function splitCSVLine(line) {
    const fields = [];
    let cur = '';
    let inQuote = false;
    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') {
        if (inQuote && line[i + 1] === '"') { cur += '"'; i++; }
        else inQuote = !inQuote;
      } else if (ch === ',' && !inQuote) {
        fields.push(cur);
        cur = '';
      } else {
        cur += ch;
      }
    }
    fields.push(cur);
    return fields;
  }

  // ─── Iris loader (async, from data/iris.csv) ──────────────────────────────

  /**
   * loadIris() — fetch and parse the committed iris.csv.
   * Returns a dataset object matching the shape above.
   *
   * Provenance:
   *   Fisher, R.A. (1936). The use of multiple measurements in taxonomic problems.
   *     Annals of Eugenics, 7(2), 179–188.
   *   UCI ML Repository: https://archive.ics.uci.edu/ml/datasets/iris
   */
  async function loadIris() {
    // Try fetch first (works when served); fall back to embedded data
    let text;
    try {
      const res = await fetch('data/iris.csv');
      if (!res.ok) throw new Error('fetch failed');
      text = await res.text();
    } catch (_) {
      text = IRIS_EMBEDDED;
    }

    const parsed = parseCSV(text, 'species');
    return {
      id: 'iris',
      name: 'Iris (Fisher 1936)',
      description:
        'Real dataset. 150 samples × 4 numeric features (sepal/petal length & width, cm) × 3 species. ' +
        'Source: Fisher (1936); UCI ML Repository.',
      featureNames: parsed.featureNames,
      labelColumn: 'species',
      X: parsed.X,
      labels: parsed.labels,
    };
  }

  // ─── Embedded Iris fallback (file:// protocol safety) ─────────────────────
  // Full 150-row Iris dataset embedded as a string so the tool works even when
  // opened via file:// (where fetch() may be blocked by browser CORS policy).
  const IRIS_EMBEDDED = `sepal_length,sepal_width,petal_length,petal_width,species
5.1,3.5,1.4,0.2,setosa
4.9,3.0,1.4,0.2,setosa
4.7,3.2,1.3,0.2,setosa
4.6,3.1,1.5,0.2,setosa
5.0,3.6,1.4,0.2,setosa
5.4,3.9,1.7,0.4,setosa
4.6,3.4,1.4,0.3,setosa
5.0,3.4,1.5,0.2,setosa
4.4,2.9,1.4,0.2,setosa
4.9,3.1,1.5,0.1,setosa
5.4,3.7,1.5,0.2,setosa
4.8,3.4,1.6,0.2,setosa
4.8,3.0,1.4,0.1,setosa
4.3,3.0,1.1,0.1,setosa
5.8,4.0,1.2,0.2,setosa
5.7,4.4,1.5,0.4,setosa
5.4,3.9,1.3,0.4,setosa
5.1,3.5,1.4,0.3,setosa
5.7,3.8,1.7,0.3,setosa
5.1,3.8,1.5,0.3,setosa
5.4,3.4,1.7,0.2,setosa
5.1,3.7,1.5,0.4,setosa
4.6,3.6,1.0,0.2,setosa
5.1,3.3,1.7,0.5,setosa
4.8,3.4,1.9,0.2,setosa
5.0,3.0,1.6,0.2,setosa
5.0,3.4,1.6,0.4,setosa
5.2,3.5,1.5,0.2,setosa
5.2,3.4,1.4,0.2,setosa
4.7,3.2,1.6,0.2,setosa
4.8,3.1,1.6,0.2,setosa
5.4,3.4,1.5,0.4,setosa
5.2,4.1,1.5,0.1,setosa
5.5,4.2,1.4,0.2,setosa
4.9,3.1,1.5,0.2,setosa
5.0,3.2,1.2,0.2,setosa
5.5,3.5,1.3,0.2,setosa
4.9,3.6,1.4,0.1,setosa
4.4,3.0,1.3,0.2,setosa
5.1,3.4,1.5,0.2,setosa
5.0,3.5,1.3,0.3,setosa
4.5,2.3,1.3,0.3,setosa
4.4,3.2,1.3,0.2,setosa
5.0,3.5,1.6,0.6,setosa
5.1,3.8,1.9,0.4,setosa
4.8,3.0,1.4,0.3,setosa
5.1,3.8,1.6,0.2,setosa
4.6,3.2,1.4,0.2,setosa
5.3,3.7,1.5,0.2,setosa
5.0,3.3,1.4,0.2,setosa
7.0,3.2,4.7,1.4,versicolor
6.4,3.2,4.5,1.5,versicolor
6.9,3.1,4.9,1.5,versicolor
5.5,2.3,4.0,1.3,versicolor
6.5,2.8,4.6,1.5,versicolor
5.7,2.8,4.5,1.3,versicolor
6.3,3.3,4.7,1.6,versicolor
4.9,2.4,3.3,1.0,versicolor
6.6,2.9,4.6,1.3,versicolor
5.2,2.7,3.9,1.4,versicolor
5.0,2.0,3.5,1.0,versicolor
5.9,3.0,4.2,1.5,versicolor
6.0,2.2,4.0,1.0,versicolor
6.1,2.9,4.7,1.4,versicolor
5.6,2.9,3.6,1.3,versicolor
6.7,3.1,4.4,1.4,versicolor
5.6,3.0,4.5,1.5,versicolor
5.8,2.7,4.1,1.0,versicolor
6.2,2.2,4.5,1.5,versicolor
5.6,2.5,3.9,1.1,versicolor
5.9,3.2,4.8,1.8,versicolor
6.1,2.8,4.0,1.3,versicolor
6.3,2.5,4.9,1.5,versicolor
6.1,2.8,4.7,1.2,versicolor
6.4,2.9,4.3,1.3,versicolor
6.6,3.0,4.4,1.4,versicolor
6.8,2.8,4.8,1.4,versicolor
6.7,3.0,5.0,1.7,versicolor
6.0,2.9,4.5,1.5,versicolor
5.7,2.6,3.5,1.0,versicolor
5.5,2.4,3.8,1.1,versicolor
5.5,2.4,3.7,1.0,versicolor
5.8,2.7,3.9,1.2,versicolor
6.0,2.7,5.1,1.6,versicolor
5.4,3.0,4.5,1.5,versicolor
6.0,3.4,4.5,1.6,versicolor
6.7,3.1,4.7,1.5,versicolor
6.3,2.3,4.4,1.3,versicolor
5.6,3.0,4.1,1.3,versicolor
5.5,2.5,4.0,1.3,versicolor
5.5,2.6,4.4,1.2,versicolor
6.1,3.0,4.6,1.4,versicolor
5.8,2.6,4.0,1.2,versicolor
5.0,2.3,3.3,1.0,versicolor
5.6,2.7,4.2,1.3,versicolor
5.7,3.0,4.2,1.2,versicolor
5.7,2.9,4.2,1.3,versicolor
6.2,2.9,4.3,1.3,versicolor
5.1,2.5,3.0,1.1,versicolor
5.7,2.8,4.1,1.3,versicolor
6.3,3.3,6.0,2.5,virginica
5.8,2.7,5.1,1.9,virginica
7.1,3.0,5.9,2.1,virginica
6.3,2.9,5.6,1.8,virginica
6.5,3.0,5.8,2.2,virginica
7.6,3.0,6.6,2.1,virginica
4.9,2.5,4.5,1.7,virginica
7.3,2.9,6.3,1.8,virginica
6.7,2.5,5.8,1.8,virginica
7.2,3.6,6.1,2.5,virginica
6.5,3.2,5.1,2.0,virginica
6.4,2.7,5.3,1.9,virginica
6.8,3.0,5.5,2.1,virginica
5.7,2.5,5.0,2.0,virginica
5.8,2.8,5.1,2.4,virginica
6.4,3.2,5.3,2.3,virginica
6.5,3.0,5.5,1.8,virginica
7.7,3.8,6.7,2.2,virginica
7.7,2.6,6.9,2.3,virginica
6.0,2.2,5.0,1.5,virginica
6.9,3.2,5.7,2.3,virginica
5.6,2.8,4.9,2.0,virginica
7.7,2.8,6.7,2.0,virginica
6.3,2.7,4.9,1.8,virginica
6.7,3.3,5.7,2.1,virginica
7.2,3.2,6.0,1.8,virginica
6.2,2.8,4.8,1.8,virginica
6.1,3.0,4.9,1.8,virginica
6.4,2.8,5.6,2.1,virginica
7.2,3.0,5.8,1.6,virginica
7.4,2.8,6.1,1.9,virginica
7.9,3.8,6.4,2.0,virginica
6.4,2.8,5.6,2.2,virginica
6.3,2.8,5.1,1.5,virginica
6.1,2.6,5.6,1.4,virginica
7.7,3.0,6.1,2.3,virginica
6.3,3.4,5.6,2.4,virginica
6.4,3.1,5.5,1.8,virginica
6.0,3.0,4.8,1.8,virginica
6.9,3.1,5.4,2.1,virginica
6.7,3.1,5.6,2.4,virginica
6.9,3.1,5.1,2.3,virginica
5.8,2.7,5.1,1.9,virginica
6.8,3.2,5.9,2.3,virginica
6.7,3.3,5.7,2.5,virginica
6.7,3.0,5.2,2.3,virginica
6.3,2.5,5.0,1.9,virginica
6.5,3.0,5.2,2.0,virginica
6.2,3.4,5.4,2.3,virginica
5.9,3.0,5.1,1.8,virginica`;

  // ─── Registry ─────────────────────────────────────────────────────────────

  /** All builtin datasets keyed by id */
  const REGISTRY = {
    iris: null,    // loaded async
    blobs: generateBlobs(),
    wine: generateWineLike(),
  };

  /** Load all datasets (Iris is async) */
  async function loadAll() {
    REGISTRY.iris = await loadIris();
    return REGISTRY;
  }

  return {
    loadAll,
    generateBlobs,
    generateWineLike,
    parseCSV,
    REGISTRY,
  };
})();

if (typeof window !== 'undefined') window.DATASETS = DATASETS;
