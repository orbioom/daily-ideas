/*
 * storage.js — durable state for Chroma in localStorage.
 * Key: "orbioom.chroma.v1". All access is guarded; if storage is
 * unavailable (private mode, quota, disabled) the app degrades to an
 * in-memory copy instead of crashing.
 */
(function (global) {
  'use strict';

  const KEY = 'orbioom.chroma.v1';

  const DEFAULT_SETTINGS = {
    theme: 'system', // 'light' | 'dark' | 'system'
    defaultExport: 'css', // 'css' | 'json'
    colorNotation: 'hex', // 'hex' | 'hsl'
    cvd: 'none'
  };

  // In-memory fallback when localStorage is not writable.
  let memoryStore = null;

  function storageAvailable() {
    try {
      const t = '__chroma_test__';
      global.localStorage.setItem(t, t);
      global.localStorage.removeItem(t);
      return true;
    } catch (e) {
      return false;
    }
  }

  function freshState() {
    return {
      version: 1,
      palettes: [],
      activePaletteId: null,
      settings: Object.assign({}, DEFAULT_SETTINGS)
    };
  }

  function normalizeState(raw) {
    const state = freshState();
    if (!raw || typeof raw !== 'object') return state;
    if (Array.isArray(raw.palettes)) {
      state.palettes = raw.palettes
        .filter(function (p) { return p && typeof p === 'object'; })
        .map(function (p) {
          return {
            id: typeof p.id === 'string' ? p.id : genId('pal'),
            name: typeof p.name === 'string' && p.name.trim() ? p.name : 'Untitled',
            swatches: Array.isArray(p.swatches)
              ? p.swatches
                  .filter(function (s) { return s && typeof s === 'object'; })
                  .map(function (s) {
                    return {
                      id: typeof s.id === 'string' ? s.id : genId('sw'),
                      name: typeof s.name === 'string' ? s.name : 'Swatch',
                      hex: typeof s.hex === 'string' ? s.hex : '#000000',
                      role: typeof s.role === 'string' ? s.role : ''
                    };
                  })
              : []
          };
        });
    }
    if (typeof raw.activePaletteId === 'string') {
      state.activePaletteId = raw.activePaletteId;
    }
    if (raw.settings && typeof raw.settings === 'object') {
      state.settings = Object.assign({}, DEFAULT_SETTINGS, raw.settings);
    }
    // Ensure active id points at a real palette.
    if (!state.palettes.some(function (p) { return p.id === state.activePaletteId; })) {
      state.activePaletteId = state.palettes.length ? state.palettes[0].id : null;
    }
    return state;
  }

  function load() {
    if (!storageAvailable()) {
      return memoryStore ? normalizeState(memoryStore) : freshState();
    }
    try {
      const raw = global.localStorage.getItem(KEY);
      if (!raw) return freshState();
      return normalizeState(JSON.parse(raw));
    } catch (e) {
      // Corrupt JSON: start clean rather than crash.
      return freshState();
    }
  }

  function save(state) {
    const normalized = normalizeState(state);
    if (!storageAvailable()) {
      memoryStore = normalized;
      return false;
    }
    try {
      global.localStorage.setItem(KEY, JSON.stringify(normalized));
      return true;
    } catch (e) {
      memoryStore = normalized;
      return false;
    }
  }

  function clear() {
    if (storageAvailable()) {
      try { global.localStorage.removeItem(KEY); } catch (e) { /* ignore */ }
    }
    memoryStore = null;
  }

  let idCounter = 0;
  function genId(prefix) {
    idCounter += 1;
    return (prefix || 'id') + '-' + Date.now().toString(36) + '-' + idCounter.toString(36);
  }

  global.Storage = {
    KEY: KEY,
    DEFAULT_SETTINGS: DEFAULT_SETTINGS,
    load: load,
    save: save,
    clear: clear,
    genId: genId,
    freshState: freshState,
    normalizeState: normalizeState
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = global.Storage;
  }
})(typeof window !== 'undefined' ? window : this);
