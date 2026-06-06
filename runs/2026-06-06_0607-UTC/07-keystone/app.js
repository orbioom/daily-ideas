/*
 * app.js — UI wiring for Keystone.
 *
 * Owns app state (projects, active project, settings), renders the timeline +
 * table from the live CPM result, handles CRUD on tasks and projects, modals
 * (focus-trapped, Esc to close), validation, import/export, and settings.
 * The schedule math lives entirely in cpm.js; this file never computes ES/EF.
 */

(function () {
  "use strict";

  var $ = function (sel, root) {
    return (root || document).querySelector(sel);
  };

  // ---------- App state ----------
  var state = STORAGE.load();

  function activeProject() {
    return (
      state.projects.filter(function (p) {
        return p.id === state.activeId;
      })[0] || null
    );
  }

  function persist() {
    STORAGE.save(state);
  }

  function uid(prefix) {
    return (
      (prefix || "id") +
      "-" +
      Date.now().toString(36) +
      "-" +
      Math.random().toString(36).slice(2, 7)
    );
  }

  // ---------- First-run seed ----------
  function ensureSeed() {
    if (state.projects.length === 0) {
      var sample = SEED.makeSampleProject();
      state.projects.push(sample);
      state.activeId = sample.id;
      persist();
    }
  }

  // ---------- Toast ----------
  var toastEl = $("#toast");
  var toastTimer = null;
  function toast(msg) {
    toastEl.textContent = msg;
    toastEl.hidden = false;
    // force reflow so the transition runs
    void toastEl.offsetWidth;
    toastEl.classList.add("is-visible");
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(function () {
      toastEl.classList.remove("is-visible");
      setTimeout(function () {
        toastEl.hidden = true;
      }, 400);
    }, 2600);
  }

  // ---------- Settings application ----------
  function applySettings() {
    document.documentElement.setAttribute(
      "data-theme",
      state.settings.dark ? "dark" : "light"
    );
  }

  // ---------- Sorting state for table ----------
  var sort = { key: "es", dir: "asc" };

  // ---------- Rendering ----------
  var lastResult = null;

  function render() {
    var proj = activeProject();
    renderProjectSelect();

    var emptyState = $("#empty-state");
    var views = $("#views");
    var dataActions = $(".data-actions");
    var errorBanner = $("#error-banner");

    if (!proj) {
      emptyState.hidden = true;
      views.hidden = true;
      errorBanner.hidden = true;
      setSummary(0, 0, 0, "—");
      return;
    }

    var unit = proj.unit || "days";
    $("#sum-unit").textContent = unit;

    var result = CPM.compute(proj.tasks);
    lastResult = result;

    if (!result.ok && result.cycle) {
      showCycleError(result.cycle, proj);
    } else {
      errorBanner.hidden = true;
    }

    // Empty vs populated.
    if (proj.tasks.length === 0) {
      emptyState.hidden = false;
      views.hidden = true;
      dataActions.hidden = false;
      setSummary(0, 0, 0, "—");
      return;
    }

    emptyState.hidden = true;
    views.hidden = false;
    dataActions.hidden = false;

    if (result.ok) {
      var critCount = result.criticalIds.length;
      setSummary(
        result.projectDuration,
        critCount,
        proj.tasks.length,
        formatCriticalPath(result, proj)
      );
      renderTimeline(proj, result);
      renderTable(proj, result);
    } else {
      // Cycle: keep counts honest, blank the schedule views.
      setSummary("—", "—", proj.tasks.length, "Resolve the cycle to compute");
      $("#timeline").innerHTML = "";
      $("#table-body").innerHTML = "";
    }
  }

  function setSummary(dur, crit, tasks, path) {
    $("#sum-duration").textContent = dur;
    $("#sum-critical").textContent = crit;
    $("#sum-tasks").textContent = tasks;
    $("#sum-path").innerHTML = path;
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return {
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;",
      }[c];
    });
  }

  function formatCriticalPath(result, proj) {
    if (!result.criticalPaths.length) return "—";
    var byId = taskMap(proj);
    var path = result.criticalPaths[0];
    return path
      .map(function (id) {
        return (
          '<span class="crit-chip">' +
          escapeHtml(byId[id] ? byId[id].name : id) +
          "</span>"
        );
      })
      .join(" → ");
  }

  function taskMap(proj) {
    var m = {};
    proj.tasks.forEach(function (t) {
      m[t.id] = t;
    });
    return m;
  }

  function showCycleError(cycle, proj) {
    var byId = taskMap(proj);
    var names = cycle.map(function (id) {
      return byId[id] ? byId[id].name : id;
    });
    var banner = $("#error-banner");
    banner.innerHTML =
      "<strong>Dependency cycle detected.</strong> These tasks depend on each " +
      "other in a loop, so a schedule can't be computed: " +
      escapeHtml(names.join(" → ")) +
      ". Edit one of these tasks to remove a predecessor and break the loop.";
    banner.hidden = false;
  }

  function renderProjectSelect() {
    var sel = $("#project-select");
    var prev = sel.value;
    sel.innerHTML = "";
    state.projects.forEach(function (p) {
      var opt = document.createElement("option");
      opt.value = p.id;
      opt.textContent = p.name;
      if (p.id === state.activeId) opt.selected = true;
      sel.appendChild(opt);
    });
    if (state.projects.length === 0) {
      var opt = document.createElement("option");
      opt.textContent = "No projects";
      opt.disabled = true;
      sel.appendChild(opt);
    }
    if (prev && sel.value !== state.activeId) sel.value = state.activeId || "";
  }

  // ---------- Timeline ----------
  function renderTimeline(proj, result) {
    var tl = $("#timeline");
    tl.innerHTML = "";
    tl.classList.toggle("hide-slack", !state.settings.showSlackBars);

    var duration = result.projectDuration || 1;
    var col = 26;
    // Cap column width so long projects still fit; expand short ones a little.
    var unitW = Math.max(8, Math.min(col, Math.floor(900 / Math.max(1, duration))));
    tl.style.setProperty("--col", unitW + "px");

    // Render in topological order for a readable cascade.
    var order = result.order.slice();
    var byId = taskMap(proj);
    var trackW = duration * unitW;

    order.forEach(function (id) {
      var n = result.tasks[id];
      var t = byId[id];
      var row = document.createElement("div");
      row.className = "tl-row" + (n.critical ? " is-critical" : "");

      var name = document.createElement("div");
      name.className = "tl-name";
      name.title = t.name;
      name.innerHTML =
        '<span class="dot" aria-hidden="true"></span>' + escapeHtml(t.name);

      var track = document.createElement("div");
      track.className = "tl-track";
      track.style.minWidth = trackW + "px";

      var grid = document.createElement("div");
      grid.className = "tl-grid";
      track.appendChild(grid);

      var bar = document.createElement("div");
      bar.className = "tl-bar";
      bar.style.left = n.es * unitW + "px";
      bar.style.width = Math.max(4, n.duration * unitW) + "px";
      bar.setAttribute(
        "aria-label",
        t.name +
          ": starts at " +
          n.es +
          ", finishes at " +
          n.ef +
          (n.critical ? ", critical" : ", slack " + n.slack)
      );
      var label = document.createElement("span");
      label.className = "tl-bar-label";
      label.textContent = n.duration > 0 ? n.es + "–" + n.ef : "" + n.es;
      bar.appendChild(label);
      track.appendChild(bar);

      if (n.slack > 0) {
        var slack = document.createElement("div");
        slack.className = "tl-slack";
        slack.style.left = n.ef * unitW + "px";
        slack.style.width = n.slack * unitW + "px";
        slack.title = "Slack: " + n.slack + " " + (proj.unit || "days");
        track.appendChild(slack);
      }

      row.appendChild(name);
      row.appendChild(track);
      tl.appendChild(row);
    });
  }

  // ---------- Table ----------
  function renderTable(proj, result) {
    var body = $("#table-body");
    body.innerHTML = "";
    var byId = taskMap(proj);

    var rows = proj.tasks.map(function (t) {
      var n = result.tasks[t.id];
      return { t: t, n: n };
    });

    rows.sort(function (a, b) {
      var av = sortValue(a, sort.key);
      var bv = sortValue(b, sort.key);
      if (av < bv) return sort.dir === "asc" ? -1 : 1;
      if (av > bv) return sort.dir === "asc" ? 1 : -1;
      return a.n.es - b.n.es;
    });

    // Reflect sort direction on the active sort button.
    document.querySelectorAll(".sort-btn").forEach(function (btn) {
      if (btn.getAttribute("data-sort") === sort.key) {
        btn.setAttribute("data-dir", sort.dir);
      } else {
        btn.removeAttribute("data-dir");
      }
    });

    rows.forEach(function (r) {
      var t = r.t;
      var n = r.n;
      var tr = document.createElement("tr");
      if (n.critical) tr.className = "is-critical";

      var preds = (t.predecessors || [])
        .map(function (p) {
          return byId[p] ? byId[p].name : null;
        })
        .filter(Boolean);

      tr.innerHTML =
        '<td><span class="t-name">' +
        escapeHtml(t.name) +
        (n.critical ? ' <span class="crit-flag">critical</span>' : "") +
        "</span></td>" +
        '<td class="num">' +
        n.duration +
        "</td>" +
        '<td class="num">' +
        n.es +
        "</td>" +
        '<td class="num">' +
        n.ef +
        "</td>" +
        '<td class="num">' +
        n.ls +
        "</td>" +
        '<td class="num">' +
        n.lf +
        "</td>" +
        '<td class="num ' +
        (n.slack === 0 ? "slack-zero" : "") +
        '">' +
        n.slack +
        "</td>" +
        '<td class="preds-cell">' +
        (preds.length ? escapeHtml(preds.join(", ")) : "—") +
        "</td>" +
        '<td><div class="row-actions">' +
        '<button type="button" class="btn btn-ghost btn-icon" data-edit="' +
        t.id +
        '">Edit</button>' +
        '<button type="button" class="btn btn-ghost btn-icon btn-danger" data-del="' +
        t.id +
        '">Delete</button>' +
        "</div></td>";
      body.appendChild(tr);
    });
  }

  function sortValue(r, key) {
    if (key === "slack") return r.n.slack;
    if (key === "es") return r.n.es;
    return r.n.es;
  }

  // ---------- Modal infrastructure (focus trap + Esc) ----------
  var openModalEl = null;
  var lastFocused = null;

  function getFocusable(modal) {
    return Array.prototype.slice
      .call(
        modal.querySelectorAll(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        )
      )
      .filter(function (el) {
        return !el.disabled && el.offsetParent !== null;
      });
  }

  function openModal(overlayId, onOpen) {
    var overlay = $("#" + overlayId);
    lastFocused = document.activeElement;
    overlay.hidden = false;
    openModalEl = overlay;
    if (onOpen) onOpen(overlay);
    var focusables = getFocusable(overlay.querySelector(".modal"));
    if (focusables.length) focusables[0].focus();
  }

  function closeModal() {
    if (!openModalEl) return;
    openModalEl.hidden = true;
    openModalEl = null;
    if (lastFocused && lastFocused.focus) lastFocused.focus();
  }

  document.addEventListener("keydown", function (e) {
    if (!openModalEl) return;
    if (e.key === "Escape") {
      e.preventDefault();
      closeModal();
      return;
    }
    if (e.key === "Tab") {
      var modal = openModalEl.querySelector(".modal");
      var f = getFocusable(modal);
      if (!f.length) return;
      var first = f[0];
      var last = f[f.length - 1];
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    }
  });

  // Click outside the modal closes; explicit close buttons close.
  document.querySelectorAll(".modal-overlay").forEach(function (overlay) {
    overlay.addEventListener("mousedown", function (e) {
      if (e.target === overlay) closeModal();
    });
  });
  document.querySelectorAll("[data-close-modal]").forEach(function (btn) {
    btn.addEventListener("click", closeModal);
  });

  // ---------- Task modal ----------
  var editingTaskId = null;

  function openTaskModal(taskId) {
    var proj = activeProject();
    if (!proj) return;
    editingTaskId = taskId || null;
    var existing = taskId
      ? proj.tasks.filter(function (t) {
          return t.id === taskId;
        })[0]
      : null;

    $("#task-modal-title").textContent = existing ? "Edit task" : "Add task";
    $("#task-submit").textContent = existing ? "Save changes" : "Add task";
    $("#task-name").value = existing ? existing.name : "";
    $("#task-duration").value = existing ? existing.duration : 1;
    $("#duration-label").textContent =
      "Duration (" + (proj.unit || "days") + ")";
    clearTaskErrors();

    // Build predecessor options (exclude self), preselect existing.
    var predsSel = $("#task-preds");
    predsSel.innerHTML = "";
    proj.tasks.forEach(function (t) {
      if (existing && t.id === existing.id) return;
      var opt = document.createElement("option");
      opt.value = t.id;
      opt.textContent = t.name;
      if (existing && existing.predecessors.indexOf(t.id) !== -1)
        opt.selected = true;
      predsSel.appendChild(opt);
    });
    if (predsSel.options.length === 0) {
      var opt = document.createElement("option");
      opt.textContent = "No other tasks yet";
      opt.disabled = true;
      predsSel.appendChild(opt);
    }

    openModal("task-modal");
  }

  function clearTaskErrors() {
    $("#task-name-error").textContent = "";
    $("#task-duration-error").textContent = "";
    $("#task-preds-error").textContent = "";
  }

  function submitTask(e) {
    e.preventDefault();
    var proj = activeProject();
    if (!proj) return;
    clearTaskErrors();

    var name = $("#task-name").value.trim();
    var durRaw = $("#task-duration").value;
    var preds = Array.prototype.slice
      .call($("#task-preds").selectedOptions)
      .map(function (o) {
        return o.value;
      })
      .filter(function (v) {
        return !!v;
      });

    var valid = true;

    if (!name) {
      $("#task-name-error").textContent = "Give the task a name.";
      valid = false;
    } else {
      var dup = proj.tasks.some(function (t) {
        return (
          t.id !== editingTaskId &&
          t.name.trim().toLowerCase() === name.toLowerCase()
        );
      });
      if (dup) {
        $("#task-name-error").textContent =
          "A task with this name already exists.";
        valid = false;
      }
    }

    var dur = Number(durRaw);
    if (durRaw === "" || isNaN(dur) || dur < 0) {
      $("#task-duration-error").textContent =
        "Duration must be a number of 0 or more.";
      valid = false;
    } else if (dur > 9999) {
      $("#task-duration-error").textContent = "Duration is too large (max 9999).";
      valid = false;
    }

    // Self-dependency guard (defensive; self is excluded from the list).
    if (editingTaskId && preds.indexOf(editingTaskId) !== -1) {
      $("#task-preds-error").textContent = "A task can't depend on itself.";
      valid = false;
    }

    if (!valid) return;

    // Build the prospective task set and reject cycles before committing.
    var id = editingTaskId || uid("t");
    var prospective = proj.tasks.map(function (t) {
      return {
        id: t.id,
        name: t.name,
        duration: t.duration,
        predecessors: t.predecessors.slice(),
      };
    });
    var target = prospective.filter(function (t) {
      return t.id === id;
    })[0];
    if (target) {
      target.name = name;
      target.duration = dur;
      target.predecessors = preds;
    } else {
      prospective.push({
        id: id,
        name: name,
        duration: dur,
        predecessors: preds,
      });
    }

    var cycle = CPM.findCycle(prospective);
    if (cycle) {
      var byId = {};
      prospective.forEach(function (t) {
        byId[t.id] = t;
      });
      var names = cycle.map(function (cid) {
        return byId[cid] ? byId[cid].name : cid;
      });
      $("#task-preds-error").textContent =
        "These predecessors would create a cycle: " + names.join(" → ") + ".";
      return;
    }

    // Commit.
    proj.tasks = prospective;
    persist();
    closeModal();
    render();
    toast(editingTaskId ? "Task updated" : "Task added");
    announceRecompute();
  }

  function deleteTask(taskId) {
    var proj = activeProject();
    if (!proj) return;
    var t = proj.tasks.filter(function (x) {
      return x.id === taskId;
    })[0];
    if (!t) return;

    var doDelete = function () {
      proj.tasks = proj.tasks
        .filter(function (x) {
          return x.id !== taskId;
        })
        .map(function (x) {
          return {
            id: x.id,
            name: x.name,
            duration: x.duration,
            predecessors: x.predecessors.filter(function (p) {
              return p !== taskId;
            }),
          };
        });
      persist();
      render();
      toast("Task deleted");
      announceRecompute();
    };

    if (state.settings.confirmDeletes) {
      confirmAction(
        "Delete task",
        'Delete "' +
          t.name +
          '"? Other tasks that depend on it will lose this dependency.',
        doDelete
      );
    } else {
      doDelete();
    }
  }

  function announceRecompute() {
    // The aria-live summary values were already updated in render(); nudging
    // them is enough for screen readers to read the new schedule.
  }

  // ---------- Confirm modal ----------
  var confirmCb = null;
  function confirmAction(title, body, cb) {
    $("#confirm-modal-title").textContent = title;
    $("#confirm-modal-body").textContent = body;
    confirmCb = cb;
    openModal("confirm-modal");
  }
  $("#confirm-ok").addEventListener("click", function () {
    var cb = confirmCb;
    confirmCb = null;
    closeModal();
    if (cb) cb();
  });

  // ---------- Prompt modal (new / rename project) ----------
  var promptCb = null;
  function promptText(title, label, initial, cb) {
    $("#prompt-modal-title").textContent = title;
    $("#prompt-label").textContent = label;
    $("#prompt-error").textContent = "";
    promptCb = cb;
    openModal("prompt-modal", function () {
      $("#prompt-input").value = initial || "";
    });
  }
  $("#prompt-form").addEventListener("submit", function (e) {
    e.preventDefault();
    var val = $("#prompt-input").value.trim();
    if (!val) {
      $("#prompt-error").textContent = "Please enter a name.";
      return;
    }
    var cb = promptCb;
    promptCb = null;
    closeModal();
    if (cb) cb(val);
  });

  // ---------- Project CRUD ----------
  function newProject() {
    promptText("New project", "Project name", "", function (name) {
      var proj = {
        id: uid("proj"),
        name: name,
        unit: "days",
        createdAt: Date.now(),
        tasks: [],
      };
      state.projects.push(proj);
      state.activeId = proj.id;
      persist();
      render();
      toast("Project created");
    });
  }

  function renameProject() {
    var proj = activeProject();
    if (!proj) return;
    promptText("Rename project", "Project name", proj.name, function (name) {
      proj.name = name;
      persist();
      render();
      toast("Project renamed");
    });
  }

  function deleteProject() {
    var proj = activeProject();
    if (!proj) return;
    var doDelete = function () {
      state.projects = state.projects.filter(function (p) {
        return p.id !== proj.id;
      });
      state.activeId = state.projects.length ? state.projects[0].id : null;
      persist();
      render();
      toast("Project deleted");
    };
    if (state.settings.confirmDeletes) {
      confirmAction(
        "Delete project",
        'Delete the project "' +
          proj.name +
          '" and all its tasks? This cannot be undone.',
        doDelete
      );
    } else {
      doDelete();
    }
  }

  // ---------- Settings modal ----------
  function openSettings() {
    var proj = activeProject();
    $("#set-unit").value = proj ? proj.unit || "days" : "days";
    $("#set-unit").disabled = !proj;
    $("#set-slack").checked = state.settings.showSlackBars;
    $("#set-dark").checked = state.settings.dark;
    $("#set-confirm").checked = state.settings.confirmDeletes;
    openModal("settings-modal");
  }

  $("#set-unit").addEventListener("change", function () {
    var proj = activeProject();
    if (!proj) return;
    proj.unit = $("#set-unit").value;
    persist();
    render();
  });
  $("#set-slack").addEventListener("change", function () {
    state.settings.showSlackBars = $("#set-slack").checked;
    persist();
    render();
  });
  $("#set-dark").addEventListener("change", function () {
    state.settings.dark = $("#set-dark").checked;
    persist();
    applySettings();
  });
  $("#set-confirm").addEventListener("change", function () {
    state.settings.confirmDeletes = $("#set-confirm").checked;
    persist();
  });

  // ---------- Export / Import ----------
  function download(filename, text, type) {
    var blob = new Blob([text], { type: type || "text/plain" });
    var url = URL.createObjectURL(blob);
    var a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    setTimeout(function () {
      URL.revokeObjectURL(url);
    }, 1000);
  }

  function safeName(s) {
    return (s || "project")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 40) || "project";
  }

  function exportJSON() {
    var proj = activeProject();
    if (!proj) return;
    var payload = {
      keystone: "project",
      version: 1,
      project: {
        id: proj.id,
        name: proj.name,
        unit: proj.unit || "days",
        createdAt: proj.createdAt || Date.now(),
        tasks: proj.tasks,
      },
    };
    download(
      "keystone-" + safeName(proj.name) + ".json",
      JSON.stringify(payload, null, 2),
      "application/json"
    );
    toast("Project exported");
  }

  function exportCSV() {
    var proj = activeProject();
    if (!proj) return;
    var result = CPM.compute(proj.tasks);
    if (!result.ok) {
      toast("Resolve the cycle before exporting the schedule.");
      return;
    }
    var byId = taskMap(proj);
    var rows = [
      ["Task", "Duration", "ES", "EF", "LS", "LF", "Slack", "Critical", "Predecessors"],
    ];
    result.order.forEach(function (id) {
      var n = result.tasks[id];
      var t = byId[id];
      var preds = (t.predecessors || [])
        .map(function (p) {
          return byId[p] ? byId[p].name : "";
        })
        .filter(Boolean)
        .join("; ");
      rows.push([
        t.name,
        n.duration,
        n.es,
        n.ef,
        n.ls,
        n.lf,
        n.slack,
        n.critical ? "yes" : "no",
        preds,
      ]);
    });
    var csv = rows
      .map(function (r) {
        return r
          .map(function (cell) {
            var s = String(cell);
            if (/[",\n]/.test(s)) return '"' + s.replace(/"/g, '""') + '"';
            return s;
          })
          .join(",");
      })
      .join("\r\n");
    download(
      "keystone-schedule-" + safeName(proj.name) + ".csv",
      csv,
      "text/csv"
    );
    toast("Schedule exported as CSV");
  }

  function importJSON(file) {
    var reader = new FileReader();
    reader.onload = function () {
      var parsed;
      try {
        parsed = JSON.parse(reader.result);
      } catch (err) {
        toast("That file isn't valid JSON.");
        return;
      }
      var p = parsed && parsed.project ? parsed.project : parsed;
      if (!p || !Array.isArray(p.tasks) || typeof p.name !== "string") {
        toast("That JSON isn't a Keystone project.");
        return;
      }
      // Sanitize tasks; re-key ids if they collide with existing projects is
      // unnecessary because each project keeps its own task ids.
      var seenIds = {};
      var tasks = [];
      var valid = true;
      p.tasks.forEach(function (t) {
        if (!t || typeof t.id !== "string" || typeof t.name !== "string") {
          valid = false;
          return;
        }
        if (seenIds[t.id]) {
          valid = false;
          return;
        }
        seenIds[t.id] = true;
        tasks.push({
          id: t.id,
          name: String(t.name),
          duration: Math.max(0, Number(t.duration) || 0),
          predecessors: Array.isArray(t.predecessors)
            ? t.predecessors.filter(function (x) {
                return typeof x === "string";
              })
            : [],
        });
      });
      if (!valid) {
        toast("Some tasks in that file were malformed and couldn't be read.");
        return;
      }
      var proj = {
        id: uid("proj"),
        name: p.name,
        unit: p.unit === "weeks" || p.unit === "hours" ? p.unit : "days",
        createdAt: Date.now(),
        tasks: tasks,
      };
      state.projects.push(proj);
      state.activeId = proj.id;
      persist();
      render();
      toast('Imported "' + proj.name + '"');
    };
    reader.onerror = function () {
      toast("Couldn't read that file.");
    };
    reader.readAsText(file);
  }

  // ---------- Reset / clear ----------
  function resetSample() {
    confirmAction(
      "Reset to sample",
      "Add a fresh copy of the sample project (Mobile App v1 Launch)? Your other projects are kept.",
      function () {
        var sample = SEED.makeSampleProject();
        sample.id = uid("proj");
        state.projects.push(sample);
        state.activeId = sample.id;
        persist();
        render();
        toast("Sample project added");
      }
    );
  }

  function clearAll() {
    confirmAction(
      "Clear all data",
      "Delete every project and reset all settings? This removes all Keystone data from this browser and cannot be undone.",
      function () {
        STORAGE.clearAll();
        state = STORAGE.defaultState();
        ensureSeed();
        applySettings();
        render();
        toast("All data cleared — sample reloaded");
      }
    );
  }

  // ---------- Tab switching ----------
  function switchTab(which) {
    var isTimeline = which === "timeline";
    $("#tab-timeline").classList.toggle("is-active", isTimeline);
    $("#tab-table").classList.toggle("is-active", !isTimeline);
    $("#tab-timeline").setAttribute("aria-selected", String(isTimeline));
    $("#tab-table").setAttribute("aria-selected", String(!isTimeline));
    $("#panel-timeline").hidden = !isTimeline;
    $("#panel-table").hidden = isTimeline;
  }

  // ---------- Event wiring ----------
  function wire() {
    $("#add-task").addEventListener("click", function () {
      openTaskModal(null);
    });
    $("#empty-add-task").addEventListener("click", function () {
      openTaskModal(null);
    });
    $("#empty-load-sample").addEventListener("click", function () {
      var proj = activeProject();
      if (proj && proj.tasks.length === 0) {
        // Fill the current empty project from the sample.
        var sample = SEED.makeSampleProject();
        proj.tasks = sample.tasks;
        proj.unit = sample.unit;
        persist();
        render();
        toast("Sample tasks loaded");
      } else {
        resetSample();
      }
    });

    $("#task-form").addEventListener("submit", submitTask);

    $("#table-body").addEventListener("click", function (e) {
      var edit = e.target.closest("[data-edit]");
      var del = e.target.closest("[data-del]");
      if (edit) openTaskModal(edit.getAttribute("data-edit"));
      else if (del) deleteTask(del.getAttribute("data-del"));
    });

    $("#project-select").addEventListener("change", function () {
      state.activeId = $("#project-select").value;
      persist();
      render();
    });
    $("#new-project").addEventListener("click", newProject);
    $("#rename-project").addEventListener("click", renameProject);
    $("#delete-project").addEventListener("click", deleteProject);

    $("#open-settings").addEventListener("click", openSettings);

    $("#export-json").addEventListener("click", exportJSON);
    $("#export-csv").addEventListener("click", exportCSV);
    $("#import-json").addEventListener("click", function () {
      $("#import-file").click();
    });
    $("#import-file").addEventListener("change", function (e) {
      var file = e.target.files && e.target.files[0];
      if (file) importJSON(file);
      e.target.value = "";
    });
    $("#reset-sample").addEventListener("click", resetSample);
    $("#clear-all").addEventListener("click", clearAll);

    $("#tab-timeline").addEventListener("click", function () {
      switchTab("timeline");
    });
    $("#tab-table").addEventListener("click", function () {
      switchTab("table");
    });

    document.querySelectorAll(".sort-btn").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var key = btn.getAttribute("data-sort");
        if (sort.key === key) {
          sort.dir = sort.dir === "asc" ? "desc" : "asc";
        } else {
          sort.key = key;
          sort.dir = "asc";
        }
        var proj = activeProject();
        if (proj && lastResult && lastResult.ok) renderTable(proj, lastResult);
      });
    });
  }

  // ---------- Boot ----------
  ensureSeed();
  applySettings();
  wire();
  render();
})();
