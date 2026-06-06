/*
 * storage.js — localStorage persistence for Keystone.
 *
 * Holds the full app state: the list of projects, the active project id,
 * and user settings. All reads/writes are defensive: a corrupt or absent
 * store yields a clean default rather than a crash.
 */

(function (root) {
  "use strict";

  var KEY = "keystone.state.v1";

  var DEFAULT_SETTINGS = {
    showSlackBars: true,
    dark: false,
    confirmDeletes: true,
  };

  function defaultState() {
    return {
      projects: [],
      activeId: null,
      settings: cloneSettings(DEFAULT_SETTINGS),
    };
  }

  function cloneSettings(s) {
    return {
      showSlackBars: s.showSlackBars !== false,
      dark: s.dark === true,
      confirmDeletes: s.confirmDeletes !== false,
    };
  }

  function load() {
    var raw;
    try {
      raw = root.localStorage.getItem(KEY);
    } catch (e) {
      return defaultState();
    }
    if (!raw) return defaultState();
    try {
      var parsed = JSON.parse(raw);
      if (!parsed || typeof parsed !== "object") return defaultState();
      var state = defaultState();
      if (Array.isArray(parsed.projects)) state.projects = parsed.projects;
      if (typeof parsed.activeId === "string") state.activeId = parsed.activeId;
      if (parsed.settings) state.settings = cloneSettings(parsed.settings);
      // Repair a dangling activeId.
      if (
        state.activeId &&
        !state.projects.some(function (p) {
          return p.id === state.activeId;
        })
      ) {
        state.activeId = state.projects.length ? state.projects[0].id : null;
      }
      return state;
    } catch (e) {
      return defaultState();
    }
  }

  function save(state) {
    try {
      root.localStorage.setItem(KEY, JSON.stringify(state));
      return true;
    } catch (e) {
      return false;
    }
  }

  function clearAll() {
    try {
      root.localStorage.removeItem(KEY);
      return true;
    } catch (e) {
      return false;
    }
  }

  var STORAGE = {
    KEY: KEY,
    DEFAULT_SETTINGS: DEFAULT_SETTINGS,
    defaultState: defaultState,
    load: load,
    save: save,
    clearAll: clearAll,
  };

  if (typeof module !== "undefined" && module.exports) {
    module.exports = STORAGE;
  } else {
    root.STORAGE = STORAGE;
  }
})(typeof self !== "undefined" ? self : this);
