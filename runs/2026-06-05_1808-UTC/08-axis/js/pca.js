/**
 * pca.js — Principal Component Analysis
 *
 * Implements PCA via:
 *   1. Mean-centering (always)
 *   2. Optional autoscaling / standardization (z-score per feature)
 *   3. Covariance (or correlation, when standardized) matrix
 *   4. Jacobi eigenvalue algorithm for symmetric matrices (Jacobi 1846;
 *      see also: Golub & Van Loan, "Matrix Computations", 4th ed.)
 *   5. Sort eigenpairs by eigenvalue descending
 *   6. Project data to get scores; compute explained variance ratios
 *
 * All functions are pure (no side effects), making them independently testable.
 *
 * References:
 *   Pearson, K. (1901). On lines and planes of closest fit to systems of
 *     points in space. Philosophical Magazine, 2(11), 559–572.
 *   Hotelling, H. (1933). Analysis of a complex of statistical variables
 *     into principal components. Journal of Educational Psychology, 24, 417–441.
 */

'use strict';

const PCA = (() => {

  // ─── Matrix helpers ────────────────────────────────────────────────────────

  /** Create n×n identity matrix */
  function identity(n) {
    const M = [];
    for (let i = 0; i < n; i++) {
      M.push(new Float64Array(n));
      M[i][i] = 1.0;
    }
    return M;
  }

  /** Deep-copy a 2-D array of Float64Array rows */
  function copyMatrix(M) {
    return M.map(row => new Float64Array(row));
  }

  /** Matrix–vector product: M (p×p) times v (length p) → length-p array */
  function matvec(M, v) {
    const p = v.length;
    const out = new Float64Array(p);
    for (let i = 0; i < p; i++) {
      let s = 0;
      for (let j = 0; j < p; j++) s += M[i][j] * v[j];
      out[i] = s;
    }
    return out;
  }

  /** Dot product of two same-length arrays */
  function dot(a, b) {
    let s = 0;
    for (let i = 0; i < a.length; i++) s += a[i] * b[i];
    return s;
  }

  /** Euclidean norm of array */
  function norm(a) {
    return Math.sqrt(dot(a, a));
  }

  // ─── Jacobi eigenvalue algorithm ──────────────────────────────────────────

  /**
   * jacobi(S) — symmetric eigenvalue decomposition via cyclic Jacobi rotations.
   *
   * Input : S — p×p symmetric matrix (array of Float64Array rows).
   * Output: { eigenvalues: Float64Array(p), eigenvectors: Float64Array[p] }
   *         where eigenvectors[j] is the j-th eigenvector (length p).
   *         Eigenpairs are sorted by eigenvalue DESCENDING.
   *
   * Algorithm: iteratively zero off-diagonal elements with Givens rotations.
   * Convergence criterion: max |off-diagonal element| < ε.
   * For p ≤ ~30 and double precision, this converges in a handful of sweeps.
   */
  function jacobi(S) {
    const p = S.length;
    const A = copyMatrix(S);           // working copy of S
    const V = identity(p);             // accumulates rotations → eigenvectors

    const MAX_ITER = 500 * p * p;      // generous bound; convergence is fast
    const EPS = 1e-12;

    for (let iter = 0; iter < MAX_ITER; iter++) {
      // Find largest off-diagonal element
      let maxVal = 0, p_idx = 0, q_idx = 1;
      for (let i = 0; i < p - 1; i++) {
        for (let j = i + 1; j < p; j++) {
          const v = Math.abs(A[i][j]);
          if (v > maxVal) { maxVal = v; p_idx = i; q_idx = j; }
        }
      }
      if (maxVal < EPS) break;         // converged

      // Compute Givens rotation angle
      const Apq = A[p_idx][q_idx];
      const App = A[p_idx][p_idx];
      const Aqq = A[q_idx][q_idx];

      const tau = (Aqq - App) / (2.0 * Apq);
      // t = sign(tau) / (|tau| + sqrt(1+tau²))  — numerically stable choice
      const t = (tau >= 0 ? 1 : -1) / (Math.abs(tau) + Math.sqrt(1.0 + tau * tau));
      const c = 1.0 / Math.sqrt(1.0 + t * t);
      const s = t * c;

      // Apply rotation to A from both sides
      // Update diagonal
      const App_new = App - t * Apq;
      const Aqq_new = Aqq + t * Apq;
      A[p_idx][p_idx] = App_new;
      A[q_idx][q_idx] = Aqq_new;
      A[p_idx][q_idx] = 0.0;
      A[q_idx][p_idx] = 0.0;

      // Update remaining rows/cols
      for (let r = 0; r < p; r++) {
        if (r === p_idx || r === q_idx) continue;
        const Arp = A[r][p_idx];
        const Arq = A[r][q_idx];
        const newArp = c * Arp - s * Arq;
        const newArq = s * Arp + c * Arq;
        A[r][p_idx] = newArp;
        A[p_idx][r] = newArp;
        A[r][q_idx] = newArq;
        A[q_idx][r] = newArq;
      }

      // Accumulate rotation into V
      for (let r = 0; r < p; r++) {
        const Vrp = V[r][p_idx];
        const Vrq = V[r][q_idx];
        V[r][p_idx] = c * Vrp - s * Vrq;
        V[r][q_idx] = s * Vrp + c * Vrq;
      }
    }

    // Extract eigenvalues (diagonal of A) and eigenvectors (columns of V)
    const eigenvalues = new Float64Array(p);
    for (let i = 0; i < p; i++) eigenvalues[i] = A[i][i];

    const eigenvectors = [];
    for (let j = 0; j < p; j++) {
      const ev = new Float64Array(p);
      for (let i = 0; i < p; i++) ev[i] = V[i][j];
      eigenvectors.push(ev);
    }

    // Sort by eigenvalue descending
    const idx = Array.from({ length: p }, (_, i) => i);
    idx.sort((a, b) => eigenvalues[b] - eigenvalues[a]);

    const sortedValues = new Float64Array(p);
    const sortedVecs   = [];
    for (let k = 0; k < p; k++) {
      sortedValues[k] = Math.max(0, eigenvalues[idx[k]]); // clamp tiny negatives from floating-point
      sortedVecs.push(eigenvectors[idx[k]]);
    }

    return { eigenvalues: sortedValues, eigenvectors: sortedVecs };
  }

  // ─── Core PCA pipeline ────────────────────────────────────────────────────

  /**
   * computeColumnMeans(X) — mean of each column.
   * X: n×p row-major array of arrays (or Float64Arrays).
   * Returns Float64Array of length p.
   */
  function computeColumnMeans(X) {
    const n = X.length, p = X[0].length;
    const means = new Float64Array(p);
    for (let i = 0; i < n; i++)
      for (let j = 0; j < p; j++)
        means[j] += X[i][j];
    for (let j = 0; j < p; j++) means[j] /= n;
    return means;
  }

  /**
   * computeColumnStdDevs(X, means) — population std dev (ddof=1, i.e. sample std dev).
   * Returns Float64Array of length p.
   */
  function computeColumnStdDevs(X, means) {
    const n = X.length, p = X[0].length;
    const stds = new Float64Array(p);
    for (let i = 0; i < n; i++)
      for (let j = 0; j < p; j++) {
        const d = X[i][j] - means[j];
        stds[j] += d * d;
      }
    for (let j = 0; j < p; j++) {
      stds[j] = Math.sqrt(stds[j] / (n - 1));
      // Guard against zero-variance columns
      if (stds[j] < 1e-14) stds[j] = 1.0;
    }
    return stds;
  }

  /**
   * centerAndScale(X, means, stds, standardize)
   * Returns n×p Float64Array matrix (row-major, flat).
   */
  function centerAndScale(X, means, stds, standardize) {
    const n = X.length, p = X[0].length;
    // Store as array of Float64Array rows for easy covariance computation
    const Z = [];
    for (let i = 0; i < n; i++) {
      const row = new Float64Array(p);
      for (let j = 0; j < p; j++) {
        row[j] = (X[i][j] - means[j]) / (standardize ? stds[j] : 1.0);
      }
      Z.push(row);
    }
    return Z;
  }

  /**
   * covarianceMatrix(Z) — (n-1)-denominator sample covariance of centered matrix Z.
   * Z: n×p array of Float64Array rows.
   * Returns p×p symmetric Float64Array matrix.
   */
  function covarianceMatrix(Z) {
    const n = Z.length, p = Z[0].length;
    const C = [];
    for (let i = 0; i < p; i++) C.push(new Float64Array(p));

    for (let i = 0; i < p; i++) {
      for (let j = i; j < p; j++) {
        let s = 0;
        for (let k = 0; k < n; k++) s += Z[k][i] * Z[k][j];
        s /= (n - 1);
        C[i][j] = s;
        C[j][i] = s;
      }
    }
    return C;
  }

  /**
   * run(X, labels, featureNames, options) — full PCA pipeline.
   *
   * X           : n×p numeric matrix (array of arrays)
   * labels      : array of n strings (class labels; may be empty strings)
   * featureNames: array of p strings
   * options     : { standardize: bool, nComponents: int }
   *
   * Returns:
   * {
   *   scores,           // n×k Float64Array rows  (k = nComponents or p)
   *   loadings,         // k×p Float64Array rows  (eigenvectors, top k)
   *   eigenvalues,      // Float64Array(p)  all eigenvalues
   *   explainedVariance,// Float64Array(p)  ratio per PC
   *   cumulative,       // Float64Array(p)  cumulative ratio
   *   means,            // Float64Array(p)
   *   stds,             // Float64Array(p)
   *   nSamples,         // n
   *   nFeatures,        // p
   *   featureNames,     // as passed
   *   labels,           // as passed
   *   standardize,      // bool
   *   computeTimeMs,    // number
   *   sanity,           // { orthonormal, varianceSum, ok }
   * }
   */
  function run(X, labels, featureNames, options = {}) {
    const t0 = performance.now();

    const standardize = !!options.standardize;
    const n = X.length;
    const p = X[0].length;

    if (n < 2) throw new Error('Need at least 2 samples for PCA.');
    if (p < 2) throw new Error('Need at least 2 features for PCA.');

    // 1. Compute column statistics
    const means = computeColumnMeans(X);
    const stds  = computeColumnStdDevs(X, means);

    // 2. Center (+ optionally scale)
    const Z = centerAndScale(X, means, stds, standardize);

    // 3. Covariance matrix
    const C = covarianceMatrix(Z);

    // 4. Jacobi eigendecomposition
    const { eigenvalues, eigenvectors } = jacobi(C);

    // 5. Explained variance ratios
    const totalVar = eigenvalues.reduce((a, b) => a + b, 0);
    const explainedVariance = new Float64Array(p);
    const cumulative        = new Float64Array(p);
    let cumSum = 0;
    for (let i = 0; i < p; i++) {
      explainedVariance[i] = totalVar > 0 ? eigenvalues[i] / totalVar : 0;
      cumSum += explainedVariance[i];
      cumulative[i] = cumSum;
    }

    // 6. Determine k components to return
    const k = Math.min(options.nComponents || p, p);

    // 7. Loadings (top k eigenvectors as rows)
    const loadings = eigenvectors.slice(0, k);

    // 8. Scores: project Z onto loadings
    const scores = [];
    for (let i = 0; i < n; i++) {
      const row = new Float64Array(k);
      for (let c = 0; c < k; c++) {
        row[c] = dot(Z[i], loadings[c]);
      }
      scores.push(row);
    }

    // 9. Sanity checks
    const sanity = sanityCheck(eigenvectors, explainedVariance, cumulative);

    const computeTimeMs = performance.now() - t0;

    return {
      scores,
      loadings,
      eigenvalues,
      explainedVariance,
      cumulative,
      means,
      stds,
      nSamples: n,
      nFeatures: p,
      featureNames,
      labels,
      standardize,
      computeTimeMs,
      sanity,
    };
  }

  // ─── Sanity checks ────────────────────────────────────────────────────────

  /**
   * sanityCheck — verify eigenvector orthonormality and variance ratio sum.
   *
   * Eigenvectors should be:
   *   - unit norm: ||v_i|| ≈ 1
   *   - orthogonal: v_i · v_j ≈ 0 for i≠j
   * Explained variance ratios should sum to ≈ 1.
   *
   * Returns { orthonormal: bool, varianceSum: number, ok: bool }
   */
  function sanityCheck(eigenvectors, explainedVariance) {
    const p = eigenvectors.length;
    const EPS = 1e-8;

    let orthonormal = true;
    for (let i = 0; i < p && orthonormal; i++) {
      const ni = norm(eigenvectors[i]);
      if (Math.abs(ni - 1.0) > EPS) { orthonormal = false; break; }
      for (let j = i + 1; j < p && orthonormal; j++) {
        const d = Math.abs(dot(eigenvectors[i], eigenvectors[j]));
        if (d > EPS) { orthonormal = false; break; }
      }
    }

    const varianceSum = Array.from(explainedVariance).reduce((a, b) => a + b, 0);
    const varianceSumOk = Math.abs(varianceSum - 1.0) < 1e-6;

    return {
      orthonormal,
      varianceSum: +varianceSum.toFixed(8),
      ok: orthonormal && varianceSumOk,
    };
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  return { run, jacobi, computeColumnMeans, computeColumnStdDevs, sanityCheck };

})();

// Make available globally (classic script tags, no module bundler)
if (typeof window !== 'undefined') window.PCA = PCA;
