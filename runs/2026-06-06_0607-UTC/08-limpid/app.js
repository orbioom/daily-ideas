/*
 * app.js — Limpid editor + UI wiring.
 *
 * Connects the pure analysis engine (analysis.js), persistence (storage.js),
 * and seed data (seed.js) to the DOM. Implements the overlay-highlight
 * editor, live debounced analysis, document CRUD, settings, export, and
 * accessible modals.
 */
(function () {
  'use strict';

  var A = window.LimpidAnalysis;
  var Store = window.LimpidStorage;
  var Seed = window.LimpidSeed;

  // ---- State ----
  var state = {
    docs: [],
    activeId: null,
    settings: Store.loadSettings(),
    lastAnalysis: null
  };

  // Cap analysis work on pathological input to avoid freezing the UI.
  var MAX_ANALYZE_CHARS = 200000;

  // ---- Element refs ----
  var $ = function (id) { return document.getElementById(id); };
  var editor = $('editor');
  var highlightLayer = $('highlight-layer');
  var emptyState = $('empty-state');
  var docList = $('doc-list');
  var docTitle = $('doc-title');
  var toastEl = $('toast');

  // ---- Utilities ----
  function escapeHtml(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function debounce(fn, ms) {
    var t = null;
    return function () {
      var args = arguments, self = this;
      clearTimeout(t);
      t = setTimeout(function () { fn.apply(self, args); }, ms);
    };
  }

  var toastTimer = null;
  function toast(msg) {
    toastEl.textContent = msg;
    toastEl.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toastEl.hidden = true; }, 2400);
  }

  function fmt(n, digits) {
    if (n == null || isNaN(n)) return '—';
    return Number(n).toFixed(digits == null ? 1 : digits);
  }

  // ---- Document helpers ----
  function activeDoc() {
    for (var i = 0; i < state.docs.length; i++) {
      if (state.docs[i].id === state.activeId) return state.docs[i];
    }
    return null;
  }

  function persistDocs() { Store.saveDocuments(state.docs); }

  function setActive(id) {
    state.activeId = id;
    Store.setActiveId(id);
    var doc = activeDoc();
    if (doc) {
      editor.value = doc.content;
      docTitle.value = doc.title;
    }
    renderDocList();
    runAnalysis();
    updateEmptyState();
  }

  // ---- Empty state ----
  function updateEmptyState() {
    var hasText = editor.value.trim().length > 0;
    emptyState.hidden = hasText;
  }

  // ---- Rendering: document list ----
  function renderDocList() {
    docList.innerHTML = '';
    if (state.docs.length === 0) {
      var li = document.createElement('li');
      li.className = 'hardest-empty';
      li.style.padding = '8px 10px';
      li.textContent = 'No documents yet.';
      docList.appendChild(li);
      return;
    }
    state.docs.forEach(function (doc) {
      var li = document.createElement('li');
      li.className = 'doc-item' + (doc.id === state.activeId ? ' active' : '');
      li.setAttribute('role', 'option');
      li.setAttribute('aria-selected', doc.id === state.activeId ? 'true' : 'false');
      li.tabIndex = 0;

      var name = document.createElement('span');
      name.className = 'doc-item-name';
      name.textContent = doc.title || 'Untitled';

      var actions = document.createElement('span');
      actions.className = 'doc-item-actions';

      var renameBtn = document.createElement('button');
      renameBtn.className = 'doc-mini-btn';
      renameBtn.title = 'Rename';
      renameBtn.setAttribute('aria-label', 'Rename ' + (doc.title || 'document'));
      renameBtn.textContent = '✎';
      renameBtn.addEventListener('click', function (e) { e.stopPropagation(); renameDoc(doc.id); });

      var delBtn = document.createElement('button');
      delBtn.className = 'doc-mini-btn';
      delBtn.title = 'Delete';
      delBtn.setAttribute('aria-label', 'Delete ' + (doc.title || 'document'));
      delBtn.textContent = '🗑';
      delBtn.addEventListener('click', function (e) { e.stopPropagation(); deleteDoc(doc.id); });

      actions.appendChild(renameBtn);
      actions.appendChild(delBtn);

      li.appendChild(name);
      li.appendChild(actions);

      li.addEventListener('click', function () { if (doc.id !== state.activeId) setActive(doc.id); });
      li.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); setActive(doc.id); }
      });

      docList.appendChild(li);
    });
  }

  // ---- Document CRUD ----
  function newDoc() {
    var doc = Store.createDocument('Untitled', '');
    state.docs.unshift(doc);
    persistDocs();
    setActive(doc.id);
    docTitle.focus();
    docTitle.select();
  }

  function renameDoc(id) {
    var doc = null;
    for (var i = 0; i < state.docs.length; i++) if (state.docs[i].id === id) doc = state.docs[i];
    if (!doc) return;
    openConfirm({
      title: 'Rename document',
      message: 'Enter a new name for this document.',
      input: doc.title,
      okLabel: 'Rename',
      onOk: function (value) {
        doc.title = (value || '').trim() || 'Untitled';
        doc.updatedAt = Date.now();
        if (doc.id === state.activeId) docTitle.value = doc.title;
        persistDocs();
        renderDocList();
        toast('Renamed');
      }
    });
  }

  function deleteDoc(id) {
    var doc = null, idx = -1;
    for (var i = 0; i < state.docs.length; i++) if (state.docs[i].id === id) { doc = state.docs[i]; idx = i; }
    if (!doc) return;
    openConfirm({
      title: 'Delete document',
      message: 'Delete “' + (doc.title || 'Untitled') + '”? This cannot be undone.',
      okLabel: 'Delete',
      onOk: function () {
        state.docs.splice(idx, 1);
        persistDocs();
        if (state.activeId === id) {
          if (state.docs.length > 0) {
            setActive(state.docs[0].id);
          } else {
            state.activeId = null;
            Store.setActiveId('');
            editor.value = '';
            docTitle.value = '';
            renderDocList();
            runAnalysis();
            updateEmptyState();
          }
        } else {
          renderDocList();
        }
        toast('Deleted');
      }
    });
  }

  // ---- Editor input handling ----
  function onEditorInput() {
    var doc = activeDoc();
    if (!doc) {
      // Create a document on first keystroke so content persists.
      doc = Store.createDocument('Untitled', editor.value);
      state.docs.unshift(doc);
      state.activeId = doc.id;
      Store.setActiveId(doc.id);
      docTitle.value = doc.title;
      renderDocList();
    } else {
      doc.content = editor.value;
      doc.updatedAt = Date.now();
    }
    persistDocs();
    updateEmptyState();
    syncScroll();
    scheduleAnalysis();
  }

  function onTitleInput() {
    var doc = activeDoc();
    if (!doc) return;
    doc.title = docTitle.value.trim() || 'Untitled';
    doc.updatedAt = Date.now();
    persistDocs();
    renderDocList();
  }

  // ---- Highlight rendering (overlay technique) ----
  function buildHighlightHtml(text, highlights, settings) {
    // Collect active spans, then paint by walking the text and wrapping
    // non-overlapping segments. When spans overlap, the first active type by
    // priority wins for the overlapping region (kept simple + accurate).
    var active = [];
    var order = ['long', 'passive', 'filler', 'adverb', 'complex'];
    order.forEach(function (type) {
      if (settings.highlights[type] && highlights[type]) {
        highlights[type].forEach(function (sp) {
          active.push({ start: sp.start, end: sp.end, type: type });
        });
      }
    });
    if (active.length === 0) return escapeHtml(text);

    // Build a per-character type map (priority = order index, lower wins).
    var n = text.length;
    var map = new Array(n);
    var prio = {};
    order.forEach(function (t, i) { prio[t] = i; });
    active.forEach(function (sp) {
      var s = Math.max(0, sp.start), e = Math.min(n, sp.end);
      for (var i = s; i < e; i++) {
        if (map[i] === undefined || prio[sp.type] < prio[map[i]]) map[i] = sp.type;
      }
    });

    var html = '';
    var i = 0;
    while (i < n) {
      var t = map[i];
      if (t === undefined) {
        var j = i;
        while (j < n && map[j] === undefined) j++;
        html += escapeHtml(text.slice(i, j));
        i = j;
      } else {
        var k = i;
        while (k < n && map[k] === t) k++;
        html += '<mark class="hl-' + t + '">' + escapeHtml(text.slice(i, k)) + '</mark>';
        i = k;
      }
    }
    return html;
  }

  function renderHighlights(text, analysis) {
    var html = buildHighlightHtml(text, analysis.highlights, state.settings);
    // Trailing newline needs a placeholder so the layer matches textarea height.
    if (text.length === 0 || text[text.length - 1] === '\n') html += ' ';
    highlightLayer.innerHTML = html;
  }

  function syncScroll() {
    highlightLayer.scrollTop = editor.scrollTop;
    highlightLayer.scrollLeft = editor.scrollLeft;
  }

  // ---- Analysis run ----
  function runAnalysis() {
    var text = editor.value;
    if (text.length > MAX_ANALYZE_CHARS) {
      toast('Text is very large — analyzing the first ' +
        Math.round(MAX_ANALYZE_CHARS / 1000) + 'k characters.');
      text = text.slice(0, MAX_ANALYZE_CHARS);
    }
    var analysis;
    try {
      analysis = A.analyze(text, { longThreshold: state.settings.longThreshold });
    } catch (e) {
      analysis = A.analyze('', { longThreshold: state.settings.longThreshold });
    }
    state.lastAnalysis = analysis;
    renderHighlights(text, analysis);
    renderScores(analysis);
    renderStats(analysis);
    renderHistogram(analysis);
    renderHardest(analysis);
    renderCounts(analysis);
    syncScroll();
  }

  var scheduleAnalysis = debounce(runAnalysis, 220);

  // ---- Rendering: scores ----
  function renderScores(a) {
    var sc = a.scores;
    $('s-fre').textContent = fmt(sc.fleschReadingEase, 1);
    $('s-fk').textContent = fmt(sc.fleschKincaidGrade, 1);
    $('s-fog').textContent = fmt(sc.gunningFog, 1);
    $('s-smog').textContent = fmt(sc.smog, 1);
    $('s-ari').textContent = fmt(sc.automatedReadabilityIndex, 1);
    $('s-cl').textContent = fmt(sc.colemanLiau, 1);

    var pill = $('ease-pill');
    pill.textContent = a.easeLabel;
    var good = sc.fleschReadingEase != null && sc.fleschReadingEase >= 60;
    pill.classList.toggle('good', good);

    // Goal indicator (target grade).
    var gi = $('goal-indicator');
    var target = state.settings.targetGrade;
    var grade = sc.fleschKincaidGrade;
    if (grade == null) {
      gi.textContent = 'Target ' + target;
      gi.classList.remove('met');
    } else if (grade <= target) {
      gi.textContent = 'At/under grade ' + target + ' ✓';
      gi.classList.add('met');
    } else {
      gi.textContent = 'Above target (' + fmt(grade, 1) + ' > ' + target + ')';
      gi.classList.remove('met');
    }
  }

  // ---- Rendering: stats ----
  function renderStats(a) {
    var s = a.stats;
    $('st-words').textContent = s.words;
    $('st-sentences').textContent = s.sentences;
    $('st-paragraphs').textContent = s.paragraphs;
    $('st-avg').textContent = s.sentences > 0 ? fmt(s.avgSentenceLength, 1) : '—';
    $('st-var').textContent = s.sentences > 0 ? fmt(s.sentenceLengthVariance, 1) : '—';
    $('st-time').textContent = readingTime(s.readingMinutes, s.words);

    var longest = a.longestSentence;
    $('longest-sentence').textContent = longest && longest.words > 0
      ? '(' + longest.words + ' words) ' + longest.text
      : '—';
  }

  function readingTime(minutes, words) {
    if (!words) return '—';
    if (minutes < 1) {
      var secs = Math.max(1, Math.round(minutes * 60));
      return secs + ' sec';
    }
    return fmt(minutes, 1) + ' min';
  }

  // ---- Rendering: histogram ----
  function renderHistogram(a) {
    var hist = $('histogram');
    hist.innerHTML = '';
    var max = 0;
    a.distribution.forEach(function (b) { if (b.count > max) max = b.count; });
    a.distribution.forEach(function (b) {
      var bar = document.createElement('div');
      bar.className = 'hist-bar';
      var pct = max > 0 ? Math.round((b.count / max) * 100) : 0;

      var count = document.createElement('span');
      count.className = 'hist-count';
      count.textContent = b.count;

      var fill = document.createElement('div');
      fill.className = 'hist-fill';
      fill.style.height = (b.count > 0 ? Math.max(6, pct) : 2) + '%';

      var label = document.createElement('span');
      label.className = 'hist-label';
      label.textContent = b.label;

      bar.appendChild(count);
      bar.appendChild(fill);
      bar.appendChild(label);
      bar.title = b.count + ' sentence(s) of ' + b.label + ' words';
      hist.appendChild(bar);
    });
  }

  // ---- Rendering: hardest sentences ----
  function renderHardest(a) {
    var list = $('hardest-list');
    list.innerHTML = '';
    var ranked = a.rankedHardest.slice(0, 5);
    if (ranked.length === 0) {
      var li = document.createElement('li');
      li.className = 'hardest-empty';
      li.textContent = 'Write something to rank sentences by difficulty.';
      list.appendChild(li);
      return;
    }
    ranked.forEach(function (s) {
      var li = document.createElement('li');
      li.className = 'hardest-item';
      li.tabIndex = 0;
      li.setAttribute('role', 'button');
      li.setAttribute('aria-label', 'Grade ' + fmt(s.grade, 1) + ', ' + s.words + ' words. Click to select in editor.');

      var meta = document.createElement('div');
      meta.className = 'hardest-meta';
      meta.innerHTML = '<span class="hardest-grade">Grade ' + escapeHtml(fmt(s.grade, 1)) +
        '</span><span>' + s.words + ' words</span>';

      var p = document.createElement('p');
      p.className = 'hardest-text';
      p.textContent = s.text;

      li.appendChild(meta);
      li.appendChild(p);

      var select = function () { selectRange(s.start, s.end); };
      li.addEventListener('click', select);
      li.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); select(); }
      });
      li.addEventListener('mouseenter', function () { showHover(s); });
      li.addEventListener('mouseleave', hideHover);
      li.addEventListener('focus', function () { showHover(s); });
      li.addEventListener('blur', hideHover);

      list.appendChild(li);
    });
  }

  function selectRange(start, end) {
    editor.focus();
    try { editor.setSelectionRange(start, end); } catch (e) {}
    // Scroll selection into view approximately.
    var ratio = start / Math.max(1, editor.value.length);
    editor.scrollTop = Math.max(0, ratio * editor.scrollHeight - editor.clientHeight / 2);
    syncScroll();
  }

  function showHover(s) {
    var ro = $('hover-readout');
    ro.hidden = false;
    ro.setAttribute('aria-hidden', 'false');
    ro.innerHTML = '<strong>Sentence detail:</strong> ' +
      '<span class="mono">grade ' + escapeHtml(fmt(s.grade, 1)) + '</span> · ' +
      '<span class="mono">ease ' + escapeHtml(fmt(s.ease, 0)) + '</span> · ' +
      '<span class="mono">' + s.words + ' words</span> — click to jump to it.';
  }
  function hideHover() {
    var ro = $('hover-readout');
    ro.hidden = true;
    ro.setAttribute('aria-hidden', 'true');
  }

  // ---- Rendering: highlight counts ----
  function renderCounts(a) {
    ['long', 'passive', 'adverb', 'filler', 'complex'].forEach(function (t) {
      $('c-' + t).textContent = a.highlights[t] ? a.highlights[t].length : 0;
    });
  }

  // ---- Highlight toggles ----
  function syncHighlightToggles() {
    var boxes = document.querySelectorAll('[data-hl]');
    boxes.forEach(function (b) {
      var t = b.getAttribute('data-hl');
      b.checked = !!state.settings.highlights[t];
    });
  }

  function wireHighlightToggles() {
    document.querySelectorAll('[data-hl]').forEach(function (b) {
      b.addEventListener('change', function () {
        var t = b.getAttribute('data-hl');
        state.settings.highlights[t] = b.checked;
        Store.saveSettings(state.settings);
        runAnalysis();
      });
    });
  }

  // ---- Export ----
  function download(filename, content, mime) {
    var blob = new Blob([content], { type: mime });
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
  }

  function safeName(title) {
    return (title || 'document').replace(/[^a-z0-9\-_ ]/gi, '').trim().replace(/\s+/g, '-') || 'document';
  }

  function exportAs(kind) {
    var doc = activeDoc();
    var title = doc ? doc.title : 'Untitled';
    var content = editor.value;
    if (kind === 'txt') {
      download(safeName(title) + '.txt', content, 'text/plain');
    } else if (kind === 'md') {
      download(safeName(title) + '.md', '# ' + title + '\n\n' + content, 'text/markdown');
    } else if (kind === 'json') {
      var a = state.lastAnalysis || A.analyze(content, { longThreshold: state.settings.longThreshold });
      var payload = {
        title: title,
        exportedAt: new Date().toISOString(),
        stats: a.stats,
        scores: a.scores,
        easeLabel: a.easeLabel,
        targetGrade: state.settings.targetGrade,
        rankedHardest: a.rankedHardest.slice(0, 10).map(function (s) {
          return { text: s.text, words: s.words, grade: s.grade, ease: s.ease };
        }),
        distribution: a.distribution,
        highlightCounts: {
          long: a.highlights.long.length,
          passive: a.highlights.passive.length,
          adverb: a.highlights.adverb.length,
          filler: a.highlights.filler.length,
          complex: a.highlights.complex.length
        }
      };
      download(safeName(title) + '-analysis.json', JSON.stringify(payload, null, 2), 'application/json');
    }
    toast('Exported ' + kind.toUpperCase());
  }

  function copyText() {
    var text = editor.value;
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(function () { toast('Copied to clipboard'); },
        function () { fallbackCopy(text); });
    } else {
      fallbackCopy(text);
    }
  }
  function fallbackCopy(text) {
    try {
      editor.focus();
      editor.select();
      document.execCommand('copy');
      editor.setSelectionRange(editor.value.length, editor.value.length);
      toast('Copied to clipboard');
    } catch (e) { toast('Copy not available'); }
  }

  // ---- Clear / sample ----
  function clearDoc() {
    var doc = activeDoc();
    if (!doc && editor.value.trim() === '') return;
    openConfirm({
      title: 'Clear document',
      message: 'Clear all text in this document? The document itself is kept.',
      okLabel: 'Clear',
      onOk: function () {
        editor.value = '';
        var d = activeDoc();
        if (d) { d.content = ''; d.updatedAt = Date.now(); persistDocs(); }
        updateEmptyState();
        runAnalysis();
        editor.focus();
        toast('Cleared');
      }
    });
  }

  function loadSample() {
    // Cycle through samples — load the first not already present by title,
    // else just add the first sample as a fresh doc.
    var samples = Seed.SAMPLES;
    var existingTitles = {};
    state.docs.forEach(function (d) { existingTitles[d.title] = true; });
    var pick = null;
    for (var i = 0; i < samples.length; i++) {
      if (!existingTitles[samples[i].title]) { pick = samples[i]; break; }
    }
    if (!pick) pick = samples[Math.floor(Math.random() * samples.length)];
    var doc = Store.createDocument(pick.title, pick.content);
    state.docs.unshift(doc);
    persistDocs();
    setActive(doc.id);
    toast('Loaded sample: ' + pick.title);
  }

  // ---- Settings modal ----
  function openSettings() {
    syncSettingsForm();
    openModal('settings-overlay', 'settings-modal');
  }
  function syncSettingsForm() {
    $('set-threshold').value = state.settings.longThreshold;
    $('set-threshold-out').textContent = state.settings.longThreshold;
    $('set-grade').value = state.settings.targetGrade;
    $('set-grade-out').textContent = state.settings.targetGrade;
    $('set-theme').value = state.settings.theme;
    document.querySelectorAll('[data-defhl]').forEach(function (b) {
      var t = b.getAttribute('data-defhl');
      b.checked = !!state.settings.highlights[t];
    });
  }
  function wireSettings() {
    $('set-threshold').addEventListener('input', function () {
      state.settings.longThreshold = parseInt(this.value, 10);
      $('set-threshold-out').textContent = this.value;
      Store.saveSettings(state.settings);
      runAnalysis();
    });
    $('set-grade').addEventListener('input', function () {
      state.settings.targetGrade = parseInt(this.value, 10);
      $('set-grade-out').textContent = this.value;
      Store.saveSettings(state.settings);
      if (state.lastAnalysis) renderScores(state.lastAnalysis);
    });
    $('set-theme').addEventListener('change', function () {
      state.settings.theme = this.value;
      applyTheme();
      Store.saveSettings(state.settings);
    });
    document.querySelectorAll('[data-defhl]').forEach(function (b) {
      b.addEventListener('change', function () {
        var t = b.getAttribute('data-defhl');
        state.settings.highlights[t] = b.checked;
        Store.saveSettings(state.settings);
        syncHighlightToggles();
        runAnalysis();
      });
    });
  }

  // ---- Theme ----
  function applyTheme() {
    document.body.setAttribute('data-theme', state.settings.theme);
    var btn = $('btn-theme');
    btn.setAttribute('aria-pressed', state.settings.theme === 'dark' ? 'true' : 'false');
  }
  function toggleTheme() {
    state.settings.theme = state.settings.theme === 'dark' ? 'light' : 'dark';
    applyTheme();
    Store.saveSettings(state.settings);
  }

  // ---- Generic modal w/ focus trap + Esc ----
  var modalStack = [];
  function openModal(overlayId, modalId) {
    var overlay = $(overlayId);
    var modal = $(modalId);
    overlay.hidden = false;
    var prevFocus = document.activeElement;
    modalStack.push({ overlay: overlay, modal: modal, prevFocus: prevFocus });
    var focusables = getFocusable(modal);
    if (focusables.length) focusables[0].focus();

    function onKey(e) {
      if (e.key === 'Escape') { e.preventDefault(); closeModal(overlayId); }
      else if (e.key === 'Tab') { trapTab(e, modal); }
    }
    overlay._onKey = onKey;
    document.addEventListener('keydown', onKey, true);

    overlay._onClick = function (e) { if (e.target === overlay) closeModal(overlayId); };
    overlay.addEventListener('mousedown', overlay._onClick);
  }
  function closeModal(overlayId) {
    var overlay = $(overlayId);
    overlay.hidden = true;
    if (overlay._onKey) document.removeEventListener('keydown', overlay._onKey, true);
    if (overlay._onClick) overlay.removeEventListener('mousedown', overlay._onClick);
    var top = modalStack.pop();
    if (top && top.prevFocus && top.prevFocus.focus) top.prevFocus.focus();
  }
  function getFocusable(container) {
    return Array.prototype.slice.call(container.querySelectorAll(
      'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
    )).filter(function (el) { return el.offsetParent !== null || el === document.activeElement; });
  }
  function trapTab(e, modal) {
    var f = getFocusable(modal);
    if (f.length === 0) return;
    var first = f[0], last = f[f.length - 1];
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
  }

  // ---- Confirm modal ----
  var confirmHandler = null;
  function openConfirm(opts) {
    $('confirm-title').textContent = opts.title || 'Confirm';
    $('confirm-message').textContent = opts.message || '';
    $('confirm-ok').textContent = opts.okLabel || 'OK';
    var wrap = $('confirm-input-wrap');
    var input = $('confirm-input');
    if (opts.input !== undefined) {
      wrap.hidden = false;
      input.value = opts.input;
    } else {
      wrap.hidden = true;
      input.value = '';
    }
    confirmHandler = opts.onOk || null;
    openModal('confirm-overlay', 'confirm-modal');
    if (opts.input !== undefined) { input.focus(); input.select(); }
  }
  function wireConfirm() {
    $('confirm-ok').addEventListener('click', function () {
      var value = $('confirm-input').value;
      var h = confirmHandler;
      closeModal('confirm-overlay');
      if (h) h(value);
    });
    $('confirm-cancel').addEventListener('click', function () { closeModal('confirm-overlay'); });
    $('confirm-close').addEventListener('click', function () { closeModal('confirm-overlay'); });
    $('confirm-input').addEventListener('keydown', function (e) {
      if (e.key === 'Enter') { e.preventDefault(); $('confirm-ok').click(); }
    });
  }

  // ---- Export menu ----
  function wireExportMenu() {
    var btn = $('btn-export');
    var menu = $('export-menu');
    function close() { menu.hidden = true; btn.setAttribute('aria-expanded', 'false'); document.removeEventListener('click', onDoc); }
    function onDoc(e) { if (!menu.contains(e.target) && e.target !== btn) close(); }
    btn.addEventListener('click', function (e) {
      e.stopPropagation();
      var open = menu.hidden;
      if (open) { menu.hidden = false; btn.setAttribute('aria-expanded', 'true'); setTimeout(function () { document.addEventListener('click', onDoc); }, 0); }
      else close();
    });
    menu.querySelectorAll('[data-export]').forEach(function (item) {
      item.addEventListener('click', function () { exportAs(item.getAttribute('data-export')); close(); });
    });
    menu.addEventListener('keydown', function (e) { if (e.key === 'Escape') { close(); btn.focus(); } });
  }

  // ---- Init ----
  function init() {
    applyTheme();

    // Load docs, seed on first run.
    state.docs = Store.loadDocuments();
    if (!Store.isSeeded() && state.docs.length === 0) {
      state.docs = Seed.buildSeedDocuments(Store.createDocument);
      persistDocs();
      Store.markSeeded();
    }

    var savedActive = Store.getActiveId();
    var hasActive = false;
    for (var i = 0; i < state.docs.length; i++) if (state.docs[i].id === savedActive) hasActive = true;
    if (hasActive) {
      state.activeId = savedActive;
    } else if (state.docs.length > 0) {
      state.activeId = state.docs[0].id;
    } else {
      state.activeId = null;
    }
    Store.setActiveId(state.activeId || '');

    var doc = activeDoc();
    if (doc) { editor.value = doc.content; docTitle.value = doc.title; }

    syncHighlightToggles();
    renderDocList();
    runAnalysis();
    updateEmptyState();

    // Wire events.
    editor.addEventListener('input', onEditorInput);
    editor.addEventListener('scroll', syncScroll);
    docTitle.addEventListener('input', onTitleInput);

    $('btn-new-doc').addEventListener('click', newDoc);
    $('btn-load-sample').addEventListener('click', loadSample);
    $('btn-reset').addEventListener('click', function () {
      openConfirm({
        title: 'Reset everything',
        message: 'Delete all documents and settings and reload the samples? This cannot be undone.',
        okLabel: 'Reset',
        onOk: function () {
          Store.resetAll();
          state.settings = Store.loadSettings();
          state.docs = Seed.buildSeedDocuments(Store.createDocument);
          persistDocs();
          Store.markSeeded();
          applyTheme();
          syncHighlightToggles();
          setActive(state.docs[0].id);
          toast('Reset complete');
        }
      });
    });

    $('btn-copy').addEventListener('click', copyText);
    $('btn-clear').addEventListener('click', clearDoc);
    $('btn-theme').addEventListener('click', toggleTheme);
    $('btn-settings').addEventListener('click', openSettings);
    $('settings-close').addEventListener('click', function () { closeModal('settings-overlay'); });
    $('settings-done').addEventListener('click', function () { closeModal('settings-overlay'); });

    $('empty-sample').addEventListener('click', loadSample);
    $('empty-write').addEventListener('click', function () { emptyState.hidden = true; editor.focus(); });

    wireHighlightToggles();
    wireSettings();
    wireConfirm();
    wireExportMenu();

    // Keyboard shortcut: Ctrl/Cmd+S exports txt (prevent browser save dialog).
    document.addEventListener('keydown', function (e) {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {
        e.preventDefault();
        exportAs('txt');
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
