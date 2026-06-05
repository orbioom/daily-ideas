/* ============================================================
   app.js — Sift UI wiring, regex engine, rendering
   Depends on: window.SiftSeed, window.SiftStore
   No external network. No frameworks.
   ============================================================ */
(function () {
  'use strict';

  const { LIBRARY, SEED_SNIPPETS, CHEATSHEET } = window.SiftSeed;
  const Store = window.SiftStore;

  /* ---- Safety caps (crash-proofing) ---- */
  const MAX_SUBJECT = 200000;   // chars processed for matching
  const MAX_MATCHES = 10000;    // stop after this many matches
  const DEBOUNCE_MS = 120;

  const ALL_FLAGS = [
    { key: 'g', desc: 'global' },
    { key: 'i', desc: 'ignore case' },
    { key: 'm', desc: 'multiline' },
    { key: 's', desc: 'dotall' },
    { key: 'u', desc: 'unicode' },
    { key: 'y', desc: 'sticky' }
  ];

  /* ---- App state ---- */
  const state = {
    pattern: '',
    flags: { g: true, i: false, m: false, s: false, u: false, y: false },
    subject: '',
    replacement: '',
    activeSnippetId: null,
    settings: Store.getSettings(),
    lastResult: null   // cached compile/match result
  };

  /* ---- Element refs ---- */
  const el = {};
  function $(id) { return document.getElementById(id); }

  /* ============================================================
     Utilities
     ============================================================ */
  function escapeHTML(s) {
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function debounce(fn, ms) {
    let t = null;
    return function () {
      const args = arguments;
      if (t) clearTimeout(t);
      t = setTimeout(() => { t = null; fn.apply(null, args); }, ms);
    };
  }

  function flagsString() {
    return ALL_FLAGS.filter(f => state.flags[f.key]).map(f => f.key).join('');
  }

  let toastId = 0;
  function toast(message, kind) {
    const node = document.createElement('div');
    node.className = 'toast' + (kind ? ' ' + kind : '');
    node.textContent = message;
    node.setAttribute('role', 'status');
    const id = ++toastId;
    node.dataset.tid = String(id);
    el.toasts.appendChild(node);
    setTimeout(() => {
      if (node.parentNode) node.parentNode.removeChild(node);
    }, 2600);
  }

  /* ============================================================
     Regex engine — compile + match decomposition
     ============================================================ */
  function compile() {
    const flags = flagsString();
    if (state.pattern === '') {
      return { ok: true, empty: true, re: null, flags };
    }
    try {
      const re = new RegExp(state.pattern, flags);
      return { ok: true, empty: false, re, flags };
    } catch (err) {
      return { ok: false, empty: false, error: err && err.message ? err.message : 'Invalid regular expression', flags };
    }
  }

  /* Run matching, returning a normalized result. Crash-proofed:
     - subject is truncated to MAX_SUBJECT
     - match loop is capped at MAX_MATCHES
     - zero-width matches advance lastIndex to avoid infinite loops */
  function runMatch(compiled) {
    const result = {
      ok: compiled.ok,
      empty: compiled.empty,
      error: compiled.error || null,
      matches: [],
      count: 0,
      capped: false,
      truncated: false,
      elapsed: 0,
      hasGlobal: state.flags.g || state.flags.y
    };
    if (!compiled.ok || compiled.empty) return result;

    let subject = state.subject;
    if (subject.length > MAX_SUBJECT) {
      subject = subject.slice(0, MAX_SUBJECT);
      result.truncated = true;
    }

    const start = performance.now();
    const re = compiled.re;

    try {
      if (result.hasGlobal) {
        re.lastIndex = 0;
        let m;
        let guard = 0;
        while ((m = re.exec(subject)) !== null) {
          result.matches.push(normalizeMatch(m));
          guard++;
          if (m.index === re.lastIndex) re.lastIndex++; // zero-width safety
          if (guard >= MAX_MATCHES) { result.capped = true; break; }
        }
      } else {
        const m = re.exec(subject);
        if (m) result.matches.push(normalizeMatch(m));
      }
    } catch (err) {
      result.ok = false;
      result.error = err && err.message ? err.message : 'Matching failed';
      result.matches = [];
    }

    result.elapsed = performance.now() - start;
    result.count = result.matches.length;
    return result;
  }

  function normalizeMatch(m) {
    const groups = [];
    for (let i = 1; i < m.length; i++) {
      groups.push({ index: i, value: m[i] }); // value may be undefined
    }
    const named = [];
    if (m.groups) {
      for (const name of Object.keys(m.groups)) {
        named.push({ name, value: m.groups[name] });
      }
    }
    return {
      full: m[0],
      index: m.index,
      end: m.index + m[0].length,
      groups,
      named
    };
  }

  /* ============================================================
     Replace preview (with backreference support)
     ============================================================ */
  function buildReplacePreview(compiled) {
    if (!compiled.ok) return { ok: false, text: '' };
    if (compiled.empty) return { ok: true, text: state.subject };
    let subject = state.subject;
    if (subject.length > MAX_SUBJECT) subject = subject.slice(0, MAX_SUBJECT);
    try {
      // String.prototype.replace natively supports $1, $<name>, $&, $$, $`, $'
      const out = subject.replace(compiled.re, state.replacement);
      return { ok: true, text: out };
    } catch (err) {
      return { ok: false, text: '', error: err && err.message ? err.message : 'Replace failed' };
    }
  }

  /* ============================================================
     Rendering
     ============================================================ */
  function renderFlags() {
    el.flags.querySelectorAll('.flag').forEach(n => n.remove());
    ALL_FLAGS.forEach(f => {
      const label = document.createElement('label');
      label.className = 'flag';
      label.title = f.desc;
      const input = document.createElement('input');
      input.type = 'checkbox';
      input.checked = !!state.flags[f.key];
      input.dataset.flag = f.key;
      input.setAttribute('aria-label', f.key + ' — ' + f.desc);
      input.addEventListener('change', () => {
        state.flags[f.key] = input.checked;
        update();
      });
      const key = document.createElement('span');
      key.className = 'flag-key mono';
      key.textContent = f.key;
      const desc = document.createElement('span');
      desc.className = 'flag-desc';
      desc.textContent = f.desc;
      label.appendChild(input);
      label.appendChild(key);
      label.appendChild(desc);
      el.flags.appendChild(label);
    });
  }

  function renderStatus(compiled) {
    el.flagsDelim.textContent = '/' + (flagsString() || '');
    if (compiled.empty) {
      el.regexStatus.className = 'status status-valid';
      el.regexStatusText.textContent = 'empty';
      el.regexError.hidden = true;
      return;
    }
    if (compiled.ok) {
      el.regexStatus.className = 'status status-valid';
      el.regexStatusText.textContent = 'valid';
      el.regexError.hidden = true;
    } else {
      el.regexStatus.className = 'status status-invalid';
      el.regexStatusText.textContent = 'invalid';
      el.regexError.hidden = false;
      el.regexError.textContent = compiled.error;
    }
  }

  /* Build highlighted HTML by escaping the subject and wrapping each
     match span in <mark>. Overlapping is impossible since matches are
     sequential & non-overlapping from exec. */
  function renderHighlights(result) {
    const subject = state.subject;
    if (subject === '') {
      el.highlight.innerHTML = '<span class="highlight-empty">No test text yet. Type or load a sample.</span>';
      return;
    }
    if (!result.ok) {
      el.highlight.innerHTML = '<span class="highlight-empty">Fix the pattern to see highlights.</span>';
      return;
    }
    if (result.empty || result.count === 0) {
      el.highlight.innerHTML = escapeHTML(subject) || '<span class="highlight-empty">(empty)</span>';
      return;
    }

    const distinct = state.settings.distinctGroups;
    let html = '';
    let cursor = 0;
    const limit = Math.min(subject.length, MAX_SUBJECT);

    for (let i = 0; i < result.matches.length; i++) {
      const m = result.matches[i];
      if (m.index < cursor) continue; // safety against any overlap
      if (m.index > limit) break;
      html += escapeHTML(subject.slice(cursor, m.index));
      const cls = distinct ? ('g' + (((i) % 6) + 1)) : '';
      html += '<mark' + (cls ? ' class="' + cls + '"' : '') +
              ' title="match ' + (i + 1) + ' @ ' + m.index + '">' +
              escapeHTML(m.full) + '</mark>';
      cursor = m.end;
      if (m.end === m.index) cursor = m.index + 1; // zero-width visual nudge
    }
    html += escapeHTML(subject.slice(cursor));
    el.highlight.innerHTML = html;
  }

  function groupChipColor(i) {
    return 'var(--g' + (((i) % 6) + 1) + ')';
  }

  function renderMatchList(result) {
    // Meta
    if (!result.ok) {
      el.matchCount.textContent = 'invalid pattern';
      el.matchTime.textContent = '—';
    } else if (result.empty) {
      el.matchCount.textContent = 'enter a pattern';
      el.matchTime.textContent = '—';
    } else {
      const label = result.count === 1 ? '1 match' : result.count + ' matches';
      el.matchCount.textContent = (result.capped ? '≥ ' : '') + label;
      el.matchTime.textContent = result.elapsed.toFixed(2) + ' ms';
    }

    el.matchList.innerHTML = '';

    if (!result.ok || result.empty) return;

    if (result.count === 0) {
      const empty = document.createElement('div');
      empty.className = 'empty-state';
      empty.innerHTML = '<div class="empty-icon" aria-hidden="true">∅</div><p>No matches in the current text.</p>';
      el.matchList.appendChild(empty);
      return;
    }

    const frag = document.createDocumentFragment();
    const distinct = state.settings.distinctGroups;

    result.matches.forEach((m, i) => {
      const item = document.createElement('div');
      item.className = 'match-item';

      const head = document.createElement('div');
      head.className = 'match-item-head';

      const left = document.createElement('div');
      const idx = document.createElement('span');
      idx.className = 'match-idx mono';
      idx.textContent = '#' + (i + 1);
      const text = document.createElement('span');
      text.className = 'match-text';
      text.textContent = m.full === '' ? '∅ (empty match)' : m.full;
      left.appendChild(idx);
      left.appendChild(document.createTextNode(' '));
      left.appendChild(text);

      const pos = document.createElement('span');
      pos.className = 'match-pos mono';
      pos.textContent = '[' + m.index + '–' + m.end + ']';

      head.appendChild(left);
      head.appendChild(pos);
      item.appendChild(head);

      if (m.groups.length || m.named.length) {
        const groups = document.createElement('div');
        groups.className = 'groups';

        m.groups.forEach((g, gi) => {
          const row = document.createElement('div');
          row.className = 'group-row';
          const key = document.createElement('span');
          key.className = 'group-key mono';
          if (distinct) {
            const chip = document.createElement('span');
            chip.className = 'chip';
            chip.style.background = groupChipColor(i); // chip reflects match tint
            key.appendChild(chip);
          }
          key.appendChild(document.createTextNode('$' + g.index));
          const val = document.createElement('span');
          if (g.value === undefined) {
            val.className = 'group-val empty';
            val.textContent = '(no match)';
          } else if (g.value === '') {
            val.className = 'group-val empty';
            val.textContent = '(empty)';
          } else {
            val.className = 'group-val mono';
            val.textContent = g.value;
          }
          row.appendChild(key);
          row.appendChild(val);
          groups.appendChild(row);
        });

        m.named.forEach(n => {
          const row = document.createElement('div');
          row.className = 'group-row';
          const key = document.createElement('span');
          key.className = 'group-key mono';
          key.textContent = '$<' + n.name + '>';
          const val = document.createElement('span');
          if (n.value === undefined) {
            val.className = 'group-val empty';
            val.textContent = '(no match)';
          } else if (n.value === '') {
            val.className = 'group-val empty';
            val.textContent = '(empty)';
          } else {
            val.className = 'group-val mono';
            val.textContent = n.value;
          }
          row.appendChild(key);
          row.appendChild(val);
          groups.appendChild(row);
        });

        item.appendChild(groups);
      }

      frag.appendChild(item);
    });

    el.matchList.appendChild(frag);
  }

  function renderReplace(compiled) {
    const prev = buildReplacePreview(compiled);
    if (!prev.ok) {
      el.replacePreview.innerHTML = '<span class="highlight-empty">' +
        escapeHTML(prev.error || 'Replace unavailable while the pattern is invalid.') + '</span>';
      return;
    }
    if (state.subject === '') {
      el.replacePreview.innerHTML = '<span class="highlight-empty">Replacement preview appears here.</span>';
      return;
    }
    el.replacePreview.textContent = prev.text;
  }

  /* ============================================================
     Central update — compile, match, render everything (debounced)
     ============================================================ */
  function computeAndRender() {
    const compiled = compile();
    const result = runMatch(compiled);
    state.lastResult = { compiled, result };

    renderStatus(compiled);
    renderMatchList(result);
    renderHighlights(result);
    renderReplace(compiled);

    if (result.truncated) {
      // surface once per truncation via the count pill suffix
      el.matchCount.textContent += ' · text truncated';
    }
  }
  const debouncedRender = debounce(computeAndRender, DEBOUNCE_MS);

  function update() {
    // status delimiter updates immediately for snappy feel
    el.flagsDelim.textContent = '/' + (flagsString() || '');
    debouncedRender();
  }

  /* ============================================================
     Snippets sidebar (CRUD)
     ============================================================ */
  function renderSnippets() {
    const list = Store.getSnippets();
    el.snipList.innerHTML = '';

    if (list.length === 0) {
      const empty = document.createElement('div');
      empty.className = 'empty-state';
      empty.innerHTML =
        '<div class="empty-icon" aria-hidden="true">◇</div>' +
        '<p>No saved cases yet.</p>' +
        '<p class="panel-hint" style="margin-top:.3rem">Set up a pattern and press “Save current” to keep your first test case.</p>';
      el.snipList.appendChild(empty);
      return;
    }

    const frag = document.createDocumentFragment();
    list.forEach(s => {
      const item = document.createElement('div');
      item.className = 'snip-item' + (s.id === state.activeSnippetId ? ' active' : '');

      const name = document.createElement('div');
      name.className = 'snip-name';
      name.textContent = s.name;

      const meta = document.createElement('div');
      meta.className = 'snip-meta';
      const flags = s.flags || '';
      meta.textContent = '/' + truncate(s.pattern, 40) + '/' + flags;

      const actions = document.createElement('div');
      actions.className = 'snip-actions';

      const loadBtn = mkBtn('Load', 'btn-sm', () => loadSnippet(s));
      const renameBtn = mkBtn('Rename', 'btn-sm btn-ghost', () => openRename(s));
      const delBtn = mkBtn('Delete', 'btn-sm btn-ghost', () => confirmDelete(s));
      delBtn.setAttribute('aria-label', 'Delete ' + s.name);

      actions.appendChild(loadBtn);
      actions.appendChild(renameBtn);
      actions.appendChild(delBtn);

      item.appendChild(name);
      item.appendChild(meta);
      item.appendChild(actions);
      frag.appendChild(item);
    });
    el.snipList.appendChild(frag);
  }

  function mkBtn(text, cls, onClick) {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = cls;
    b.textContent = text;
    b.addEventListener('click', onClick);
    return b;
  }
  function truncate(s, n) {
    s = String(s);
    return s.length > n ? s.slice(0, n - 1) + '…' : s;
  }

  function loadSnippet(s) {
    state.pattern = s.pattern || '';
    state.replacement = s.replacement || '';
    state.subject = s.subject || '';
    // reset flags then apply
    ALL_FLAGS.forEach(f => { state.flags[f.key] = false; });
    String(s.flags || '').split('').forEach(ch => {
      if (Object.prototype.hasOwnProperty.call(state.flags, ch)) state.flags[ch] = true;
    });
    state.activeSnippetId = s.id;
    syncInputsFromState();
    renderFlags();
    renderSnippets();
    computeAndRender();
    toast('Loaded “' + s.name + '”', 'success');
  }

  function loadLibraryEntry(entry) {
    state.pattern = entry.pattern;
    state.subject = entry.sample;
    state.replacement = '';
    ALL_FLAGS.forEach(f => { state.flags[f.key] = false; });
    String(entry.flags || '').split('').forEach(ch => {
      if (Object.prototype.hasOwnProperty.call(state.flags, ch)) state.flags[ch] = true;
    });
    state.activeSnippetId = null;
    syncInputsFromState();
    renderFlags();
    renderSnippets();
    computeAndRender();
    toast('Loaded pattern: ' + entry.name);
  }

  function syncInputsFromState() {
    el.pattern.value = state.pattern;
    el.subject.value = state.subject;
    el.replacement.value = state.replacement;
    el.flagsDelim.textContent = '/' + (flagsString() || '');
  }

  /* ---- Save / rename dialog flow ---- */
  let nameDialogMode = 'save'; // 'save' | 'rename'
  let renameTarget = null;

  function openSave() {
    nameDialogMode = 'save';
    renameTarget = null;
    el.nameDialogTitle.textContent = 'Save test case';
    el.nameInput.value = suggestName();
    el.nameWarn.textContent = '';
    el.nameDialog.showModal();
    el.nameInput.focus();
    el.nameInput.select();
  }

  function openRename(s) {
    nameDialogMode = 'rename';
    renameTarget = s;
    el.nameDialogTitle.textContent = 'Rename test case';
    el.nameInput.value = s.name;
    el.nameWarn.textContent = '';
    el.nameDialog.showModal();
    el.nameInput.focus();
    el.nameInput.select();
  }

  function suggestName() {
    const p = state.pattern.trim();
    if (!p) return 'Untitled case';
    return 'Test: /' + truncate(p, 24) + '/';
  }

  function submitName(ev) {
    if (ev) ev.preventDefault();
    const raw = el.nameInput.value;
    const name = raw.trim();
    if (name === '') {
      el.nameWarn.textContent = 'Please enter a name.';
      el.nameInput.focus();
      return;
    }
    const existing = Store.getSnippets();
    const dupes = existing.filter(s =>
      s.name.toLowerCase() === name.toLowerCase() &&
      (!renameTarget || s.id !== renameTarget.id)
    );

    if (nameDialogMode === 'save') {
      const snippet = {
        id: Store.newId(),
        name,
        pattern: state.pattern,
        flags: flagsString(),
        replacement: state.replacement,
        subject: state.subject,
        createdAt: Store.nowISO(),
        updatedAt: Store.nowISO()
      };
      Store.addSnippet(snippet);
      state.activeSnippetId = snippet.id;
      el.nameDialog.close();
      renderSnippets();
      toast(dupes.length ? 'Saved (duplicate name)' : 'Saved “' + name + '”', 'success');
    } else if (renameTarget) {
      Store.updateSnippet(renameTarget.id, { name });
      el.nameDialog.close();
      renderSnippets();
      toast(dupes.length ? 'Renamed (duplicate name)' : 'Renamed to “' + name + '”', 'success');
    }
  }

  function confirmDelete(s) {
    openConfirm('Delete test case', 'Remove “' + s.name + '”? This cannot be undone.', () => {
      Store.deleteSnippet(s.id);
      if (state.activeSnippetId === s.id) state.activeSnippetId = null;
      renderSnippets();
      toast('Deleted “' + s.name + '”');
    });
  }

  /* ---- Generic confirm dialog ---- */
  let confirmHandler = null;
  function openConfirm(title, msg, onOk) {
    el.confirmTitle.textContent = title;
    el.confirmMsg.textContent = msg;
    confirmHandler = onOk;
    el.confirmDialog.showModal();
    el.confirmOk.focus();
  }

  /* ============================================================
     Export / import
     ============================================================ */
  function exportSnippets() {
    const list = Store.getSnippets();
    const payload = {
      app: 'orbioom.sift',
      version: 1,
      exportedAt: Store.nowISO(),
      snippets: list
    };
    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    const stamp = new Date().toISOString().slice(0, 10);
    a.download = 'sift-snippets-' + stamp + '.json';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    setTimeout(() => URL.revokeObjectURL(url), 1000);
    toast(list.length + (list.length === 1 ? ' case exported' : ' cases exported'), 'success');
  }

  function importSnippetsFromFile(file) {
    if (!file) return;
    // subtle loading affordance
    el.btnImport.disabled = true;
    const original = el.btnImport.textContent;
    el.btnImport.innerHTML = '<span class="spinner" aria-hidden="true"></span>';

    const reader = new FileReader();
    reader.onload = () => {
      restoreImportButton(original);
      let data;
      try {
        data = JSON.parse(String(reader.result));
      } catch (e) {
        toast('That file is not valid JSON.', 'error');
        return;
      }
      const incoming = extractSnippets(data);
      if (incoming === null) {
        toast('No snippets found in that file.', 'error');
        return;
      }
      mergeImported(incoming);
    };
    reader.onerror = () => {
      restoreImportButton(original);
      toast('Could not read that file.', 'error');
    };
    reader.readAsText(file);
  }

  function restoreImportButton(original) {
    el.btnImport.disabled = false;
    el.btnImport.textContent = original;
  }

  function extractSnippets(data) {
    let arr = null;
    if (Array.isArray(data)) arr = data;
    else if (data && Array.isArray(data.snippets)) arr = data.snippets;
    if (!arr) return null;

    const cleaned = [];
    arr.forEach(s => {
      if (!s || typeof s !== 'object') return;
      if (typeof s.pattern !== 'string') return;
      cleaned.push({
        id: typeof s.id === 'string' && s.id ? s.id : Store.newId(),
        name: typeof s.name === 'string' && s.name.trim() ? s.name.trim() : 'Imported case',
        pattern: s.pattern,
        flags: sanitizeFlags(s.flags),
        replacement: typeof s.replacement === 'string' ? s.replacement : '',
        subject: typeof s.subject === 'string' ? s.subject : '',
        createdAt: typeof s.createdAt === 'string' ? s.createdAt : Store.nowISO(),
        updatedAt: Store.nowISO()
      });
    });
    return cleaned.length ? cleaned : null;
  }

  function sanitizeFlags(f) {
    if (typeof f !== 'string') return '';
    const valid = ALL_FLAGS.map(x => x.key);
    const seen = {};
    return f.split('').filter(ch => {
      if (valid.indexOf(ch) === -1 || seen[ch]) return false;
      seen[ch] = true;
      return true;
    }).join('');
  }

  function mergeImported(incoming) {
    const existing = Store.getSnippets();
    const byId = {};
    existing.forEach(s => { byId[s.id] = true; });
    let added = 0;
    incoming.forEach(s => {
      if (byId[s.id]) s.id = Store.newId(); // avoid id collisions
      existing.push(s);
      added++;
    });
    Store.replaceAllSnippets(existing);
    renderSnippets();
    toast('Imported ' + added + (added === 1 ? ' case' : ' cases'), 'success');
  }

  /* ============================================================
     Clipboard
     ============================================================ */
  function copyText(text, okMsg) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(
        () => toast(okMsg, 'success'),
        () => fallbackCopy(text, okMsg)
      );
    } else {
      fallbackCopy(text, okMsg);
    }
  }
  function fallbackCopy(text, okMsg) {
    try {
      const ta = document.createElement('textarea');
      ta.value = text;
      ta.setAttribute('readonly', '');
      ta.style.position = 'absolute';
      ta.style.left = '-9999px';
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
      toast(okMsg, 'success');
    } catch (e) {
      toast('Copy failed — select and copy manually.', 'error');
    }
  }

  /* ============================================================
     Settings + theme
     ============================================================ */
  function applyTheme(theme) {
    let resolved = theme;
    if (theme === 'system') {
      resolved = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
        ? 'dark' : 'light';
    }
    document.documentElement.setAttribute('data-theme', resolved);
  }

  function applySettings() {
    applyTheme(state.settings.theme);
    el.setTheme.value = state.settings.theme;
    el.setGroups.checked = !!state.settings.distinctGroups;
  }

  function openSettings() {
    el.setTheme.value = state.settings.theme;
    el.setGroups.checked = !!state.settings.distinctGroups;
    el.settingsDialog.showModal();
  }

  function resetToSample() {
    openConfirm('Reset to sample data',
      'This replaces all saved cases with Sift’s starter set and resets settings. Continue?',
      () => {
        const res = Store.resetToSample(SEED_SNIPPETS);
        state.settings = res.settings;
        state.activeSnippetId = null;
        applySettings();
        renderSnippets();
        toast('Reset to sample data', 'success');
      });
  }

  /* ============================================================
     Cheatsheet + library render (static)
     ============================================================ */
  function renderCheatsheet() {
    const frag = document.createDocumentFragment();
    CHEATSHEET.forEach(c => {
      const row = document.createElement('div');
      row.className = 'cheat-row';
      const tok = document.createElement('span');
      tok.className = 'cheat-tok';
      tok.textContent = c.tok;
      const desc = document.createElement('span');
      desc.className = 'cheat-desc';
      desc.textContent = c.desc;
      row.appendChild(tok);
      row.appendChild(desc);
      frag.appendChild(row);
    });
    el.cheat.appendChild(frag);
  }

  function renderLibrary() {
    const frag = document.createDocumentFragment();
    LIBRARY.forEach(entry => {
      const chip = document.createElement('button');
      chip.type = 'button';
      chip.className = 'lib-chip';
      chip.title = entry.blurb + ' — /' + entry.pattern + '/' + entry.flags;
      chip.setAttribute('aria-label', 'Load pattern: ' + entry.name);
      const name = document.createElement('span');
      name.className = 'lib-name';
      name.textContent = entry.name;
      chip.appendChild(name);
      chip.addEventListener('click', () => loadLibraryEntry(entry));
      frag.appendChild(chip);
    });
    el.libGrid.appendChild(frag);
  }

  /* ============================================================
     View toggle (edit vs highlight overlay)
     ============================================================ */
  function setView(mode) {
    const showHl = mode === 'hl';
    el.subject.hidden = showHl;
    el.highlight.hidden = !showHl;
    el.viewEdit.setAttribute('aria-pressed', String(!showHl));
    el.viewHl.setAttribute('aria-pressed', String(showHl));
    if (showHl) computeAndRender();
  }

  /* ============================================================
     Bootstrap
     ============================================================ */
  function cacheEls() {
    [
      'pattern', 'flags', 'flags-delim', 'regex-status', 'regex-status-text', 'regex-error',
      'subject', 'highlight', 'view-edit', 'view-hl',
      'replacement', 'replace-preview', 'btn-copy-result',
      'match-count', 'match-time', 'match-list',
      'lib-grid', 'cheat', 'snip-list',
      'btn-save', 'btn-export', 'btn-import', 'file-import', 'btn-settings',
      'settings-dialog', 'settings-close', 'settings-done',
      'set-theme', 'set-groups', 'set-reset',
      'name-dialog', 'name-dialog-title', 'name-input', 'name-warn',
      'name-form', 'name-cancel',
      'confirm-dialog', 'confirm-title', 'confirm-msg', 'confirm-ok', 'confirm-cancel',
      'toasts'
    ].forEach(id => {
      const camel = id.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
      el[camel] = $(id);
    });
  }

  function wireEvents() {
    el.pattern.addEventListener('input', () => { state.pattern = el.pattern.value; update(); });
    el.subject.addEventListener('input', () => { state.subject = el.subject.value; update(); });
    el.replacement.addEventListener('input', () => { state.replacement = el.replacement.value; update(); });

    el.viewEdit.addEventListener('click', () => setView('edit'));
    el.viewHl.addEventListener('click', () => setView('hl'));

    el.btnCopyResult.addEventListener('click', () => {
      const compiled = compile();
      const prev = buildReplacePreview(compiled);
      if (!prev.ok) { toast('Fix the pattern before copying.', 'error'); return; }
      copyText(prev.text, 'Result copied to clipboard');
    });

    el.btnSave.addEventListener('click', openSave);
    el.btnExport.addEventListener('click', exportSnippets);
    el.btnImport.addEventListener('click', () => el.fileImport.click());
    el.fileImport.addEventListener('change', () => {
      const file = el.fileImport.files && el.fileImport.files[0];
      importSnippetsFromFile(file);
      el.fileImport.value = ''; // allow re-importing same file
    });

    el.btnSettings.addEventListener('click', openSettings);
    el.settingsClose.addEventListener('click', () => el.settingsDialog.close());
    el.settingsDone.addEventListener('click', () => el.settingsDialog.close());
    el.setTheme.addEventListener('change', () => {
      state.settings = Store.setSettings({ theme: el.setTheme.value });
      applyTheme(state.settings.theme);
    });
    el.setGroups.addEventListener('change', () => {
      state.settings = Store.setSettings({ distinctGroups: el.setGroups.checked });
      computeAndRender();
    });
    el.setReset.addEventListener('click', resetToSample);

    // Name dialog
    el.nameForm.addEventListener('submit', submitName);
    el.nameCancel.addEventListener('click', () => el.nameDialog.close());

    // Confirm dialog
    el.confirmOk.addEventListener('click', () => {
      el.confirmDialog.close();
      if (typeof confirmHandler === 'function') confirmHandler();
      confirmHandler = null;
    });
    el.confirmCancel.addEventListener('click', () => {
      el.confirmDialog.close();
      confirmHandler = null;
    });

    // React to system theme changes when in "system" mode
    if (window.matchMedia) {
      const mq = window.matchMedia('(prefers-color-scheme: dark)');
      const onChange = () => { if (state.settings.theme === 'system') applyTheme('system'); };
      if (mq.addEventListener) mq.addEventListener('change', onChange);
      else if (mq.addListener) mq.addListener(onChange);
    }

    // Keyboard: Cmd/Ctrl+S saves
    document.addEventListener('keydown', (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 's') {
        e.preventDefault();
        if (!el.nameDialog.open && !el.settingsDialog.open && !el.confirmDialog.open) openSave();
      }
    });
  }

  function bootstrapData() {
    // First open: seed snippets so the workbench is never cold.
    if (!Store.isSeeded()) {
      if (Store.getSnippets().length === 0) {
        Store.replaceAllSnippets(SEED_SNIPPETS.slice());
      }
      Store.markSeeded();
    }
  }

  function loadInitialState() {
    // Load the first seeded/saved snippet into the editor, else first library entry.
    const snippets = Store.getSnippets();
    if (snippets.length) {
      loadSnippet(snippets[0]);
    } else {
      loadLibraryEntry(LIBRARY[0]);
    }
  }

  function init() {
    cacheEls();
    state.settings = Store.getSettings();
    applySettings();

    renderFlags();
    renderCheatsheet();
    renderLibrary();
    wireEvents();

    bootstrapData();
    renderSnippets();
    loadInitialState();

    // ensure initial compute even if loadInitialState already did (idempotent)
    computeAndRender();

    if (!Store.isStorageUsable()) {
      toast('Storage is unavailable — changes won’t persist this session.', 'error');
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
