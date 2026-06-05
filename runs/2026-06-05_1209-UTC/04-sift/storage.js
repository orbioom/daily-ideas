/* ============================================================
   storage.js — localStorage persistence for Sift
   Namespaced under "orbioom.sift.v1". Holds:
     - snippets: saved test cases (array)
     - settings: { theme, distinctGroups }
     - seeded:   flag so seed data only loads once
   All reads/writes are wrapped so a disabled or full
   localStorage degrades to in-memory state instead of crashing.
   ============================================================ */

const SiftStore = (() => {
  const ROOT = 'orbioom.sift.v1';
  const K = {
    snippets: ROOT + '.snippets',
    settings: ROOT + '.settings',
    seeded: ROOT + '.seeded'
  };

  const DEFAULT_SETTINGS = {
    theme: 'system',          // 'light' | 'dark' | 'system'
    distinctGroups: true      // color capture groups distinctly
  };

  /* In-memory fallback if localStorage is unavailable (private mode, etc.) */
  let usable = true;
  const mem = {};
  try {
    const probe = ROOT + '.probe';
    window.localStorage.setItem(probe, '1');
    window.localStorage.removeItem(probe);
  } catch (e) {
    usable = false;
  }

  function rawGet(key) {
    if (!usable) return key in mem ? mem[key] : null;
    try { return window.localStorage.getItem(key); }
    catch (e) { return key in mem ? mem[key] : null; }
  }
  function rawSet(key, value) {
    mem[key] = value;
    if (!usable) return;
    try { window.localStorage.setItem(key, value); }
    catch (e) { usable = false; } // quota or blocked → fall back to memory
  }

  function readJSON(key, fallback) {
    const raw = rawGet(key);
    if (raw == null) return fallback;
    try {
      const parsed = JSON.parse(raw);
      return parsed == null ? fallback : parsed;
    } catch (e) {
      return fallback;
    }
  }

  /* ---------- Snippets ---------- */
  function getSnippets() {
    const list = readJSON(K.snippets, []);
    return Array.isArray(list) ? list.filter(isValidSnippet) : [];
  }
  function setSnippets(list) {
    const clean = Array.isArray(list) ? list.filter(isValidSnippet) : [];
    rawSet(K.snippets, JSON.stringify(clean));
    return clean;
  }
  function isValidSnippet(s) {
    return s && typeof s === 'object' &&
      typeof s.id === 'string' &&
      typeof s.name === 'string' &&
      typeof s.pattern === 'string';
  }

  function addSnippet(snippet) {
    const list = getSnippets();
    list.unshift(snippet);
    setSnippets(list);
    return snippet;
  }
  function updateSnippet(id, patch) {
    const list = getSnippets();
    const idx = list.findIndex(s => s.id === id);
    if (idx === -1) return null;
    list[idx] = Object.assign({}, list[idx], patch, { updatedAt: nowISO() });
    setSnippets(list);
    return list[idx];
  }
  function deleteSnippet(id) {
    const list = getSnippets();
    const next = list.filter(s => s.id !== id);
    setSnippets(next);
    return next;
  }

  /* ---------- Settings ---------- */
  function getSettings() {
    const s = readJSON(K.settings, {});
    return Object.assign({}, DEFAULT_SETTINGS, s && typeof s === 'object' ? s : {});
  }
  function setSettings(patch) {
    const next = Object.assign({}, getSettings(), patch);
    rawSet(K.settings, JSON.stringify(next));
    return next;
  }

  /* ---------- Seed bootstrap ---------- */
  function isSeeded() { return rawGet(K.seeded) === 'true'; }
  function markSeeded() { rawSet(K.seeded, 'true'); }

  /* Full reset to sample data: re-seed snippets, reset settings, mark seeded. */
  function resetToSample(seedSnippets) {
    setSnippets(Array.isArray(seedSnippets) ? seedSnippets.slice() : []);
    rawSet(K.settings, JSON.stringify(DEFAULT_SETTINGS));
    markSeeded();
    return { snippets: getSnippets(), settings: getSettings() };
  }

  /* Bulk replace (used by import). */
  function replaceAllSnippets(list) {
    return setSnippets(list);
  }

  /* ---------- Helpers ---------- */
  function nowISO() { return new Date().toISOString(); }
  function newId() {
    if (window.crypto && typeof window.crypto.randomUUID === 'function') {
      return window.crypto.randomUUID();
    }
    return 'sn-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 8);
  }

  return {
    KEYS: K,
    DEFAULT_SETTINGS,
    isStorageUsable: () => usable,
    getSnippets, setSnippets, addSnippet, updateSnippet, deleteSnippet,
    replaceAllSnippets,
    getSettings, setSettings,
    isSeeded, markSeeded, resetToSample,
    nowISO, newId
  };
})();

window.SiftStore = SiftStore;
