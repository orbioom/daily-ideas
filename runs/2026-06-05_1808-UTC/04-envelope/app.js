/**
 * app.js — Envelope Budget · UI wiring, views, render, controls
 * Classic script (no ES modules) for file:// compatibility.
 */

/* ─────────────────────────────────────────────────────────────
   APP STATE
   ───────────────────────────────────────────────────────────── */
var App = (function () {
  'use strict';

  var state = null; // loaded from storage
  var currentView = 'dashboard';
  var modalStack = []; // stacked modal IDs for focus management
  var txSortField = 'date';
  var txSortDir = 'desc';
  var txFilterAccount = '';
  var txFilterEnvelope = '';
  var txFilterType = '';

  // palette for chart segments (cycled)
  var PALETTE = [
    '#86C79A', '#6BA5D7', '#C78686', '#C7A868', '#8A86C7',
    '#C786B8', '#7BC7C7', '#B8C786', '#C7866F', '#86B8C7',
  ];

  /* ─── Helpers ─────────────────────────────────────────────── */

  function fmt(amount, currency) {
    currency = currency || (state && state.settings.currency) || '$';
    var n = typeof amount === 'number' && isFinite(amount) ? amount : 0;
    return currency + Math.abs(n).toFixed(2);
  }

  function fmtSigned(amount, currency) {
    currency = currency || (state && state.settings.currency) || '$';
    var n = typeof amount === 'number' && isFinite(amount) ? amount : 0;
    var sign = n < 0 ? '-' : (n > 0 ? '+' : '');
    return sign + currency + Math.abs(n).toFixed(2);
  }

  function todayYYYYMM() {
    return new Date().toISOString().slice(0, 7);
  }

  function getActiveMonth() {
    return state.currentMonth || todayYYYYMM();
  }

  function monthLabel(yyyymm) {
    if (!yyyymm) yyyymm = todayYYYYMM();
    var parts = yyyymm.split('-');
    var d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, 1);
    return d.toLocaleString('default', { month: 'long', year: 'numeric' });
  }

  function prevMonth(yyyymm) {
    var parts = yyyymm.split('-');
    var d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, 1);
    d.setMonth(d.getMonth() - 1);
    return d.toISOString().slice(0, 7);
  }

  function nextMonth(yyyymm) {
    var parts = yyyymm.split('-');
    var d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, 1);
    d.setMonth(d.getMonth() + 1);
    return d.toISOString().slice(0, 7);
  }

  function escHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function el(id) { return document.getElementById(id); }

  /* ─── Domain computations ─────────────────────────────────── */

  function getTxForMonth(yyyymm) {
    return state.transactions.filter(function(t) {
      return t.date && t.date.slice(0, 7) === yyyymm;
    });
  }

  function getMonthIncome(yyyymm) {
    return getTxForMonth(yyyymm).reduce(function(s, t) {
      return s + (t.type === 'income' ? t.amount : 0);
    }, 0);
  }

  function getTotalBudgeted() {
    return state.envelopes.reduce(function(s, e) { return s + e.budgetedAmount; }, 0);
  }

  function getRolloverForEnvelope(envId, yyyymm) {
    // Sum leftover from all months prior to yyyymm for rollover envelopes
    var env = state.envelopes.find(function(e) { return e.id === envId; });
    if (!env || !env.rollover) return 0;

    // Collect all distinct months before yyyymm
    var months = [];
    state.transactions.forEach(function(t) {
      var m = t.date ? t.date.slice(0, 7) : null;
      if (m && m < yyyymm && months.indexOf(m) < 0) months.push(m);
    });

    var carry = 0;
    months.sort();
    months.forEach(function(m) {
      var spent = state.transactions.reduce(function(s, t) {
        return s + (t.envelopeId === envId && t.type === 'expense' && t.date && t.date.slice(0, 7) === m ? t.amount : 0);
      }, 0);
      var leftover = env.budgetedAmount - spent + carry;
      carry = leftover > 0 ? leftover : 0;
    });
    return carry;
  }

  function getEnvelopeStats(envId, yyyymm) {
    var env = state.envelopes.find(function(e) { return e.id === envId; });
    if (!env) return null;

    var spent = getTxForMonth(yyyymm).reduce(function(s, t) {
      return s + (t.envelopeId === envId && t.type === 'expense' ? t.amount : 0);
    }, 0);

    var rollover = getRolloverForEnvelope(envId, yyyymm);
    var available = env.budgetedAmount + rollover;
    var remaining = available - spent;
    var pct = available > 0 ? Math.min((spent / available) * 100, 100) : (spent > 0 ? 100 : 0);
    var overspent = spent > available;

    return {
      budgeted: env.budgetedAmount,
      rollover: rollover,
      available: available,
      spent: spent,
      remaining: remaining,
      pct: pct,
      overspent: overspent,
    };
  }

  function getToBeBudgeted(yyyymm) {
    var income = getMonthIncome(yyyymm);
    var totalBudgeted = getTotalBudgeted();
    return income - totalBudgeted;
  }

  function getAccountBalance(accountId) {
    var account = state.accounts.find(function(a) { return a.id === accountId; });
    if (!account) return 0;

    var balance = account.startingBalance;
    state.transactions.forEach(function(t) {
      if (t.accountId === accountId) {
        if (t.type === 'income') balance += t.amount;
        else if (t.type === 'expense') balance -= t.amount;
        else if (t.type === 'transfer') balance -= t.amount;
      }
      if (t.toAccountId === accountId && t.type === 'transfer') {
        balance += t.amount;
      }
    });
    return balance;
  }

  function getGroupedEnvelopes() {
    var groups = {};
    state.envelopes.forEach(function(e) {
      var g = e.group || 'General';
      if (!groups[g]) groups[g] = [];
      groups[g].push(e);
    });
    return groups;
  }

  function getSpendingByGroup(yyyymm) {
    var groups = {};
    var txs = getTxForMonth(yyyymm).filter(function(t) { return t.type === 'expense'; });

    txs.forEach(function(t) {
      if (!t.envelopeId) return;
      var env = state.envelopes.find(function(e) { return e.id === t.envelopeId; });
      if (!env) return;
      var g = env.group || 'General';
      groups[g] = (groups[g] || 0) + t.amount;
    });

    return groups;
  }

  function getTopEnvelopes(yyyymm, limit) {
    limit = limit || 6;
    var yyyymmStr = yyyymm;
    var result = state.envelopes.map(function(e) {
      var stats = getEnvelopeStats(e.id, yyyymmStr);
      return {
        id: e.id,
        name: e.name,
        icon: e.icon,
        spent: stats ? stats.spent : 0,
        budgeted: e.budgetedAmount,
        available: stats ? stats.available : 0,
      };
    });

    result.sort(function(a, b) { return b.spent - a.spent; });
    return result.slice(0, limit);
  }

  /* ─── Theme / settings application ───────────────────────── */

  function applyTheme(theme) {
    var root = document.documentElement;
    if (theme === 'dark') {
      root.setAttribute('data-theme', 'dark');
    } else if (theme === 'light') {
      root.setAttribute('data-theme', 'light');
    } else {
      // system
      var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      root.setAttribute('data-theme', prefersDark ? 'dark' : 'light');
    }
  }

  function applyReducedMotion(enabled) {
    document.documentElement.setAttribute('data-reduced-motion', enabled ? 'true' : 'false');
  }

  function applySettings() {
    var s = state.settings;
    applyTheme(s.theme);
    applyReducedMotion(s.reducedMotion);
  }

  /* ─── Toast notifications ─────────────────────────────────── */

  function toast(message, type, duration) {
    type = type || 'info';
    duration = duration || 3500;

    var region = el('toast-region');
    if (!region) return;

    var icons = { success: '✓', error: '⚠', info: 'ℹ' };
    var div = document.createElement('div');
    div.className = 'toast ' + type;
    div.setAttribute('role', 'status');
    div.setAttribute('aria-live', 'polite');
    div.innerHTML = '<span aria-hidden="true">' + icons[type] + '</span>'
      + '<span>' + escHtml(message) + '</span>';

    region.appendChild(div);

    var tid = setTimeout(function () {
      div.classList.add('leaving');
      setTimeout(function () {
        if (div.parentNode) div.parentNode.removeChild(div);
      }, 400);
    }, duration);

    div.addEventListener('click', function () {
      clearTimeout(tid);
      div.classList.add('leaving');
      setTimeout(function () {
        if (div.parentNode) div.parentNode.removeChild(div);
      }, 400);
    });
  }

  /* ─── Loading overlay ─────────────────────────────────────── */

  function showLoading(message) {
    var overlay = el('loading-overlay');
    if (!overlay) return;
    var txt = overlay.querySelector('.loading-text');
    if (txt) txt.textContent = message || 'Working…';
    overlay.classList.add('visible');
  }

  function hideLoading() {
    var overlay = el('loading-overlay');
    if (overlay) overlay.classList.remove('visible');
  }

  /* ─── Modal management ────────────────────────────────────── */

  var _lastFocused = null;

  function openModal(id) {
    var overlay = el(id);
    if (!overlay) return;

    _lastFocused = document.activeElement;
    overlay.removeAttribute('hidden');
    overlay.style.display = 'flex';

    // Force reflow for transition
    overlay.getBoundingClientRect();
    overlay.classList.add('visible');

    // Focus first focusable element
    var focusable = overlay.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    if (focusable.length) focusable[0].focus();

    modalStack.push(id);

    // Trap focus
    overlay.addEventListener('keydown', trapFocusHandler);
  }

  function closeModal(id) {
    var overlay = el(id);
    if (!overlay) return;

    overlay.classList.remove('visible');
    overlay.removeEventListener('keydown', trapFocusHandler);

    setTimeout(function () {
      overlay.style.display = 'none';
      overlay.setAttribute('hidden', '');
    }, 320);

    var idx = modalStack.indexOf(id);
    if (idx >= 0) modalStack.splice(idx, 1);

    // Restore focus
    if (_lastFocused && _lastFocused.focus) {
      try { _lastFocused.focus(); } catch (_) {}
    }
  }

  function trapFocusHandler(e) {
    if (e.key !== 'Tab') return;
    var overlay = e.currentTarget;
    var focusable = Array.from(overlay.querySelectorAll(
      'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
    ));
    if (!focusable.length) return;
    var first = focusable[0];
    var last = focusable[focusable.length - 1];
    if (e.shiftKey) {
      if (document.activeElement === first) { e.preventDefault(); last.focus(); }
    } else {
      if (document.activeElement === last) { e.preventDefault(); first.focus(); }
    }
  }

  function closeTopModal() {
    if (modalStack.length) closeModal(modalStack[modalStack.length - 1]);
  }

  /* ─── Confirmation dialog ─────────────────────────────────── */

  function confirm(title, message, onConfirm) {
    var overlay = el('confirm-overlay');
    var titleEl = el('confirm-title');
    var msgEl = el('confirm-message');
    var confirmBtn = el('confirm-ok-btn');

    if (!overlay) return;
    titleEl.textContent = title;
    msgEl.textContent = message;

    // Remove old listener
    var newBtn = confirmBtn.cloneNode(true);
    confirmBtn.parentNode.replaceChild(newBtn, confirmBtn);

    newBtn.addEventListener('click', function () {
      closeModal('confirm-overlay');
      onConfirm();
    });

    openModal('confirm-overlay');
  }

  /* ─── Navigation ──────────────────────────────────────────── */

  function navigateTo(viewId) {
    currentView = viewId;

    // Update nav items
    document.querySelectorAll('.nav-item').forEach(function (btn) {
      var isActive = btn.getAttribute('data-view') === viewId;
      btn.classList.toggle('active', isActive);
      btn.setAttribute('aria-current', isActive ? 'page' : 'false');
    });

    // Show/hide views
    document.querySelectorAll('.view').forEach(function (v) {
      var active = v.id === 'view-' + viewId;
      v.classList.toggle('active', active);
      if (active) v.removeAttribute('hidden');
      else v.setAttribute('hidden', '');
    });

    // Render the active view
    renderView(viewId);

    // Close sidebar on mobile
    closeSidebar();
  }

  function renderView(viewId) {
    if (viewId === 'dashboard') renderDashboard();
    else if (viewId === 'transactions') renderTransactions();
    else if (viewId === 'accounts') renderAccounts();
    else if (viewId === 'reports') renderReports();
    else if (viewId === 'settings') renderSettings();
  }

  /* ─── Mobile sidebar ──────────────────────────────────────── */

  function openSidebar() {
    var sidebar = el('sidebar');
    var overlay = el('sidebar-overlay');
    if (sidebar) sidebar.classList.add('open');
    if (overlay) overlay.classList.add('visible');
  }

  function closeSidebar() {
    var sidebar = el('sidebar');
    var overlay = el('sidebar-overlay');
    if (sidebar) sidebar.classList.remove('open');
    if (overlay) overlay.classList.remove('visible');
  }

  /* ─── Month navigation ────────────────────────────────────── */

  function renderMonthSelector() {
    var m = getActiveMonth();
    var lbl = el('month-label');
    if (lbl) lbl.textContent = monthLabel(m);
  }

  function navPrevMonth() {
    state.currentMonth = prevMonth(getActiveMonth());
    Storage.save(state);
    renderMonthSelector();
    renderView(currentView);
  }

  function navNextMonth() {
    state.currentMonth = nextMonth(getActiveMonth());
    Storage.save(state);
    renderMonthSelector();
    renderView(currentView);
  }

  function navToday() {
    state.currentMonth = null;
    Storage.save(state);
    renderMonthSelector();
    renderView(currentView);
  }

  /* ─────────────────────────────────────────────────────────────
     DASHBOARD VIEW
     ───────────────────────────────────────────────────────────── */

  function renderDashboard() {
    var yyyymm = getActiveMonth();
    var income = getMonthIncome(yyyymm);
    var totalBudgeted = getTotalBudgeted();
    var tbb = getToBeBudgeted(yyyymm);
    var currency = state.settings.currency;

    // Total spent this month
    var totalSpent = getTxForMonth(yyyymm).reduce(function(s, t) {
      return s + (t.type === 'expense' ? t.amount : 0);
    }, 0);

    // Hero card
    var heroCard = el('hero-card');
    var heroAmount = el('hero-amount');
    var heroMeta = el('hero-meta');

    if (heroCard) {
      heroCard.className = 'glass-card hero-card';
      if (tbb < -0.005) heroCard.classList.add('over');
      else if (Math.abs(tbb) < 0.01) heroCard.classList.add('zero');
      else heroCard.classList.add('under');
    }

    if (heroAmount) {
      heroAmount.className = 'hero-amount';
      heroAmount.textContent = fmt(tbb, currency);
      if (tbb < -0.005) heroAmount.classList.add('negative');
      else if (Math.abs(tbb) < 0.01) heroAmount.classList.add('zero-val');
      else heroAmount.classList.add('positive');
    }

    if (heroMeta) {
      if (Math.abs(tbb) < 0.01) {
        heroMeta.textContent = 'Perfectly balanced. Every dollar has a job.';
      } else if (tbb < 0) {
        heroMeta.textContent = 'Over-allocated by ' + fmt(Math.abs(tbb), currency) + '. Reduce some envelopes.';
      } else {
        heroMeta.textContent = fmt(tbb, currency) + ' still needs a job. Assign it to an envelope.';
      }
    }

    // Hero stats
    var statIncome = el('stat-income');
    var statBudgeted = el('stat-budgeted');
    var statSpent = el('stat-spent');
    if (statIncome) statIncome.textContent = fmt(income, currency);
    if (statBudgeted) statBudgeted.textContent = fmt(totalBudgeted, currency);
    if (statSpent) statSpent.textContent = fmt(totalSpent, currency);

    // ARIA live update
    var liveRegion = el('tbb-live');
    if (liveRegion) {
      liveRegion.textContent = 'To be budgeted: ' + fmt(tbb, currency);
    }

    // Grouped envelopes
    renderEnvelopeGroups(yyyymm);
  }

  function renderEnvelopeGroups(yyyymm) {
    var container = el('envelope-groups');
    if (!container) return;

    if (state.envelopes.length === 0) {
      container.innerHTML = '<div class="empty-state">'
        + '<div class="empty-icon">📋</div>'
        + '<div class="empty-title">No envelopes yet</div>'
        + '<div class="empty-desc">Create your first budget envelope to start giving your money a job.</div>'
        + '<button class="btn btn-primary" id="add-envelope-cta">Add Envelope</button>'
        + '</div>';
      var ctaBtn = el('add-envelope-cta');
      if (ctaBtn) ctaBtn.addEventListener('click', function() { openEnvelopeModal(); });
      return;
    }

    var groups = getGroupedEnvelopes();
    var html = '';

    Object.keys(groups).forEach(function(groupName) {
      var envs = groups[groupName];
      var groupBudgeted = envs.reduce(function(s, e) { return s + e.budgetedAmount; }, 0);
      var groupSpent = envs.reduce(function(s, e) {
        var stats = getEnvelopeStats(e.id, yyyymm);
        return s + (stats ? stats.spent : 0);
      }, 0);

      html += '<div class="group-section">';
      html += '<div class="group-header">';
      html += '<span class="group-title">' + escHtml(groupName) + '</span>';
      html += '<span class="group-totals text-mono">' + fmt(groupSpent) + ' / ' + fmt(groupBudgeted) + '</span>';
      html += '</div>';
      html += '<div class="glass-card envelope-list">';

      envs.forEach(function(env) {
        var stats = getEnvelopeStats(env.id, yyyymm);
        if (!stats) return;

        var pctClamped = Math.max(0, Math.min(100, stats.pct));
        var fillClass = stats.overspent ? 'overspent' : (stats.pct >= 90 ? 'warning' : '');
        var remClass = stats.overspent ? 'overspent' : (stats.remaining < 0 ? 'overspent' : 'remaining');

        html += '<div class="envelope-row" data-id="' + escHtml(env.id) + '">';
        html += '<div class="envelope-icon" aria-hidden="true">' + escHtml(env.icon) + '</div>';
        html += '<div>';
        html += '<div class="envelope-name">' + escHtml(env.name) + '</div>';
        html += '<div class="envelope-name-sub">';
        if (env.rollover) html += '<span class="rollover-tag">ROLLOVER</span> ';
        if (stats.rollover > 0) html += '<span class="text-tertiary text-mono" style="font-size:0.7rem">+' + fmt(stats.rollover) + ' carried</span>';
        html += '</div>';
        html += '</div>';

        html += '<div class="envelope-progress-wrap">';
        html += '<div class="progress-bar-track" role="progressbar" aria-valuenow="' + Math.round(pctClamped)
          + '" aria-valuemin="0" aria-valuemax="100" aria-label="' + escHtml(env.name) + ' ' + Math.round(pctClamped) + '% used">';
        html += '<div class="progress-bar-fill ' + fillClass + '" style="width:' + pctClamped + '%"></div>';
        html += '</div>';
        html += '<div class="progress-pct">' + Math.round(pctClamped) + '% of ' + fmt(stats.available) + '</div>';
        html += '</div>';

        html += '<div class="envelope-amount spent text-mono">' + fmt(stats.spent) + ' spent</div>';
        html += '<div class="envelope-amount ' + remClass + ' text-mono">';
        if (stats.overspent) {
          html += '<span class="overspent-tag">OVER</span> ' + fmt(Math.abs(stats.remaining));
        } else {
          html += fmt(stats.remaining) + ' left';
        }
        html += '</div>';

        html += '<div style="display:flex;gap:4px;">';
        html += '<button class="btn btn-icon btn-sm" data-action="edit-envelope" data-id="' + escHtml(env.id)
          + '" aria-label="Edit ' + escHtml(env.name) + '" title="Edit envelope">✏️</button>';
        html += '<button class="btn btn-icon btn-sm" data-action="delete-envelope" data-id="' + escHtml(env.id)
          + '" aria-label="Delete ' + escHtml(env.name) + '" title="Delete envelope">🗑️</button>';
        html += '</div>';
        html += '</div>'; // envelope-row
      });

      html += '</div>'; // glass-card
      html += '</div>'; // group-section
    });

    container.innerHTML = html;

    // Wire action buttons
    container.querySelectorAll('[data-action="edit-envelope"]').forEach(function(btn) {
      btn.addEventListener('click', function() { openEnvelopeModal(btn.getAttribute('data-id')); });
    });
    container.querySelectorAll('[data-action="delete-envelope"]').forEach(function(btn) {
      btn.addEventListener('click', function() { deleteEnvelope(btn.getAttribute('data-id')); });
    });
  }

  /* ─────────────────────────────────────────────────────────────
     TRANSACTIONS VIEW
     ───────────────────────────────────────────────────────────── */

  function renderTransactions() {
    var yyyymm = getActiveMonth();
    var currency = state.settings.currency;

    // Populate filter selects
    var filterAccount = el('filter-account');
    var filterEnvelope = el('filter-envelope');
    if (filterAccount) {
      var opts = '<option value="">All Accounts</option>';
      state.accounts.forEach(function(a) {
        opts += '<option value="' + escHtml(a.id) + '"' + (txFilterAccount === a.id ? ' selected' : '') + '>'
          + escHtml(a.name) + '</option>';
      });
      filterAccount.innerHTML = opts;
    }
    if (filterEnvelope) {
      var eOpts = '<option value="">All Envelopes</option>';
      state.envelopes.forEach(function(e) {
        eOpts += '<option value="' + escHtml(e.id) + '"' + (txFilterEnvelope === e.id ? ' selected' : '') + '>'
          + escHtml(e.icon + ' ' + e.name) + '</option>';
      });
      filterEnvelope.innerHTML = eOpts;
    }

    // Filter transactions
    var txs = state.transactions.filter(function(t) {
      if (t.date && t.date.slice(0, 7) !== yyyymm) return false;
      if (txFilterAccount && t.accountId !== txFilterAccount) return false;
      if (txFilterEnvelope && t.envelopeId !== txFilterEnvelope) return false;
      if (txFilterType && t.type !== txFilterType) return false;
      return true;
    });

    // Sort
    txs.sort(function(a, b) {
      var av, bv;
      if (txSortField === 'date') { av = a.date; bv = b.date; }
      else if (txSortField === 'amount') { av = a.amount; bv = b.amount; }
      else if (txSortField === 'payee') { av = (a.payee || '').toLowerCase(); bv = (b.payee || '').toLowerCase(); }
      else if (txSortField === 'type') { av = a.type; bv = b.type; }
      else { av = a.date; bv = b.date; }

      if (av < bv) return txSortDir === 'asc' ? -1 : 1;
      if (av > bv) return txSortDir === 'asc' ? 1 : -1;
      return 0;
    });

    var accountMap = {};
    state.accounts.forEach(function(a) { accountMap[a.id] = a.name; });
    var envMap = {};
    state.envelopes.forEach(function(e) { envMap[e.id] = e.icon + ' ' + e.name; });

    var tbody = el('tx-tbody');
    if (!tbody) return;

    if (txs.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7"><div class="empty-state">'
        + '<div class="empty-icon">💸</div>'
        + '<div class="empty-title">No transactions</div>'
        + '<div class="empty-desc">No transactions found for this period. Add one to get started.</div>'
        + '</div></td></tr>';
      return;
    }

    var rows = '';
    txs.forEach(function(t) {
      var accName = t.accountId ? (accountMap[t.accountId] || 'Unknown') : '—';
      var envName = t.envelopeId ? (envMap[t.envelopeId] || 'Unknown') : '—';
      var amtClass = t.type === 'income' ? 'income' : (t.type === 'expense' ? 'expense' : 'transfer');

      rows += '<tr>';
      rows += '<td class="tx-date">' + escHtml(t.date) + '</td>';
      rows += '<td>';
      rows += '<div class="tx-payee">' + escHtml(t.payee || '(no payee)') + '</div>';
      if (t.notes) rows += '<div class="tx-meta">' + escHtml(t.notes) + '</div>';
      rows += '</td>';
      rows += '<td><span class="tx-type-badge ' + t.type + '">' + t.type + '</span></td>';
      rows += '<td class="tx-meta">' + escHtml(accName) + '</td>';
      rows += '<td class="tx-meta">' + escHtml(envName) + '</td>';
      rows += '<td class="tx-amount ' + amtClass + '">';
      if (t.type === 'income') rows += '+';
      else if (t.type === 'expense') rows += '−';
      rows += fmt(t.amount, currency);
      rows += '</td>';
      rows += '<td><div class="tx-actions">';
      rows += '<button class="btn btn-icon btn-sm" data-action="edit-tx" data-id="' + escHtml(t.id)
        + '" aria-label="Edit transaction" title="Edit">✏️</button>';
      rows += '<button class="btn btn-icon btn-sm" data-action="delete-tx" data-id="' + escHtml(t.id)
        + '" aria-label="Delete transaction" title="Delete">🗑️</button>';
      rows += '</div></td>';
      rows += '</tr>';
    });

    tbody.innerHTML = rows;

    tbody.querySelectorAll('[data-action="edit-tx"]').forEach(function(btn) {
      btn.addEventListener('click', function() { openTxModal(btn.getAttribute('data-id')); });
    });
    tbody.querySelectorAll('[data-action="delete-tx"]').forEach(function(btn) {
      btn.addEventListener('click', function() { deleteTransaction(btn.getAttribute('data-id')); });
    });

    // Update sort indicators
    document.querySelectorAll('.tx-table th[data-sort]').forEach(function(th) {
      var sorted = th.getAttribute('data-sort') === txSortField;
      th.classList.toggle('sorted', sorted);
      var ind = th.querySelector('.sort-indicator');
      if (ind) ind.textContent = sorted ? (txSortDir === 'asc' ? '↑' : '↓') : '';
    });
  }

  /* ─────────────────────────────────────────────────────────────
     ACCOUNTS VIEW
     ───────────────────────────────────────────────────────────── */

  function renderAccounts() {
    var grid = el('accounts-grid');
    if (!grid) return;

    if (state.accounts.length === 0) {
      grid.innerHTML = '<div class="empty-state">'
        + '<div class="empty-icon">🏦</div>'
        + '<div class="empty-title">No accounts yet</div>'
        + '<div class="empty-desc">Add your checking, savings, or cash accounts to start tracking balances.</div>'
        + '<button class="btn btn-primary" id="add-account-cta">Add Account</button>'
        + '</div>';
      var cta = el('add-account-cta');
      if (cta) cta.addEventListener('click', function() { openAccountModal(); });
      return;
    }

    var currency = state.settings.currency;
    var typeIcons = { checking: '🏦', savings: '💰', cash: '💵' };

    var html = '';
    state.accounts.forEach(function(a) {
      var balance = getAccountBalance(a.id);
      var balClass = balance >= 0 ? 'positive' : 'negative';

      html += '<div class="glass-card account-card">';
      html += '<div class="flex-between">';
      html += '<div class="account-type-icon" aria-hidden="true">' + (typeIcons[a.type] || '🏦') + '</div>';
      html += '<div style="display:flex;gap:4px;">';
      html += '<button class="btn btn-icon btn-sm" data-action="edit-account" data-id="' + escHtml(a.id)
        + '" aria-label="Edit ' + escHtml(a.name) + '">✏️</button>';
      html += '<button class="btn btn-icon btn-sm" data-action="delete-account" data-id="' + escHtml(a.id)
        + '" aria-label="Delete ' + escHtml(a.name) + '">🗑️</button>';
      html += '</div>';
      html += '</div>';
      html += '<div class="account-name">' + escHtml(a.name) + '</div>';
      html += '<div class="account-type-label">' + escHtml(a.type) + '</div>';
      html += '<div class="account-balance ' + balClass + ' text-mono">' + fmt(balance, currency) + '</div>';
      html += '<div class="text-tertiary" style="font-size:0.75rem;font-family:var(--font-mono)">Starting: ' + fmt(a.startingBalance, currency) + '</div>';
      html += '</div>';
    });

    grid.innerHTML = html;

    grid.querySelectorAll('[data-action="edit-account"]').forEach(function(btn) {
      btn.addEventListener('click', function() { openAccountModal(btn.getAttribute('data-id')); });
    });
    grid.querySelectorAll('[data-action="delete-account"]').forEach(function(btn) {
      btn.addEventListener('click', function() { deleteAccount(btn.getAttribute('data-id')); });
    });
  }

  /* ─────────────────────────────────────────────────────────────
     REPORTS VIEW
     ───────────────────────────────────────────────────────────── */

  function renderReports() {
    var yyyymm = getActiveMonth();
    var currency = state.settings.currency;

    // Spending by group
    var spendingByGroup = getSpendingByGroup(yyyymm);
    var groupNames = Object.keys(spendingByGroup);
    var totalSpent = groupNames.reduce(function(s, g) { return s + spendingByGroup[g]; }, 0);

    // Donut segments
    var segments = groupNames.map(function(g, i) {
      return {
        label: g,
        value: spendingByGroup[g],
        color: PALETTE[i % PALETTE.length],
      };
    });

    // Draw donut
    var canvas = el('donut-canvas');
    if (canvas) {
      Charts.drawDonut(
        canvas,
        segments,
        fmt(totalSpent, currency),
        'spent'
      );
    }

    // Legend
    var legend = el('donut-legend');
    if (legend) {
      if (segments.length === 0) {
        legend.innerHTML = '<div class="text-tertiary" style="font-size:0.8rem">No expenses this month.</div>';
      } else {
        legend.innerHTML = segments.map(function(s) {
          var pct = totalSpent > 0 ? Math.round((s.value / totalSpent) * 100) : 0;
          return '<div class="legend-item">'
            + '<div class="legend-dot" style="background:' + escHtml(s.color) + '"></div>'
            + '<span class="legend-label">' + escHtml(s.label) + '</span>'
            + '<span class="legend-value text-mono">' + pct + '%</span>'
            + '</div>';
        }).join('');
      }
    }

    // Bar chart — spending by group
    var barWrap = el('bar-chart-wrap');
    if (barWrap) {
      var bars = groupNames.map(function(g, i) {
        return { label: g, value: spendingByGroup[g], color: PALETTE[i % PALETTE.length] };
      });
      bars.sort(function(a, b) { return b.value - a.value; });
      var svgWidth = Math.min(barWrap.clientWidth || 480, 600);
      barWrap.innerHTML = Charts.buildGroupBarSVG(bars, currency, svgWidth);
    }

    // Top envelopes
    var topWrap = el('top-envelopes-wrap');
    if (topWrap) {
      var topEnvs = getTopEnvelopes(yyyymm, 6);
      var svgW = Math.min(topWrap.clientWidth || 480, 600);
      topWrap.innerHTML = Charts.buildTopEnvelopesSVG(topEnvs, currency, svgW);
    }

    // Month summary
    var income = getMonthIncome(yyyymm);
    var summaryEl = el('report-summary');
    if (summaryEl) {
      var tbb = getToBeBudgeted(yyyymm);
      summaryEl.innerHTML = '<div class="flex-gap" style="flex-wrap:wrap;gap:20px;">'
        + '<div><div class="hero-stat-label">Income</div><div class="hero-stat-value text-mono">' + fmt(income, currency) + '</div></div>'
        + '<div><div class="hero-stat-label">Total Spent</div><div class="hero-stat-value text-mono text-red">' + fmt(totalSpent, currency) + '</div></div>'
        + '<div><div class="hero-stat-label">Net</div><div class="hero-stat-value text-mono ' + (income - totalSpent >= 0 ? 'text-green' : 'text-red') + '">'
        + fmtSigned(income - totalSpent, currency) + '</div></div>'
        + '<div><div class="hero-stat-label">To Be Budgeted</div><div class="hero-stat-value text-mono ' + (tbb >= 0 ? 'text-green' : 'text-red') + '">'
        + fmtSigned(tbb, currency) + '</div></div>'
        + '</div>';
    }
  }

  /* ─────────────────────────────────────────────────────────────
     SETTINGS VIEW
     ───────────────────────────────────────────────────────────── */

  function renderSettings() {
    var s = state.settings;

    var currencyInput = el('setting-currency');
    if (currencyInput) currencyInput.value = s.currency;

    var fdomSelect = el('setting-fdom');
    if (fdomSelect) fdomSelect.value = String(s.firstDayOfMonth);

    var themeSelect = el('setting-theme');
    if (themeSelect) themeSelect.value = s.theme;

    var motionToggle = el('setting-reduced-motion');
    if (motionToggle) motionToggle.checked = s.reducedMotion;
  }

  /* ─────────────────────────────────────────────────────────────
     ACCOUNT MODAL (create / edit)
     ───────────────────────────────────────────────────────────── */

  function openAccountModal(accountId) {
    var account = accountId ? state.accounts.find(function(a) { return a.id === accountId; }) : null;

    el('account-modal-title').textContent = account ? 'Edit Account' : 'Add Account';
    el('account-id').value = account ? account.id : '';
    el('account-name').value = account ? account.name : '';
    el('account-type').value = account ? account.type : 'checking';
    el('account-balance').value = account ? account.startingBalance.toFixed(2) : '';
    clearFormErrors('account-form');

    openModal('account-modal');
  }

  function saveAccount() {
    clearFormErrors('account-form');
    var id = el('account-id').value;
    var name = el('account-name').value.trim();
    var type = el('account-type').value;
    var balRaw = el('account-balance').value.trim();
    var balance = parseFloat(balRaw);

    var valid = true;

    if (!name) {
      showFieldError('account-name', 'Account name is required.');
      valid = false;
    } else if (name.length > 60) {
      showFieldError('account-name', 'Name must be 60 characters or fewer.');
      valid = false;
    } else {
      // Duplicate check
      var dup = state.accounts.find(function(a) {
        return a.name.toLowerCase() === name.toLowerCase() && a.id !== id;
      });
      if (dup) {
        showFieldError('account-name', 'An account with this name already exists.');
        valid = false;
      }
    }

    if (balRaw === '' || isNaN(balance) || !isFinite(balance)) {
      showFieldError('account-balance', 'Enter a valid starting balance (e.g. 0.00).');
      valid = false;
    }

    if (!valid) return;

    if (id) {
      // Update
      var idx = state.accounts.findIndex(function(a) { return a.id === id; });
      if (idx >= 0) {
        state.accounts[idx].name = name;
        state.accounts[idx].type = type;
        state.accounts[idx].startingBalance = balance;
      }
      toast('Account updated.', 'success');
    } else {
      // Create
      state.accounts.push({
        id: Storage.generateId(),
        name: name,
        type: type,
        startingBalance: balance,
        createdAt: new Date().toISOString(),
      });
      toast('Account added.', 'success');
    }

    Storage.save(state);
    closeModal('account-modal');
    renderView(currentView);
  }

  function deleteAccount(accountId) {
    var account = state.accounts.find(function(a) { return a.id === accountId; });
    if (!account) return;

    var txCount = state.transactions.filter(function(t) {
      return t.accountId === accountId || t.toAccountId === accountId;
    }).length;

    confirm(
      'Delete Account',
      'Delete "' + account.name + '"?' + (txCount > 0 ? ' This account has ' + txCount + ' transaction(s). They will remain but will lose the account link.' : ''),
      function () {
        state.accounts = state.accounts.filter(function(a) { return a.id !== accountId; });
        Storage.save(state);
        toast('Account deleted.', 'info');
        renderView(currentView);
      }
    );
  }

  /* ─────────────────────────────────────────────────────────────
     ENVELOPE MODAL (create / edit)
     ───────────────────────────────────────────────────────────── */

  function openEnvelopeModal(envelopeId) {
    var env = envelopeId ? state.envelopes.find(function(e) { return e.id === envelopeId; }) : null;

    el('envelope-modal-title').textContent = env ? 'Edit Envelope' : 'Add Envelope';
    el('envelope-id').value = env ? env.id : '';
    el('envelope-name').value = env ? env.name : '';
    el('envelope-icon').value = env ? env.icon : '📋';
    el('envelope-amount').value = env ? env.budgetedAmount.toFixed(2) : '';
    el('envelope-group').value = env ? env.group : 'General';
    el('envelope-rollover').checked = env ? env.rollover : false;
    clearFormErrors('envelope-form');

    openModal('envelope-modal');
  }

  function saveEnvelope() {
    clearFormErrors('envelope-form');

    var id = el('envelope-id').value;
    var name = el('envelope-name').value.trim();
    var icon = el('envelope-icon').value.trim() || '📋';
    var amtRaw = el('envelope-amount').value.trim();
    var amount = parseFloat(amtRaw);
    var group = el('envelope-group').value.trim() || 'General';
    var rollover = el('envelope-rollover').checked;

    var valid = true;

    if (!name) {
      showFieldError('envelope-name', 'Envelope name is required.');
      valid = false;
    } else if (name.length > 60) {
      showFieldError('envelope-name', 'Name must be 60 characters or fewer.');
      valid = false;
    } else {
      var dup = state.envelopes.find(function(e) {
        return e.name.toLowerCase() === name.toLowerCase() && e.id !== id;
      });
      if (dup) {
        showFieldError('envelope-name', 'An envelope with this name already exists.');
        valid = false;
      }
    }

    if (amtRaw === '' || isNaN(amount) || !isFinite(amount) || amount < 0) {
      showFieldError('envelope-amount', 'Enter a valid positive amount (e.g. 200.00).');
      valid = false;
    }

    if (!valid) return;

    if (id) {
      var idx = state.envelopes.findIndex(function(e) { return e.id === id; });
      if (idx >= 0) {
        state.envelopes[idx].name = name;
        state.envelopes[idx].icon = icon;
        state.envelopes[idx].budgetedAmount = amount;
        state.envelopes[idx].group = group;
        state.envelopes[idx].rollover = rollover;
      }
      toast('Envelope updated.', 'success');
    } else {
      state.envelopes.push({
        id: Storage.generateId(),
        name: name,
        icon: icon,
        budgetedAmount: amount,
        group: group,
        rollover: rollover,
        createdAt: new Date().toISOString(),
      });
      toast('Envelope added.', 'success');
    }

    Storage.save(state);
    closeModal('envelope-modal');
    renderView(currentView);
  }

  function deleteEnvelope(envId) {
    var env = state.envelopes.find(function(e) { return e.id === envId; });
    if (!env) return;

    var txCount = state.transactions.filter(function(t) { return t.envelopeId === envId; }).length;

    confirm(
      'Delete Envelope',
      'Delete "' + env.name + '"?' + (txCount > 0 ? ' ' + txCount + ' transaction(s) reference this envelope and will become uncategorized.' : ''),
      function () {
        state.envelopes = state.envelopes.filter(function(e) { return e.id !== envId; });
        state.transactions.forEach(function(t) {
          if (t.envelopeId === envId) t.envelopeId = null;
        });
        Storage.save(state);
        toast('Envelope deleted.', 'info');
        renderView(currentView);
      }
    );
  }

  /* ─────────────────────────────────────────────────────────────
     TRANSACTION MODAL (create / edit)
     ───────────────────────────────────────────────────────────── */

  function populateTxModalSelects(tx) {
    // Account select
    var accSel = el('tx-account');
    var accHtml = '<option value="">Select account…</option>';
    state.accounts.forEach(function(a) {
      accHtml += '<option value="' + escHtml(a.id) + '"'
        + (tx && tx.accountId === a.id ? ' selected' : '') + '>'
        + escHtml(a.name) + '</option>';
    });
    accSel.innerHTML = accHtml;

    // To-account select (for transfers)
    var toAccSel = el('tx-to-account');
    var toAccHtml = '<option value="">Select account…</option>';
    state.accounts.forEach(function(a) {
      toAccHtml += '<option value="' + escHtml(a.id) + '"'
        + (tx && tx.toAccountId === a.id ? ' selected' : '') + '>'
        + escHtml(a.name) + '</option>';
    });
    toAccSel.innerHTML = toAccHtml;

    // Envelope select
    var envSel = el('tx-envelope');
    var envHtml = '<option value="">No envelope</option>';
    state.envelopes.forEach(function(e) {
      envHtml += '<option value="' + escHtml(e.id) + '"'
        + (tx && tx.envelopeId === e.id ? ' selected' : '') + '>'
        + escHtml(e.icon + ' ' + e.name) + '</option>';
    });
    envSel.innerHTML = envHtml;
  }

  function updateTxModalType() {
    var type = el('tx-type').value;
    var envelopeRow = el('tx-envelope-row');
    var toAccountRow = el('tx-to-account-row');

    if (envelopeRow) envelopeRow.style.display = type === 'expense' ? '' : 'none';
    if (toAccountRow) toAccountRow.style.display = type === 'transfer' ? '' : 'none';
  }

  function openTxModal(txId) {
    var tx = txId ? state.transactions.find(function(t) { return t.id === txId; }) : null;

    el('tx-modal-title').textContent = tx ? 'Edit Transaction' : 'Add Transaction';
    el('tx-id').value = tx ? tx.id : '';
    el('tx-date').value = tx ? tx.date : new Date().toISOString().slice(0, 10);
    el('tx-payee').value = tx ? tx.payee : '';
    el('tx-amount').value = tx ? tx.amount.toFixed(2) : '';
    el('tx-type').value = tx ? tx.type : 'expense';
    el('tx-notes').value = tx ? tx.notes : '';

    populateTxModalSelects(tx);
    updateTxModalType();
    clearFormErrors('tx-form');

    openModal('tx-modal');
  }

  function saveTransaction() {
    clearFormErrors('tx-form');

    var id = el('tx-id').value;
    var date = el('tx-date').value.trim();
    var payee = el('tx-payee').value.trim();
    var amtRaw = el('tx-amount').value.trim();
    var amount = parseFloat(amtRaw);
    var type = el('tx-type').value;
    var accountId = el('tx-account').value;
    var envelopeId = el('tx-envelope').value || null;
    var toAccountId = el('tx-to-account').value || null;
    var notes = el('tx-notes').value.trim();

    var valid = true;

    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      showFieldError('tx-date', 'Please enter a valid date.');
      valid = false;
    }

    if (!payee && type !== 'transfer') {
      showFieldError('tx-payee', 'Please enter a payee or description.');
      valid = false;
    }

    if (amtRaw === '' || isNaN(amount) || !isFinite(amount) || amount <= 0) {
      showFieldError('tx-amount', 'Enter a valid amount greater than zero.');
      valid = false;
    }

    if (!accountId) {
      showFieldError('tx-account', 'Please select an account.');
      valid = false;
    }

    if (type === 'transfer' && !toAccountId) {
      showFieldError('tx-to-account', 'Please select a destination account.');
      valid = false;
    }

    if (type === 'transfer' && toAccountId && toAccountId === accountId) {
      showFieldError('tx-to-account', 'Source and destination accounts must be different.');
      valid = false;
    }

    if (!valid) return;

    var txData = {
      date: date,
      payee: payee,
      amount: amount,
      type: type,
      accountId: accountId,
      envelopeId: type === 'expense' ? (envelopeId || null) : null,
      toAccountId: type === 'transfer' ? toAccountId : null,
      notes: notes,
    };

    if (id) {
      var idx = state.transactions.findIndex(function(t) { return t.id === id; });
      if (idx >= 0) {
        state.transactions[idx] = Object.assign({}, state.transactions[idx], txData);
      }
      toast('Transaction updated.', 'success');
    } else {
      state.transactions.push(Object.assign({
        id: Storage.generateId(),
        createdAt: new Date().toISOString(),
      }, txData));
      toast('Transaction added.', 'success');
    }

    Storage.save(state);
    closeModal('tx-modal');
    renderView(currentView);

    // Re-render dashboard if open (TBB needs update)
    if (currentView !== 'dashboard') {
      // update live region
      var liveRegion = el('tbb-live');
      if (liveRegion) {
        var yyyymm = getActiveMonth();
        var tbb = getToBeBudgeted(yyyymm);
        liveRegion.textContent = 'To be budgeted: ' + fmt(tbb);
      }
    }
  }

  function deleteTransaction(txId) {
    var tx = state.transactions.find(function(t) { return t.id === txId; });
    if (!tx) return;

    confirm(
      'Delete Transaction',
      'Delete this transaction from ' + tx.date + ' for ' + fmt(tx.amount) + '?',
      function () {
        state.transactions = state.transactions.filter(function(t) { return t.id !== txId; });
        Storage.save(state);
        toast('Transaction deleted.', 'info');
        renderView(currentView);
      }
    );
  }

  /* ─── Form validation helpers ─────────────────────────────── */

  function showFieldError(inputId, message) {
    var input = el(inputId);
    if (input) input.classList.add('error');
    var errEl = document.getElementById(inputId + '-error');
    if (errEl) {
      errEl.textContent = message;
      errEl.style.display = 'block';
    }
  }

  function clearFormErrors(formId) {
    var form = el(formId);
    if (!form) return;
    form.querySelectorAll('.error').forEach(function(el) { el.classList.remove('error'); });
    form.querySelectorAll('.form-error').forEach(function(el) {
      el.textContent = '';
      el.style.display = 'none';
    });
  }

  /* ─────────────────────────────────────────────────────────────
     SETTINGS ACTIONS
     ───────────────────────────────────────────────────────────── */

  function saveSettings() {
    var currencyRaw = el('setting-currency') ? el('setting-currency').value.trim() : '$';
    var fdom = el('setting-fdom') ? parseInt(el('setting-fdom').value) : 1;
    var theme = el('setting-theme') ? el('setting-theme').value : 'system';
    var reducedMotion = el('setting-reduced-motion') ? el('setting-reduced-motion').checked : false;

    if (!currencyRaw) {
      toast('Currency symbol cannot be empty.', 'error');
      return;
    }

    state.settings = {
      currency: currencyRaw,
      firstDayOfMonth: isFinite(fdom) ? Math.min(28, Math.max(1, fdom)) : 1,
      theme: theme,
      reducedMotion: reducedMotion,
    };

    Storage.save(state);
    applySettings();
    toast('Settings saved.', 'success');
    renderView(currentView);
  }

  function handleResetToSample() {
    confirm(
      'Reset to Sample Data',
      'This will replace all your current data with the built-in example budget. This cannot be undone.',
      function () {
        showLoading('Restoring sample data…');
        setTimeout(function () {
          state = Seed.buildSeedData();
          Storage.save(state);
          hideLoading();
          applySettings();
          renderMonthSelector();
          renderView(currentView);
          toast('Sample data restored.', 'success');
        }, 500);
      }
    );
  }

  function handleClearAll() {
    confirm(
      'Clear All Data',
      'This will permanently delete all accounts, envelopes, and transactions. You cannot undo this.',
      function () {
        Storage.clear();
        state = Storage.load();
        applySettings();
        renderMonthSelector();
        renderView(currentView);
        toast('All data cleared.', 'info');
      }
    );
  }

  function handleExportJSON() {
    showLoading('Exporting…');
    setTimeout(function () {
      try {
        Storage.exportJSON(state);
        hideLoading();
        toast('JSON exported.', 'success');
      } catch (e) {
        hideLoading();
        toast('Export failed. Please try again.', 'error');
      }
    }, 200);
  }

  function handleExportCSV() {
    showLoading('Exporting…');
    setTimeout(function () {
      try {
        Storage.exportCSV(state);
        hideLoading();
        toast('CSV exported.', 'success');
      } catch (e) {
        hideLoading();
        toast('Export failed. Please try again.', 'error');
      }
    }, 200);
  }

  function handleImportJSON() {
    var fileInput = el('import-file');
    if (!fileInput) return;
    fileInput.value = '';
    fileInput.click();
  }

  function processImportFile(file) {
    if (!file) return;
    if (!file.name.endsWith('.json')) {
      toast('Please select a .json file exported by Envelope.', 'error');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      toast('File is too large. Max 5 MB.', 'error');
      return;
    }

    showLoading('Importing…');

    var reader = new FileReader();
    reader.onload = function(e) {
      var result = Storage.importJSON(e.target.result);
      hideLoading();
      if (result.ok) {
        state = result.state;
        Storage.save(state);
        applySettings();
        renderMonthSelector();
        renderView(currentView);
        toast('Import successful. ' + state.transactions.length + ' transactions loaded.', 'success');
      } else {
        toast(result.error, 'error');
      }
    };
    reader.onerror = function() {
      hideLoading();
      toast('Could not read the file. Please try again.', 'error');
    };
    reader.readAsText(file);
  }

  /* ─────────────────────────────────────────────────────────────
     INIT & EVENT WIRING
     ───────────────────────────────────────────────────────────── */

  function init() {
    // Load state
    state = Storage.load();

    // If first load (no accounts), seed sample data
    if (state.accounts.length === 0 && state.envelopes.length === 0 && state.transactions.length === 0) {
      state = Seed.buildSeedData();
      Storage.save(state);
    }

    applySettings();

    // System theme change
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function () {
      if (state.settings.theme === 'system') applyTheme('system');
    });

    renderMonthSelector();

    // ── Navigation buttons
    document.querySelectorAll('.nav-item').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var view = btn.getAttribute('data-view');
        if (view) navigateTo(view);
      });
    });

    // ── Month navigation
    var prevBtn = el('month-prev');
    var nextBtn = el('month-next');
    var todayLabel = el('month-label');

    if (prevBtn) prevBtn.addEventListener('click', navPrevMonth);
    if (nextBtn) nextBtn.addEventListener('click', navNextMonth);
    if (todayLabel) todayLabel.addEventListener('click', navToday);

    // ── Mobile sidebar
    var hamburger = el('hamburger');
    var sidebarOverlay = el('sidebar-overlay');
    if (hamburger) hamburger.addEventListener('click', openSidebar);
    if (sidebarOverlay) sidebarOverlay.addEventListener('click', closeSidebar);

    // ── Global Esc key
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') closeTopModal();
    });

    // ── Add buttons (header)
    var addEnvelopeBtn = el('add-envelope-btn');
    if (addEnvelopeBtn) addEnvelopeBtn.addEventListener('click', function () { openEnvelopeModal(); });

    var addTxBtn = el('add-tx-btn');
    if (addTxBtn) addTxBtn.addEventListener('click', function () { openTxModal(); });

    // Dashboard "add transaction" shortcut button
    var addTxDashBtn = el('add-tx-btn-dash');
    if (addTxDashBtn) addTxDashBtn.addEventListener('click', function () { openTxModal(); });

    var addAccountBtn = el('add-account-btn');
    if (addAccountBtn) addAccountBtn.addEventListener('click', function () { openAccountModal(); });

    // ── Account modal
    var accountSaveBtn = el('account-save-btn');
    if (accountSaveBtn) accountSaveBtn.addEventListener('click', saveAccount);

    var accountCancelBtn = el('account-cancel-btn');
    if (accountCancelBtn) accountCancelBtn.addEventListener('click', function () { closeModal('account-modal'); });

    var accountCancelBtnFooter = el('account-cancel-btn-footer');
    if (accountCancelBtnFooter) accountCancelBtnFooter.addEventListener('click', function () { closeModal('account-modal'); });

    var accountModalOverlay = el('account-modal');
    if (accountModalOverlay) {
      accountModalOverlay.addEventListener('click', function (e) {
        if (e.target === accountModalOverlay) closeModal('account-modal');
      });
    }

    // ── Envelope modal
    var envSaveBtn = el('envelope-save-btn');
    if (envSaveBtn) envSaveBtn.addEventListener('click', saveEnvelope);

    var envCancelBtn = el('envelope-cancel-btn');
    if (envCancelBtn) envCancelBtn.addEventListener('click', function () { closeModal('envelope-modal'); });

    var envCancelBtnFooter = el('envelope-cancel-btn-footer');
    if (envCancelBtnFooter) envCancelBtnFooter.addEventListener('click', function () { closeModal('envelope-modal'); });

    var envModalOverlay = el('envelope-modal');
    if (envModalOverlay) {
      envModalOverlay.addEventListener('click', function (e) {
        if (e.target === envModalOverlay) closeModal('envelope-modal');
      });
    }

    // ── Transaction modal
    var txSaveBtn = el('tx-save-btn');
    if (txSaveBtn) txSaveBtn.addEventListener('click', saveTransaction);

    var txCancelBtn = el('tx-cancel-btn');
    if (txCancelBtn) txCancelBtn.addEventListener('click', function () { closeModal('tx-modal'); });

    var txCancelBtnFooter = el('tx-cancel-btn-footer');
    if (txCancelBtnFooter) txCancelBtnFooter.addEventListener('click', function () { closeModal('tx-modal'); });

    var txModalOverlay = el('tx-modal');
    if (txModalOverlay) {
      txModalOverlay.addEventListener('click', function (e) {
        if (e.target === txModalOverlay) closeModal('tx-modal');
      });
    }

    var txTypeSelect = el('tx-type');
    if (txTypeSelect) txTypeSelect.addEventListener('change', updateTxModalType);

    // ── Confirm modal cancel
    var confirmCancelBtn = el('confirm-cancel-btn');
    if (confirmCancelBtn) {
      confirmCancelBtn.addEventListener('click', function () { closeModal('confirm-overlay'); });
    }
    var confirmCancelBtnFooter = el('confirm-cancel-btn-footer');
    if (confirmCancelBtnFooter) {
      confirmCancelBtnFooter.addEventListener('click', function () { closeModal('confirm-overlay'); });
    }
    var confirmOverlay = el('confirm-overlay');
    if (confirmOverlay) {
      confirmOverlay.addEventListener('click', function (e) {
        if (e.target === confirmOverlay) closeModal('confirm-overlay');
      });
    }

    // ── Transaction filters
    var filterAcctEl = el('filter-account');
    if (filterAcctEl) filterAcctEl.addEventListener('change', function () {
      txFilterAccount = this.value;
      renderTransactions();
    });

    var filterEnvEl = el('filter-envelope');
    if (filterEnvEl) filterEnvEl.addEventListener('change', function () {
      txFilterEnvelope = this.value;
      renderTransactions();
    });

    var filterTypeEl = el('filter-type');
    if (filterTypeEl) filterTypeEl.addEventListener('change', function () {
      txFilterType = this.value;
      renderTransactions();
    });

    // ── Transaction table sort
    document.querySelectorAll('.tx-table th[data-sort]').forEach(function (th) {
      th.addEventListener('click', function () {
        var field = th.getAttribute('data-sort');
        if (txSortField === field) {
          txSortDir = txSortDir === 'asc' ? 'desc' : 'asc';
        } else {
          txSortField = field;
          txSortDir = 'desc';
        }
        renderTransactions();
      });
    });

    // ── Settings save
    var settingsSaveBtn = el('settings-save-btn');
    if (settingsSaveBtn) settingsSaveBtn.addEventListener('click', saveSettings);

    var resetSampleBtn = el('reset-sample-btn');
    if (resetSampleBtn) resetSampleBtn.addEventListener('click', handleResetToSample);

    var clearAllBtn = el('clear-all-btn');
    if (clearAllBtn) clearAllBtn.addEventListener('click', handleClearAll);

    var exportJsonBtn = el('export-json-btn');
    if (exportJsonBtn) exportJsonBtn.addEventListener('click', handleExportJSON);

    var exportCsvBtn = el('export-csv-btn');
    if (exportCsvBtn) exportCsvBtn.addEventListener('click', handleExportCSV);

    var importBtn = el('import-json-btn');
    if (importBtn) importBtn.addEventListener('click', handleImportJSON);

    var importFile = el('import-file');
    if (importFile) {
      importFile.addEventListener('change', function () {
        processImportFile(this.files && this.files[0]);
      });
    }

    // ── Initial render
    navigateTo('dashboard');
  }

  // Public API
  return { init: init };
})();

// Start app
document.addEventListener('DOMContentLoaded', function () {
  App.init();
});
