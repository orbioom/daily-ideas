/*
 * kmeans.js — the real k-means clustering algorithm, framework-free and testable.
 *
 * Implements:
 *   - mulberry32 seeded PRNG (reproducible runs)
 *   - k-means++ seeding (Arthur & Vassilvitskii 2007)
 *   - random seeding (uniform pick of distinct points)
 *   - Lloyd's algorithm: assignment step + update step (Lloyd 1957/1982)
 *   - inertia (within-cluster sum of squared Euclidean distances, WCSS)
 *   - silhouette score (Rousseeuw 1987)
 *   - empty-cluster handling (re-seed the orphaned centroid at the farthest point)
 *
 * All distances are squared/Euclidean in 2-D. No external dependencies.
 *
 * Exposed as a global `KMeans` object (works without a module bundler) and,
 * when available, as CommonJS exports for unit testing under Node.
 */
(function (root) {
  'use strict';

  /* ------------------------------------------------------------------ */
  /* Seeded PRNG: mulberry32. Deterministic 32-bit generator.           */
  /* Returns a function producing floats in [0, 1).                     */
  /* ------------------------------------------------------------------ */
  function mulberry32(seed) {
    let a = seed >>> 0;
    return function () {
      a |= 0;
      a = (a + 0x6d2b79f5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  /* Squared Euclidean distance between two [x, y] points. */
  function dist2(a, b) {
    const dx = a[0] - b[0];
    const dy = a[1] - b[1];
    return dx * dx + dy * dy;
  }

  /* Euclidean distance. */
  function dist(a, b) {
    return Math.sqrt(dist2(a, b));
  }

  /* ------------------------------------------------------------------ */
  /* Seeding                                                            */
  /* ------------------------------------------------------------------ */

  /*
   * Random seeding: choose k distinct points uniformly at random as the
   * initial centroids. Falls back gracefully if there are duplicate points.
   */
  function seedRandom(points, k, rng) {
    const n = points.length;
    const idx = [];
    const used = new Set();
    let guard = 0;
    while (idx.length < k && guard < n * 50) {
      const i = Math.floor(rng() * n);
      const key = points[i][0] + ',' + points[i][1];
      if (!used.has(key)) {
        used.add(key);
        idx.push(i);
      } else if (used.size >= Math.min(k, n)) {
        // All distinct points already chosen but we still need more
        // (k > unique points): allow a repeat to avoid an infinite loop.
        idx.push(i);
      }
      guard++;
    }
    // If the guard tripped, top up deterministically.
    let j = 0;
    while (idx.length < k) {
      idx.push(j % n);
      j++;
    }
    return idx.map((i) => points[i].slice());
  }

  /*
   * k-means++ seeding (Arthur & Vassilvitskii 2007, SODA).
   *   1. Choose one centroid uniformly at random from the data points.
   *   2. For each remaining point x, compute D(x) = distance to the nearest
   *      already-chosen centroid.
   *   3. Choose the next centroid with probability proportional to D(x)^2.
   *   4. Repeat until k centroids are chosen.
   * This spreads initial centroids out, giving O(log k)-competitive results.
   */
  function seedKMeansPP(points, k, rng) {
    const n = points.length;
    const centroids = [];
    const first = Math.floor(rng() * n);
    centroids.push(points[first].slice());

    // D2[i] = squared distance from point i to nearest chosen centroid.
    const D2 = new Array(n).fill(Infinity);

    for (let c = 1; c < k; c++) {
      let sum = 0;
      const last = centroids[centroids.length - 1];
      for (let i = 0; i < n; i++) {
        const d = dist2(points[i], last);
        if (d < D2[i]) D2[i] = d;
        sum += D2[i];
      }
      if (sum === 0) {
        // All remaining points coincide with chosen centroids; pick any.
        centroids.push(points[Math.floor(rng() * n)].slice());
        continue;
      }
      // Weighted random selection proportional to D2.
      let target = rng() * sum;
      let chosen = n - 1;
      for (let i = 0; i < n; i++) {
        target -= D2[i];
        if (target <= 0) {
          chosen = i;
          break;
        }
      }
      centroids.push(points[chosen].slice());
    }
    return centroids;
  }

  /*
   * Initialise centroids using the chosen strategy.
   * method: 'kmeans++' | 'random'
   */
  function initCentroids(points, k, method, rng) {
    if (method === 'random') return seedRandom(points, k, rng);
    return seedKMeansPP(points, k, rng);
  }

  /* ------------------------------------------------------------------ */
  /* Lloyd's algorithm steps                                            */
  /* ------------------------------------------------------------------ */

  /*
   * Assignment step: assign each point to its nearest centroid.
   * Returns { assignments: Int32Array, inertia: number }.
   * Inertia (WCSS) = sum over points of squared distance to assigned centroid.
   */
  function assign(points, centroids) {
    const n = points.length;
    const assignments = new Int32Array(n);
    let inertia = 0;
    for (let i = 0; i < n; i++) {
      let best = 0;
      let bestD = Infinity;
      for (let c = 0; c < centroids.length; c++) {
        const d = dist2(points[i], centroids[c]);
        if (d < bestD) {
          bestD = d;
          best = c;
        }
      }
      assignments[i] = best;
      inertia += bestD;
    }
    return { assignments: assignments, inertia: inertia };
  }

  /*
   * Update step: recompute each centroid as the mean of its assigned points.
   * Empty clusters (no assigned points) are re-seeded to the data point that
   * is currently farthest from any centroid, which guarantees progress and
   * avoids division by zero.
   * Returns { centroids, moved } where moved is the total centroid movement.
   */
  function update(points, assignments, k, prevCentroids) {
    const sums = [];
    const counts = new Array(k).fill(0);
    for (let c = 0; c < k; c++) sums.push([0, 0]);

    for (let i = 0; i < points.length; i++) {
      const a = assignments[i];
      sums[a][0] += points[i][0];
      sums[a][1] += points[i][1];
      counts[a]++;
    }

    const centroids = [];
    const empties = [];
    for (let c = 0; c < k; c++) {
      if (counts[c] > 0) {
        centroids.push([sums[c][0] / counts[c], sums[c][1] / counts[c]]);
      } else {
        // Keep the previous position for now; re-seeded below.
        centroids.push(prevCentroids[c].slice());
        empties.push(c);
      }
    }

    // Re-seed any empty cluster at the point farthest from all current
    // centroids (a standard, deterministic empty-cluster repair).
    for (let e = 0; e < empties.length; e++) {
      let farIdx = 0;
      let farD = -1;
      for (let i = 0; i < points.length; i++) {
        let nearest = Infinity;
        for (let c = 0; c < centroids.length; c++) {
          const d = dist2(points[i], centroids[c]);
          if (d < nearest) nearest = d;
        }
        if (nearest > farD) {
          farD = nearest;
          farIdx = i;
        }
      }
      centroids[empties[e]] = points[farIdx].slice();
    }

    // Total movement of centroids (Euclidean), for convergence testing.
    let moved = 0;
    for (let c = 0; c < k; c++) {
      moved += dist(centroids[c], prevCentroids[c]);
    }

    return { centroids: centroids, moved: moved, counts: counts };
  }

  /*
   * One full Lloyd iteration: assign then update.
   * Returns the new state.
   */
  function step(points, centroids) {
    const k = centroids.length;
    const a = assign(points, centroids);
    const u = update(points, a.assignments, k, centroids);
    // Recompute inertia after the update so the reported inertia matches the
    // new centroid positions used for the next assignment.
    return {
      centroids: u.centroids,
      assignments: a.assignments,
      inertia: a.inertia,
      moved: u.moved,
      counts: u.counts,
    };
  }

  /* ------------------------------------------------------------------ */
  /* Silhouette score (Rousseeuw 1987)                                  */
  /* ------------------------------------------------------------------ */
  /*
   * For each point i:
   *   a(i) = mean distance from i to all other points in its own cluster.
   *   b(i) = min over other clusters of the mean distance from i to that
   *          cluster's points.
   *   s(i) = (b - a) / max(a, b)   (defined as 0 for singleton clusters).
   * The silhouette score is the mean of s(i) over all points, in [-1, 1].
   * Higher is better. This is O(n^2); callers should bound n.
   */
  function silhouette(points, assignments, k) {
    const n = points.length;
    if (n === 0 || k <= 1) return 0;

    // Group point indices by cluster.
    const clusters = [];
    for (let c = 0; c < k; c++) clusters.push([]);
    for (let i = 0; i < n; i++) clusters[assignments[i]].push(i);

    let total = 0;
    let counted = 0;
    for (let i = 0; i < n; i++) {
      const ci = assignments[i];
      const own = clusters[ci];
      if (own.length <= 1) {
        // Singleton cluster: s(i) defined as 0.
        counted++;
        continue;
      }
      // a(i)
      let aSum = 0;
      for (let j = 0; j < own.length; j++) {
        if (own[j] !== i) aSum += dist(points[i], points[own[j]]);
      }
      const a = aSum / (own.length - 1);

      // b(i)
      let b = Infinity;
      for (let c = 0; c < k; c++) {
        if (c === ci) continue;
        const other = clusters[c];
        if (other.length === 0) continue;
        let sum = 0;
        for (let j = 0; j < other.length; j++) {
          sum += dist(points[i], points[other[j]]);
        }
        const mean = sum / other.length;
        if (mean < b) b = mean;
      }
      if (b === Infinity) {
        counted++;
        continue;
      }
      const denom = Math.max(a, b);
      const s = denom === 0 ? 0 : (b - a) / denom;
      total += s;
      counted++;
    }
    return counted === 0 ? 0 : total / counted;
  }

  /* ------------------------------------------------------------------ */
  /* Convenience: run to convergence                                    */
  /* ------------------------------------------------------------------ */
  /*
   * Runs Lloyd's algorithm from a given seeding until centroids stop moving
   * (movement <= tol) or maxIter is reached. Used by the elbow sweep and for
   * a single headless run. Returns the final state plus the inertia history.
   */
  function run(points, k, opts) {
    opts = opts || {};
    const method = opts.method || 'kmeans++';
    const seed = opts.seed == null ? 1 : opts.seed;
    const maxIter = opts.maxIter == null ? 100 : opts.maxIter;
    const tol = opts.tol == null ? 1e-9 : opts.tol;
    const rng = mulberry32(seed);

    let centroids = initCentroids(points, k, method, rng);
    const history = [];
    let assignments = null;
    let inertia = Infinity;
    let counts = null;
    let iter = 0;
    let converged = false;

    for (iter = 0; iter < maxIter; iter++) {
      const s = step(points, centroids);
      centroids = s.centroids;
      assignments = s.assignments;
      inertia = s.inertia;
      counts = s.counts;
      history.push(inertia);
      if (s.moved <= tol) {
        converged = true;
        iter++; // count this completed iteration
        break;
      }
    }
    // Final assignment pass so assignments/inertia match final centroids.
    const finalA = assign(points, centroids);
    return {
      centroids: centroids,
      assignments: finalA.assignments,
      inertia: finalA.inertia,
      counts: counts,
      iterations: iter,
      converged: converged,
      history: history,
    };
  }

  /*
   * Elbow sweep: run k-means for k = 1..kMax with a few restarts each,
   * keeping the best (lowest-inertia) run per k. Returns array of
   * { k, inertia }. Bounded by restarts and maxIter for performance.
   */
  function elbow(points, kMax, opts) {
    opts = opts || {};
    const restarts = opts.restarts == null ? 4 : opts.restarts;
    const baseSeed = opts.seed == null ? 1 : opts.seed;
    const maxIter = opts.maxIter == null ? 50 : opts.maxIter;
    const out = [];
    const limit = Math.min(kMax, points.length);
    for (let k = 1; k <= limit; k++) {
      let best = Infinity;
      for (let r = 0; r < restarts; r++) {
        const res = run(points, k, {
          method: 'kmeans++',
          seed: baseSeed + r * 7919 + k * 104729,
          maxIter: maxIter,
        });
        if (res.inertia < best) best = res.inertia;
      }
      out.push({ k: k, inertia: best });
    }
    return out;
  }

  const API = {
    mulberry32: mulberry32,
    dist: dist,
    dist2: dist2,
    seedRandom: seedRandom,
    seedKMeansPP: seedKMeansPP,
    initCentroids: initCentroids,
    assign: assign,
    update: update,
    step: step,
    silhouette: silhouette,
    run: run,
    elbow: elbow,
  };

  root.KMeans = API;
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = API;
  }
})(typeof window !== 'undefined' ? window : globalThis);
