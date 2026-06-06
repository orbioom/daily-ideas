/*
 * Distill — UI wiring (main.js)
 *
 * Owns the DOM, the Web Worker lifecycle, and the export actions. All heavy
 * compute lives in the worker; this file only orchestrates and renders.
 */
'use strict';

(function () {
  // Cap input size so the UI never locks. PPM is ~quadratic-ish in constant
  // factors; ~512 KB of text compresses in well under a second on the worker.
  var MAX_BYTES = 512 * 1024;

  var els = {};
  var worker = null;
  var reqId = 0;
  var lastResult = null;     // last compress result (for export)
  var lastCompressed = null; // Uint8Array of last .distill bytes
  var lastInputBytes = null;

  var encoder = new TextEncoder();
  var decoder = new TextDecoder('utf-8');

  document.addEventListener('DOMContentLoaded', init);

  function init() {
    els.input = document.getElementById('input');
    els.compressBtn = document.getElementById('compressBtn');
    els.fileInput = document.getElementById('fileInput');
    els.distillUpload = document.getElementById('distillUpload');
    els.clearBtn = document.getElementById('clearBtn');
    els.status = document.getElementById('status');
    els.progress = document.getElementById('progress');
    els.progressBar = document.getElementById('progressBar');
    els.results = document.getElementById('results');
    els.verdict = document.getElementById('verdict');
    els.roundtrip = document.getElementById('roundtrip');
    els.exportDistill = document.getElementById('exportDistill');
    els.exportJson = document.getElementById('exportJson');
    els.byteInfo = document.getElementById('byteInfo');
    els.aboutToggle = document.getElementById('aboutToggle');
    els.about = document.getElementById('about');

    // metric cells
    els.mOrig = document.getElementById('m-orig');
    els.mDistill = document.getElementById('m-distill');
    els.mRatio = document.getElementById('m-ratio');
    els.mBpb = document.getElementById('m-bpb');
    els.mGzip = document.getElementById('m-gzip');
    els.mGzipRatio = document.getElementById('m-gzipratio');
    els.mTime = document.getElementById('m-time');

    spawnWorker();

    els.compressBtn.addEventListener('click', onCompress);
    els.fileInput.addEventListener('change', onFilePicked);
    els.distillUpload.addEventListener('change', onDistillPicked);
    els.clearBtn.addEventListener('click', onClear);
    els.exportDistill.addEventListener('click', onExportDistill);
    els.exportJson.addEventListener('click', onExportJson);
    els.input.addEventListener('input', onInputChanged);
    els.aboutToggle.addEventListener('click', toggleAbout);

    loadSample();
  }

  function spawnWorker() {
    worker = new Worker('js/worker.js');
    worker.onmessage = onWorkerMessage;
    worker.onerror = function (e) {
      setStatus('Worker error: ' + (e.message || 'unknown') + '. Reload to retry.', 'error');
      hideProgress();
    };
  }

  function loadSample() {
    setStatus('Loading sample prose…', 'busy');
    fetch('data/sample.txt')
      .then(function (r) {
        if (!r.ok) throw new Error('HTTP ' + r.status);
        return r.text();
      })
      .then(function (text) {
        els.input.value = text;
        onInputChanged();
        setStatus('Sample loaded. Compressing…', 'busy');
        onCompress();
      })
      .catch(function (err) {
        // Fetch can be blocked by file:// in some browsers; degrade gracefully.
        setStatus(
          'Could not auto-load the sample (' + err.message +
          '). Paste or type text and press Compress.', 'idle');
      });
  }

  function onInputChanged() {
    var bytes = encoder.encode(els.input.value);
    var n = bytes.length;
    if (n === 0) {
      els.byteInfo.textContent = 'No input yet.';
    } else if (n > MAX_BYTES) {
      els.byteInfo.textContent = n.toLocaleString() + ' bytes — will be capped to ' +
        MAX_BYTES.toLocaleString() + ' bytes for a responsive demo.';
    } else {
      els.byteInfo.textContent = n.toLocaleString() + ' bytes of UTF-8 input.';
    }
  }

  function currentInputBytes() {
    var bytes = encoder.encode(els.input.value);
    if (bytes.length > MAX_BYTES) {
      // Cap on a UTF-8 character boundary by re-decoding the truncated slice.
      var capped = bytes.subarray(0, MAX_BYTES);
      var safeText = new TextDecoder('utf-8', { fatal: false }).decode(capped);
      bytes = encoder.encode(safeText);
    }
    return bytes;
  }

  function onCompress() {
    var bytes = currentInputBytes();
    if (bytes.length === 0) {
      setStatus('Nothing to compress yet — type or paste some text, or load a .txt file.', 'idle');
      els.results.hidden = true;
      return;
    }
    lastInputBytes = bytes;
    els.compressBtn.disabled = true;
    showProgress();
    setStatus('Compressing ' + bytes.length.toLocaleString() + ' bytes off the main thread…', 'busy');
    var id = ++reqId;
    // Copy into a transferable buffer.
    var copy = bytes.slice();
    worker.postMessage({ type: 'compress', id: id, bytes: copy }, [copy.buffer]);
  }

  function onWorkerMessage(e) {
    var msg = e.data;
    if (msg.id !== reqId) return; // stale response from a superseded request
    if (msg.type === 'progress') {
      updateProgress(msg.phase, msg.value);
    } else if (msg.type === 'result') {
      if (msg.kind === 'compress') renderCompressResult(msg);
      else if (msg.kind === 'decompress') renderDecompressResult(msg);
    } else if (msg.type === 'error') {
      setStatus('Error: ' + msg.message, 'error');
      hideProgress();
      els.compressBtn.disabled = false;
    }
  }

  function renderCompressResult(msg) {
    hideProgress();
    els.compressBtn.disabled = false;
    lastCompressed = new Uint8Array(msg.compressed);

    var orig = msg.originalSize;
    var distill = msg.distillSize;
    var gzip = msg.gzipSize;
    var ratio = distill > 0 ? orig / distill : 0;
    var bpb = orig > 0 ? (distill * 8) / orig : 0;
    var gzipRatio = (gzip && gzip > 0) ? orig / gzip : null;

    lastResult = {
      originalSize: orig,
      distillSize: distill,
      distillRatio: ratio,
      bitsPerByte: bpb,
      gzipSize: gzip,
      gzipRatio: gzipRatio,
      compressMs: msg.compressMs,
      decompressMs: msg.decompressMs,
      gzipMs: msg.gzipMs,
      roundTrip: msg.roundTrip,
      order: 3,
      engine: 'Distill PPM order-3 + range coder',
      generatedAt: new Date().toISOString()
    };

    els.mOrig.textContent = fmt(orig) + ' B';
    els.mDistill.textContent = fmt(distill) + ' B';
    els.mRatio.textContent = ratio.toFixed(2) + '×';
    els.mBpb.textContent = bpb.toFixed(3);
    if (gzip != null) {
      els.mGzip.textContent = fmt(gzip) + ' B';
      els.mGzipRatio.textContent = gzipRatio.toFixed(2) + '×';
    } else {
      els.mGzip.textContent = 'n/a';
      els.mGzipRatio.textContent = '—';
    }
    els.mTime.textContent = msg.compressMs.toFixed(1) + ' ms';

    // Verdict (honest).
    var win = false;
    if (gzip != null) {
      if (distill < gzip) {
        var pct = ((gzip - distill) / gzip) * 100;
        els.verdict.textContent = 'Distill is ' + pct.toFixed(1) + '% smaller than gzip here.';
        win = true;
      } else if (distill > gzip) {
        var pct2 = ((distill - gzip) / gzip) * 100;
        els.verdict.textContent = 'gzip wins here by ' + pct2.toFixed(1) + '% — Distill shines on natural-language text, less so on tiny or already-dense data.';
      } else {
        els.verdict.textContent = 'Distill and gzip tie here.';
      }
    } else {
      els.verdict.textContent = 'gzip comparison unavailable in this browser (no CompressionStream).';
    }
    els.verdict.classList.toggle('win', win);

    // Round-trip badge.
    if (msg.roundTrip) {
      els.roundtrip.textContent = '✓ Round-trip verified — decompressed output is byte-for-byte identical to your input (' +
        fmt(orig) + ' bytes, in ' + msg.decompressMs.toFixed(1) + ' ms).';
      els.roundtrip.className = 'roundtrip ok';
    } else {
      els.roundtrip.textContent = '✗ Round-trip FAILED — output did not match input. Please report this input.';
      els.roundtrip.className = 'roundtrip fail';
    }

    els.results.hidden = false;
    var verdictText = win ? 'Distill beat gzip.' : 'Done.';
    setStatus('Compressed in ' + msg.compressMs.toFixed(1) + ' ms. ' + verdictText, 'idle');
    // Move focus to results for screen-reader users.
    els.results.setAttribute('tabindex', '-1');
  }

  function renderDecompressResult(msg) {
    hideProgress();
    els.compressBtn.disabled = false;
    var text;
    try {
      text = new TextDecoder('utf-8', { fatal: false }).decode(new Uint8Array(msg.restored));
    } catch (err) {
      text = '';
    }
    els.input.value = text;
    onInputChanged();
    setStatus('Decompressed .distill file → ' + fmt(msg.restoredSize) +
      ' bytes restored in ' + msg.decompressMs.toFixed(1) + ' ms. Press Compress to analyse it.', 'idle');
    els.results.hidden = true;
  }

  // ---- File handling ----
  function onFilePicked(e) {
    var file = e.target.files && e.target.files[0];
    if (!file) return;
    if (!/\.txt$/i.test(file.name) && file.type && file.type.indexOf('text') === -1) {
      setStatus('Please choose a plain-text (.txt) file. "' + file.name + '" does not look like text.', 'error');
      e.target.value = '';
      return;
    }
    var reader = new FileReader();
    reader.onload = function () {
      els.input.value = String(reader.result || '');
      onInputChanged();
      setStatus('Loaded "' + file.name + '". Compressing…', 'busy');
      onCompress();
    };
    reader.onerror = function () {
      setStatus('Could not read "' + file.name + '".', 'error');
    };
    reader.readAsText(file);
    e.target.value = '';
  }

  function onDistillPicked(e) {
    var file = e.target.files && e.target.files[0];
    if (!file) return;
    var reader = new FileReader();
    reader.onload = function () {
      var bytes = new Uint8Array(reader.result);
      if (bytes.length === 0) {
        setStatus('That .distill file is empty.', 'error');
        return;
      }
      showProgress();
      setStatus('Decompressing "' + file.name + '"…', 'busy');
      var id = ++reqId;
      var copy = bytes.slice();
      worker.postMessage({ type: 'decompress', id: id, bytes: copy }, [copy.buffer]);
    };
    reader.onerror = function () {
      setStatus('Could not read "' + file.name + '".', 'error');
    };
    reader.readAsArrayBuffer(file);
    e.target.value = '';
  }

  function onClear() {
    els.input.value = '';
    onInputChanged();
    els.results.hidden = true;
    lastResult = null;
    lastCompressed = null;
    setStatus('Cleared. Type or paste text, or load a .txt file, then press Compress.', 'idle');
    els.input.focus();
  }

  // ---- Export ----
  function onExportDistill() {
    if (!lastCompressed) { setStatus('Compress something first.', 'idle'); return; }
    downloadBlob(lastCompressed, 'distill-output.distill', 'application/octet-stream');
  }

  function onExportJson() {
    if (!lastResult) { setStatus('Compress something first.', 'idle'); return; }
    var json = JSON.stringify(lastResult, null, 2);
    downloadBlob(encoder.encode(json), 'distill-result.json', 'application/json');
  }

  function downloadBlob(bytes, name, mime) {
    var blob = new Blob([bytes], { type: mime });
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    a.download = name;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    setTimeout(function () { URL.revokeObjectURL(url); }, 2000);
  }

  // ---- About panel ----
  function toggleAbout() {
    var open = els.about.hidden;
    els.about.hidden = !open;
    els.aboutToggle.setAttribute('aria-expanded', String(open));
  }

  // ---- Progress + status ----
  function showProgress() {
    els.progress.hidden = false;
    els.progress.setAttribute('aria-busy', 'true');
    setBar(0);
  }
  function hideProgress() {
    els.progress.hidden = true;
    els.progress.setAttribute('aria-busy', 'false');
  }
  function updateProgress(phase, value) {
    // Map phases onto a single 0..100 bar: compress 0-60, verify 60-85, gzip 85-100.
    var base = 0, span = 1;
    if (phase === 'compress') { base = 0; span = 0.60; }
    else if (phase === 'verify') { base = 0.60; span = 0.25; }
    else if (phase === 'gzip') { base = 0.85; span = 0.15; }
    else if (phase === 'decompress') { base = 0; span = 1; }
    setBar((base + span * Math.max(0, Math.min(1, value))) * 100);
  }
  function setBar(pct) {
    els.progressBar.style.width = pct.toFixed(1) + '%';
    els.progress.setAttribute('aria-valuenow', String(Math.round(pct)));
  }

  function setStatus(text, kind) {
    els.status.textContent = text;
    els.status.dataset.kind = kind || 'idle';
  }

  function fmt(n) {
    return Number(n).toLocaleString();
  }
})();
