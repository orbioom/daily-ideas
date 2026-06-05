/* app.js — Stacks UI + logic
 * Depends on storage.js (window.StacksStorage) and seed.js (window.StacksSeed).
 */
(function (global) {
  "use strict";

  var S = global.StacksStorage;
  var Seed = global.StacksSeed;

  // ---- App state -----------------------------------------------------------
  var state = null;
  var ui = {
    view: "library",
    search: "",
    filterStatus: "",
    filterShelf: "",
    filterGenre: "",
    sort: "dateAdded"
  };

  var STATUS_LABEL = {
    "want-to-read": "Want to read",
    "reading": "Reading",
    "finished": "Finished",
    "abandoned": "Abandoned"
  };
  var STATUS_CLASS = {
    "want-to-read": "want",
    "reading": "reading",
    "finished": "finished",
    "abandoned": "abandoned"
  };
  var STATUS_COLOR = {
    "want-to-read": "#6E7BB0",
    "reading": "#C7973A",
    "finished": "#86C79A",
    "abandoned": "#9A6E8E"
  };

  // ---- DOM helpers ---------------------------------------------------------
  function $(sel, root) { return (root || document).querySelector(sel); }
  function $all(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }

  function esc(s) {
    return String(s == null ? "" : s)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
  }

  function el(tag, attrs, children) {
    var node = document.createElement(tag);
    if (attrs) {
      Object.keys(attrs).forEach(function (k) {
        if (k === "class") node.className = attrs[k];
        else if (k === "html") node.innerHTML = attrs[k];
        else if (k === "text") node.textContent = attrs[k];
        else if (k.slice(0, 2) === "on" && typeof attrs[k] === "function") {
          node.addEventListener(k.slice(2).toLowerCase(), attrs[k]);
        } else if (attrs[k] != null && attrs[k] !== false) {
          node.setAttribute(k, attrs[k]);
        }
      });
    }
    (children || []).forEach(function (c) {
      if (c == null) return;
      node.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
    });
    return node;
  }

  // ---- Persistence ---------------------------------------------------------
  function persist() { S.save(state); }

  function init() {
    if (S.exists()) {
      state = S.load();
    } else {
      state = Seed.build();
      S.save(state);
    }
    // First-ever open never blank: if no data and never seeded, seed.
    if (!state.seeded && state.books.length === 0 && state.shelves.length === 0) {
      state = Seed.build();
      S.save(state);
    }
    ui.sort = state.settings.defaultSort;
    applySettings();
    bindChrome();
    render();
  }

  // ---- Settings application ------------------------------------------------
  function applySettings() {
    document.documentElement.setAttribute("data-theme", state.settings.theme);
    // density applied at render time via class
    var st = $("#set-theme"); if (st) st.value = state.settings.theme;
    var ss = $("#set-sort"); if (ss) ss.value = state.settings.defaultSort;
    setPressed($("#density-comfortable"), state.settings.density === "comfortable");
    setPressed($("#density-compact"), state.settings.density === "compact");
    setPressed($("#view-grid"), state.settings.view === "grid");
    setPressed($("#view-list"), state.settings.view === "list");
  }

  function setPressed(node, on) { if (node) node.setAttribute("aria-pressed", on ? "true" : "false"); }

  // ---- Derived data --------------------------------------------------------
  function bookById(id) {
    for (var i = 0; i < state.books.length; i++) if (state.books[i].id === id) return state.books[i];
    return null;
  }
  function shelfById(id) {
    for (var i = 0; i < state.shelves.length; i++) if (state.shelves[i].id === id) return state.shelves[i];
    return null;
  }
  function sessionsForBook(id) {
    return state.sessions.filter(function (s) { return s.bookId === id; })
      .sort(function (a, b) { return a.date < b.date ? 1 : a.date > b.date ? -1 : 0; });
  }
  function genres() {
    var seen = {};
    state.books.forEach(function (b) { if (b.genre) seen[b.genre] = true; });
    return Object.keys(seen).sort();
  }

  function progressPct(b) {
    if (!b.pageCount || b.pageCount <= 0) return 0;
    var p = Math.round((b.currentPage / b.pageCount) * 100);
    return Math.max(0, Math.min(100, p));
  }

  function filteredBooks() {
    var q = ui.search.trim().toLowerCase();
    var list = state.books.filter(function (b) {
      if (q) {
        var hay = (b.title + " " + b.author).toLowerCase();
        if (hay.indexOf(q) < 0) return false;
      }
      if (ui.filterStatus && b.status !== ui.filterStatus) return false;
      if (ui.filterShelf && b.shelfIds.indexOf(ui.filterShelf) < 0) return false;
      if (ui.filterGenre && b.genre !== ui.filterGenre) return false;
      return true;
    });
    var dir = 1;
    list.sort(function (a, b) {
      switch (ui.sort) {
        case "title": return a.title.localeCompare(b.title) * dir;
        case "author": return a.author.localeCompare(b.author) * dir;
        case "year": return (b.year - a.year);
        case "rating": return (b.rating - a.rating) || a.title.localeCompare(b.title);
        case "dateAdded":
        default:
          return (a.dateAdded < b.dateAdded ? 1 : a.dateAdded > b.dateAdded ? -1 : 0);
      }
    });
    return list;
  }

  // ---- Date helpers --------------------------------------------------------
  function fmtDate(iso) {
    if (!iso) return "—";
    var d = new Date(iso);
    if (isNaN(d.getTime())) return "—";
    return d.toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" });
  }
  function todayStr() { return new Date().toISOString().slice(0, 10); }

  // ===========================================================================
  //  RENDER
  // ===========================================================================
  function render() {
    renderShelfFilter();
    renderGenreFilter();
    if (ui.view === "library") renderLibrary();
    else if (ui.view === "shelves") renderShelves();
    else if (ui.view === "stats") renderStats();
    // settings view is static markup; values synced in applySettings
  }

  function renderShelfFilter() {
    var sel = $("#filter-shelf");
    if (!sel) return;
    var cur = ui.filterShelf;
    sel.innerHTML = "";
    sel.appendChild(el("option", { value: "" }, ["All shelves"]));
    state.shelves.forEach(function (sh) {
      sel.appendChild(el("option", { value: sh.id }, [sh.name]));
    });
    sel.value = cur;
    if (sel.value !== cur) { ui.filterShelf = ""; sel.value = ""; }
  }

  function renderGenreFilter() {
    var sel = $("#filter-genre");
    if (!sel) return;
    var cur = ui.filterGenre;
    sel.innerHTML = "";
    sel.appendChild(el("option", { value: "" }, ["All genres"]));
    genres().forEach(function (g) { sel.appendChild(el("option", { value: g }, [g])); });
    sel.value = cur;
    if (sel.value !== cur) { ui.filterGenre = ""; sel.value = ""; }
  }

  // ---- Library -------------------------------------------------------------
  function renderLibrary() {
    var body = $("#library-body");
    body.innerHTML = "";
    var list = filteredBooks();
    var countEl = $("#library-count");

    if (state.books.length === 0) {
      countEl.textContent = "";
      body.appendChild(emptyState(
        "📚",
        "Your library is empty",
        "Add your first book, or restore the Orbioom sample collection to explore Stacks.",
        [
          { label: "+ Add book", primary: true, on: function () { openBookForm(null); } },
          { label: "Reset to sample", on: function () { confirmResetSample(); } }
        ]
      ));
      return;
    }

    countEl.textContent = list.length + " of " + state.books.length + " book" + (state.books.length === 1 ? "" : "s");

    if (list.length === 0) {
      body.appendChild(emptyState(
        "🔍",
        "No books match your filters",
        "Try a different search term, or clear the filters to see your whole library.",
        [{ label: "Clear filters", primary: true, on: clearFilters }]
      ));
      return;
    }

    var grid = el("div", { class: "book-grid" + (state.settings.view === "list" ? " list" : "") + (state.settings.density === "compact" ? " compact" : "") });
    list.forEach(function (b) { grid.appendChild(bookCard(b)); });
    body.appendChild(grid);
  }

  function bookCard(b) {
    var card = el("button", {
      class: "book-card", type: "button",
      "aria-label": "Open details for " + b.title + " by " + b.author,
      onclick: function () { openBookDetail(b.id); }
    });

    var spine = el("span", { class: "spine", "aria-hidden": "true" });
    spine.style.background = b.coverColor;

    var meta = el("div", { class: "book-meta" }, [
      el("div", { class: "book-title", title: b.title }, [b.title]),
      el("div", { class: "book-author" }, [b.author]),
      el("div", { class: "book-year mono" }, [b.year > 0 ? String(b.year) : "—"])
    ]);

    var top = el("div", { class: "book-top" }, [spine, meta]);
    card.appendChild(top);

    var foot = el("div", { class: "card-foot" });
    var badge = el("span", { class: "badge " + STATUS_CLASS[b.status] }, [
      el("span", { class: "dot", "aria-hidden": "true" }), STATUS_LABEL[b.status]
    ]);
    foot.appendChild(badge);

    if (b.status === "finished" && b.rating > 0) {
      foot.appendChild(starsNode(b.rating));
    }
    card.appendChild(foot);

    if (b.shelfIds.length) {
      var chips = el("div", { class: "shelf-chips" });
      b.shelfIds.forEach(function (sid) {
        var sh = shelfById(sid);
        if (!sh) return;
        var chip = el("span", { class: "shelf-chip" }, [sh.name]);
        chip.style.background = sh.color;
        chips.appendChild(chip);
      });
      card.appendChild(chips);
    }

    if (b.status === "reading" && b.pageCount > 0) {
      var pct = progressPct(b);
      var row = el("div", { class: "progress-row" }, [
        el("div", { class: "progress" }, [(function () {
          var bar = el("span"); bar.style.width = pct + "%"; return bar;
        })()]),
        el("span", { class: "progress-pct" }, [pct + "%"])
      ]);
      card.appendChild(row);
    }

    return card;
  }

  function starsNode(rating) {
    var n = Math.round(rating);
    var wrap = el("span", { class: "stars", "aria-label": rating + " out of 5 stars" });
    var html = "";
    for (var i = 1; i <= 5; i++) {
      html += i <= n ? "★" : '<span class="off">★</span>';
    }
    wrap.innerHTML = html;
    return wrap;
  }

  function emptyState(glyph, title, body, actions) {
    var wrap = el("div", { class: "panel" }, [
      el("div", { class: "empty" }, [
        el("div", { class: "glyph", "aria-hidden": "true" }, [glyph]),
        el("h3", {}, [title]),
        el("p", {}, [body])
      ])
    ]);
    if (actions && actions.length) {
      var act = el("div", { class: "actions" });
      actions.forEach(function (a) {
        act.appendChild(el("button", {
          class: "btn " + (a.primary ? "btn-primary" : ""), type: "button", onclick: a.on
        }, [a.label]));
      });
      $(".empty", wrap).appendChild(act);
    }
    return wrap;
  }

  // ---- Shelves -------------------------------------------------------------
  function renderShelves() {
    var body = $("#shelves-body");
    body.innerHTML = "";
    $("#shelves-count").textContent = state.shelves.length + " shelf" + (state.shelves.length === 1 ? "" : "ves");

    if (state.shelves.length === 0) {
      body.appendChild(emptyState(
        "🗂️",
        "No shelves yet",
        "Shelves group books into collections — a reading list, a favorites set, anything. Create one to get started.",
        [{ label: "+ New shelf", primary: true, on: function () { openShelfForm(null); } }]
      ));
      return;
    }

    var list = el("div", { class: "shelf-list" });
    state.shelves.forEach(function (sh) {
      var count = state.books.filter(function (b) { return b.shelfIds.indexOf(sh.id) >= 0; }).length;
      var card = el("div", { class: "panel shelf-card" });
      var sw = el("div", { class: "swatch" }); sw.style.background = sh.color;
      card.appendChild(sw);
      card.appendChild(el("h3", {}, [sh.name]));
      card.appendChild(el("div", { class: "desc" }, [sh.description || "No description."]));
      var foot = el("div", { class: "foot" }, [
        el("span", { class: "n mono" }, [count + " book" + (count === 1 ? "" : "s")]),
        el("button", { class: "btn btn-sm btn-ghost", type: "button", onclick: function () { viewShelfBooks(sh.id); } }, ["View"]),
        el("button", { class: "btn btn-sm", type: "button", onclick: function () { openShelfForm(sh.id); } }, ["Edit"]),
        el("button", { class: "icon-btn", type: "button", "aria-label": "Delete shelf " + sh.name, onclick: function () { confirmDeleteShelf(sh.id); } }, ["🗑"])
      ]);
      card.appendChild(foot);
      list.appendChild(card);
    });
    body.appendChild(list);
  }

  function viewShelfBooks(shelfId) {
    ui.filterShelf = shelfId;
    switchView("library");
    var sel = $("#filter-shelf"); if (sel) sel.value = shelfId;
  }

  // ---- Stats ---------------------------------------------------------------
  function computeStats() {
    var books = state.books;
    var total = books.length;
    var byStatus = { "want-to-read": 0, "reading": 0, "finished": 0, "abandoned": 0 };
    books.forEach(function (b) { byStatus[b.status] = (byStatus[b.status] || 0) + 1; });

    var year = new Date().getFullYear();
    var finishedThisYear = books.filter(function (b) {
      if (b.status !== "finished" || !b.dateFinished) return false;
      var d = new Date(b.dateFinished);
      return !isNaN(d.getTime()) && d.getFullYear() === year;
    }).length;

    var pagesRead = state.sessions.reduce(function (sum, s) { return sum + (s.pagesRead || 0); }, 0);

    var rated = books.filter(function (b) { return b.status === "finished" && b.rating > 0; });
    var avgRating = rated.length
      ? (rated.reduce(function (s, b) { return s + b.rating; }, 0) / rated.length)
      : 0;

    var streak = computeStreak();
    var totalMinutes = state.sessions.reduce(function (s, x) { return s + (x.minutes || 0); }, 0);

    return {
      total: total, byStatus: byStatus, finishedThisYear: finishedThisYear,
      pagesRead: pagesRead, avgRating: avgRating, ratedCount: rated.length,
      streak: streak, totalMinutes: totalMinutes, sessionCount: state.sessions.length
    };
  }

  function computeStreak() {
    // consecutive days (ending today or yesterday) with >=1 session
    if (state.sessions.length === 0) return 0;
    var days = {};
    state.sessions.forEach(function (s) { if (s.date) days[s.date] = true; });
    var streak = 0;
    var cursor = new Date(); cursor.setHours(12, 0, 0, 0);
    // allow streak to count even if no session today yet: start from today,
    // but if today has none and yesterday has one, begin there.
    var todayKey = cursor.toISOString().slice(0, 10);
    if (!days[todayKey]) {
      cursor.setDate(cursor.getDate() - 1);
    }
    while (true) {
      var key = cursor.toISOString().slice(0, 10);
      if (days[key]) { streak++; cursor.setDate(cursor.getDate() - 1); }
      else break;
    }
    return streak;
  }

  function renderStats() {
    var body = $("#stats-body");
    body.innerHTML = "";
    var st = computeStats();

    if (state.books.length === 0 && state.sessions.length === 0) {
      body.appendChild(emptyState(
        "📈",
        "No stats yet",
        "Once you add books and log reading sessions, your stats will appear here.",
        [{ label: "+ Add book", primary: true, on: function () { openBookForm(null); } }]
      ));
      return;
    }

    // Stat cards
    var grid = el("div", { class: "stat-grid" });
    function statCard(value, label, live) {
      return el("div", { class: "stat" + (live ? " live" : "") }, [
        el("div", { class: "v mono" }, [String(value)]),
        el("div", { class: "l" }, [label])
      ]);
    }
    grid.appendChild(statCard(st.total, "Total books"));
    grid.appendChild(statCard(st.finishedThisYear, "Finished in " + new Date().getFullYear(), true));
    grid.appendChild(statCard(st.pagesRead.toLocaleString(), "Pages read (logged)"));
    grid.appendChild(statCard(st.avgRating ? st.avgRating.toFixed(1) : "—", st.ratedCount ? "Avg rating (" + st.ratedCount + ")" : "Avg rating"));
    grid.appendChild(statCard(formatHours(st.totalMinutes), "Time logged"));
    body.appendChild(grid);

    // Streak panel
    var streakPanel = el("div", { class: "panel" });
    var milestone = st.streak >= 7;
    streakPanel.appendChild(el("div", { class: "section-title" }, ["Reading streak"]));
    var sb = el("div", { class: "streak-badge" + (milestone ? " milestone" : "") }, [
      el("span", { style: "font-size:1.6rem" }, [milestone ? "✨" : "🔥"]),
      el("span", { style: "font-size:1.6rem" }, [String(st.streak)]),
      el("span", { style: "font-weight:600;color:var(--text-2);font-family:var(--font-ui)" },
        [st.streak === 1 ? " day in a row" : " days in a row"])
    ]);
    streakPanel.appendChild(sb);
    streakPanel.appendChild(el("p", { style: "color:var(--text-2);font-size:0.85rem;margin-top:0.5rem" }, [
      st.streak === 0
        ? "Log a reading session today to start a streak."
        : milestone
          ? "A full week and counting — nicely done."
          : "Keep logging daily to grow your streak."
    ]));
    body.appendChild(streakPanel);

    // Charts row: bars + donut
    var row = el("div", { class: "chart-row" });

    // Bars: books by status
    var barsPanel = el("div", { class: "panel" });
    barsPanel.appendChild(el("div", { class: "section-title" }, ["Books by status"]));
    var maxStatus = Math.max(1, st.byStatus["want-to-read"], st.byStatus["reading"], st.byStatus["finished"], st.byStatus["abandoned"]);
    var bars = el("div", { class: "bars" });
    ["want-to-read", "reading", "finished", "abandoned"].forEach(function (k) {
      var n = st.byStatus[k] || 0;
      var fill = el("div", { class: "bar-fill" });
      fill.style.width = Math.round((n / maxStatus) * 100) + "%";
      fill.style.background = STATUS_COLOR[k];
      bars.appendChild(el("div", { class: "bar-item" }, [
        el("span", { class: "lab" }, [STATUS_LABEL[k]]),
        el("div", { class: "bar-track" }, [fill]),
        el("span", { class: "num mono" }, [String(n)])
      ]));
    });
    barsPanel.appendChild(bars);
    row.appendChild(barsPanel);

    // Donut: status distribution
    var donutPanel = el("div", { class: "panel" });
    donutPanel.appendChild(el("div", { class: "section-title" }, ["Distribution"]));
    donutPanel.appendChild(buildDonut(st.byStatus, st.total));
    row.appendChild(donutPanel);

    body.appendChild(row);
  }

  function formatHours(minutes) {
    if (!minutes) return "0h";
    var h = Math.floor(minutes / 60);
    var m = minutes % 60;
    if (h === 0) return m + "m";
    if (m === 0) return h + "h";
    return h + "h " + m + "m";
  }

  function buildDonut(byStatus, total) {
    var order = ["finished", "reading", "want-to-read", "abandoned"];
    var wrap = el("div", { class: "donut-wrap" });
    var size = 132, stroke = 20, r = (size - stroke) / 2, cx = size / 2, cy = size / 2;
    var circ = 2 * Math.PI * r;

    var svgNS = "http://www.w3.org/2000/svg";
    var svg = document.createElementNS(svgNS, "svg");
    svg.setAttribute("viewBox", "0 0 " + size + " " + size);
    svg.setAttribute("class", "donut");
    svg.setAttribute("role", "img");
    svg.setAttribute("aria-label", "Status distribution of " + total + " books");

    // track
    var track = document.createElementNS(svgNS, "circle");
    track.setAttribute("cx", cx); track.setAttribute("cy", cy); track.setAttribute("r", r);
    track.setAttribute("fill", "none");
    track.setAttribute("stroke", "rgba(120,120,140,0.16)");
    track.setAttribute("stroke-width", stroke);
    svg.appendChild(track);

    var offset = 0;
    if (total > 0) {
      order.forEach(function (k) {
        var n = byStatus[k] || 0;
        if (n <= 0) return;
        var frac = n / total;
        var arc = document.createElementNS(svgNS, "circle");
        arc.setAttribute("cx", cx); arc.setAttribute("cy", cy); arc.setAttribute("r", r);
        arc.setAttribute("fill", "none");
        arc.setAttribute("stroke", STATUS_COLOR[k]);
        arc.setAttribute("stroke-width", stroke);
        arc.setAttribute("stroke-dasharray", (frac * circ) + " " + circ);
        arc.setAttribute("stroke-dashoffset", -offset * circ);
        arc.setAttribute("transform", "rotate(-90 " + cx + " " + cy + ")");
        arc.setAttribute("stroke-linecap", "butt");
        svg.appendChild(arc);
        offset += frac;
      });
    }

    // center label
    var t1 = document.createElementNS(svgNS, "text");
    t1.setAttribute("x", cx); t1.setAttribute("y", cy - 2);
    t1.setAttribute("text-anchor", "middle");
    t1.setAttribute("font-family", "var(--font-mono)");
    t1.setAttribute("font-size", "26"); t1.setAttribute("font-weight", "700");
    t1.setAttribute("fill", "var(--text)");
    t1.textContent = String(total);
    svg.appendChild(t1);
    var t2 = document.createElementNS(svgNS, "text");
    t2.setAttribute("x", cx); t2.setAttribute("y", cy + 16);
    t2.setAttribute("text-anchor", "middle");
    t2.setAttribute("font-size", "10");
    t2.setAttribute("fill", "var(--text-3)");
    t2.textContent = "books";
    svg.appendChild(t2);

    wrap.appendChild(svg);

    var legend = el("div", { class: "donut-legend" });
    order.forEach(function (k) {
      var n = byStatus[k] || 0;
      var sw = el("span", { class: "sw" }); sw.style.background = STATUS_COLOR[k];
      legend.appendChild(el("div", { class: "legend-item" }, [
        sw, el("span", {}, [STATUS_LABEL[k]]), el("span", { class: "ln mono" }, [String(n)])
      ]));
    });
    wrap.appendChild(legend);
    return wrap;
  }

  // ===========================================================================
  //  MODALS
  // ===========================================================================
  var lastFocused = null;
  var trapHandler = null;

  function openModal(wide) {
    var overlay = $("#overlay");
    var modal = $("#modal");
    modal.className = "modal" + (wide ? " wide" : "");
    lastFocused = document.activeElement;
    overlay.classList.add("open");
    document.body.style.overflow = "hidden";
    // focus first focusable
    setTimeout(function () {
      var f = modal.querySelector("input,select,textarea,button,[tabindex]");
      if (f) f.focus(); else modal.focus();
    }, 30);
    trapHandler = function (e) {
      if (e.key === "Escape") { e.preventDefault(); closeModal(); return; }
      if (e.key === "Tab") {
        var foc = $all('input,select,textarea,button,[href],[tabindex]:not([tabindex="-1"])', modal)
          .filter(function (n) { return !n.disabled && n.offsetParent !== null; });
        if (foc.length === 0) return;
        var first = foc[0], last = foc[foc.length - 1];
        if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
        else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
      }
    };
    document.addEventListener("keydown", trapHandler, true);
  }

  function closeModal() {
    var overlay = $("#overlay");
    overlay.classList.remove("open");
    document.body.style.overflow = "";
    if (trapHandler) { document.removeEventListener("keydown", trapHandler, true); trapHandler = null; }
    $("#modal").innerHTML = "";
    if (lastFocused && typeof lastFocused.focus === "function") {
      try { lastFocused.focus(); } catch (e) { /* element gone */ }
    }
    lastFocused = null;
  }

  // ---- Book form -----------------------------------------------------------
  function openBookForm(bookId) {
    var editing = bookId ? bookById(bookId) : null;
    var b = editing || {
      title: "", author: "", year: "", pageCount: "", genre: "",
      coverColor: S.BRAND_COLORS[0], status: "want-to-read", currentPage: 0,
      rating: 0, review: "", shelfIds: []
    };

    var modal = $("#modal");
    modal.innerHTML = "";

    var ratingVal = b.rating || 0;
    var colorVal = b.coverColor;
    var selectedShelves = b.shelfIds.slice();

    var titleInput, authorInput, yearInput, pagesInput, genreInput,
      statusSelect, currentPageInput, reviewInput;

    modal.appendChild(el("div", { class: "modal-head" }, [
      el("div", {}, [
        el("h2", { id: "modal-title" }, [editing ? "Edit book" : "Add book"]),
        el("p", { class: "sub" }, [editing ? "Update the details for this book." : "Catalog a new book in your library."])
      ]),
      el("button", { class: "icon-btn", type: "button", "aria-label": "Close", onclick: closeModal }, ["✕"])
    ]));

    var form = el("form", { class: "form-grid", novalidate: "novalidate" });

    // Title
    titleInput = el("input", { class: "field", id: "f-title", type: "text", value: b.title, maxlength: "200", required: "required" });
    form.appendChild(field("Title", "f-title", titleInput, true, "f-title-err"));
    // Author
    authorInput = el("input", { class: "field", id: "f-author", type: "text", value: b.author, maxlength: "160", required: "required" });
    form.appendChild(field("Author", "f-author", authorInput, true, "f-author-err"));
    // Year
    yearInput = el("input", { class: "field mono", id: "f-year", type: "number", value: b.year || "", min: "-3000", max: "9999", inputmode: "numeric" });
    form.appendChild(field("Year", "f-year", yearInput, false, "f-year-err"));
    // Pages
    pagesInput = el("input", { class: "field mono", id: "f-pages", type: "number", value: b.pageCount || "", min: "0", max: "100000", inputmode: "numeric" });
    form.appendChild(field("Page count", "f-pages", pagesInput, false, "f-pages-err"));
    // Genre
    genreInput = el("input", { class: "field", id: "f-genre", type: "text", value: b.genre, maxlength: "60", list: "genre-list" });
    var dl = el("datalist", { id: "genre-list" });
    genres().forEach(function (g) { dl.appendChild(el("option", { value: g })); });
    genreInput.appendChild(dl);
    var genreWrap = field("Genre", "f-genre", genreInput, false);
    genreWrap.appendChild(dl);
    form.appendChild(genreWrap);
    // Status
    statusSelect = el("select", { class: "field", id: "f-status" });
    S.STATUSES.forEach(function (s) {
      var o = el("option", { value: s }, [STATUS_LABEL[s]]);
      if (s === b.status) o.selected = true;
      statusSelect.appendChild(o);
    });
    form.appendChild(field("Status", "f-status", statusSelect, false));

    // Current page (relevant for reading)
    currentPageInput = el("input", { class: "field mono", id: "f-current", type: "number", value: b.currentPage || 0, min: "0", max: "100000", inputmode: "numeric" });
    var curWrap = field("Current page", "f-current", currentPageInput, false, "f-current-err");
    form.appendChild(curWrap);

    // Cover color
    var colorWrap = el("div", { class: "full" }, [
      el("span", { class: "lbl" }, ["Cover color"]),
      (function () {
        var row = el("div", { class: "color-row", role: "group", "aria-label": "Cover color" });
        S.BRAND_COLORS.forEach(function (c) {
          var dot = el("button", {
            type: "button", class: "color-dot", "aria-label": "Color " + c,
            "aria-pressed": c === colorVal ? "true" : "false",
            onclick: function () {
              colorVal = c;
              $all(".color-dot", row).forEach(function (d) { d.setAttribute("aria-pressed", "false"); });
              dot.setAttribute("aria-pressed", "true");
            }
          });
          dot.style.background = c;
          row.appendChild(dot);
        });
        return row;
      })()
    ]);
    form.appendChild(colorWrap);

    // Rating (shown when finished)
    var ratingWrap = el("div", { class: "full" }, [
      el("span", { class: "lbl" }, ["Rating (when finished)"]),
      (function () {
        var rw = el("div", { class: "rating-input", role: "group", "aria-label": "Rating, 0 to 5 stars" });
        function paint() {
          $all("button", rw).forEach(function (btn, i) {
            btn.classList.toggle("on", (i + 1) <= ratingVal);
          });
        }
        for (var i = 1; i <= 5; i++) {
          (function (val) {
            var btn = el("button", {
              type: "button", "aria-label": val + " star" + (val === 1 ? "" : "s"),
              onclick: function () { ratingVal = (ratingVal === val) ? 0 : val; paint(); }
            }, ["★"]);
            rw.appendChild(btn);
          })(i);
        }
        paint();
        return rw;
      })()
    ]);
    form.appendChild(ratingWrap);

    // Review
    reviewInput = el("textarea", { class: "field", id: "f-review", maxlength: "2000", rows: "3" });
    reviewInput.value = b.review;
    form.appendChild(field("Review / notes", "f-review", reviewInput, false, null, true));

    // Shelves
    var shelvesWrap = el("div", { class: "full" }, [el("span", { class: "lbl" }, ["Shelves"])]);
    if (state.shelves.length === 0) {
      shelvesWrap.appendChild(el("p", { style: "color:var(--text-3);font-size:0.82rem" }, ["No shelves yet. Create shelves from the Shelves tab."]));
    } else {
      var cl = el("div", { class: "checkbox-list" });
      state.shelves.forEach(function (sh) {
        var cb = el("input", { type: "checkbox", value: sh.id });
        if (selectedShelves.indexOf(sh.id) >= 0) cb.checked = true;
        cb.addEventListener("change", function () {
          var idx = selectedShelves.indexOf(sh.id);
          if (cb.checked && idx < 0) selectedShelves.push(sh.id);
          else if (!cb.checked && idx >= 0) selectedShelves.splice(idx, 1);
        });
        var sw = el("span", { class: "sw" }); sw.style.background = sh.color;
        cl.appendChild(el("label", { class: "check-row" }, [cb, sw, sh.name]));
      });
      shelvesWrap.appendChild(cl);
    }
    form.appendChild(shelvesWrap);

    modal.appendChild(form);

    // Footer
    var foot = el("div", { class: "modal-foot" });
    if (editing) {
      foot.appendChild(el("button", {
        class: "btn btn-danger left", type: "button",
        onclick: function () { confirmDeleteBook(editing.id); }
      }, ["Delete"]));
    }
    foot.appendChild(el("button", { class: "btn btn-ghost", type: "button", onclick: closeModal }, ["Cancel"]));
    foot.appendChild(el("button", { class: "btn btn-primary", type: "button", onclick: submit }, [editing ? "Save changes" : "Add book"]));
    modal.appendChild(foot);

    form.addEventListener("submit", function (e) { e.preventDefault(); submit(); });

    openModal(false);

    function submit() {
      clearErr(["f-title-err", "f-author-err", "f-year-err", "f-pages-err", "f-current-err"]);
      [titleInput, authorInput, yearInput, pagesInput, currentPageInput].forEach(function (n) { n.classList.remove("invalid"); });

      var ok = true;
      var title = titleInput.value.trim();
      var author = authorInput.value.trim();
      if (!title) { showErr("f-title-err", titleInput, "Title is required."); ok = false; }
      if (!author) { showErr("f-author-err", authorInput, "Author is required."); ok = false; }

      var year = 0;
      if (yearInput.value.trim() !== "") {
        year = parseInt(yearInput.value, 10);
        if (isNaN(year) || year < -3000 || year > 9999) { showErr("f-year-err", yearInput, "Enter a valid year (up to 9999)."); ok = false; }
      }

      var pageCount = 0;
      if (pagesInput.value.trim() !== "") {
        pageCount = parseInt(pagesInput.value, 10);
        if (isNaN(pageCount) || pageCount < 0 || pageCount > 100000) { showErr("f-pages-err", pagesInput, "Pages must be 0–100000."); ok = false; }
      }

      var currentPage = parseInt(currentPageInput.value, 10);
      if (isNaN(currentPage) || currentPage < 0) currentPage = 0;
      if (pageCount > 0 && currentPage > pageCount) {
        showErr("f-current-err", currentPageInput, "Current page can't exceed page count (" + pageCount + ").");
        ok = false;
      }

      if (!ok) {
        var firstInvalid = form.querySelector(".invalid");
        if (firstInvalid) firstInvalid.focus();
        return;
      }

      var status = statusSelect.value;
      var rating = (status === "finished") ? ratingVal : 0;

      if (editing) {
        editing.title = title; editing.author = author; editing.year = year || 0;
        editing.pageCount = pageCount; editing.genre = genreInput.value.trim();
        editing.coverColor = colorVal; editing.review = reviewInput.value;
        editing.shelfIds = selectedShelves.slice();
        editing.rating = rating;
        editing.currentPage = currentPage;
        applyStatusChange(editing, status);
        persist();
        toast("Saved “" + title + "”", "success");
      } else {
        var nb = S.normBook({
          title: title, author: author, year: year || 0, pageCount: pageCount,
          genre: genreInput.value.trim(), coverColor: colorVal, status: "want-to-read",
          currentPage: currentPage, rating: rating, review: reviewInput.value,
          shelfIds: selectedShelves.slice(), dateAdded: new Date().toISOString()
        });
        applyStatusChange(nb, status);
        state.books.push(nb);
        persist();
        toast("Added “" + title + "”", "success");
      }
      closeModal();
      render();
    }
  }

  // Apply a status change with the right side effects (dates, progress).
  function applyStatusChange(book, newStatus) {
    var old = book.status;
    book.status = newStatus;
    if (newStatus === "finished") {
      if (book.pageCount > 0) book.currentPage = book.pageCount;
      if (!book.dateFinished) book.dateFinished = new Date().toISOString();
    } else {
      // leaving finished clears finish date & rating only if it was finished
      if (old === "finished") { book.dateFinished = ""; }
      if (newStatus === "want-to-read") book.currentPage = 0;
      if (newStatus !== "finished") book.rating = (newStatus === "finished") ? book.rating : (newStatus === "want-to-read" ? 0 : book.rating);
    }
  }

  function field(label, id, input, required, errId, full) {
    var wrap = el("div", { class: full ? "full" : "" });
    var lbl = el("label", { class: "lbl", for: id }, [label]);
    if (required) lbl.appendChild(el("span", { class: "req", "aria-hidden": "true" }, [" *"]));
    wrap.appendChild(lbl);
    wrap.appendChild(input);
    if (errId) wrap.appendChild(el("span", { class: "err-msg", id: errId, role: "alert" }));
    return wrap;
  }

  function showErr(errId, input, msg) {
    var e = document.getElementById(errId);
    if (e) e.textContent = msg;
    if (input) {
      input.classList.add("invalid");
      input.setAttribute("aria-invalid", "true");
    }
  }
  function clearErr(ids) {
    ids.forEach(function (id) {
      var e = document.getElementById(id);
      if (e) e.textContent = "";
    });
  }

  // ---- Book detail ---------------------------------------------------------
  function openBookDetail(bookId) {
    var b = bookById(bookId);
    if (!b) { toast("That book no longer exists.", "error"); return; }

    var modal = $("#modal");
    modal.innerHTML = "";

    modal.appendChild(el("div", { class: "modal-head" }, [
      el("div", { style: "flex:1" }, [el("h2", { id: "modal-title", class: "sr-only" }, [b.title + " details"])]),
      el("button", { class: "icon-btn", type: "button", "aria-label": "Close", onclick: closeModal }, ["✕"])
    ]));

    // Header
    var cover = el("div", { class: "detail-cover", "aria-hidden": "true" });
    cover.style.background = b.coverColor;
    var info = el("div", { class: "detail-info" });
    info.appendChild(el("h2", {}, [b.title]));
    info.appendChild(el("div", { class: "by" }, ["by " + b.author + (b.year > 0 ? " · " + b.year : "")]));
    var tags = el("div", { class: "detail-tags" });
    tags.appendChild(el("span", { class: "badge " + STATUS_CLASS[b.status] }, [
      el("span", { class: "dot", "aria-hidden": "true" }), STATUS_LABEL[b.status]
    ]));
    if (b.genre) tags.appendChild(el("span", { class: "badge" }, [b.genre]));
    if (b.status === "finished" && b.rating > 0) tags.appendChild(starsNode(b.rating));
    info.appendChild(tags);
    if (b.shelfIds.length) {
      var chips = el("div", { class: "shelf-chips", style: "margin-top:0.5rem" });
      b.shelfIds.forEach(function (sid) {
        var sh = shelfById(sid); if (!sh) return;
        var chip = el("span", { class: "shelf-chip" }, [sh.name]); chip.style.background = sh.color;
        chips.appendChild(chip);
      });
      info.appendChild(chips);
    }
    modal.appendChild(el("div", { class: "detail-head" }, [cover, info]));

    // Progress
    if (b.pageCount > 0) {
      var pct = progressPct(b);
      var prog = el("div", { style: "margin-top:0.85rem" }, [
        el("div", { class: "progress-row" }, [
          el("div", { class: "progress" }, [(function () { var s = el("span"); s.style.width = pct + "%"; return s; })()]),
          el("span", { class: "progress-pct mono" }, [b.currentPage + " / " + b.pageCount + " (" + pct + "%)"])
        ])
      ]);
      modal.appendChild(prog);
    }

    // Key/value
    var kv = el("div", { class: "kv" }, [
      el("div", {}, [el("div", { class: "k" }, ["Added"]), el("div", { class: "v" }, [fmtDate(b.dateAdded)])]),
      el("div", {}, [el("div", { class: "k" }, ["Finished"]), el("div", { class: "v" }, [b.dateFinished ? fmtDate(b.dateFinished) : "—"])]),
      el("div", {}, [el("div", { class: "k" }, ["Pages"]), el("div", { class: "v" }, [b.pageCount > 0 ? String(b.pageCount) : "—"])])
    ]);
    modal.appendChild(kv);

    // Review
    if (b.review.trim()) {
      modal.appendChild(el("div", { class: "review-box" }, [b.review]));
    }

    // Quick actions
    modal.appendChild(el("div", { class: "section-title" }, ["Quick actions"]));
    var qa = el("div", { class: "quick-actions" });

    // Status select
    var statusSel = el("select", { class: "field", style: "width:auto", "aria-label": "Change status" });
    S.STATUSES.forEach(function (s) {
      var o = el("option", { value: s }, [STATUS_LABEL[s]]);
      if (s === b.status) o.selected = true;
      statusSel.appendChild(o);
    });
    statusSel.addEventListener("change", function () {
      applyStatusChange(b, statusSel.value);
      persist();
      if (b.status === "finished") toast("Marked “" + b.title + "” finished", "success");
      openBookDetail(b.id);
      renderIfVisible();
    });
    qa.appendChild(statusSel);

    qa.appendChild(el("button", { class: "btn btn-sm", type: "button", onclick: function () { openProgressForm(b.id); } }, ["Update progress"]));
    qa.appendChild(el("button", { class: "btn btn-sm", type: "button", onclick: function () { openSessionForm(b.id); } }, ["Log session"]));
    qa.appendChild(el("button", { class: "btn btn-sm", type: "button", onclick: function () { openBookForm(b.id); } }, ["Edit"]));
    qa.appendChild(el("button", { class: "btn btn-sm btn-danger", type: "button", onclick: function () { confirmDeleteBook(b.id); } }, ["Delete"]));
    modal.appendChild(qa);

    // Sessions
    var sess = sessionsForBook(b.id);
    modal.appendChild(el("div", { class: "section-title" }, ["Reading sessions (" + sess.length + ")"]));
    if (sess.length === 0) {
      modal.appendChild(el("p", { style: "color:var(--text-3);font-size:0.85rem" }, ["No sessions logged yet."]));
    } else {
      var sl = el("div", { class: "session-list" });
      sess.forEach(function (s) {
        var infoParts = [s.pagesRead + " page" + (s.pagesRead === 1 ? "" : "s")];
        if (s.minutes) infoParts.push(s.minutes + " min");
        var infoNode = el("div", { class: "info" }, [
          el("div", {}, [infoParts.join(" · ")]),
          s.note ? el("div", { class: "note" }, [s.note]) : null
        ]);
        sl.appendChild(el("div", { class: "session-row" }, [
          el("span", { class: "date" }, [fmtDate(s.date)]),
          infoNode,
          el("span", { class: "pages mono" }, ["+" + s.pagesRead]),
          el("button", { class: "icon-btn", type: "button", "aria-label": "Delete session from " + fmtDate(s.date), onclick: function () { deleteSession(s.id, b.id); } }, ["🗑"])
        ]));
      });
      modal.appendChild(sl);
    }

    openModal(true);
  }

  // ---- Progress update -----------------------------------------------------
  function openProgressForm(bookId) {
    var b = bookById(bookId);
    if (!b) return;
    var modal = $("#modal");
    modal.innerHTML = "";

    modal.appendChild(el("div", { class: "modal-head" }, [
      el("div", { style: "flex:1" }, [
        el("h2", { id: "modal-title" }, ["Update progress"]),
        el("p", { class: "sub" }, [b.title])
      ]),
      el("button", { class: "icon-btn", type: "button", "aria-label": "Close", onclick: function () { openBookDetail(bookId); } }, ["✕"])
    ]));

    var maxP = b.pageCount > 0 ? b.pageCount : 100000;
    var pageInput = el("input", { class: "field mono", id: "p-page", type: "number", value: b.currentPage, min: "0", max: String(maxP), inputmode: "numeric" });
    var logChk = el("input", { type: "checkbox", id: "p-log", checked: "checked" });

    var form = el("form", { novalidate: "novalidate" }, [
      field("Current page" + (b.pageCount > 0 ? " (of " + b.pageCount + ")" : ""), "p-page", pageInput, true, "p-page-err"),
      el("label", { class: "check-row", style: "margin-top:0.6rem" }, [logChk, "Log a reading session for the pages I just read"])
    ]);
    modal.appendChild(form);

    var foot = el("div", { class: "modal-foot" }, [
      el("button", { class: "btn btn-ghost", type: "button", onclick: function () { openBookDetail(bookId); } }, ["Cancel"]),
      el("button", { class: "btn btn-primary", type: "button", onclick: submit }, ["Save progress"])
    ]);
    modal.appendChild(foot);
    form.addEventListener("submit", function (e) { e.preventDefault(); submit(); });
    openModal(false);

    function submit() {
      clearErr(["p-page-err"]); pageInput.classList.remove("invalid");
      var newPage = parseInt(pageInput.value, 10);
      if (isNaN(newPage) || newPage < 0) { showErr("p-page-err", pageInput, "Enter a valid page number."); return; }
      if (b.pageCount > 0 && newPage > b.pageCount) { showErr("p-page-err", pageInput, "Can't exceed page count (" + b.pageCount + ")."); return; }

      var delta = newPage - b.currentPage;
      b.currentPage = newPage;
      if (b.status === "want-to-read" && newPage > 0) b.status = "reading";

      if (logChk.checked && delta > 0) {
        state.sessions.push(S.normSession({
          bookId: b.id, date: todayStr(), pagesRead: delta, minutes: null, note: ""
        }));
      }
      persist();

      // Reached the end?
      if (b.pageCount > 0 && newPage >= b.pageCount && b.status !== "finished") {
        closeModalToDetail(bookId);
        promptFinish(b.id);
        return;
      }
      toast("Progress updated", "success");
      openBookDetail(bookId);
      renderIfVisible();
    }
  }

  function closeModalToDetail(bookId) { /* no-op helper for readability */ }

  function promptFinish(bookId) {
    var b = bookById(bookId);
    if (!b) return;
    confirmDialog({
      title: "Finished the book?",
      body: "You've reached the last page of “" + b.title + "”. Mark it as finished?",
      confirmLabel: "Mark finished",
      confirmClass: "btn-primary",
      onConfirm: function () {
        applyStatusChange(b, "finished");
        persist();
        toast("Finished “" + b.title + "” 🎉", "success");
        closeModal();
        openBookDetail(bookId);
        renderIfVisible();
      },
      onCancel: function () { openBookDetail(bookId); }
    });
  }

  // ---- Session form --------------------------------------------------------
  function openSessionForm(bookId) {
    var b = bookById(bookId);
    if (!b) return;
    var modal = $("#modal");
    modal.innerHTML = "";

    modal.appendChild(el("div", { class: "modal-head" }, [
      el("div", { style: "flex:1" }, [
        el("h2", { id: "modal-title" }, ["Log reading session"]),
        el("p", { class: "sub" }, [b.title])
      ]),
      el("button", { class: "icon-btn", type: "button", "aria-label": "Close", onclick: function () { openBookDetail(bookId); } }, ["✕"])
    ]));

    var dateInput = el("input", { class: "field mono", id: "s-date", type: "date", value: todayStr(), max: todayStr() });
    var pagesInput = el("input", { class: "field mono", id: "s-pages", type: "number", value: "", min: "0", max: "100000", inputmode: "numeric", placeholder: "e.g. 30" });
    var minutesInput = el("input", { class: "field mono", id: "s-min", type: "number", value: "", min: "0", max: "100000", inputmode: "numeric", placeholder: "optional" });
    var noteInput = el("textarea", { class: "field", id: "s-note", rows: "2", maxlength: "500", placeholder: "Optional note about this session" });

    var form = el("form", { class: "form-grid", novalidate: "novalidate" }, [
      field("Date", "s-date", dateInput, true, "s-date-err"),
      field("Pages read", "s-pages", pagesInput, true, "s-pages-err"),
      field("Minutes", "s-min", minutesInput, false, "s-min-err"),
      el("div", { class: "full" }, [
        el("label", { class: "check-row" }, [
          el("input", { type: "checkbox", id: "s-advance", checked: "checked" }),
          "Advance current page by the pages read"
        ])
      ]),
      field("Note", "s-note", noteInput, false, null, true)
    ]);
    modal.appendChild(form);

    var foot = el("div", { class: "modal-foot" }, [
      el("button", { class: "btn btn-ghost", type: "button", onclick: function () { openBookDetail(bookId); } }, ["Cancel"]),
      el("button", { class: "btn btn-primary", type: "button", onclick: submit }, ["Log session"])
    ]);
    modal.appendChild(foot);
    form.addEventListener("submit", function (e) { e.preventDefault(); submit(); });
    openModal(false);

    function submit() {
      clearErr(["s-date-err", "s-pages-err", "s-min-err"]);
      [dateInput, pagesInput, minutesInput].forEach(function (n) { n.classList.remove("invalid"); });
      var ok = true;

      var dval = dateInput.value;
      if (!dval || isNaN(new Date(dval).getTime())) { showErr("s-date-err", dateInput, "Pick a valid date."); ok = false; }

      var pages = parseInt(pagesInput.value, 10);
      if (isNaN(pages) || pages < 0 || pages > 100000) { showErr("s-pages-err", pagesInput, "Enter pages read (0–100000)."); ok = false; }

      var minutes = null;
      if (minutesInput.value.trim() !== "") {
        minutes = parseInt(minutesInput.value, 10);
        if (isNaN(minutes) || minutes < 0 || minutes > 100000) { showErr("s-min-err", minutesInput, "Minutes must be 0–100000."); ok = false; }
      }
      if (!ok) { var fi = form.querySelector(".invalid"); if (fi) fi.focus(); return; }

      state.sessions.push(S.normSession({
        bookId: b.id, date: dval, pagesRead: pages, minutes: minutes, note: noteInput.value.trim()
      }));

      var advance = $("#s-advance").checked;
      if (advance && pages > 0) {
        var np = b.currentPage + pages;
        if (b.pageCount > 0) np = Math.min(np, b.pageCount);
        b.currentPage = np;
        if (b.status === "want-to-read") b.status = "reading";
      }
      persist();

      if (b.status === "reading" && b.pageCount > 0 && b.currentPage >= b.pageCount) {
        closeModal();
        promptFinish(b.id);
        return;
      }
      toast("Session logged", "success");
      openBookDetail(bookId);
      renderIfVisible();
    }
  }

  function deleteSession(sessionId, bookId) {
    confirmDialog({
      title: "Delete session?",
      body: "This reading session will be removed. This can't be undone.",
      confirmLabel: "Delete",
      confirmClass: "btn-danger",
      onConfirm: function () {
        state.sessions = state.sessions.filter(function (s) { return s.id !== sessionId; });
        persist();
        toast("Session deleted");
        closeModal();
        if (bookId && bookById(bookId)) openBookDetail(bookId);
        renderIfVisible();
      },
      onCancel: function () { if (bookId) openBookDetail(bookId); }
    });
  }

  // ---- Shelf form ----------------------------------------------------------
  function openShelfForm(shelfId) {
    var editing = shelfId ? shelfById(shelfId) : null;
    var sh = editing || { name: "", description: "", color: S.BRAND_COLORS[1] };
    var colorVal = sh.color;

    var modal = $("#modal");
    modal.innerHTML = "";
    modal.appendChild(el("div", { class: "modal-head" }, [
      el("div", { style: "flex:1" }, [
        el("h2", { id: "modal-title" }, [editing ? "Edit shelf" : "New shelf"]),
        el("p", { class: "sub" }, [editing ? "Update this collection." : "Group books into a collection."])
      ]),
      el("button", { class: "icon-btn", type: "button", "aria-label": "Close", onclick: closeModal }, ["✕"])
    ]));

    var nameInput = el("input", { class: "field", id: "sh-name", type: "text", value: sh.name, maxlength: "80", required: "required" });
    var descInput = el("textarea", { class: "field", id: "sh-desc", rows: "2", maxlength: "240" });
    descInput.value = sh.description;

    var form = el("form", { novalidate: "novalidate" }, [
      field("Name", "sh-name", nameInput, true, "sh-name-err"),
      field("Description", "sh-desc", descInput, false),
      el("div", {}, [
        el("span", { class: "lbl" }, ["Color"]),
        (function () {
          var row = el("div", { class: "color-row", role: "group", "aria-label": "Shelf color" });
          S.BRAND_COLORS.forEach(function (c) {
            var dot = el("button", {
              type: "button", class: "color-dot", "aria-label": "Color " + c,
              "aria-pressed": c === colorVal ? "true" : "false",
              onclick: function () {
                colorVal = c;
                $all(".color-dot", row).forEach(function (d) { d.setAttribute("aria-pressed", "false"); });
                dot.setAttribute("aria-pressed", "true");
              }
            });
            dot.style.background = c;
            row.appendChild(dot);
          });
          return row;
        })()
      ])
    ]);
    modal.appendChild(form);

    var foot = el("div", { class: "modal-foot" });
    if (editing) {
      foot.appendChild(el("button", { class: "btn btn-danger left", type: "button", onclick: function () { confirmDeleteShelf(editing.id); } }, ["Delete"]));
    }
    foot.appendChild(el("button", { class: "btn btn-ghost", type: "button", onclick: closeModal }, ["Cancel"]));
    foot.appendChild(el("button", { class: "btn btn-primary", type: "button", onclick: submit }, [editing ? "Save" : "Create shelf"]));
    modal.appendChild(foot);
    form.addEventListener("submit", function (e) { e.preventDefault(); submit(); });
    openModal(false);

    function submit() {
      clearErr(["sh-name-err"]); nameInput.classList.remove("invalid");
      var name = nameInput.value.trim();
      if (!name) { showErr("sh-name-err", nameInput, "Shelf name is required."); return; }

      if (editing) {
        editing.name = name; editing.description = descInput.value.trim(); editing.color = colorVal;
        toast("Shelf updated", "success");
      } else {
        state.shelves.push(S.normShelf({ name: name, description: descInput.value.trim(), color: colorVal }));
        toast("Shelf created", "success");
      }
      persist();
      closeModal();
      render();
    }
  }

  function confirmDeleteShelf(shelfId) {
    var sh = shelfById(shelfId);
    if (!sh) return;
    var count = state.books.filter(function (b) { return b.shelfIds.indexOf(shelfId) >= 0; }).length;
    confirmDialog({
      title: "Delete shelf?",
      body: "“" + sh.name + "” will be deleted. " +
        (count > 0 ? count + " book" + (count === 1 ? "" : "s") + " will be unassigned from it, but no books are deleted." : "No books are assigned to it."),
      confirmLabel: "Delete shelf",
      confirmClass: "btn-danger",
      onConfirm: function () {
        state.books.forEach(function (b) {
          b.shelfIds = b.shelfIds.filter(function (id) { return id !== shelfId; });
        });
        state.shelves = state.shelves.filter(function (s) { return s.id !== shelfId; });
        if (ui.filterShelf === shelfId) ui.filterShelf = "";
        persist();
        toast("Shelf deleted");
        closeModal();
        render();
      }
    });
  }

  function confirmDeleteBook(bookId) {
    var b = bookById(bookId);
    if (!b) return;
    confirmDialog({
      title: "Delete book?",
      body: "“" + b.title + "” and its reading sessions will be permanently removed.",
      confirmLabel: "Delete book",
      confirmClass: "btn-danger",
      onConfirm: function () {
        state.books = state.books.filter(function (x) { return x.id !== bookId; });
        state.sessions = state.sessions.filter(function (s) { return s.bookId !== bookId; });
        persist();
        toast("Book deleted");
        closeModal();
        render();
      }
    });
  }

  // ---- Generic confirm dialog ---------------------------------------------
  function confirmDialog(opts) {
    var modal = $("#modal");
    modal.innerHTML = "";
    modal.appendChild(el("div", { class: "modal-head" }, [
      el("h2", { id: "modal-title", style: "flex:1" }, [opts.title])
    ]));
    modal.appendChild(el("p", { style: "color:var(--text-2);line-height:1.6" }, [opts.body]));
    var foot = el("div", { class: "modal-foot" }, [
      el("button", {
        class: "btn btn-ghost", type: "button",
        onclick: function () { if (opts.onCancel) opts.onCancel(); else closeModal(); }
      }, [opts.cancelLabel || "Cancel"]),
      el("button", {
        class: "btn " + (opts.confirmClass || "btn-primary"), type: "button",
        onclick: function () { opts.onConfirm(); }
      }, [opts.confirmLabel || "Confirm"])
    ]);
    modal.appendChild(foot);
    openModal(false);
    // focus confirm by default for keyboard flow
    setTimeout(function () { var c = foot.querySelector(".btn:last-child"); if (c) c.focus(); }, 40);
  }

  // ===========================================================================
  //  EXPORT / IMPORT
  // ===========================================================================
  function exportJSON() {
    var data = S.normState(state);
    var blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
    downloadBlob(blob, "stacks-library-" + todayStr() + ".json");
    toast("Library exported", "success");
  }

  function csvCell(v) {
    var s = String(v == null ? "" : v);
    if (/[",\n]/.test(s)) return '"' + s.replace(/"/g, '""') + '"';
    return s;
  }

  function exportCSV() {
    var headers = ["Title", "Author", "Year", "Pages", "Genre", "Status", "Current Page", "Rating", "Date Added", "Date Finished", "Shelves", "Review"];
    var rows = [headers.map(csvCell).join(",")];
    state.books.forEach(function (b) {
      var shelfNames = b.shelfIds.map(function (id) { var s = shelfById(id); return s ? s.name : ""; }).filter(Boolean).join("; ");
      rows.push([
        b.title, b.author, b.year || "", b.pageCount || "", b.genre, STATUS_LABEL[b.status],
        b.currentPage || "", (b.status === "finished" && b.rating ? b.rating : ""),
        b.dateAdded ? b.dateAdded.slice(0, 10) : "", b.dateFinished ? b.dateFinished.slice(0, 10) : "",
        shelfNames, b.review
      ].map(csvCell).join(","));
    });
    var blob = new Blob([rows.join("\n")], { type: "text/csv" });
    downloadBlob(blob, "stacks-books-" + todayStr() + ".csv");
    toast("CSV exported", "success");
  }

  function downloadBlob(blob, name) {
    try {
      var url = URL.createObjectURL(blob);
      var a = document.createElement("a");
      a.href = url; a.download = name;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
    } catch (e) {
      toast("Download failed in this browser.", "error");
    }
  }

  function importJSON() { $("#import-file").click(); }

  function handleImportFile(file) {
    if (!file) return;
    var loading = $("#import-loading");
    loading.classList.add("on");
    var reader = new FileReader();
    reader.onload = function () {
      setTimeout(function () {
        loading.classList.remove("on");
        var parsed = S.parseImport(reader.result);
        if (!parsed) {
          toast("That file isn't a valid Stacks library.", "error");
          return;
        }
        confirmDialog({
          title: "Replace your library?",
          body: "Importing will replace your current library with " + parsed.books.length +
            " book" + (parsed.books.length === 1 ? "" : "s") + ", " + parsed.shelves.length +
            " shelf" + (parsed.shelves.length === 1 ? "" : "ves") + ", and " + parsed.sessions.length +
            " session" + (parsed.sessions.length === 1 ? "" : "s") + ". This can't be undone.",
          confirmLabel: "Import & replace",
          confirmClass: "btn-primary",
          onConfirm: function () {
            // keep current settings unless import carries valid ones
            parsed.settings = state.settings;
            parsed.seeded = true;
            state = parsed;
            persist();
            applySettings();
            closeModal();
            toast("Library imported", "success");
            render();
          }
        });
      }, 350); // subtle loading affordance
    };
    reader.onerror = function () {
      loading.classList.remove("on");
      toast("Could not read that file.", "error");
    };
    try { reader.readAsText(file); }
    catch (e) { loading.classList.remove("on"); toast("Could not read that file.", "error"); }
  }

  // ===========================================================================
  //  SETTINGS ACTIONS
  // ===========================================================================
  function confirmResetSample() {
    confirmDialog({
      title: "Reset to sample library?",
      body: "This replaces everything in Stacks with the original Orbioom starter collection. Your current books, shelves, and sessions will be lost.",
      confirmLabel: "Reset to sample",
      confirmClass: "btn-danger",
      onConfirm: function () {
        state = Seed.build();
        // preserve display prefs people likely want to keep
        persist();
        applySettings();
        ui.filterShelf = ""; ui.filterStatus = ""; ui.filterGenre = ""; ui.search = "";
        var sb = $("#search"); if (sb) sb.value = "";
        var fs = $("#filter-status"); if (fs) fs.value = "";
        closeModal();
        toast("Sample library restored", "success");
        render();
      }
    });
  }

  function confirmClearAll() {
    confirmDialog({
      title: "Clear all data?",
      body: "Every book, shelf, and reading session on this device will be permanently deleted. Your settings are kept.",
      confirmLabel: "Clear everything",
      confirmClass: "btn-danger",
      onConfirm: function () {
        var keepSettings = state.settings;
        state = S.normState({ settings: keepSettings, seeded: true });
        persist();
        ui.filterShelf = ""; ui.filterStatus = ""; ui.filterGenre = ""; ui.search = "";
        var sb = $("#search"); if (sb) sb.value = "";
        var fs = $("#filter-status"); if (fs) fs.value = "";
        closeModal();
        toast("All data cleared");
        render();
      }
    });
  }

  // ===========================================================================
  //  CHROME / EVENTS
  // ===========================================================================
  function switchView(view) {
    ui.view = view;
    $all(".nav-btn").forEach(function (b) {
      var on = b.getAttribute("data-view") === view;
      b.setAttribute("aria-current", on ? "page" : "false");
      if (!on) b.removeAttribute("aria-current");
    });
    $all(".view").forEach(function (v) { v.classList.remove("active"); });
    var target = $("#view-" + view);
    if (target) { target.classList.add("active"); }
    render();
  }

  function renderIfVisible() { render(); }

  function clearFilters() {
    ui.search = ""; ui.filterStatus = ""; ui.filterShelf = ""; ui.filterGenre = "";
    $("#search").value = "";
    $("#filter-status").value = "";
    $("#filter-shelf").value = "";
    $("#filter-genre").value = "";
    renderLibrary();
  }

  function bindChrome() {
    $all(".nav-btn").forEach(function (b) {
      b.addEventListener("click", function () { switchView(b.getAttribute("data-view")); });
    });

    $("#add-book-top").addEventListener("click", function () { openBookForm(null); });

    // Library toolbar
    var search = $("#search");
    search.addEventListener("input", function () { ui.search = search.value; renderLibrary(); });
    $("#filter-status").addEventListener("change", function (e) { ui.filterStatus = e.target.value; renderLibrary(); });
    $("#filter-shelf").addEventListener("change", function (e) { ui.filterShelf = e.target.value; renderLibrary(); });
    $("#filter-genre").addEventListener("change", function (e) { ui.filterGenre = e.target.value; renderLibrary(); });
    $("#sort-by").addEventListener("change", function (e) { ui.sort = e.target.value; renderLibrary(); });
    $("#sort-by").value = ui.sort;
    $("#clear-filters").addEventListener("click", clearFilters);

    $("#view-grid").addEventListener("click", function () { setView("grid"); });
    $("#view-list").addEventListener("click", function () { setView("list"); });

    // Shelves
    $("#add-shelf").addEventListener("click", function () { openShelfForm(null); });

    // Settings
    $("#set-theme").addEventListener("change", function (e) {
      state.settings.theme = e.target.value;
      document.documentElement.setAttribute("data-theme", state.settings.theme);
      persist();
    });
    $("#set-sort").addEventListener("change", function (e) {
      state.settings.defaultSort = e.target.value;
      ui.sort = e.target.value;
      $("#sort-by").value = e.target.value;
      persist();
      if (ui.view === "library") renderLibrary();
    });
    $("#density-comfortable").addEventListener("click", function () { setDensity("comfortable"); });
    $("#density-compact").addEventListener("click", function () { setDensity("compact"); });

    $("#export-json").addEventListener("click", exportJSON);
    $("#export-csv").addEventListener("click", exportCSV);
    $("#import-json").addEventListener("click", importJSON);
    $("#import-file").addEventListener("change", function (e) {
      var f = e.target.files && e.target.files[0];
      handleImportFile(f);
      e.target.value = ""; // allow re-importing same file
    });
    $("#reset-sample").addEventListener("click", confirmResetSample);
    $("#clear-all").addEventListener("click", confirmClearAll);

    // overlay click-out
    $("#overlay").addEventListener("mousedown", function (e) {
      if (e.target === $("#overlay")) closeModal();
    });

    // react to system theme changes when in system mode
    if (global.matchMedia) {
      var mq = global.matchMedia("(prefers-color-scheme: dark)");
      var onChange = function () { /* CSS handles it via [data-theme=system]; nothing needed */ };
      if (mq.addEventListener) mq.addEventListener("change", onChange);
      else if (mq.addListener) mq.addListener(onChange);
    }
  }

  function setView(v) {
    state.settings.view = v;
    setPressed($("#view-grid"), v === "grid");
    setPressed($("#view-list"), v === "list");
    persist();
    renderLibrary();
  }

  function setDensity(d) {
    state.settings.density = d;
    setPressed($("#density-comfortable"), d === "comfortable");
    setPressed($("#density-compact"), d === "compact");
    persist();
    if (ui.view === "library") renderLibrary();
  }

  // ---- Toast ---------------------------------------------------------------
  function toast(msg, kind) {
    var wrap = $("#toast-wrap");
    var t = el("div", { class: "toast" + (kind ? " " + kind : "") }, [msg]);
    wrap.appendChild(t);
    setTimeout(function () {
      t.style.transition = "opacity 0.3s, transform 0.3s";
      t.style.opacity = "0"; t.style.transform = "translateY(8px)";
      setTimeout(function () { if (t.parentNode) t.parentNode.removeChild(t); }, 320);
    }, 2600);
  }

  // ---- Boot ----------------------------------------------------------------
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})(window);
