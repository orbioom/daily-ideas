/**
 * main.js — UI wiring, canvas renderer, export logic for "Smooth".
 *
 * Depends on: savgol.js, signals.js (loaded before this script)
 * No module system — uses global variables for file:// compatibility.
 */

"use strict";

(function () {

  /* ================================================================== */
  /* State                                                               */
  /* ================================================================== */
  var state = {
    sourceId:      "gaussian_peak",
    windowLength:  11,
    polyOrder:     3,
    derivOrder:    0,
    rawSignal:     null,   // Float64Array
    smoothed:      null,   // Float64Array
    derivative:    null,   // Float64Array or null
    xValues:       null,   // Float64Array
    signalMeta:    null,   // { name, unit, description }
    error:         null,   // string or null
    computeMs:     0,
    residualRMS:   0,
    noiseReduction:0,
    userText:      "",
    showDeriv:     false,
    checkResults:  null
  };

  /* ================================================================== */
  /* Debounce                                                            */
  /* ================================================================== */
  function debounce(fn, delay) {
    var timer;
    return function () {
      clearTimeout(timer);
      timer = setTimeout(fn, delay);
    };
  }

  /* ================================================================== */
  /* DOM refs (populated after DOMContentLoaded)                         */
  /* ================================================================== */
  var dom = {};

  /* ================================================================== */
  /* Compute pipeline                                                    */
  /* ================================================================== */
  function runCompute() {
    var err = SavGol.validate(state.windowLength, state.polyOrder, state.derivOrder, state.rawSignal ? state.rawSignal.length : undefined);
    if (err) {
      state.error = err;
      state.smoothed = null;
      state.derivative = null;
      updateUI();
      return;
    }
    if (!state.rawSignal || state.rawSignal.length === 0) {
      state.error = "No signal data loaded.";
      state.smoothed = null;
      updateUI();
      return;
    }

    state.error = null;
    var t0 = performance.now();

    // Smoothed signal (deriv=0)
    state.smoothed = SavGol.apply(state.rawSignal, state.windowLength, state.polyOrder, 0);

    // Derivative if requested
    if (state.derivOrder > 0) {
      state.derivative = SavGol.apply(state.rawSignal, state.windowLength, state.polyOrder, state.derivOrder);
    } else {
      state.derivative = null;
    }

    var t1 = performance.now();
    state.computeMs = t1 - t0;

    // Residual RMS
    var sumSq = 0;
    var n = state.rawSignal.length;
    for (var i = 0; i < n; i++) {
      var d = state.rawSignal[i] - state.smoothed[i];
      sumSq += d * d;
    }
    state.residualRMS = Math.sqrt(sumSq / n);

    // Noise reduction estimate = 1 - (smoothed std / raw std)
    var rawMean = 0, smMean = 0;
    for (var i = 0; i < n; i++) { rawMean += state.rawSignal[i]; smMean += state.smoothed[i]; }
    rawMean /= n; smMean /= n;
    var rawVar = 0, smVar = 0;
    for (var i = 0; i < n; i++) {
      rawVar += (state.rawSignal[i] - rawMean) * (state.rawSignal[i] - rawMean);
      smVar  += (state.smoothed[i]   - smMean)  * (state.smoothed[i]   - smMean);
    }
    var rawStd = Math.sqrt(rawVar / n);
    var smStd  = Math.sqrt(smVar  / n);
    state.noiseReduction = rawStd > 0 ? Math.max(0, 1 - state.residualRMS / rawStd) * 100 : 0;

    updateUI();
  }

  /* ================================================================== */
  /* Load signal source                                                  */
  /* ================================================================== */
  function loadSource(sourceId) {
    state.sourceId = sourceId;
    var src = null;
    for (var i = 0; i < Signals.SOURCES.length; i++) {
      if (Signals.SOURCES[i].id === sourceId) { src = Signals.SOURCES[i]; break; }
    }
    if (src) {
      var data = src.gen(256);
      state.rawSignal = data.y;
      state.xValues   = data.x;
      state.signalMeta = { name: data.name, unit: data.unit, description: data.description };
      state.error = null;
    }
    runCompute();
  }

  function loadUserData() {
    var text = dom.userDataInput.value;
    var result = Signals.parseUserData(text);
    if (result.error) {
      state.error = result.error;
      state.smoothed = null;
      state.rawSignal = null;
      updateUI();
      return;
    }
    state.rawSignal = result.y;
    state.xValues   = result.x;
    state.signalMeta = { name: result.name, unit: result.unit, description: result.description };
    state.error = null;
    runCompute();
  }

  /* ================================================================== */
  /* Canvas renderer                                                     */
  /* ================================================================== */
  var CHART = {
    paddingTop:    48,
    paddingBottom: 56,
    paddingLeft:   72,
    paddingRight:  60,
    axisColor:     "#565A70",
    gridColor:     "rgba(86,90,112,0.12)",
    rawColor:      "rgba(140,145,170,0.55)",
    smoothColor:   "#86C79A",
    derivColor:    "#5EF0B0",
    textColor:     "#1B1D2A",
    subTextColor:  "#565A70",
    fontUI:        "Manrope, system-ui, sans-serif",
    fontMono:      "JetBrains Mono, ui-monospace, monospace"
  };

  function niceTicks(min, max, targetCount) {
    if (min === max) { return [min]; }
    var range = max - min;
    var rawStep = range / targetCount;
    var mag = Math.pow(10, Math.floor(Math.log10(rawStep)));
    var candidates = [1, 2, 2.5, 5, 10];
    var step = mag * 10;
    for (var i = 0; i < candidates.length; i++) {
      var s = candidates[i] * mag;
      if (range / s <= targetCount + 1) { step = s; break; }
    }
    var start = Math.ceil(min / step) * step;
    var ticks = [];
    var v = start;
    while (v <= max + step * 0.001) {
      ticks.push(parseFloat(v.toPrecision(10)));
      v += step;
    }
    return ticks;
  }

  function formatTick(v) {
    if (Math.abs(v) === 0) return "0";
    if (Math.abs(v) >= 1000 || (Math.abs(v) < 0.01 && v !== 0)) {
      return v.toExponential(1);
    }
    // strip floating-point noise
    var s = v.toPrecision(6);
    return parseFloat(s).toString();
  }

  function drawChart(canvas, pixelRatio) {
    var ctx = canvas.getContext("2d");
    var W = canvas.width  / pixelRatio;
    var H = canvas.height / pixelRatio;

    ctx.save();
    ctx.scale(pixelRatio, pixelRatio);
    ctx.clearRect(0, 0, W, H);

    var C = CHART;
    var pl = C.paddingLeft, pr = C.paddingRight, pt = C.paddingTop, pb = C.paddingBottom;
    var chartW = W - pl - pr;
    var chartH = H - pt - pb;

    /* ---- Background ---- */
    ctx.fillStyle = "rgba(255,255,255,0)";
    ctx.fillRect(0, 0, W, H);

    /* ---- No-data state ---- */
    if (!state.rawSignal || !state.smoothed) {
      ctx.fillStyle = C.subTextColor;
      ctx.font = "14px " + C.fontUI;
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      var msg = state.error || "Load a signal to begin.";
      // Word-wrap
      var words = msg.split(" ");
      var lines = [], line = "";
      for (var wi = 0; wi < words.length; wi++) {
        var test = line + (line ? " " : "") + words[wi];
        if (ctx.measureText(test).width > chartW - 20) {
          if (line) lines.push(line);
          line = words[wi];
        } else {
          line = test;
        }
      }
      if (line) lines.push(line);
      var lineH = 22;
      var startY = H / 2 - (lines.length - 1) * lineH / 2;
      for (var li = 0; li < lines.length; li++) {
        ctx.fillText(lines[li], W / 2, startY + li * lineH);
      }
      ctx.restore();
      return;
    }

    var raw = state.rawSignal;
    var sm  = state.smoothed;
    var drv = state.derivative;
    var xs  = state.xValues;
    var N   = raw.length;

    /* ---- Data ranges ---- */
    var yMin = Infinity, yMax = -Infinity;
    for (var i = 0; i < N; i++) {
      if (raw[i] < yMin) yMin = raw[i];
      if (raw[i] > yMax) yMax = raw[i];
      if (sm[i]  < yMin) yMin = sm[i];
      if (sm[i]  > yMax) yMax = sm[i];
    }
    var yPad = (yMax - yMin) * 0.08 || 0.5;
    var yLo = yMin - yPad, yHi = yMax + yPad;

    var xMin = xs[0], xMax = xs[N - 1];
    if (xMin === xMax) { xMin -= 1; xMax += 1; }

    // Derivative panel: separate y-axis on right
    var dMin = 0, dMax = 0;
    if (drv) {
      for (var i = 0; i < N; i++) {
        if (drv[i] < dMin) dMin = drv[i];
        if (drv[i] > dMax) dMax = drv[i];
      }
      var dPad = (dMax - dMin) * 0.08 || 0.5;
      dMin -= dPad; dMax += dPad;
    }

    /* ---- Coordinate transforms ---- */
    function toCanvasX(x) { return pl + (x - xMin) / (xMax - xMin) * chartW; }
    function toCanvasY(y) { return pt + (1 - (y - yLo)  / (yHi - yLo))  * chartH; }
    function toCanvasD(d) {
      if (dMin === dMax) return pt + chartH / 2;
      return pt + (1 - (d - dMin) / (dMax - dMin)) * chartH;
    }

    /* ---- Grid ---- */
    ctx.strokeStyle = C.gridColor;
    ctx.lineWidth = 1;
    var yTicks = niceTicks(yLo, yHi, 6);
    for (var ti = 0; ti < yTicks.length; ti++) {
      var cy = toCanvasY(yTicks[ti]);
      if (cy < pt || cy > pt + chartH) continue;
      ctx.beginPath();
      ctx.moveTo(pl, cy);
      ctx.lineTo(pl + chartW, cy);
      ctx.stroke();
    }
    var xTicks = niceTicks(xMin, xMax, 8);
    for (var ti = 0; ti < xTicks.length; ti++) {
      var cx = toCanvasX(xTicks[ti]);
      if (cx < pl || cx > pl + chartW) continue;
      ctx.beginPath();
      ctx.moveTo(cx, pt);
      ctx.lineTo(cx, pt + chartH);
      ctx.stroke();
    }

    /* ---- Clip to chart area ---- */
    ctx.save();
    ctx.beginPath();
    ctx.rect(pl, pt, chartW, chartH);
    ctx.clip();

    /* ---- Raw signal ---- */
    ctx.beginPath();
    ctx.strokeStyle = C.rawColor;
    ctx.lineWidth = 1;
    for (var i = 0; i < N; i++) {
      var cx = toCanvasX(xs[i]);
      var cy = toCanvasY(raw[i]);
      if (i === 0) ctx.moveTo(cx, cy); else ctx.lineTo(cx, cy);
    }
    ctx.stroke();

    /* ---- Smoothed signal ---- */
    ctx.beginPath();
    ctx.strokeStyle = C.smoothColor;
    ctx.lineWidth = 2.5;
    ctx.lineJoin = "round";
    for (var i = 0; i < N; i++) {
      var cx = toCanvasX(xs[i]);
      var cy = toCanvasY(sm[i]);
      if (i === 0) ctx.moveTo(cx, cy); else ctx.lineTo(cx, cy);
    }
    ctx.stroke();

    /* ---- Derivative ---- */
    if (drv && dMin !== dMax) {
      ctx.beginPath();
      ctx.strokeStyle = C.derivColor;
      ctx.lineWidth = 1.8;
      ctx.setLineDash([6, 4]);
      for (var i = 0; i < N; i++) {
        var cx = toCanvasX(xs[i]);
        var cy = toCanvasD(drv[i]);
        if (i === 0) ctx.moveTo(cx, cy); else ctx.lineTo(cx, cy);
      }
      ctx.stroke();
      ctx.setLineDash([]);
    }

    ctx.restore(); // end clip

    /* ---- Axes ---- */
    ctx.strokeStyle = C.axisColor;
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(pl, pt);
    ctx.lineTo(pl, pt + chartH);
    ctx.lineTo(pl + chartW, pt + chartH);
    ctx.stroke();

    /* ---- Y tick labels ---- */
    ctx.fillStyle = C.subTextColor;
    ctx.font = "11px " + C.fontMono;
    ctx.textAlign = "right";
    ctx.textBaseline = "middle";
    for (var ti = 0; ti < yTicks.length; ti++) {
      var cy = toCanvasY(yTicks[ti]);
      if (cy < pt || cy > pt + chartH) continue;
      ctx.fillText(formatTick(yTicks[ti]), pl - 8, cy);
      ctx.beginPath();
      ctx.moveTo(pl - 4, cy);
      ctx.lineTo(pl, cy);
      ctx.stroke();
    }

    /* ---- X tick labels ---- */
    ctx.textAlign = "center";
    ctx.textBaseline = "top";
    for (var ti = 0; ti < xTicks.length; ti++) {
      var cx = toCanvasX(xTicks[ti]);
      if (cx < pl || cx > pl + chartW) continue;
      ctx.fillText(formatTick(xTicks[ti]), cx, pt + chartH + 8);
      ctx.beginPath();
      ctx.moveTo(cx, pt + chartH);
      ctx.lineTo(cx, pt + chartH + 4);
      ctx.stroke();
    }

    /* ---- Derivative right-axis labels ---- */
    if (drv && dMin !== dMax) {
      var dTicks = niceTicks(dMin, dMax, 5);
      ctx.fillStyle = C.derivColor;
      ctx.font = "10px " + C.fontMono;
      ctx.textAlign = "left";
      ctx.textBaseline = "middle";
      for (var ti = 0; ti < dTicks.length; ti++) {
        var cy = toCanvasD(dTicks[ti]);
        if (cy < pt || cy > pt + chartH) continue;
        ctx.fillText(formatTick(dTicks[ti]), pl + chartW + 6, cy);
      }
      // Right-axis label
      ctx.save();
      ctx.translate(W - 12, pt + chartH / 2);
      ctx.rotate(-Math.PI / 2);
      ctx.textAlign = "center";
      ctx.font = "10px " + C.fontUI;
      ctx.fillText("derivative", 0, 0);
      ctx.restore();
    }

    /* ---- Y-axis label ---- */
    ctx.save();
    ctx.fillStyle = C.subTextColor;
    ctx.font = "12px " + C.fontUI;
    ctx.translate(16, pt + chartH / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.textAlign = "center";
    var unitLabel = state.signalMeta ? state.signalMeta.unit : "value";
    ctx.fillText("Signal (" + unitLabel + ")", 0, 0);
    ctx.restore();

    /* ---- X-axis label ---- */
    ctx.fillStyle = C.subTextColor;
    ctx.font = "12px " + C.fontUI;
    ctx.textAlign = "center";
    ctx.textBaseline = "bottom";
    ctx.fillText("Sample index", pl + chartW / 2, H - 6);

    /* ---- Title ---- */
    ctx.fillStyle = C.textColor;
    ctx.font = "bold 13px " + C.fontUI;
    ctx.textAlign = "left";
    ctx.textBaseline = "top";
    var titleStr = state.signalMeta ? state.signalMeta.name : "Signal";
    ctx.fillText(titleStr, pl, 12);

    /* ---- Legend ---- */
    var lx = pl + chartW - 10;
    var ly = pt + 10;
    var legendItems = [
      { color: C.rawColor,    label: "Raw (noisy)", dash: [] },
      { color: C.smoothColor, label: "SG Smoothed",  dash: [] }
    ];
    if (drv) {
      var dLabel = "SG " + (state.derivOrder === 1 ? "1st" : "2nd") + " Derivative";
      legendItems.push({ color: C.derivColor, label: dLabel, dash: [6, 4] });
    }
    ctx.font = "11px " + C.fontUI;
    ctx.textAlign = "right";
    ctx.textBaseline = "middle";
    for (var li = legendItems.length - 1; li >= 0; li--) {
      var item = legendItems[li];
      var textW = ctx.measureText(item.label).width;
      ctx.fillStyle = "rgba(255,255,255,0.75)";
      ctx.fillRect(lx - textW - 34, ly - 8, textW + 40, 18);
      ctx.strokeStyle = item.color;
      ctx.lineWidth = 2;
      if (item.dash.length) ctx.setLineDash(item.dash); else ctx.setLineDash([]);
      ctx.beginPath();
      ctx.moveTo(lx - textW - 28, ly);
      ctx.lineTo(lx - textW - 10, ly);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.fillStyle = C.subTextColor;
      ctx.fillText(item.label, lx, ly);
      ly += 22;
    }

    ctx.restore();
  }

  /* ================================================================== */
  /* Resize handling                                                     */
  /* ================================================================== */
  var canvas, pixelRatio;

  function resizeCanvas() {
    var container = dom.chartContainer;
    var w = container.clientWidth;
    var h = Math.max(340, Math.min(520, window.innerHeight * 0.48));
    pixelRatio = window.devicePixelRatio || 1;
    canvas.width  = w * pixelRatio;
    canvas.height = h * pixelRatio;
    canvas.style.width  = w + "px";
    canvas.style.height = h + "px";
    drawChart(canvas, pixelRatio);
  }

  var debouncedResize = debounce(resizeCanvas, 120);
  var debouncedCompute = debounce(runCompute, 80);

  /* ================================================================== */
  /* Update UI                                                           */
  /* ================================================================== */
  function updateUI() {
    // Error banner
    if (state.error) {
      dom.errorBanner.textContent = state.error;
      dom.errorBanner.style.display = "block";
    } else {
      dom.errorBanner.style.display = "none";
    }

    // Metrics
    dom.metricWindow.textContent  = state.windowLength;
    dom.metricOrder.textContent   = state.polyOrder;
    dom.metricDeriv.textContent   = state.derivOrder;
    dom.metricRMS.textContent     = state.smoothed ? state.residualRMS.toFixed(5) : "—";
    dom.metricNR.textContent      = state.smoothed ? state.noiseReduction.toFixed(1) + "%" : "—";
    dom.metricTime.textContent    = state.computeMs.toFixed(2) + " ms";
    dom.metricPoints.textContent  = state.rawSignal ? state.rawSignal.length : 0;

    // Sync controls to state (avoids drift)
    dom.windowSlider.value  = state.windowLength;
    dom.windowSlider.setAttribute("aria-valuenow", state.windowLength);
    dom.windowNumber.value  = state.windowLength;
    if (dom.windowDisplay) dom.windowDisplay.textContent = state.windowLength;
    dom.orderSelect.value   = state.polyOrder;
    dom.derivSelect.value   = state.derivOrder;
    dom.sourceSelect.value  = state.sourceId;

    // Redraw
    resizeCanvas();
  }

  /* ================================================================== */
  /* Export functions                                                    */
  /* ================================================================== */
  function exportPNG() {
    if (!canvas) return;
    // Render at 2× for export
    var expCanvas = document.createElement("canvas");
    var expPR = 2;
    expCanvas.width  = canvas.width  / pixelRatio * expPR;
    expCanvas.height = canvas.height / pixelRatio * expPR;
    // White background
    var ectx = expCanvas.getContext("2d");
    ectx.fillStyle = "#EDEEF3";
    ectx.fillRect(0, 0, expCanvas.width, expCanvas.height);
    // Draw at export ratio
    var old = { width: canvas.width, height: canvas.height };
    canvas.width  = expCanvas.width;
    canvas.height = expCanvas.height;
    canvas.style.width  = (expCanvas.width / expPR) + "px";
    canvas.style.height = (expCanvas.height / expPR) + "px";
    drawChart(canvas, expPR);
    // Copy to expCanvas
    ectx.drawImage(canvas, 0, 0);
    // Restore
    canvas.width  = old.width;
    canvas.height = old.height;
    resizeCanvas();

    expCanvas.toBlob(function (blob) {
      var url = URL.createObjectURL(blob);
      var a   = document.createElement("a");
      a.href  = url;
      a.download = "smooth-sg-" + Date.now() + ".png";
      a.click();
      setTimeout(function () { URL.revokeObjectURL(url); }, 5000);
    });
  }

  function exportCSV() {
    if (!state.rawSignal || !state.smoothed) return;
    var N = state.rawSignal.length;
    var lines = ["x,raw,smoothed,derivative"];
    for (var i = 0; i < N; i++) {
      var row = [
        state.xValues[i].toFixed(6),
        state.rawSignal[i].toFixed(8),
        state.smoothed[i].toFixed(8),
        state.derivative ? state.derivative[i].toFixed(8) : ""
      ];
      lines.push(row.join(","));
    }
    var blob = new Blob([lines.join("\n")], { type: "text/csv" });
    var url  = URL.createObjectURL(blob);
    var a    = document.createElement("a");
    a.href   = url;
    a.download = "smooth-sg-" + Date.now() + ".csv";
    a.click();
    setTimeout(function () { URL.revokeObjectURL(url); }, 5000);
  }

  /* ================================================================== */
  /* Sanity check display                                                */
  /* ================================================================== */
  function renderChecks() {
    var results = SavGol.Checks.run();
    state.checkResults = results;
    var container = dom.checksContainer;
    container.innerHTML = "";
    for (var i = 0; i < results.details.length; i++) {
      var r = results.details[i];
      var row = document.createElement("div");
      row.className = "check-row " + (r.pass ? "check-pass" : "check-fail");
      var icon = document.createElement("span");
      icon.className = "check-icon";
      icon.setAttribute("aria-label", r.pass ? "pass" : "fail");
      icon.textContent = r.pass ? "✓" : "✗";
      var text = document.createElement("span");
      text.className = "check-label";
      text.textContent = r.label;
      var detail = document.createElement("span");
      detail.className = "check-detail";
      detail.textContent = r.detail;
      row.appendChild(icon);
      row.appendChild(text);
      row.appendChild(detail);
      container.appendChild(row);
    }
    dom.checksStatus.textContent = results.pass ? "All checks pass." : "Some checks failed — see details.";
    dom.checksStatus.className   = results.pass ? "checks-status pass" : "checks-status fail";
  }

  /* ================================================================== */
  /* Window-length utilities                                             */
  /* ================================================================== */
  function enforceOdd(val) {
    val = parseInt(val, 10);
    if (isNaN(val)) return state.windowLength;
    if (val < 3) val = 3;
    if (val % 2 === 0) val += 1;
    return val;
  }

  /* ================================================================== */
  /* Init                                                                */
  /* ================================================================== */
  function init() {
    /* -- gather DOM refs -- */
    canvas           = document.getElementById("chart-canvas");
    dom.chartContainer = document.getElementById("chart-container");
    dom.errorBanner  = document.getElementById("error-banner");
    dom.windowSlider = document.getElementById("ctrl-window-slider");
    dom.windowNumber = document.getElementById("ctrl-window-number");
    dom.orderSelect  = document.getElementById("ctrl-order");
    dom.derivSelect  = document.getElementById("ctrl-deriv");
    dom.sourceSelect = document.getElementById("ctrl-source");
    dom.userDataInput    = document.getElementById("user-data-input");
    dom.loadUserDataBtn  = document.getElementById("load-user-data");
    dom.exportPNGBtn     = document.getElementById("export-png");
    dom.exportCSVBtn     = document.getElementById("export-csv");
    dom.metricWindow  = document.getElementById("metric-window");
    dom.metricOrder   = document.getElementById("metric-order");
    dom.metricDeriv   = document.getElementById("metric-deriv");
    dom.metricRMS     = document.getElementById("metric-rms");
    dom.metricNR      = document.getElementById("metric-nr");
    dom.metricTime    = document.getElementById("metric-time");
    dom.metricPoints  = document.getElementById("metric-points");
    dom.checksContainer = document.getElementById("sanity-checks");
    dom.checksStatus    = document.getElementById("checks-status");
    dom.runChecksBtn    = document.getElementById("run-checks");
    dom.windowDisplay   = document.getElementById("ctrl-window-display");

    /* -- window slider sync -- */
    dom.windowSlider.addEventListener("input", function () {
      var v = enforceOdd(this.value);
      state.windowLength = v;
      dom.windowNumber.value = v;
      debouncedCompute();
    });
    dom.windowNumber.addEventListener("change", function () {
      var v = enforceOdd(this.value);
      state.windowLength = v;
      dom.windowSlider.value = v;
      debouncedCompute();
    });
    dom.windowNumber.addEventListener("input", function () {
      var v = enforceOdd(this.value);
      state.windowLength = v;
      dom.windowSlider.value = v;
      debouncedCompute();
    });

    /* -- order -- */
    dom.orderSelect.addEventListener("change", function () {
      state.polyOrder = parseInt(this.value, 10);
      debouncedCompute();
    });

    /* -- derivative -- */
    dom.derivSelect.addEventListener("change", function () {
      state.derivOrder = parseInt(this.value, 10);
      debouncedCompute();
    });

    /* -- source -- */
    dom.sourceSelect.addEventListener("change", function () {
      loadSource(this.value);
    });

    /* -- user data -- */
    dom.loadUserDataBtn.addEventListener("click", function () {
      loadUserData();
    });
    dom.userDataInput.addEventListener("keydown", function (e) {
      if ((e.ctrlKey || e.metaKey) && e.key === "Enter") loadUserData();
    });

    /* -- export -- */
    dom.exportPNGBtn.addEventListener("click", exportPNG);
    dom.exportCSVBtn.addEventListener("click", exportCSV);

    /* -- sanity checks -- */
    dom.runChecksBtn.addEventListener("click", renderChecks);

    /* -- resize -- */
    window.addEventListener("resize", debouncedResize);

    /* -- initial load -- */
    loadSource("gaussian_peak");
    renderChecks();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }

})();
