/* storage.js — localStorage persistence layer for Stacks
 * Key: "orbioom.stacks.v1"
 * Tolerant decode: every read fills defaults for missing/legacy fields and
 * never throws. Returns a normalized, always-valid state object.
 */
(function (global) {
  "use strict";

  var STORAGE_KEY = "orbioom.stacks.v1";

  var STATUSES = ["want-to-read", "reading", "finished", "abandoned"];

  var BRAND_COLORS = [
    "#3A3E4C", "#565A70", "#5B6CA8", "#6E7BB0", "#86C79A",
    "#C7A36B", "#B07C8E", "#7A8CA0", "#9A6E8E", "#5E8C8C",
    "#8B6F5E", "#5EF0B0"
  ];

  // ---- ID generation -------------------------------------------------------
  function makeId(prefix) {
    var rand = Math.random().toString(36).slice(2, 8);
    var t = Date.now().toString(36);
    return (prefix || "id") + "_" + t + rand;
  }

  // ---- Coercion helpers ----------------------------------------------------
  function toStr(v, fallback) {
    if (v === null || v === undefined) return fallback || "";
    if (typeof v === "string") return v;
    try { return String(v); } catch (e) { return fallback || ""; }
  }

  function toInt(v, fallback, min, max) {
    var n = parseInt(v, 10);
    if (!isFinite(n) || isNaN(n)) n = fallback;
    if (typeof min === "number" && n < min) n = min;
    if (typeof max === "number" && n > max) n = max;
    return n;
  }

  function toNum(v, fallback, min, max) {
    var n = typeof v === "number" ? v : parseFloat(v);
    if (!isFinite(n) || isNaN(n)) n = fallback;
    if (typeof min === "number" && n < min) n = min;
    if (typeof max === "number" && n > max) n = max;
    return n;
  }

  function toArray(v) {
    if (Array.isArray(v)) return v.slice();
    return [];
  }

  function toBool(v, fallback) {
    if (typeof v === "boolean") return v;
    if (v === "true") return true;
    if (v === "false") return false;
    return !!fallback;
  }

  function normStatus(v) {
    var s = toStr(v, "want-to-read");
    return STATUSES.indexOf(s) >= 0 ? s : "want-to-read";
  }

  function normColor(v, fallback) {
    var s = toStr(v, "");
    if (/^#[0-9a-fA-F]{6}$/.test(s)) return s;
    if (/^#[0-9a-fA-F]{3}$/.test(s)) return s;
    return fallback || BRAND_COLORS[0];
  }

  function normDate(v, fallback) {
    var s = toStr(v, "");
    if (!s) return fallback || "";
    var d = new Date(s);
    if (isNaN(d.getTime())) return fallback || "";
    return s;
  }

  // ---- Normalizers ---------------------------------------------------------
  function normBook(b) {
    b = b && typeof b === "object" ? b : {};
    var pageCount = toInt(b.pageCount, 0, 0, 100000);
    var currentPage = toInt(b.currentPage, 0, 0, 100000);
    if (pageCount > 0 && currentPage > pageCount) currentPage = pageCount;
    var status = normStatus(b.status);
    var rating = toNum(b.rating, 0, 0, 5);
    // rating only meaningful when finished
    if (status !== "finished") rating = toNum(b.rating, 0, 0, 5);
    return {
      id: toStr(b.id, "") || makeId("book"),
      title: toStr(b.title, "Untitled"),
      author: toStr(b.author, "Unknown"),
      year: toInt(b.year, 0, -5000, 9999),
      pageCount: pageCount,
      genre: toStr(b.genre, ""),
      coverColor: normColor(b.coverColor, BRAND_COLORS[0]),
      status: status,
      currentPage: currentPage,
      rating: rating,
      review: toStr(b.review, ""),
      shelfIds: toArray(b.shelfIds).map(function (x) { return toStr(x, ""); }).filter(Boolean),
      dateAdded: normDate(b.dateAdded, new Date().toISOString()),
      dateFinished: normDate(b.dateFinished, "")
    };
  }

  function normShelf(s) {
    s = s && typeof s === "object" ? s : {};
    return {
      id: toStr(s.id, "") || makeId("shelf"),
      name: toStr(s.name, "Untitled Shelf"),
      description: toStr(s.description, ""),
      color: normColor(s.color, BRAND_COLORS[1])
    };
  }

  function normSession(ss) {
    ss = ss && typeof ss === "object" ? ss : {};
    var minutes = ss.minutes === null || ss.minutes === undefined || ss.minutes === ""
      ? null : toInt(ss.minutes, 0, 0, 100000);
    return {
      id: toStr(ss.id, "") || makeId("sess"),
      bookId: toStr(ss.bookId, ""),
      date: normDate(ss.date, new Date().toISOString().slice(0, 10)),
      pagesRead: toInt(ss.pagesRead, 0, 0, 100000),
      minutes: minutes,
      note: toStr(ss.note, "")
    };
  }

  function normSettings(s) {
    s = s && typeof s === "object" ? s : {};
    var theme = toStr(s.theme, "system");
    if (["light", "dark", "system"].indexOf(theme) < 0) theme = "system";
    var sort = toStr(s.defaultSort, "dateAdded");
    var validSorts = ["title", "author", "year", "dateAdded", "rating"];
    if (validSorts.indexOf(sort) < 0) sort = "dateAdded";
    var density = toStr(s.density, "comfortable");
    if (["comfortable", "compact"].indexOf(density) < 0) density = "comfortable";
    return {
      theme: theme,
      defaultSort: sort,
      density: density,
      view: (["grid", "list"].indexOf(toStr(s.view, "grid")) >= 0) ? toStr(s.view, "grid") : "grid"
    };
  }

  function normState(raw) {
    raw = raw && typeof raw === "object" ? raw : {};
    var shelves = toArray(raw.shelves).map(normShelf);
    var shelfIds = {};
    shelves.forEach(function (s) { shelfIds[s.id] = true; });

    var books = toArray(raw.books).map(normBook).map(function (b) {
      // drop references to shelves that no longer exist
      b.shelfIds = b.shelfIds.filter(function (id) { return shelfIds[id]; });
      return b;
    });
    var bookIds = {};
    books.forEach(function (b) { bookIds[b.id] = true; });

    var sessions = toArray(raw.sessions).map(normSession).filter(function (ss) {
      return bookIds[ss.bookId];
    });

    return {
      version: 1,
      books: books,
      shelves: shelves,
      sessions: sessions,
      settings: normSettings(raw.settings),
      seeded: toBool(raw.seeded, false)
    };
  }

  // ---- Public API ----------------------------------------------------------
  function load() {
    var raw = null;
    try {
      var txt = global.localStorage.getItem(STORAGE_KEY);
      if (txt) raw = JSON.parse(txt);
    } catch (e) {
      raw = null;
    }
    return normState(raw);
  }

  function save(state) {
    try {
      var clean = normState(state);
      global.localStorage.setItem(STORAGE_KEY, JSON.stringify(clean));
      return true;
    } catch (e) {
      return false;
    }
  }

  function exists() {
    try {
      return global.localStorage.getItem(STORAGE_KEY) !== null;
    } catch (e) {
      return false;
    }
  }

  function clear() {
    try {
      global.localStorage.removeItem(STORAGE_KEY);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Parse an imported object/string tolerantly; returns normalized state or null.
  function parseImport(input) {
    var obj = input;
    if (typeof input === "string") {
      try { obj = JSON.parse(input); } catch (e) { return null; }
    }
    if (!obj || typeof obj !== "object") return null;
    // Accept either a full state or a bare {books, shelves, sessions}
    if (!Array.isArray(obj.books) && !Array.isArray(obj.shelves)) return null;
    return normState(obj);
  }

  global.StacksStorage = {
    STORAGE_KEY: STORAGE_KEY,
    STATUSES: STATUSES,
    BRAND_COLORS: BRAND_COLORS,
    makeId: makeId,
    load: load,
    save: save,
    exists: exists,
    clear: clear,
    parseImport: parseImport,
    normState: normState,
    normBook: normBook,
    normShelf: normShelf,
    normSession: normSession
  };
})(window);
