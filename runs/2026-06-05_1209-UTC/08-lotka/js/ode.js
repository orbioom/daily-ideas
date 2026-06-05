/*
 * ode.js — Lotka–Volterra predator–prey dynamics.
 *
 * Implements the classical Lotka (1925) / Volterra (1926) model and an
 * optional logistic-prey extension (carrying capacity K), integrated with a
 * hand-written classical 4th-order Runge–Kutta (RK4) scheme. No libraries.
 *
 * This module is deliberately free of DOM / UI references so it can be tested
 * in isolation (e.g. node) or reused.
 *
 * State vector s = [x, y] where x = prey population, y = predator population.
 *
 * Classic model:
 *   dx/dt = alpha*x - beta*x*y
 *   dy/dt = delta*x*y - gamma*y
 *
 * Logistic-prey extension (when logistic === true, K > 0):
 *   dx/dt = alpha*x*(1 - x/K) - beta*x*y
 *   dy/dt = delta*x*y - gamma*y
 */

(function (global) {
  'use strict';

  // Hard upper bound on integration steps to keep the UI responsive and to
  // make runaway loops impossible. T/dt is clamped to this.
  var MAX_STEPS = 200000;

  /**
   * Evaluate the Lotka–Volterra vector field at state s for parameters p.
   * Returns [dx/dt, dy/dt]. Pure function, no allocation beyond the result.
   *
   * @param {number[]} s  state [x, y]
   * @param {Object} p    {alpha, beta, gamma, delta, logistic, K}
   * @returns {number[]}  derivative [dx, dy]
   */
  function vectorField(s, p) {
    var x = s[0];
    var y = s[1];
    var prey;
    if (p.logistic && p.K > 0) {
      prey = p.alpha * x * (1 - x / p.K) - p.beta * x * y;
    } else {
      prey = p.alpha * x - p.beta * x * y;
    }
    var pred = p.delta * x * y - p.gamma * y;
    return [prey, pred];
  }

  /**
   * One RK4 step of size h from state s.
   * Classical four-stage Runge–Kutta:
   *   k1 = f(s)
   *   k2 = f(s + h/2 * k1)
   *   k3 = f(s + h/2 * k2)
   *   k4 = f(s + h   * k3)
   *   s_next = s + h/6 * (k1 + 2 k2 + 2 k3 + k4)
   *
   * @param {number[]} s  state [x, y]
   * @param {number} h    step size
   * @param {Object} p    parameters
   * @returns {number[]}  next state [x, y]
   */
  function rk4Step(s, h, p) {
    var k1 = vectorField(s, p);
    var s2 = [s[0] + 0.5 * h * k1[0], s[1] + 0.5 * h * k1[1]];
    var k2 = vectorField(s2, p);
    var s3 = [s[0] + 0.5 * h * k2[0], s[1] + 0.5 * h * k2[1]];
    var k3 = vectorField(s3, p);
    var s4 = [s[0] + h * k3[0], s[1] + h * k3[1]];
    var k4 = vectorField(s4, p);
    var nx = s[0] + (h / 6) * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]);
    var ny = s[1] + (h / 6) * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]);
    return [nx, ny];
  }

  /**
   * The conserved quantity for the *classic* (non-logistic) model:
   *   V = delta*x - gamma*ln(x) + beta*y - alpha*ln(y)
   * V is invariant along exact trajectories; tracking its drift is a
   * numerical-quality check. Returns NaN when x<=0 or y<=0 (ln undefined).
   *
   * @param {number} x
   * @param {number} y
   * @param {Object} p
   * @returns {number} V or NaN
   */
  function conservedQuantity(x, y, p) {
    if (!(x > 0) || !(y > 0)) return NaN;
    return p.delta * x - p.gamma * Math.log(x) + p.beta * y - p.alpha * Math.log(y);
  }

  /**
   * The non-trivial (coexistence) equilibrium of the classic model:
   *   x* = gamma/delta, y* = alpha/beta.
   * Returns null when delta or beta is zero.
   *
   * @param {Object} p
   * @returns {{x:number,y:number}|null}
   */
  function equilibrium(p) {
    if (p.delta === 0 || p.beta === 0) return null;
    return { x: p.gamma / p.delta, y: p.alpha / p.beta };
  }

  /**
   * Validate & clamp a parameter / control set. Never throws.
   * Returns {params, ctrl, warnings:[], steps}.
   *
   * @param {Object} raw  arbitrary user values
   * @returns {Object}
   */
  function sanitize(raw) {
    var warnings = [];

    function num(v, fallback) {
      var n = Number(v);
      return isFinite(n) ? n : fallback;
    }

    var p = {
      alpha: num(raw.alpha, 1.0),
      beta: num(raw.beta, 0.1),
      gamma: num(raw.gamma, 1.5),
      delta: num(raw.delta, 0.075),
      logistic: !!raw.logistic,
      K: num(raw.K, 50)
    };

    var x0 = num(raw.x0, 10);
    var y0 = num(raw.y0, 5);
    var T = num(raw.T, 50);
    var dt = num(raw.dt, 0.01);

    // Non-negative rates / populations.
    ['alpha', 'beta', 'gamma', 'delta'].forEach(function (k) {
      if (p[k] < 0) {
        warnings.push('Rate ' + k + ' was negative; clamped to 0.');
        p[k] = 0;
      }
    });
    if (p.logistic && !(p.K > 0)) {
      warnings.push('Carrying capacity K must be > 0; set to 50.');
      p.K = 50;
    }

    if (x0 < 0) { warnings.push('Initial prey x0 was negative; clamped to 0.'); x0 = 0; }
    if (y0 < 0) { warnings.push('Initial predator y0 was negative; clamped to 0.'); y0 = 0; }

    if (!(dt > 0)) {
      warnings.push('Step dt must be > 0; reset to 0.01.');
      dt = 0.01;
    }
    if (!(T > 0)) {
      warnings.push('Total time T must be > 0; reset to 50.');
      T = 50;
    }

    // Cap total steps. If too many, grow dt to fit MAX_STEPS.
    var steps = Math.floor(T / dt);
    if (steps > MAX_STEPS) {
      var newDt = T / MAX_STEPS;
      warnings.push(
        'T/dt requested ' + steps.toLocaleString() + ' steps (cap ' +
        MAX_STEPS.toLocaleString() + '); dt increased to ' + newDt.toPrecision(3) + '.'
      );
      dt = newDt;
      steps = MAX_STEPS;
    }
    if (steps < 1) steps = 1;

    return {
      params: p,
      ctrl: { x0: x0, y0: y0, T: T, dt: dt },
      warnings: warnings,
      steps: steps
    };
  }

  /**
   * Integrate the system. Produces parallel typed arrays for t, prey, pred,
   * plus the conserved quantity series (classic model only).
   * Detects non-finite blow-ups and stops early gracefully.
   *
   * @param {Object} clean  output of sanitize()
   * @returns {Object} {t, prey, pred, V, n, blewUp}
   */
  function integrate(clean) {
    var p = clean.params;
    var c = clean.ctrl;
    var n = clean.steps + 1; // include t=0 sample

    var t = new Float64Array(n);
    var prey = new Float64Array(n);
    var pred = new Float64Array(n);
    var V = new Float64Array(n);

    var s = [c.x0, c.y0];
    var blewUp = false;
    var i = 0;

    t[0] = 0;
    prey[0] = s[0];
    pred[0] = s[1];
    V[0] = clean.params.logistic ? NaN : conservedQuantity(s[0], s[1], p);

    for (i = 1; i < n; i++) {
      s = rk4Step(s, c.dt, p);

      // Populations cannot be negative physically; clamp tiny negatives that
      // can appear near extinction from floating point.
      if (s[0] < 0) s[0] = 0;
      if (s[1] < 0) s[1] = 0;

      if (!isFinite(s[0]) || !isFinite(s[1])) {
        blewUp = true;
        break;
      }

      t[i] = i * c.dt;
      prey[i] = s[0];
      pred[i] = s[1];
      V[i] = p.logistic ? NaN : conservedQuantity(s[0], s[1], p);
    }

    var got = blewUp ? i : n;

    return {
      t: t.subarray(0, got),
      prey: prey.subarray(0, got),
      pred: pred.subarray(0, got),
      V: V.subarray(0, got),
      n: got,
      blewUp: blewUp
    };
  }

  /**
   * Estimate the oscillation period from the prey series by locating interior
   * local maxima and averaging the spacing between successive peaks.
   * Returns NaN if fewer than two peaks are found.
   *
   * @param {Float64Array|number[]} t
   * @param {Float64Array|number[]} prey
   * @returns {number} period estimate or NaN
   */
  function estimatePeriod(t, prey) {
    var peaks = [];
    for (var i = 1; i < prey.length - 1; i++) {
      if (prey[i] > prey[i - 1] && prey[i] >= prey[i + 1]) {
        peaks.push(t[i]);
      }
    }
    if (peaks.length < 2) return NaN;
    var sum = 0;
    for (var j = 1; j < peaks.length; j++) sum += peaks[j] - peaks[j - 1];
    return sum / (peaks.length - 1);
  }

  /**
   * Min/max of a numeric series.
   * @param {Float64Array|number[]} arr
   * @returns {{min:number,max:number}}
   */
  function range(arr) {
    var mn = Infinity, mx = -Infinity;
    for (var i = 0; i < arr.length; i++) {
      var v = arr[i];
      if (v < mn) mn = v;
      if (v > mx) mx = v;
    }
    if (!isFinite(mn)) mn = 0;
    if (!isFinite(mx)) mx = 0;
    return { min: mn, max: mx };
  }

  var api = {
    MAX_STEPS: MAX_STEPS,
    vectorField: vectorField,
    rk4Step: rk4Step,
    conservedQuantity: conservedQuantity,
    equilibrium: equilibrium,
    sanitize: sanitize,
    integrate: integrate,
    estimatePeriod: estimatePeriod,
    range: range
  };

  // Expose for browser (window.Lotka) and CommonJS (node tests).
  global.Lotka = api;
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
  }
})(typeof window !== 'undefined' ? window : this);
