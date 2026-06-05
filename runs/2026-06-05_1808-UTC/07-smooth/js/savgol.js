/**
 * savgol.js — Savitzky–Golay filter: coefficient computation and convolution.
 *
 * Reference:
 *   Savitzky, A.; Golay, M.J.E. "Smoothing and Differentiation of Data by
 *   Simplified Least Squares Procedures." Analytical Chemistry, 1964,
 *   36(8):1627–1639. DOI:10.1021/ac60214a047
 *
 * Algorithm:
 *   For a window of 2m+1 points centred at index 0 (indices −m…m), build the
 *   Vandermonde design matrix A of size (2m+1) × (p+1), where A[i,k] = i^k.
 *   The normal-equations solution gives the least-squares polynomial fit.
 *   The smoothed value (derivative order d=0) at the centre is the d-th row
 *   of (AᵀA)⁻¹Aᵀ dotted with the data window. For the d-th derivative the
 *   row is further scaled by d! (converting polynomial coefficient to value).
 *
 *   Gaussian elimination with partial pivoting solves the (p+1)×(p+1)
 *   normal-equations system — no external linear-algebra library.
 *
 * Edge policy:
 *   Asymmetric coefficients: for the first m and last m points, the full
 *   window of size (2m+1) is anchored at the signal boundary, and the
 *   polynomial is evaluated at the offset matching the point's actual position
 *   within that fixed window. This is the classical end-effect correction
 *   from Savitzky & Golay (1964) — exact polynomial fitting, not truncation
 *   or zero-padding.
 */

"use strict";

var SavGol = (function () {

  /* ------------------------------------------------------------------ */
  /* Gaussian elimination with partial pivoting                          */
  /* Solves A·x = b for x.  A is an n×n matrix stored as array of rows. */
  /* ------------------------------------------------------------------ */
  function gaussianElim(A, b) {
    var n = b.length;
    var M = [];
    for (var i = 0; i < n; i++) {
      M.push(A[i].slice());
      M[i].push(b[i]);
    }

    for (var col = 0; col < n; col++) {
      var maxRow = col;
      var maxVal = Math.abs(M[col][col]);
      for (var row = col + 1; row < n; row++) {
        if (Math.abs(M[row][col]) > maxVal) {
          maxVal = Math.abs(M[row][col]);
          maxRow = row;
        }
      }
      if (maxVal < 1e-14) throw new Error("Singular normal-equations matrix — check window/order constraints.");
      var tmp = M[col]; M[col] = M[maxRow]; M[maxRow] = tmp;

      for (var r = col + 1; r < n; r++) {
        var factor = M[r][col] / M[col][col];
        for (var c = col; c <= n; c++) {
          M[r][c] -= factor * M[col][c];
        }
      }
    }

    var x = new Array(n).fill(0);
    for (var i = n - 1; i >= 0; i--) {
      x[i] = M[i][n];
      for (var j = i + 1; j < n; j++) {
        x[i] -= M[i][j] * x[j];
      }
      x[i] /= M[i][i];
    }
    return x;
  }

  /* ------------------------------------------------------------------ */
  /* Compute convolution coefficients for a window of size (2m+1),       */
  /* polynomial order p, derivative order deriv, evaluation at evalOffset*/
  /* from window centre. Returns Float64Array of length (2m+1).          */
  /* ------------------------------------------------------------------ */
  function computeCoeffs(m, p, deriv, evalOffset) {
    if (evalOffset === undefined) evalOffset = 0;
    var winSize = 2 * m + 1;

    // Design matrix A: each row j corresponds to window point at x = (j - m)
    // A[j,k] = (j - m)^k
    var A = [];
    for (var j = 0; j < winSize; j++) {
      var row = [];
      var xj = j - m;
      var xpow = 1;
      for (var k = 0; k <= p; k++) {
        row.push(xpow);
        xpow *= xj;
      }
      A.push(row);
    }

    // AᵀA  (size (p+1)×(p+1))
    var AtA = [];
    for (var i = 0; i <= p; i++) {
      AtA.push(new Array(p + 1).fill(0));
    }
    for (var j = 0; j < winSize; j++) {
      for (var i = 0; i <= p; i++) {
        for (var k = 0; k <= p; k++) {
          AtA[i][k] += A[j][i] * A[j][k];
        }
      }
    }

    // Evaluation vector e at x0 = evalOffset
    // For d=0: e[k] = x0^k
    // For d>0: e[k] = (k!/(k-d)!) * x0^(k-d) for k>=d, else 0
    var x0 = evalOffset;
    var e = new Array(p + 1).fill(0);

    function fact(n) {
      var f = 1;
      for (var i = 2; i <= n; i++) f *= i;
      return f;
    }

    if (deriv === 0) {
      var xpow = 1;
      for (var k = 0; k <= p; k++) {
        e[k] = xpow;
        xpow *= x0;
      }
    } else {
      for (var k = 0; k <= p; k++) {
        if (k < deriv) { e[k] = 0; continue; }
        var rise = fact(k) / fact(k - deriv);
        var xpow2 = 1;
        for (var t = 0; t < k - deriv; t++) xpow2 *= x0;
        e[k] = rise * xpow2;
      }
    }

    // Solve (AᵀA) v = e
    var v = gaussianElim(AtA, e);

    // Weights w = A · v
    var w = new Float64Array(winSize);
    for (var j = 0; j < winSize; j++) {
      var sum = 0;
      for (var k = 0; k <= p; k++) {
        sum += A[j][k] * v[k];
      }
      w[j] = sum;
    }

    return w;
  }

  /* ------------------------------------------------------------------ */
  /* Apply SG filter to signal array.                                    */
  /* windowLength: odd integer > polyOrder+1 (validated externally)      */
  /* Returns Float64Array same length as signal.                         */
  /* ------------------------------------------------------------------ */
  function apply(signal, windowLength, polyOrder, deriv) {
    if (deriv === undefined) deriv = 0;
    var n = signal.length;
    var m = (windowLength - 1) / 2;
    var result = new Float64Array(n);

    // Pre-compute centred coefficients
    var wCentre = computeCoeffs(m, polyOrder, deriv, 0);

    // Cache for boundary asymmetric coefficients
    var coeffCache = {};

    for (var i = 0; i < n; i++) {
      var w;
      var winStart;
      var evalOffset;

      if (i < m) {
        // Left boundary: window anchored at signal start
        winStart = 0;
        evalOffset = i - m;
      } else if (i >= n - m) {
        // Right boundary: window anchored at signal end
        winStart = n - windowLength;
        evalOffset = i - (winStart + m);
      } else {
        winStart = i - m;
        evalOffset = 0;
      }

      if (evalOffset === 0) {
        w = wCentre;
      } else {
        var key = evalOffset;
        if (!coeffCache[key]) {
          coeffCache[key] = computeCoeffs(m, polyOrder, deriv, evalOffset);
        }
        w = coeffCache[key];
      }

      var val = 0;
      for (var j = 0; j < windowLength; j++) {
        val += w[j] * signal[winStart + j];
      }
      result[i] = val;
    }

    return result;
  }

  /* ------------------------------------------------------------------ */
  /* Validate parameters. Returns error string or null.                  */
  /* ------------------------------------------------------------------ */
  function validate(windowLength, polyOrder, deriv, signalLength) {
    if (!Number.isInteger(windowLength) || windowLength < 3) {
      return "Window length must be an integer ≥ 3.";
    }
    if (windowLength % 2 === 0) {
      return "Window length must be odd (current value " + windowLength + " is even). Try " + (windowLength + 1) + ".";
    }
    if (!Number.isInteger(polyOrder) || polyOrder < 0) {
      return "Polynomial order must be a non-negative integer.";
    }
    if (windowLength <= polyOrder + 1) {
      return "Window length (" + windowLength + ") must be ≥ polynomial order + 2 (" + (polyOrder + 2) + "). Increase window or decrease order.";
    }
    if (deriv < 0 || deriv > 2) {
      return "Derivative order must be 0, 1, or 2.";
    }
    if (deriv > polyOrder) {
      return "Derivative order (" + deriv + ") cannot exceed polynomial order (" + polyOrder + "). Increase polynomial order.";
    }
    if (signalLength !== undefined && windowLength > signalLength) {
      return "Window length (" + windowLength + ") exceeds signal length (" + signalLength + "). Use a shorter window.";
    }
    return null;
  }

  /* ------------------------------------------------------------------ */
  /* Sanity checks                                                        */
  /* ------------------------------------------------------------------ */
  var Checks = {
    run: function () {
      var results = [];
      var allPass = true;

      function check(label, pass, detail) {
        results.push({ label: label, pass: pass, detail: detail });
        if (!pass) allPass = false;
      }

      // 1. Smoothing coefficients sum to 1
      try {
        var w = computeCoeffs(2, 2, 0, 0);
        var s = 0;
        for (var i = 0; i < w.length; i++) s += w[i];
        check("Smoothing coefficients sum to 1 (window=5, p=2)", Math.abs(s - 1) < 1e-12,
          "sum = " + s.toFixed(15));
      } catch (ex) { check("Smoothing coefficients sum to 1", false, ex.message); }

      // 2. 1st derivative coefficients sum to 0
      try {
        var w2 = computeCoeffs(2, 2, 1, 0);
        var s2 = 0;
        for (var i = 0; i < w2.length; i++) s2 += w2[i];
        check("1st-deriv coefficients sum to 0 (window=5, p=2)", Math.abs(s2) < 1e-12,
          "sum = " + s2.toFixed(15));
      } catch (ex) { check("1st-deriv coefficients sum to 0", false, ex.message); }

      // 3. 2nd derivative coefficients sum to 0
      try {
        var w3 = computeCoeffs(3, 3, 2, 0);
        var s3 = 0;
        for (var i = 0; i < w3.length; i++) s3 += w3[i];
        check("2nd-deriv coefficients sum to 0 (window=7, p=3)", Math.abs(s3) < 1e-12,
          "sum = " + s3.toFixed(15));
      } catch (ex) { check("2nd-deriv coefficients sum to 0", false, ex.message); }

      // 4. SG p>=2 reproduces quadratic exactly
      try {
        var N = 50;
        var sig = new Float64Array(N);
        for (var i = 0; i < N; i++) sig[i] = 3 * i * i - 2 * i + 5;
        var smoothed = apply(sig, 7, 2, 0);
        var maxErr = 0;
        for (var i = 0; i < N; i++) maxErr = Math.max(maxErr, Math.abs(smoothed[i] - sig[i]));
        check("SG p=2 reproduces quadratic exactly (window=7, N=50)", maxErr < 1e-8,
          "max |error| = " + maxErr.toExponential(4));
      } catch (ex) { check("SG p=2 reproduces quadratic", false, ex.message); }

      // 5. SG p=3 reproduces cubic exactly
      try {
        var N2 = 60;
        var sig2 = new Float64Array(N2);
        for (var i = 0; i < N2; i++) sig2[i] = i * i * i - 4 * i * i + 2 * i - 7;
        var sm2 = apply(sig2, 9, 3, 0);
        var maxErr2 = 0;
        for (var i = 0; i < N2; i++) maxErr2 = Math.max(maxErr2, Math.abs(sm2[i] - sig2[i]));
        check("SG p=3 reproduces cubic exactly (window=9, N=60)", maxErr2 < 1e-7,
          "max |error| = " + maxErr2.toExponential(4));
      } catch (ex) { check("SG p=3 reproduces cubic", false, ex.message); }

      // 6. 1st derivative of linear signal = constant slope
      try {
        var N3 = 30;
        var sig3 = new Float64Array(N3);
        for (var i = 0; i < N3; i++) sig3[i] = 2.5 * i + 1;
        var d1 = apply(sig3, 5, 2, 1);
        var maxErrD = 0;
        for (var i = 0; i < N3; i++) maxErrD = Math.max(maxErrD, Math.abs(d1[i] - 2.5));
        check("1st deriv of linear (slope 2.5) = 2.5 everywhere (window=5, p=2)",
          maxErrD < 1e-10, "max |error| = " + maxErrD.toExponential(4));
      } catch (ex) { check("1st deriv of linear", false, ex.message); }

      return { pass: allPass, details: results };
    }
  };

  return {
    apply: apply,
    validate: validate,
    computeCoeffs: computeCoeffs,
    Checks: Checks,
    _gaussianElim: gaussianElim
  };

})();
