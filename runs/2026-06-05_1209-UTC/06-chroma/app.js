/*
 * app.js — Chroma UI controller.
 * Wires the palette builder, contrast checker, CVD simulator, scale/harmony
 * generator, live preview, export/import and settings to durable state.
 */
(function () {
  'use strict';

  const C = window.Color;
  const Store = window.Storage;
  const Seed = window.Seed;

  // ---- application state ----
  let state = Store.load();
  let editingSwatchId = null; // when set, the add form is in edit mode
  let exportFormat = 'css';
  let pickerForm = { fg: '#1B1D2A', bg: '#EDEEF3' };

  // ---- tiny DOM helpers ----
  function $(id) { return document.getElementById(id); }
  function on(el, ev, fn) { if (el) el.addEventListener(ev, fn); }
  function setHidden(el, hidden) { if (el) el.hidden = !!hidden; }

  function activePalette() {
    return state.palettes.find(function (p) { return p.id === state.activePaletteId; }) || null;
  }

  function persist() { Store.save(state); }

  // ===================================================================
  //  THEME
  // ===================================================================
  function applyTheme() {
    document.documentElement.setAttribute('data-theme', state.settings.theme || 'system');
  }

  // ===================================================================
  //  TOAST
  // ===================================================================
  let toastTimer = null;
  function toast(msg, kind) {
    const el = $('toast');
    if (!el) return;
    el.textContent = msg;
    el.className = 'toast' + (kind === 'success' ? ' toast-success' : '');
    el.hidden = false;
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { el.hidden = true; }, 2200);
  }

  // ===================================================================
  //  CVD helper — returns the hex a swatch should display as, given the
  //  active simulation mode.
  // ===================================================================
  function displayHex(hex) {
    return C.simulateCvd(hex, state.settings.cvd);
  }

  function formatColor(hex) {
    if (state.settings.colorNotation === 'hsl') {
      const h = C.hexToHsl(hex);
      if (!h) return hex;
      return 'hsl(' + Math.round(h.h) + ' ' + Math.round(h.s) + '% ' + Math.round(h.l) + '%)';
    }
    return (C.normalizeHex(hex) || hex).toUpperCase();
  }

  // ===================================================================
  //  PALETTE SELECT (header)
  // ===================================================================
  function renderPaletteSelect() {
    const sel = $('palette-select');
    if (!sel) return;
    sel.innerHTML = '';
    if (!state.palettes.length) {
      const opt = document.createElement('option');
      opt.textContent = 'No palettes';
      opt.value = '';
      sel.appendChild(opt);
      sel.disabled = true;
      return;
    }
    sel.disabled = false;
    state.palettes.forEach(function (p) {
      const opt = document.createElement('option');
      opt.value = p.id;
      opt.textContent = p.name + ' (' + p.swatches.length + ')';
      if (p.id === state.activePaletteId) opt.selected = true;
      sel.appendChild(opt);
    });
  }

  // ===================================================================
  //  SWATCH GRID
  // ===================================================================
  function renderSwatches() {
    const grid = $('swatch-grid');
    const empty = $('empty-state');
    if (!grid) return;
    grid.innerHTML = '';
    const pal = activePalette();

    if (!pal || pal.swatches.length === 0) {
      setHidden(empty, false);
      return;
    }
    setHidden(empty, true);

    pal.swatches.forEach(function (sw, index) {
      const li = document.createElement('li');
      li.className = 'swatch';

      const shown = displayHex(sw.hex);
      const chip = document.createElement('div');
      chip.className = 'swatch-chip';
      chip.style.background = shown;

      const meta = document.createElement('div');
      meta.className = 'swatch-meta';
      const name = document.createElement('p');
      name.className = 'swatch-name';
      name.textContent = sw.name || 'Swatch';
      const hex = document.createElement('p');
      hex.className = 'swatch-hex mono';
      hex.textContent = formatColor(sw.hex);
      meta.appendChild(name);
      meta.appendChild(hex);
      if (sw.role) {
        const tag = document.createElement('span');
        tag.className = 'swatch-role-tag';
        tag.textContent = sw.role;
        meta.appendChild(tag);
      }

      const actions = document.createElement('div');
      actions.className = 'swatch-actions';
      actions.appendChild(miniBtn('FG', 'Use ' + sw.name + ' as foreground', function () {
        setPicker('fg', sw.hex); renderContrast();
      }));
      actions.appendChild(miniBtn('BG', 'Use ' + sw.name + ' as background', function () {
        setPicker('bg', sw.hex); renderContrast();
      }));
      actions.appendChild(miniBtn('Edit', 'Edit ' + sw.name, function () {
        beginEdit(sw.id);
      }));
      actions.appendChild(miniBtn('▲', 'Move ' + sw.name + ' up', function () {
        moveSwatch(sw.id, -1);
      }, index === 0));
      actions.appendChild(miniBtn('▼', 'Move ' + sw.name + ' down', function () {
        moveSwatch(sw.id, 1);
      }, index === pal.swatches.length - 1));
      actions.appendChild(miniBtn('✕', 'Delete ' + sw.name, function () {
        deleteSwatch(sw.id);
      }));

      li.appendChild(chip);
      li.appendChild(meta);
      li.appendChild(actions);
      grid.appendChild(li);
    });
  }

  function miniBtn(label, aria, fn, disabled) {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'mini-btn';
    b.textContent = label;
    b.setAttribute('aria-label', aria);
    if (disabled) b.disabled = true;
    b.addEventListener('click', fn);
    return b;
  }

  // ---- swatch CRUD ----
  function moveSwatch(id, dir) {
    const pal = activePalette();
    if (!pal) return;
    const i = pal.swatches.findIndex(function (s) { return s.id === id; });
    const j = i + dir;
    if (i < 0 || j < 0 || j >= pal.swatches.length) return;
    const tmp = pal.swatches[i];
    pal.swatches[i] = pal.swatches[j];
    pal.swatches[j] = tmp;
    persist();
    renderAll();
  }

  function deleteSwatch(id) {
    const pal = activePalette();
    if (!pal) return;
    pal.swatches = pal.swatches.filter(function (s) { return s.id !== id; });
    if (editingSwatchId === id) cancelEdit();
    persist();
    renderAll();
  }

  function beginEdit(id) {
    const pal = activePalette();
    if (!pal) return;
    const sw = pal.swatches.find(function (s) { return s.id === id; });
    if (!sw) return;
    editingSwatchId = id;
    $('swatch-name').value = sw.name;
    $('swatch-role').value = sw.role || '';
    setFormColor(sw.hex);
    $('add-swatch-btn').textContent = 'Save changes';
    setHidden($('cancel-edit-btn'), false);
    $('swatch-name').focus();
  }

  function cancelEdit() {
    editingSwatchId = null;
    $('add-swatch-btn').textContent = 'Add swatch';
    setHidden($('cancel-edit-btn'), true);
    clearHexError();
  }

  // ===================================================================
  //  ADD/EDIT FORM — RGB/HSL/hex kept in sync
  // ===================================================================
  function setFormColor(hex) {
    const norm = C.normalizeHex(hex);
    if (!norm) return;
    $('swatch-hex').value = norm.toUpperCase();
    const rgb = C.hexToRgb(norm);
    const hsl = C.rgbToHsl(rgb.r, rgb.g, rgb.b);
    $('r-range').value = $('r-num').value = rgb.r;
    $('g-range').value = $('g-num').value = rgb.g;
    $('b-range').value = $('b-num').value = rgb.b;
    $('h-range').value = $('h-num').value = Math.round(hsl.h);
    $('s-range').value = $('s-num').value = Math.round(hsl.s);
    $('l-range').value = $('l-num').value = Math.round(hsl.l);
    $('swatch-preview').style.background = displayHex(norm);
    clearHexError();
  }

  function syncFromRgb() {
    const r = C.clamp($('r-num').value, 0, 255);
    const g = C.clamp($('g-num').value, 0, 255);
    const b = C.clamp($('b-num').value, 0, 255);
    setFormColor(C.rgbToHex(r, g, b));
  }

  function syncFromHsl() {
    const h = C.clamp($('h-num').value, 0, 360);
    const s = C.clamp($('s-num').value, 0, 100);
    const l = C.clamp($('l-num').value, 0, 100);
    setFormColor(C.hslToHex(h, s, l));
  }

  function showHexError(msg) {
    const el = $('hex-error');
    el.textContent = msg;
    setHidden(el, false);
  }
  function clearHexError() {
    const el = $('hex-error');
    if (el) { el.textContent = ''; setHidden(el, true); }
  }

  function wireForm() {
    // hex field — live preview + validation
    on($('swatch-hex'), 'input', function () {
      const v = $('swatch-hex').value;
      const norm = C.normalizeHex(v);
      if (norm) {
        setFormColor(norm);
      } else if (v.trim() !== '') {
        showHexError('Enter a valid hex like #5B8CFF or #abc.');
      } else {
        clearHexError();
      }
    });

    // RGB inputs
    ['r', 'g', 'b'].forEach(function (ch) {
      on($(ch + '-range'), 'input', function () { $(ch + '-num').value = $(ch + '-range').value; syncFromRgb(); });
      on($(ch + '-num'), 'input', syncFromRgb);
    });
    // HSL inputs
    ['h', 's', 'l'].forEach(function (ch) {
      on($(ch + '-range'), 'input', function () { $(ch + '-num').value = $(ch + '-range').value; syncFromHsl(); });
      on($(ch + '-num'), 'input', syncFromHsl);
    });

    on($('add-swatch-form'), 'submit', function (e) {
      e.preventDefault();
      submitSwatch();
    });
    on($('cancel-edit-btn'), 'click', cancelEdit);
  }

  function submitSwatch() {
    let pal = activePalette();
    if (!pal) {
      // No palette exists — create one so the swatch has a home.
      pal = createPalette('My palette', false);
    }
    const hex = C.normalizeHex($('swatch-hex').value);
    if (!hex) {
      showHexError('Enter a valid hex like #5B8CFF or #abc.');
      $('swatch-hex').focus();
      return;
    }
    const name = ($('swatch-name').value || '').trim() || 'Swatch';
    const role = $('swatch-role').value || '';

    if (editingSwatchId) {
      const sw = pal.swatches.find(function (s) { return s.id === editingSwatchId; });
      if (sw) { sw.name = name; sw.hex = hex; sw.role = role; }
      cancelEdit();
      toast('Swatch updated', 'success');
    } else {
      pal.swatches.push({ id: Store.genId('sw'), name: name, hex: hex, role: role });
      toast('Swatch added', 'success');
    }
    $('swatch-name').value = '';
    $('swatch-role').value = '';
    persist();
    renderAll();
  }

  // ===================================================================
  //  PALETTE management
  // ===================================================================
  function createPalette(name, focus) {
    const pal = { id: Store.genId('pal'), name: name || 'Untitled', swatches: [] };
    state.palettes.push(pal);
    state.activePaletteId = pal.id;
    persist();
    renderAll();
    if (focus !== false) toast('Palette created', 'success');
    return pal;
  }

  function wirePaletteControls() {
    on($('palette-select'), 'change', function () {
      state.activePaletteId = $('palette-select').value;
      cancelEdit();
      persist();
      renderAll();
    });
    on($('new-palette-btn'), 'click', function () {
      const name = window.prompt('Name your new palette:', 'Untitled');
      if (name === null) return;
      createPalette(name.trim() || 'Untitled');
    });
    on($('rename-palette-btn'), 'click', function () {
      const pal = activePalette();
      if (!pal) { toast('No palette to rename'); return; }
      const name = window.prompt('Rename palette:', pal.name);
      if (name === null) return;
      pal.name = name.trim() || pal.name;
      persist();
      renderAll();
    });
    on($('delete-palette-btn'), 'click', function () {
      const pal = activePalette();
      if (!pal) { toast('No palette to delete'); return; }
      if (!window.confirm('Delete palette "' + pal.name + '"? This cannot be undone.')) return;
      state.palettes = state.palettes.filter(function (p) { return p.id !== pal.id; });
      state.activePaletteId = state.palettes.length ? state.palettes[0].id : null;
      cancelEdit();
      persist();
      renderAll();
      toast('Palette deleted');
    });
    on($('load-sample-btn'), 'click', function () {
      loadSamples();
      toast('Sample palettes loaded', 'success');
    });
  }

  function loadSamples() {
    const samples = Seed.samplePalettes();
    samples.forEach(function (p) {
      // Re-id to avoid colliding with anything already stored.
      p.id = Store.genId('pal');
      p.swatches.forEach(function (s) { s.id = Store.genId('sw'); });
      state.palettes.push(p);
    });
    state.activePaletteId = state.palettes[state.palettes.length - samples.length].id;
    persist();
    renderAll();
  }

  // ===================================================================
  //  CONTRAST CHECKER
  // ===================================================================
  function setPicker(which, hex) {
    const norm = C.normalizeHex(hex);
    if (!norm) return;
    pickerForm[which] = norm;
    $(which + '-pick').value = norm.toUpperCase();
  }

  function wireContrast() {
    ['fg', 'bg'].forEach(function (which) {
      on($(which + '-pick'), 'input', function () {
        const v = $(which + '-pick').value;
        const norm = C.normalizeHex(v);
        const err = $(which + '-error');
        if (norm) {
          pickerForm[which] = norm;
          setHidden(err, true);
          renderContrast();
        } else if (v.trim() !== '') {
          err.textContent = 'Invalid hex.';
          setHidden(err, false);
        }
      });
    });
    on($('swap-btn'), 'click', function () {
      const t = pickerForm.fg;
      setPicker('fg', pickerForm.bg);
      setPicker('bg', t);
      renderContrast();
    });
  }

  function renderContrast() {
    // Use the simulated colors so contrast reflects what a CVD user sees.
    const fg = displayHex(pickerForm.fg);
    const bg = displayHex(pickerForm.bg);
    $('fg-dot').style.background = fg;
    $('bg-dot').style.background = bg;

    const ratio = C.contrastRatio(fg, bg);
    $('ratio-number').textContent = C.formatRatio(ratio);

    const levels = C.wcagLevels(ratio);
    const badges = $('wcag-badges');
    badges.innerHTML = '';
    badges.appendChild(badge('AA normal', levels.aaNormal));
    badges.appendChild(badge('AA large', levels.aaLarge));
    badges.appendChild(badge('AAA normal', levels.aaaNormal));
    badges.appendChild(badge('AAA large', levels.aaaLarge));

    const tp = $('text-preview');
    tp.style.background = bg;
    tp.style.color = fg;
  }

  function badge(label, pass) {
    const b = document.createElement('span');
    b.className = 'badge ' + (pass ? 'pass' : 'fail');
    b.innerHTML = '<span class="badge-label">' + label + '</span> ' + (pass ? 'Pass' : 'Fail');
    b.setAttribute('aria-label', label + ' ' + (pass ? 'passes' : 'fails'));
    return b;
  }

  // ===================================================================
  //  LIVE UI PREVIEW (role-driven)
  // ===================================================================
  function roleColor(role, fallback) {
    const pal = activePalette();
    if (pal) {
      const sw = pal.swatches.find(function (s) { return s.role === role; });
      if (sw) return sw.hex;
    }
    return fallback;
  }

  function renderPreview() {
    const bg = displayHex(roleColor('bg', '#EDEEF3'));
    const surface = displayHex(roleColor('surface', '#FFFFFF'));
    const text = displayHex(roleColor('text', '#1B1D2A'));
    const accent = displayHex(roleColor('accent', '#3A3E4C'));

    $('mock-stage').style.background = bg;
    const card = $('mock-card');
    card.style.background = surface;
    $('mock-title').style.color = text;
    $('mock-body').style.color = text;
    const btn = $('mock-btn');
    btn.style.background = accent;
    btn.style.color = C.bestTextOn(accent);

    // Flag any failing AA text pair.
    const titleRatio = C.contrastRatio(text, surface);
    const bodyRatio = titleRatio; // same colors
    const btnRatio = C.contrastRatio(C.bestTextOn(accent), accent);
    const flag = $('preview-flag');
    const fails = [];
    if (titleRatio < 4.5) fails.push('text on surface (' + C.formatRatio(titleRatio) + ')');
    if (btnRatio < 4.5) fails.push('button label (' + C.formatRatio(btnRatio) + ')');

    if (fails.length) {
      flag.className = 'preview-flag bad';
      flag.textContent = 'Fails AA: ' + fails.join(', ') + '.';
    } else {
      flag.className = 'preview-flag ok';
      flag.textContent = 'All preview text passes AA (≥4.5:1). Body ' + C.formatRatio(bodyRatio) + '.';
    }
  }

  // ===================================================================
  //  SCALE & HARMONY
  // ===================================================================
  function renderBaseSelect() {
    const sel = $('base-select');
    if (!sel) return;
    const prev = sel.value;
    sel.innerHTML = '';
    const pal = activePalette();
    if (!pal || !pal.swatches.length) {
      const opt = document.createElement('option');
      opt.textContent = 'Add a swatch first';
      opt.value = '';
      sel.appendChild(opt);
      sel.disabled = true;
      return;
    }
    sel.disabled = false;
    pal.swatches.forEach(function (sw) {
      const opt = document.createElement('option');
      opt.value = sw.hex;
      opt.textContent = sw.name + ' · ' + (C.normalizeHex(sw.hex) || sw.hex).toUpperCase();
      sel.appendChild(opt);
    });
    // Keep selection if still present, else first.
    if (prev && pal.swatches.some(function (s) { return s.hex === prev; })) {
      sel.value = prev;
    }
  }

  function renderScaleAndHarmony() {
    const sel = $('base-select');
    const scaleRow = $('scale-row');
    const harmonyWrap = $('harmony-sets');
    scaleRow.innerHTML = '';
    harmonyWrap.innerHTML = '';

    const base = sel && sel.value ? sel.value : null;
    if (!base) return;

    C.generateScale(base).forEach(function (step) {
      scaleRow.appendChild(colorChip(step.hex, step.key));
    });

    const harm = C.generateHarmonies(base);
    [['Complementary', harm.complementary], ['Analogous', harm.analogous], ['Triadic', harm.triadic]]
      .forEach(function (pair) {
        const set = document.createElement('div');
        set.className = 'harmony-set';
        const h = document.createElement('p');
        h.className = 'harmony-name';
        h.textContent = pair[0];
        const row = document.createElement('ul');
        row.className = 'harmony-row';
        pair[1].forEach(function (hex) {
          const li = document.createElement('li');
          li.appendChild(colorChip(hex, ''));
          row.appendChild(li);
        });
        set.appendChild(h);
        set.appendChild(row);
        harmonyWrap.appendChild(set);
      });
  }

  function colorChip(hex, label) {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'chip';
    b.setAttribute('aria-label', 'Add ' + (C.normalizeHex(hex) || hex).toUpperCase() + ' to palette');
    const color = document.createElement('span');
    color.className = 'chip-color';
    color.style.background = displayHex(hex);
    b.appendChild(color);
    const lab = document.createElement('span');
    lab.className = 'chip-label';
    lab.textContent = label || (C.normalizeHex(hex) || hex).slice(1).toUpperCase();
    b.appendChild(lab);
    b.addEventListener('click', function () {
      let pal = activePalette();
      if (!pal) pal = createPalette('My palette', false);
      pal.swatches.push({ id: Store.genId('sw'), name: label ? 'Shade ' + label : 'Color', hex: C.normalizeHex(hex), role: '' });
      persist();
      renderAll();
      toast('Added ' + (C.normalizeHex(hex) || hex).toUpperCase(), 'success');
    });
    return b;
  }

  function wireBaseSelect() {
    on($('base-select'), 'change', renderScaleAndHarmony);
  }

  // ===================================================================
  //  EXPORT / IMPORT
  // ===================================================================
  function slug(s) {
    return (s || 'color').toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '') || 'color';
  }

  function buildCss(pal) {
    if (!pal) return ':root {\n  /* no palette */\n}\n';
    const seen = {};
    const lines = pal.swatches.map(function (sw) {
      let key = slug(sw.name);
      seen[key] = (seen[key] || 0) + 1;
      if (seen[key] > 1) key += '-' + seen[key];
      const roleComment = sw.role ? '  /* role: ' + sw.role + ' */' : '';
      return '  --' + key + ': ' + (C.normalizeHex(sw.hex) || sw.hex) + ';' + roleComment;
    });
    return '/* ' + pal.name + ' — exported from Chroma */\n:root {\n' + lines.join('\n') + '\n}\n';
  }

  function buildJson(pal) {
    if (!pal) return '{}';
    return JSON.stringify({
      name: pal.name,
      swatches: pal.swatches.map(function (sw) {
        return { name: sw.name, hex: (C.normalizeHex(sw.hex) || sw.hex), role: sw.role || '' };
      })
    }, null, 2);
  }

  function currentExportText() {
    const pal = activePalette();
    return exportFormat === 'json' ? buildJson(pal) : buildCss(pal);
  }

  function renderExport() {
    $('export-out').value = currentExportText();
    $('tab-css').setAttribute('aria-selected', exportFormat === 'css' ? 'true' : 'false');
    $('tab-json').setAttribute('aria-selected', exportFormat === 'json' ? 'true' : 'false');
  }

  function downloadBlob(filename, mime, data) {
    try {
      const blob = new Blob([data], { type: mime });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
      return true;
    } catch (e) {
      toast('Download failed in this browser');
      return false;
    }
  }

  function copyText(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(function () {
        toast('Copied to clipboard', 'success');
      }, function () { fallbackCopy(text); });
    } else {
      fallbackCopy(text);
    }
  }

  function fallbackCopy(text) {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    let ok = false;
    try { ok = document.execCommand('copy'); } catch (e) { ok = false; }
    document.body.removeChild(ta);
    toast(ok ? 'Copied to clipboard' : 'Copy not supported — select and copy manually', ok ? 'success' : undefined);
  }

  function exportPng() {
    const pal = activePalette();
    if (!pal || !pal.swatches.length) { toast('Nothing to export'); return; }
    const btn = $('download-png-btn');
    const label = $('png-label');
    btn.disabled = true;
    label.textContent = 'Rendering…';

    // Defer so the disabled/loading state actually paints.
    setTimeout(function () {
      try {
        const cols = Math.min(4, pal.swatches.length);
        const rows = Math.ceil(pal.swatches.length / cols);
        const cell = 180, pad = 24, header = 70, footer = 30;
        const canvas = $('sheet-canvas');
        canvas.width = cols * cell + pad * 2;
        canvas.height = header + rows * cell + pad + footer;
        const ctx = canvas.getContext('2d');

        ctx.fillStyle = '#EDEEF3';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = '#1B1D2A';
        ctx.font = '700 26px system-ui, sans-serif';
        ctx.fillText(pal.name, pad, 44);
        ctx.fillStyle = '#565A70';
        ctx.font = '14px system-ui, sans-serif';
        ctx.fillText('Exported from Chroma · ' + pal.swatches.length + ' swatches', pad, 62);

        pal.swatches.forEach(function (sw, i) {
          const cx = pad + (i % cols) * cell;
          const cy = header + Math.floor(i / cols) * cell;
          const shown = displayHex(sw.hex);
          ctx.fillStyle = shown;
          roundRect(ctx, cx + 6, cy + 6, cell - 12, cell - 56, 14);
          ctx.fill();
          ctx.fillStyle = '#1B1D2A';
          ctx.font = '700 15px system-ui, sans-serif';
          ctx.fillText(truncate(ctx, sw.name, cell - 16), cx + 8, cy + cell - 30);
          ctx.fillStyle = '#565A70';
          ctx.font = '13px ui-monospace, monospace';
          ctx.fillText((C.normalizeHex(sw.hex) || sw.hex).toUpperCase(), cx + 8, cy + cell - 12);
        });

        const url = canvas.toDataURL('image/png');
        const a = document.createElement('a');
        a.href = url;
        a.download = slug(pal.name) + '-swatches.png';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        toast('PNG downloaded', 'success');
      } catch (e) {
        toast('PNG export failed');
      } finally {
        btn.disabled = false;
        label.textContent = 'Download PNG sheet';
      }
    }, 30);
  }

  function roundRect(ctx, x, y, w, h, r) {
    r = Math.min(r, w / 2, h / 2);
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }

  function truncate(ctx, text, maxW) {
    if (ctx.measureText(text).width <= maxW) return text;
    let t = text;
    while (t.length > 1 && ctx.measureText(t + '…').width > maxW) t = t.slice(0, -1);
    return t + '…';
  }

  function importPalette() {
    const raw = $('import-in').value;
    const msg = $('import-msg');
    if (!raw.trim()) {
      msg.textContent = 'Paste JSON first.';
      return;
    }
    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch (e) {
      msg.textContent = 'That is not valid JSON. Check for missing quotes or commas.';
      return;
    }
    if (!parsed || typeof parsed !== 'object' || !Array.isArray(parsed.swatches)) {
      msg.textContent = 'JSON must have a "swatches" array.';
      return;
    }
    const swatches = [];
    let skipped = 0;
    parsed.swatches.forEach(function (s) {
      const hex = s && C.normalizeHex(s.hex);
      if (!hex) { skipped += 1; return; }
      swatches.push({
        id: Store.genId('sw'),
        name: (s.name && String(s.name)) || 'Swatch',
        hex: hex,
        role: (s.role && String(s.role)) || ''
      });
    });
    if (!swatches.length) {
      msg.textContent = 'No usable swatches found (all hex values were invalid).';
      return;
    }
    const pal = {
      id: Store.genId('pal'),
      name: (parsed.name && String(parsed.name)) || 'Imported palette',
      swatches: swatches
    };
    state.palettes.push(pal);
    state.activePaletteId = pal.id;
    persist();
    renderAll();
    $('import-in').value = '';
    msg.textContent = 'Imported "' + pal.name + '" (' + swatches.length + ' swatches' +
      (skipped ? ', ' + skipped + ' skipped' : '') + ').';
    toast('Palette imported', 'success');
  }

  function wireExport() {
    on($('tab-css'), 'click', function () { exportFormat = 'css'; renderExport(); });
    on($('tab-json'), 'click', function () { exportFormat = 'json'; renderExport(); });
    on($('copy-btn'), 'click', function () { copyText(currentExportText()); });
    on($('download-text-btn'), 'click', function () {
      const pal = activePalette();
      const base = slug(pal ? pal.name : 'palette');
      if (exportFormat === 'json') {
        downloadBlob(base + '.tokens.json', 'application/json', currentExportText());
      } else {
        downloadBlob(base + '.css', 'text/css', currentExportText());
      }
    });
    on($('download-png-btn'), 'click', exportPng);
    on($('import-btn'), 'click', importPalette);
  }

  // ===================================================================
  //  CVD select
  // ===================================================================
  function wireCvd() {
    const sel = $('cvd-select');
    on(sel, 'change', function () {
      state.settings.cvd = sel.value;
      persist();
      $('cvd-desc').textContent = C.CVD_DESCRIPTIONS[sel.value] || '';
      renderAll();
    });
  }

  // ===================================================================
  //  SETTINGS dialog
  // ===================================================================
  let lastFocused = null;
  function openSettings() {
    lastFocused = document.activeElement;
    $('theme-select').value = state.settings.theme;
    $('export-default-select').value = state.settings.defaultExport;
    $('notation-select').value = state.settings.colorNotation;
    setHidden($('settings-backdrop'), false);
    setHidden($('settings-dialog'), false);
    $('settings-close').focus();
    document.addEventListener('keydown', onSettingsKey);
  }
  function closeSettings() {
    setHidden($('settings-backdrop'), true);
    setHidden($('settings-dialog'), true);
    document.removeEventListener('keydown', onSettingsKey);
    if (lastFocused && lastFocused.focus) lastFocused.focus();
  }
  function onSettingsKey(e) {
    if (e.key === 'Escape') { closeSettings(); return; }
    if (e.key === 'Tab') {
      // simple focus trap
      const dialog = $('settings-dialog');
      const focusable = dialog.querySelectorAll('button, select, [href], input, textarea, [tabindex]:not([tabindex="-1"])');
      if (!focusable.length) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
      else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
    }
  }

  function wireSettings() {
    on($('settings-btn'), 'click', openSettings);
    on($('settings-close'), 'click', closeSettings);
    on($('settings-backdrop'), 'click', closeSettings);

    on($('theme-select'), 'change', function () {
      state.settings.theme = $('theme-select').value;
      persist();
      applyTheme();
      renderAll();
    });
    on($('export-default-select'), 'change', function () {
      state.settings.defaultExport = $('export-default-select').value;
      exportFormat = state.settings.defaultExport;
      persist();
      renderExport();
    });
    on($('notation-select'), 'change', function () {
      state.settings.colorNotation = $('notation-select').value;
      persist();
      renderAll();
    });
    on($('reset-samples-btn'), 'click', function () {
      if (!window.confirm('Replace all palettes with the sample palettes?')) return;
      state.palettes = [];
      state.activePaletteId = null;
      loadSamples();
      closeSettings();
      toast('Reset to sample palettes', 'success');
    });
    on($('clear-all-btn'), 'click', function () {
      if (!window.confirm('Clear ALL palettes and settings? This cannot be undone.')) return;
      Store.clear();
      state = Store.freshState();
      exportFormat = state.settings.defaultExport;
      cancelEdit();
      applyTheme();
      closeSettings();
      renderAll();
      toast('All data cleared');
    });
  }

  // ===================================================================
  //  STORAGE note
  // ===================================================================
  function renderStorageNote() {
    const el = $('storage-note');
    if (!el) return;
    // Probe whether a save round-trips to real localStorage.
    let durable = false;
    try {
      window.localStorage.setItem('__chroma_probe__', '1');
      durable = window.localStorage.getItem('__chroma_probe__') === '1';
      window.localStorage.removeItem('__chroma_probe__');
    } catch (e) { durable = false; }
    el.textContent = durable
      ? 'data saved locally in your browser'
      : 'storage unavailable — changes kept only this session';
  }

  // ===================================================================
  //  RENDER ALL
  // ===================================================================
  function renderAll() {
    renderPaletteSelect();
    renderSwatches();
    renderContrast();
    renderPreview();
    renderBaseSelect();
    renderScaleAndHarmony();
    renderExport();
  }

  // ===================================================================
  //  INIT
  // ===================================================================
  function init() {
    // First open: seed samples if there is nothing stored.
    if (!state.palettes.length) {
      const samples = Seed.samplePalettes();
      state.palettes = samples;
      state.activePaletteId = samples[0].id;
      persist();
    }

    exportFormat = state.settings.defaultExport || 'css';
    applyTheme();

    // sync controls to persisted settings
    $('cvd-select').value = state.settings.cvd || 'none';
    $('cvd-desc').textContent = C.CVD_DESCRIPTIONS[state.settings.cvd] || '';

    // initialize picker fields with current values
    setPicker('fg', pickerForm.fg);
    setPicker('bg', pickerForm.bg);
    setFormColor('#5B8CFF');

    wireForm();
    wirePaletteControls();
    wireContrast();
    wireBaseSelect();
    wireExport();
    wireCvd();
    wireSettings();
    renderStorageNote();
    renderAll();

    // React to OS theme changes when in "system" mode.
    if (window.matchMedia) {
      const mq = window.matchMedia('(prefers-color-scheme: dark)');
      const handler = function () { if (state.settings.theme === 'system') renderAll(); };
      if (mq.addEventListener) mq.addEventListener('change', handler);
      else if (mq.addListener) mq.addListener(handler);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
