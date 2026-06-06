/*
 * storage.js — Limpid persistence layer.
 *
 * Wraps localStorage for documents and settings with safe fallbacks when
 * storage is unavailable or corrupt. Documents are stored as a list with an
 * "active" pointer; settings are a flat object. Everything is namespaced.
 */
(function (root) {
  'use strict';

  var DOCS_KEY = 'limpid.documents.v1';
  var ACTIVE_KEY = 'limpid.activeDoc.v1';
  var SETTINGS_KEY = 'limpid.settings.v1';
  var SEEDED_KEY = 'limpid.seeded.v1';

  var DEFAULT_SETTINGS = {
    longThreshold: 25,
    targetGrade: 8,
    theme: 'light',
    highlights: {
      long: true,
      passive: true,
      adverb: true,
      filler: true,
      complex: false
    }
  };

  function available() {
    try {
      var k = '__limpid_test__';
      localStorage.setItem(k, '1');
      localStorage.removeItem(k);
      return true;
    } catch (e) {
      return false;
    }
  }

  var memoryStore = {};
  var HAS_LS = available();

  function rawGet(key) {
    if (HAS_LS) {
      try { return localStorage.getItem(key); } catch (e) { return null; }
    }
    return Object.prototype.hasOwnProperty.call(memoryStore, key) ? memoryStore[key] : null;
  }
  function rawSet(key, value) {
    if (HAS_LS) {
      try { localStorage.setItem(key, value); return true; } catch (e) { return false; }
    }
    memoryStore[key] = value;
    return true;
  }

  function uid() {
    return 'doc-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 8);
  }

  function loadDocuments() {
    var raw = rawGet(DOCS_KEY);
    if (!raw) return [];
    try {
      var parsed = JSON.parse(raw);
      if (!Array.isArray(parsed)) return [];
      return parsed.filter(function (d) {
        return d && typeof d.id === 'string' && typeof d.content === 'string';
      });
    } catch (e) {
      return [];
    }
  }

  function saveDocuments(docs) {
    return rawSet(DOCS_KEY, JSON.stringify(docs));
  }

  function getActiveId() {
    return rawGet(ACTIVE_KEY);
  }
  function setActiveId(id) {
    return rawSet(ACTIVE_KEY, id == null ? '' : String(id));
  }

  function createDocument(title, content) {
    var now = Date.now();
    return {
      id: uid(),
      title: title || 'Untitled',
      content: content || '',
      createdAt: now,
      updatedAt: now
    };
  }

  function loadSettings() {
    var raw = rawGet(SETTINGS_KEY);
    var s = JSON.parse(JSON.stringify(DEFAULT_SETTINGS));
    if (!raw) return s;
    try {
      var parsed = JSON.parse(raw);
      if (parsed && typeof parsed === 'object') {
        if (typeof parsed.longThreshold === 'number') s.longThreshold = parsed.longThreshold;
        if (typeof parsed.targetGrade === 'number') s.targetGrade = parsed.targetGrade;
        if (parsed.theme === 'light' || parsed.theme === 'dark') s.theme = parsed.theme;
        if (parsed.highlights && typeof parsed.highlights === 'object') {
          Object.keys(s.highlights).forEach(function (k) {
            if (typeof parsed.highlights[k] === 'boolean') s.highlights[k] = parsed.highlights[k];
          });
        }
      }
    } catch (e) { /* fall through to defaults */ }
    return s;
  }

  function saveSettings(settings) {
    return rawSet(SETTINGS_KEY, JSON.stringify(settings));
  }

  function isSeeded() {
    return rawGet(SEEDED_KEY) === '1';
  }
  function markSeeded() {
    return rawSet(SEEDED_KEY, '1');
  }

  function resetAll() {
    [DOCS_KEY, ACTIVE_KEY, SETTINGS_KEY, SEEDED_KEY].forEach(function (k) {
      if (HAS_LS) { try { localStorage.removeItem(k); } catch (e) {} }
      delete memoryStore[k];
    });
  }

  var api = {
    DEFAULT_SETTINGS: DEFAULT_SETTINGS,
    hasLocalStorage: HAS_LS,
    loadDocuments: loadDocuments,
    saveDocuments: saveDocuments,
    getActiveId: getActiveId,
    setActiveId: setActiveId,
    createDocument: createDocument,
    loadSettings: loadSettings,
    saveSettings: saveSettings,
    isSeeded: isSeeded,
    markSeeded: markSeeded,
    resetAll: resetAll
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
  } else {
    root.LimpidStorage = api;
  }
})(typeof self !== 'undefined' ? self : this);
