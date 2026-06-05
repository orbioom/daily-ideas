/*
 * datasets.js — synthetic 2-D dataset generators for the Cluster visualizer.
 *
 * All datasets live in a normalized coordinate space [0, 1] x [0, 1] so the
 * renderer can map them to canvas pixels independently of point count.
 * Every generator is driven by a seeded PRNG (KMeans.mulberry32) so the same
 * seed reproduces the same point cloud across page loads.
 *
 * Generators provided:
 *   - blobs       : k isotropic Gaussian clusters (adjustable count & spread)
 *   - anisotropic : Gaussian blobs sheared by a linear transform (elongated)
 *   - moons       : two interleaving half-circles ("two moons") + noise
 *   - uniform     : uniform random points (no real cluster structure)
 *
 * Exposed as a global `Datasets` object.
 */
(function (root) {
  'use strict';

  const mulberry32 = root.KMeans.mulberry32;

  /* Box–Muller transform: two independent standard normals from two uniforms. */
  function gaussianPair(rng) {
    let u1 = rng();
    let u2 = rng();
    // Avoid log(0).
    if (u1 < 1e-12) u1 = 1e-12;
    const r = Math.sqrt(-2 * Math.log(u1));
    const theta = 2 * Math.PI * u2;
    return [r * Math.cos(theta), r * Math.sin(theta)];
  }

  /* Clamp a value into [0, 1]. */
  function clamp01(v) {
    return v < 0 ? 0 : v > 1 ? 1 : v;
  }

  /*
   * Gaussian blobs.
   *   n       : total number of points (split evenly across clusters)
   *   k       : number of cluster centres
   *   spread  : standard deviation of each blob (in normalized units)
   *   seed    : PRNG seed
   * Cluster centres are placed on a ring so they are well separated, then
   * each point is drawn from an isotropic Gaussian about its centre.
   */
  function blobs(n, k, spread, seed) {
    const rng = mulberry32(seed);
    const centers = [];
    const ringR = 0.32;
    for (let c = 0; c < k; c++) {
      // Centres on a circle plus a little jitter so they aren't perfectly regular.
      const ang = (2 * Math.PI * c) / k + rng() * 0.3;
      const rr = ringR * (0.85 + 0.3 * rng());
      centers.push([0.5 + rr * Math.cos(ang), 0.5 + rr * Math.sin(ang)]);
    }
    const pts = [];
    for (let i = 0; i < n; i++) {
      const c = i % k;
      const g = gaussianPair(rng);
      pts.push([
        clamp01(centers[c][0] + g[0] * spread),
        clamp01(centers[c][1] + g[1] * spread),
      ]);
    }
    return pts;
  }

  /*
   * Anisotropic blobs: like `blobs`, but each cluster's points are passed
   * through a per-cluster linear (shear + scale) transform, producing
   * elongated, tilted clusters that challenge isotropic k-means.
   */
  function anisotropic(n, k, spread, seed) {
    const rng = mulberry32(seed);
    const centers = [];
    const transforms = [];
    const ringR = 0.3;
    for (let c = 0; c < k; c++) {
      const ang = (2 * Math.PI * c) / k + rng() * 0.4;
      centers.push([0.5 + ringR * Math.cos(ang), 0.5 + ringR * Math.sin(ang)]);
      // Random rotation + anisotropic scaling matrix.
      const rot = rng() * Math.PI;
      const sx = 1.8 + rng() * 1.5;
      const sy = 0.35 + rng() * 0.25;
      const cos = Math.cos(rot);
      const sin = Math.sin(rot);
      // M = R * diag(sx, sy)
      transforms.push([cos * sx, -sin * sy, sin * sx, cos * sy]);
    }
    const pts = [];
    for (let i = 0; i < n; i++) {
      const c = i % k;
      const g = gaussianPair(rng);
      const m = transforms[c];
      const x = m[0] * g[0] + m[1] * g[1];
      const y = m[2] * g[0] + m[3] * g[1];
      pts.push([
        clamp01(centers[c][0] + x * spread),
        clamp01(centers[c][1] + y * spread),
      ]);
    }
    return pts;
  }

  /*
   * Two moons: two interleaving half-circles. The first moon is the upper
   * half of a circle; the second is the lower half, shifted right and down so
   * the two crescents interlock. Gaussian noise is added. This is a classic
   * example where k-means (which finds convex Voronoi cells) cannot recover
   * the true non-convex clusters — useful for teaching.
   */
  function moons(n, noise, seed) {
    const rng = mulberry32(seed);
    const pts = [];
    const half = Math.floor(n / 2);
    const R = 0.28;
    for (let i = 0; i < n; i++) {
      const upper = i < half;
      const t = rng() * Math.PI;
      let x, y;
      if (upper) {
        x = 0.38 + R * Math.cos(t);
        y = 0.58 - R * Math.sin(t);
      } else {
        x = 0.62 - R * Math.cos(t);
        y = 0.42 + R * Math.sin(t);
      }
      const g = gaussianPair(rng);
      pts.push([clamp01(x + g[0] * noise), clamp01(y + g[1] * noise)]);
    }
    return pts;
  }

  /*
   * Uniform random points across the whole space. No cluster structure;
   * useful to demonstrate that k-means will still impose k cells and that the
   * elbow/silhouette signal is weak when there is no real structure.
   */
  function uniform(n, seed) {
    const rng = mulberry32(seed);
    const pts = [];
    const margin = 0.06;
    const span = 1 - 2 * margin;
    for (let i = 0; i < n; i++) {
      pts.push([margin + rng() * span, margin + rng() * span]);
    }
    return pts;
  }

  /*
   * Dispatch by preset name. `params` carries n, k, spread, noise, seed as
   * relevant. Unknown presets fall back to blobs.
   */
  function generate(preset, params) {
    const p = params || {};
    const n = Math.max(1, p.n || 300);
    const seed = p.seed == null ? 1 : p.seed;
    switch (preset) {
      case 'blobs':
        return blobs(n, p.k || 3, p.spread == null ? 0.06 : p.spread, seed);
      case 'anisotropic':
        return anisotropic(n, p.k || 3, p.spread == null ? 0.05 : p.spread, seed);
      case 'moons':
        return moons(n, p.noise == null ? 0.03 : p.noise, seed);
      case 'uniform':
        return uniform(n, seed);
      default:
        return blobs(n, p.k || 3, p.spread == null ? 0.06 : p.spread, seed);
    }
  }

  root.Datasets = {
    blobs: blobs,
    anisotropic: anisotropic,
    moons: moons,
    uniform: uniform,
    generate: generate,
  };
})(typeof window !== 'undefined' ? window : globalThis);
