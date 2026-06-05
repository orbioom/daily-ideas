/**
 * app.js — Renewal application controller.
 * Wires together Storage, Billing, Seed, Charts.
 * No external dependencies. Works via file:// with classic script tags.
 */

'use strict';

(function () {

  // ─── Application state ─────────────────────────────────────────────────────

  let STATE = Storage.load();

  // Calendar navigation state
  let calendarYear = new Date().getFullYear();
  let calendarMonth = new Date().getMonth();
  let calendarSelectedDay = null;

  // Subscription list filter/sort state
  let listFilter = { category: '', status: '', paymentMethod: '', search: '' };
  let listSort = { field: 'nextRenewal', dir: 'asc' };

  // Modal state: which subscription/category/PM is being edited
  let editingSubId = null;
  let editingCatId = null;
  let editingPMId = null;

  // ─── DOM references (resolved once on init) ───────────────────────────────

  const $ = id => document.getElementById(id);
  const $$ = sel => document.querySelectorAll(sel);

  // ─── Initialization ───────────────────────────────────────────────────────

  function init() {
    applyTheme(STATE.settings.theme);
    applyReducedMotion(STATE.settings.reducedMotion);
    bindNav();
    bindSidebar();
    bindDashboard();
    bindSubList();
    bindCalendar();
    bindSettings();
    bindExportImport();
    bindKeyboard();
    bindToastRegion();
    navigateTo(STATE.settings.lastView || 'dashboard');
  }

  // ─── Theme ────────────────────────────────────────────────────────────────

  function applyTheme(theme) {
    const root = document.documentElement;
    if (theme === 'dark') {
      root.setAttribute('data-theme', 'dark');
    } else if (theme === 'light') {
      root.setAttribute('data-theme', 'light');
    } else {
      // System
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      root.setAttribute('data-theme', prefersDark ? 'dark' : 'light');
    }
  }

  function applyReducedMotion(val) {
    document.documentElement.setAttribute('data-reduced-motion', val ? 'true' : 'false');
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  function navigateTo(viewId) {
    const valid = ['dashboard', 'subscriptions', 'calendar', 'settings'];
    const id = valid.includes(viewId) ? viewId : 'dashboard';

    $$('.view').forEach(v => v.classList.remove('active'));
    $$('.nav-item').forEach(n => n.classList.remove('active'));

    const viewEl = $(`view-${id}`);
    if (viewEl) viewEl.classList.add('active');
    const navEl = document.querySelector(`.nav-item[data-view="${id}"]`);
    if (navEl) navEl.classList.add('active');

    STATE = Storage.updateSettings(STATE, { lastView: id });

    // Render the active view
    switch (id) {
      case 'dashboard':     renderDashboard(); break;
      case 'subscriptions': renderSubList(); break;
      case 'calendar':      renderCalendar(); break;
      case 'settings':      renderSettings(); break;
    }

    // Close mobile sidebar
    closeSidebar();
  }

  function bindNav() {
    $$('.nav-item[data-view]').forEach(btn => {
      btn.addEventListener('click', () => navigateTo(btn.dataset.view));
    });
  }

  // ─── Sidebar (mobile) ─────────────────────────────────────────────────────

  function bindSidebar() {
    const hamburger = $('hamburger');
    const overlay = $('sidebar-overlay');
    const sidebar = $('sidebar');
    if (hamburger) hamburger.addEventListener('click', openSidebar);
    if (overlay) overlay.addEventListener('click', closeSidebar);
  }

  function openSidebar() {
    $('sidebar').classList.add('open');
    $('sidebar-overlay').classList.add('open');
    $('hamburger').setAttribute('aria-expanded', 'true');
  }

  function closeSidebar() {
    $('sidebar').classList.remove('open');
    $('sidebar-overlay').classList.remove('open');
    const h = $('hamburger');
    if (h) h.setAttribute('aria-expanded', 'false');
  }

  // ─── Dashboard ────────────────────────────────────────────────────────────

  function bindDashboard() {
    const addFirst = $('dash-add-first');
    if (addFirst) addFirst.addEventListener('click', () => openSubModal(null));

    const addBtn = $('dash-add-btn');
    if (addBtn) addBtn.addEventListener('click', () => openSubModal(null));
  }

  function renderDashboard() {
    const totals = Billing.computeTotals(STATE.subscriptions);
    const sym = STATE.settings.currencySymbol || '$';

    // Hero amounts
    const monthly = $('hero-monthly');
    const yearly = $('hero-yearly');
    const count = $('hero-count');
    if (monthly) monthly.textContent = Billing.formatAmount(totals.monthly, sym);
    if (yearly)  yearly.textContent  = Billing.formatAmount(totals.yearly, sym);
    if (count)   count.textContent   = totals.count;

    // Empty state
    const heroEmpty = $('dashboard-empty');
    const heroContent = $('dashboard-content');
    const hasAny = STATE.subscriptions.length > 0;
    if (heroEmpty)   heroEmpty.style.display   = hasAny ? 'none' : 'block';
    if (heroContent) heroContent.style.display = hasAny ? 'block' : 'none';

    if (!hasAny) return;

    // Upcoming (next 30 days)
    renderUpcoming();

    // Trials ending soon (14 days)
    renderTrials();

    // Chart
    renderDashboardChart(totals, sym);
  }

  function renderUpcoming() {
    const container = $('upcoming-list');
    if (!container) return;
    const sym = STATE.settings.currencySymbol || '$';
    const items = Billing.renewingSoon(STATE.subscriptions, 30);

    if (items.length === 0) {
      container.innerHTML = '<p class="empty-note">Nothing renewing in the next 30 days.</p>';
      return;
    }

    container.innerHTML = '';
    items.forEach(({ sub, next }) => {
      const days = Math.round((next - Billing.startOfDay(new Date())) / 86400000);
      const isToday = days === 0;
      const isUrgent = days <= 3 && !isToday;
      const isSoon = days <= 7 && !isUrgent && !isToday;

      const when = isToday ? 'Today' : days === 1 ? 'Tomorrow' : `in ${days}d`;
      const whenClass = isToday ? 'upcoming-item--today' : isUrgent ? 'upcoming-item--urgent' : isSoon ? 'upcoming-item--soon' : '';

      const li = document.createElement('li');
      li.className = `upcoming-item ${whenClass}`;
      li.innerHTML = `
        <span class="upcoming-glyph" aria-hidden="true">${sub.vendor && sub.vendor.length === 1 || isEmoji(sub.vendor) ? sub.vendor : categoryGlyph(sub.category)}</span>
        <div class="upcoming-info">
          <div class="upcoming-name">${esc(sub.name)}</div>
          <div class="upcoming-detail">${esc(sub.category)} · ${Billing.cycleLabel(sub.cycle, sub.customDays)}</div>
        </div>
        <span class="upcoming-when" aria-label="${when}, ${Billing.formatAmount(sub.amount, sym)}">${when} · ${Billing.formatAmount(sub.amount, sym)}</span>
      `;
      container.appendChild(li);
    });
  }

  function renderTrials() {
    const container = $('trials-list');
    if (!container) return;
    const trials = Billing.trialsEndingSoon(STATE.subscriptions, 14);

    container.innerHTML = '';
    if (trials.length === 0) {
      container.style.display = 'none';
      return;
    }
    container.style.display = 'block';

    trials.forEach(({ sub, trialDate }) => {
      const days = Math.round((trialDate - Billing.startOfDay(new Date())) / 86400000);
      const label = days === 0 ? 'Today' : days === 1 ? 'Tomorrow' : `in ${days} days`;

      const alert = document.createElement('div');
      alert.className = 'trial-alert';
      alert.setAttribute('role', 'alert');
      alert.innerHTML = `
        <span class="trial-alert-icon" aria-hidden="true">⏳</span>
        <div>
          <strong>${esc(sub.name)}</strong>
          <span> trial ends ${label} (${trialDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })})</span>
        </div>
      `;
      container.appendChild(alert);
    });
  }

  function renderDashboardChart(totals, sym) {
    const svg = $('donut-svg');
    const legendContainer = $('donut-legend');
    const barContainer = $('bar-chart');

    if (svg) {
      Charts.drawDonut(svg, totals.byCategory, STATE.categories, sym);
    }
    if (legendContainer) {
      legendContainer.innerHTML = '';
      if (Object.keys(totals.byCategory).length > 0) {
        legendContainer.appendChild(Charts.buildLegend(totals.byCategory, STATE.categories, sym));
      }
    }
    if (barContainer) {
      Charts.drawBars(barContainer, totals.byCategory, STATE.categories, sym);
    }
  }

  // ─── Subscription List ───────────────────────────────────────────────────

  function bindSubList() {
    const addBtn = $('sub-add-btn');
    if (addBtn) addBtn.addEventListener('click', () => openSubModal(null));

    const searchInput = $('sub-search');
    if (searchInput) {
      searchInput.addEventListener('input', () => {
        listFilter.search = searchInput.value.trim();
        renderSubList();
      });
    }

    const catFilter = $('filter-category');
    if (catFilter) {
      catFilter.addEventListener('change', () => {
        listFilter.category = catFilter.value;
        renderSubList();
      });
    }

    const statusFilter = $('filter-status');
    if (statusFilter) {
      statusFilter.addEventListener('change', () => {
        listFilter.status = statusFilter.value;
        renderSubList();
      });
    }

    const pmFilter = $('filter-payment');
    if (pmFilter) {
      pmFilter.addEventListener('change', () => {
        listFilter.paymentMethod = pmFilter.value;
        renderSubList();
      });
    }

    // Sort column headers bound in renderSubList
  }

  function renderSubList() {
    populateFilterSelects();
    const tbody = $('sub-tbody');
    const emptyState = $('sub-empty-state');
    if (!tbody) return;

    const sym = STATE.settings.currencySymbol || '$';
    const today = Billing.startOfDay(new Date());

    // Filter
    let subs = STATE.subscriptions.filter(s => {
      if (listFilter.category && s.category !== listFilter.category) return false;
      if (listFilter.status && s.status !== listFilter.status) return false;
      if (listFilter.paymentMethod && s.paymentMethod !== listFilter.paymentMethod) return false;
      if (listFilter.search) {
        const q = listFilter.search.toLowerCase();
        if (!s.name.toLowerCase().includes(q) && !s.vendor.toLowerCase().includes(q) && !s.notes.toLowerCase().includes(q)) return false;
      }
      return true;
    });

    // Sort
    subs = subs.sort((a, b) => {
      let valA, valB;
      switch (listSort.field) {
        case 'name':
          valA = a.name.toLowerCase();
          valB = b.name.toLowerCase();
          break;
        case 'amount':
          valA = Billing.toMonthly(a);
          valB = Billing.toMonthly(b);
          break;
        case 'nextRenewal': {
          const na = Billing.nextRenewal(a.anchorDate, a.cycle, a.customDays, today);
          const nb = Billing.nextRenewal(b.anchorDate, b.cycle, b.customDays, today);
          valA = na ? na.getTime() : Infinity;
          valB = nb ? nb.getTime() : Infinity;
          break;
        }
        case 'category':
          valA = a.category.toLowerCase();
          valB = b.category.toLowerCase();
          break;
        default:
          valA = a.name.toLowerCase();
          valB = b.name.toLowerCase();
      }
      const cmp = valA < valB ? -1 : valA > valB ? 1 : 0;
      return listSort.dir === 'asc' ? cmp : -cmp;
    });

    // Bind sort headers
    $$('.sort-btn').forEach(btn => {
      const field = btn.dataset.sort;
      btn.setAttribute('aria-sort', listSort.field === field ? (listSort.dir === 'asc' ? 'ascending' : 'descending') : 'none');
      btn.querySelector('.sort-arrow') && (btn.querySelector('.sort-arrow').textContent =
        listSort.field === field ? (listSort.dir === 'asc' ? ' ↑' : ' ↓') : '');
      btn.onclick = () => {
        if (listSort.field === field) {
          listSort.dir = listSort.dir === 'asc' ? 'desc' : 'asc';
        } else {
          listSort.field = field;
          listSort.dir = 'asc';
        }
        renderSubList();
      };
    });

    // Empty state
    if (subs.length === 0) {
      tbody.innerHTML = '';
      if (emptyState) emptyState.style.display = 'block';
      return;
    }
    if (emptyState) emptyState.style.display = 'none';

    tbody.innerHTML = '';
    subs.forEach(sub => {
      const next = Billing.nextRenewal(sub.anchorDate, sub.cycle, sub.customDays, today);
      const days = next ? Math.round((next - today) / 86400000) : null;
      const nextStr = next ? Billing.formatLocalDate(next) : '—';
      const nextDisp = next ? next.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : '—';
      const relLabel = days === null ? '—' : days === 0 ? 'Today' : days === 1 ? 'Tomorrow' : days <= 7 ? `in ${days}d` : nextDisp;
      const renewalClass = days === 0 ? 'renewal-today' : days !== null && days <= 3 ? 'renewal-urgent' : days !== null && days <= 7 ? 'renewal-soon' : '';

      const monthly = Billing.toMonthly(sub);
      const glyph = categoryGlyph(sub.category);

      const tr = document.createElement('tr');
      tr.setAttribute('role', 'row');
      tr.setAttribute('tabindex', '0');
      tr.setAttribute('aria-label', `${sub.name}, ${sub.status}, renews ${relLabel}`);
      tr.innerHTML = `
        <td>
          <div class="sub-name-cell">
            <span class="sub-glyph" aria-hidden="true">${glyph}</span>
            <div>
              <div class="sub-name" title="${esc(sub.name)}">${esc(sub.name)}</div>
              <div class="sub-vendor" title="${esc(sub.vendor)}">${esc(sub.vendor)}</div>
            </div>
          </div>
        </td>
        <td><span class="status-badge status-${sub.status}">${sub.status}</span></td>
        <td>
          <div class="renewal-date ${renewalClass}">${relLabel}</div>
          <div class="renewal-relative">${nextStr}</div>
        </td>
        <td class="amount-mono">${Billing.formatAmount(sub.amount, sym)}</td>
        <td class="amount-mono">${sym}${monthly.toFixed(2)}<span style="font-size:0.72rem;color:var(--text-tertiary)">/mo</span></td>
        <td class="actions-cell">
          <button class="btn-icon" title="Edit" aria-label="Edit ${esc(sub.name)}" data-action="edit" data-id="${sub.id}">✏️</button>
          <button class="btn-icon" title="Delete" aria-label="Delete ${esc(sub.name)}" data-action="delete" data-id="${sub.id}">🗑️</button>
        </td>
      `;

      // Row click → edit (unless clicking action buttons)
      tr.addEventListener('click', e => {
        if (e.target.closest('[data-action]')) return;
        openSubModal(sub.id);
      });
      tr.addEventListener('keydown', e => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          openSubModal(sub.id);
        }
      });

      tbody.appendChild(tr);
    });

    // Bind action buttons
    tbody.querySelectorAll('[data-action="edit"]').forEach(btn => {
      btn.addEventListener('click', e => { e.stopPropagation(); openSubModal(btn.dataset.id); });
    });
    tbody.querySelectorAll('[data-action="delete"]').forEach(btn => {
      btn.addEventListener('click', e => { e.stopPropagation(); confirmDeleteSub(btn.dataset.id); });
    });
  }

  function populateFilterSelects() {
    const catFilter = $('filter-category');
    if (catFilter) {
      const prev = catFilter.value;
      catFilter.innerHTML = '<option value="">All Categories</option>';
      const cats = [...new Set(STATE.subscriptions.map(s => s.category))].sort();
      cats.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c;
        opt.textContent = c;
        catFilter.appendChild(opt);
      });
      catFilter.value = cats.includes(prev) ? prev : '';
    }

    const pmFilter = $('filter-payment');
    if (pmFilter) {
      const prev = pmFilter.value;
      pmFilter.innerHTML = '<option value="">All Payment Methods</option>';
      const pms = [...new Set(STATE.subscriptions.map(s => s.paymentMethod).filter(Boolean))].sort();
      pms.forEach(p => {
        const opt = document.createElement('option');
        opt.value = p;
        opt.textContent = p;
        pmFilter.appendChild(opt);
      });
      pmFilter.value = pms.includes(prev) ? prev : '';
    }
  }

  // ─── Calendar View ───────────────────────────────────────────────────────

  function bindCalendar() {
    const prevBtn = $('cal-prev');
    const nextBtn = $('cal-next');
    const todayBtn = $('cal-today');
    if (prevBtn) prevBtn.addEventListener('click', () => {
      calendarMonth--;
      if (calendarMonth < 0) { calendarMonth = 11; calendarYear--; }
      calendarSelectedDay = null;
      renderCalendar();
    });
    if (nextBtn) nextBtn.addEventListener('click', () => {
      calendarMonth++;
      if (calendarMonth > 11) { calendarMonth = 0; calendarYear++; }
      calendarSelectedDay = null;
      renderCalendar();
    });
    if (todayBtn) todayBtn.addEventListener('click', () => {
      const now = new Date();
      calendarYear = now.getFullYear();
      calendarMonth = now.getMonth();
      calendarSelectedDay = null;
      renderCalendar();
    });
  }

  function renderCalendar() {
    const label = $('cal-month-label');
    if (label) {
      label.textContent = new Date(calendarYear, calendarMonth, 1).toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    }

    const renewalMap = Billing.renewalsInMonth(STATE.subscriptions, calendarYear, calendarMonth);
    const calGrid = $('cal-grid-container');
    if (!calGrid) return;

    Charts.drawCalendar(
      calGrid,
      calendarYear,
      calendarMonth,
      renewalMap,
      STATE.settings.monthStartsOn || 0,
      (dateStr, subs) => {
        calendarSelectedDay = dateStr;
        renderCalendar(); // re-render to show selection
        renderDayDetail(dateStr, subs);
      },
      calendarSelectedDay
    );

    // Render day detail if a day is selected
    if (calendarSelectedDay && renewalMap[calendarSelectedDay]) {
      renderDayDetail(calendarSelectedDay, renewalMap[calendarSelectedDay]);
    } else if (calendarSelectedDay) {
      renderDayDetail(calendarSelectedDay, []);
    }
  }

  function renderDayDetail(dateStr, subs) {
    const container = $('day-detail');
    if (!container) return;
    const sym = STATE.settings.currencySymbol || '$';

    const date = Billing.parseLocalDate(dateStr);
    const dateLabel = date ? date.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' }) : dateStr;

    if (subs.length === 0) {
      container.innerHTML = `<p class="empty-note">No renewals on ${dateLabel}.</p>`;
      container.style.display = 'block';
      return;
    }

    container.style.display = 'block';
    container.innerHTML = `<h3 class="day-detail-title">${dateLabel}</h3><ul class="day-detail-list"></ul>`;
    const ul = container.querySelector('.day-detail-list');

    subs.forEach(sub => {
      const li = document.createElement('li');
      li.className = 'day-detail-item';
      li.innerHTML = `
        <span aria-hidden="true">${categoryGlyph(sub.category)}</span>
        <div>
          <div class="sub-name">${esc(sub.name)}</div>
          <div style="font-size:0.75rem;color:var(--text-tertiary)">${esc(sub.category)} · ${Billing.cycleLabel(sub.cycle, sub.customDays)}</div>
        </div>
        <span class="sub-amount">${Billing.formatAmount(sub.amount, sym)}</span>
      `;
      ul.appendChild(li);
    });
  }

  // ─── Settings View ────────────────────────────────────────────────────────

  function bindSettings() {
    // Theme
    const themeSelect = $('setting-theme');
    if (themeSelect) {
      themeSelect.addEventListener('change', () => {
        STATE = Storage.updateSettings(STATE, { theme: themeSelect.value });
        applyTheme(themeSelect.value);
      });
    }

    // Currency
    const currInput = $('setting-currency');
    if (currInput) {
      currInput.addEventListener('change', () => {
        const val = currInput.value.trim().slice(0, 5) || '$';
        STATE = Storage.updateSettings(STATE, { currencySymbol: val });
        showToast('Currency symbol updated.', 'success');
      });
    }

    // Month starts on
    const monthStart = $('setting-month-start');
    if (monthStart) {
      monthStart.addEventListener('change', () => {
        STATE = Storage.updateSettings(STATE, { monthStartsOn: parseInt(monthStart.value, 10) });
      });
    }

    // Reduced motion toggle
    const rmToggle = $('setting-reduced-motion');
    if (rmToggle) {
      rmToggle.addEventListener('change', () => {
        STATE = Storage.updateSettings(STATE, { reducedMotion: rmToggle.checked });
        applyReducedMotion(rmToggle.checked);
      });
    }

    // Reset to sample
    const resetBtn = $('btn-reset-sample');
    if (resetBtn) {
      resetBtn.addEventListener('click', () => {
        openConfirm(
          'Reset to sample data?',
          'This will replace all your subscriptions, categories, and payment methods with the built-in sample data. This cannot be undone.',
          () => {
            const seed = Seed.makeSeedState();
            STATE = Object.assign({}, seed, { settings: STATE.settings });
            Storage.save(STATE);
            navigateTo('dashboard');
            showToast('Sample data restored.', 'success');
          }
        );
      });
    }

    // Clear all
    const clearBtn = $('btn-clear-all');
    if (clearBtn) {
      clearBtn.addEventListener('click', () => {
        openConfirm(
          'Clear all data?',
          'This will permanently delete all subscriptions, categories, and payment methods. Settings will be preserved.',
          () => {
            STATE = Object.assign({}, Storage.defaultState(), { settings: STATE.settings });
            Storage.save(STATE);
            navigateTo('dashboard');
            showToast('All data cleared.', 'info');
          }
        );
      });
    }

    // Tabs for categories/payment methods
    bindManageTabs();

    // Add category
    const addCatBtn = $('btn-add-category');
    if (addCatBtn) addCatBtn.addEventListener('click', () => openCategoryModal(null));

    // Add PM
    const addPMBtn = $('btn-add-pm');
    if (addPMBtn) addPMBtn.addEventListener('click', () => openPMModal(null));
  }

  function renderSettings() {
    const themeSelect = $('setting-theme');
    if (themeSelect) themeSelect.value = STATE.settings.theme || 'system';

    const currInput = $('setting-currency');
    if (currInput) currInput.value = STATE.settings.currencySymbol || '$';

    const monthStart = $('setting-month-start');
    if (monthStart) monthStart.value = String(STATE.settings.monthStartsOn || 0);

    const rmToggle = $('setting-reduced-motion');
    if (rmToggle) rmToggle.checked = !!STATE.settings.reducedMotion;

    renderCategoryList();
    renderPMList();
  }

  function bindManageTabs() {
    $$('.tab-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const panel = btn.dataset.tab;
        $$('.tab-btn').forEach(b => b.classList.toggle('active', b === btn));
        $$('.tab-panel').forEach(p => p.classList.toggle('active', p.id === `tab-${panel}`));
      });
    });
  }

  function renderCategoryList() {
    const container = $('category-list');
    if (!container) return;
    container.innerHTML = '';

    if (STATE.categories.length === 0) {
      container.innerHTML = '<p class="empty-note">No custom categories yet.</p>';
      return;
    }

    STATE.categories.forEach(cat => {
      const div = document.createElement('div');
      div.className = 'manage-item';
      div.innerHTML = `
        <span class="manage-item-color" style="background:${cat.color}" aria-hidden="true"></span>
        <div class="manage-item-info">
          <div class="manage-item-name">${esc(cat.glyph)} ${esc(cat.name)}</div>
          <div class="manage-item-meta">${esc(cat.color)}</div>
        </div>
        <div class="manage-item-actions">
          <button class="btn-icon" title="Edit" aria-label="Edit category ${esc(cat.name)}" data-action="edit-cat" data-id="${cat.id}">✏️</button>
          <button class="btn-icon" title="Delete" aria-label="Delete category ${esc(cat.name)}" data-action="delete-cat" data-id="${cat.id}">🗑️</button>
        </div>
      `;
      container.appendChild(div);
    });

    container.querySelectorAll('[data-action="edit-cat"]').forEach(btn => {
      btn.addEventListener('click', () => openCategoryModal(btn.dataset.id));
    });
    container.querySelectorAll('[data-action="delete-cat"]').forEach(btn => {
      btn.addEventListener('click', () => confirmDeleteCategory(btn.dataset.id));
    });
  }

  function renderPMList() {
    const container = $('pm-list');
    if (!container) return;
    container.innerHTML = '';

    if (STATE.paymentMethods.length === 0) {
      container.innerHTML = '<p class="empty-note">No payment methods yet.</p>';
      return;
    }

    STATE.paymentMethods.forEach(pm => {
      const div = document.createElement('div');
      div.className = 'manage-item';
      div.innerHTML = `
        <span aria-hidden="true" style="font-size:1.2rem">💳</span>
        <div class="manage-item-info">
          <div class="manage-item-name">${esc(pm.label)}</div>
        </div>
        <div class="manage-item-actions">
          <button class="btn-icon" title="Edit" aria-label="Edit ${esc(pm.label)}" data-action="edit-pm" data-id="${pm.id}">✏️</button>
          <button class="btn-icon" title="Delete" aria-label="Delete ${esc(pm.label)}" data-action="delete-pm" data-id="${pm.id}">🗑️</button>
        </div>
      `;
      container.appendChild(div);
    });

    container.querySelectorAll('[data-action="edit-pm"]').forEach(btn => {
      btn.addEventListener('click', () => openPMModal(btn.dataset.id));
    });
    container.querySelectorAll('[data-action="delete-pm"]').forEach(btn => {
      btn.addEventListener('click', () => confirmDeletePM(btn.dataset.id));
    });
  }

  // ─── Subscription Modal ───────────────────────────────────────────────────

  function openSubModal(id) {
    editingSubId = id || null;
    const sub = id ? STATE.subscriptions.find(s => s.id === id) : null;
    const modal = $('sub-modal');
    const title = $('sub-modal-title');
    if (!modal) return;

    if (title) title.textContent = sub ? 'Edit Subscription' : 'Add Subscription';

    // Populate category & payment method dropdowns
    populateSubFormDropdowns();

    // Fill form
    fillSubForm(sub);

    // Clear errors
    modal.querySelectorAll('.form-error').forEach(e => e.textContent = '');
    modal.querySelectorAll('.form-input, .form-select').forEach(i => i.classList.remove('invalid'));

    openModal('sub-modal');
  }

  function populateSubFormDropdowns() {
    const catSelect = $('sub-form-category');
    if (catSelect) {
      catSelect.innerHTML = '';
      const defaultCats = ['Entertainment', 'Software', 'Utilities', 'Health', 'News & Reading', 'Storage', 'Uncategorized'];
      const allCats = [...new Set([...defaultCats, ...STATE.categories.map(c => c.name)])].sort();
      allCats.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c;
        opt.textContent = c;
        catSelect.appendChild(opt);
      });
    }

    const pmSelect = $('sub-form-payment');
    if (pmSelect) {
      pmSelect.innerHTML = '<option value="">— None —</option>';
      STATE.paymentMethods.forEach(pm => {
        const opt = document.createElement('option');
        opt.value = pm.label;
        opt.textContent = pm.label;
        pmSelect.appendChild(opt);
      });
    }
  }

  function fillSubForm(sub) {
    const fields = {
      'sub-form-name':        sub ? sub.name : '',
      'sub-form-vendor':      sub ? sub.vendor : '',
      'sub-form-amount':      sub ? String(sub.amount) : '',
      'sub-form-currency':    sub ? sub.currency : (STATE.settings.currencySymbol || '$'),
      'sub-form-cycle':       sub ? sub.cycle : 'monthly',
      'sub-form-custom-days': sub ? String(sub.customDays || 30) : '30',
      'sub-form-anchor':      sub ? sub.anchorDate : Billing.formatLocalDate(new Date()),
      'sub-form-category':    sub ? sub.category : 'Uncategorized',
      'sub-form-payment':     sub ? sub.paymentMethod : '',
      'sub-form-status':      sub ? sub.status : 'active',
      'sub-form-trial':       sub ? sub.trialEnds : '',
      'sub-form-notes':       sub ? sub.notes : '',
    };
    for (const [id, val] of Object.entries(fields)) {
      const el = $(id);
      if (el) el.value = val;
    }
    updateCycleCustomVisibility();
  }

  function updateCycleCustomVisibility() {
    const cycle = $('sub-form-cycle');
    const customRow = $('custom-days-row');
    if (!cycle || !customRow) return;
    customRow.style.display = cycle.value === 'custom' ? 'flex' : 'none';
  }

  function bindSubForm() {
    const cycleSelect = $('sub-form-cycle');
    if (cycleSelect) {
      cycleSelect.addEventListener('change', updateCycleCustomVisibility);
    }

    const form = $('sub-form');
    if (form) {
      form.addEventListener('submit', e => {
        e.preventDefault();
        saveSubForm();
      });
    }

    const cancelBtn = $('sub-form-cancel');
    if (cancelBtn) cancelBtn.addEventListener('click', () => closeModal('sub-modal'));
  }

  function saveSubForm() {
    const name     = ($('sub-form-name') || {}).value?.trim() || '';
    const vendor   = ($('sub-form-vendor') || {}).value?.trim() || '';
    const amountRaw= ($('sub-form-amount') || {}).value?.trim() || '';
    const currency = ($('sub-form-currency') || {}).value?.trim() || '$';
    const cycle    = ($('sub-form-cycle') || {}).value || 'monthly';
    const customD  = parseInt(($('sub-form-custom-days') || {}).value || '30', 10);
    const anchor   = ($('sub-form-anchor') || {}).value?.trim() || '';
    const category = ($('sub-form-category') || {}).value || 'Uncategorized';
    const payment  = ($('sub-form-payment') || {}).value?.trim() || '';
    const status   = ($('sub-form-status') || {}).value || 'active';
    const trial    = ($('sub-form-trial') || {}).value?.trim() || '';
    const notes    = ($('sub-form-notes') || {}).value?.trim() || '';

    // Validate
    let valid = true;
    // Map error-span IDs to their associated input IDs
    const errInputMap = {
      'err-name':   'sub-form-name',
      'err-amount': 'sub-form-amount',
      'err-anchor': 'sub-form-anchor',
      'err-custom': 'sub-form-custom-days',
      'err-trial':  'sub-form-trial',
    };
    const setErr = (id, msg) => {
      const el = $(id);
      if (el) el.textContent = msg;
      const inputId = errInputMap[id] || `sub-form-${id.replace('err-', '')}`;
      const input = $(inputId);
      if (input && msg) input.classList.add('invalid');
      else if (input) input.classList.remove('invalid');
      if (msg) valid = false;
    };

    if (!name) setErr('err-name', 'Name is required.');
    else setErr('err-name', '');

    const amount = parseFloat(amountRaw);
    if (amountRaw === '' || isNaN(amount) || amount < 0) {
      setErr('err-amount', 'Enter a valid non-negative amount.');
    } else {
      setErr('err-amount', '');
    }

    if (!anchor || !Billing.parseLocalDate(anchor)) {
      setErr('err-anchor', 'Enter a valid date (YYYY-MM-DD).');
    } else {
      setErr('err-anchor', '');
    }

    if (cycle === 'custom' && (isNaN(customD) || customD < 1)) {
      setErr('err-custom', 'Custom interval must be at least 1 day.');
    } else {
      setErr('err-custom', '');
    }

    if (trial && !Billing.parseLocalDate(trial)) {
      setErr('err-trial', 'Enter a valid date or leave blank.');
    } else {
      setErr('err-trial', '');
    }

    if (!valid) return;

    const data = {
      name, vendor, amount, currency, cycle,
      customDays: customD,
      anchorDate: anchor,
      category, paymentMethod: payment, status,
      trialEnds: trial, notes,
    };

    if (editingSubId) {
      STATE = Storage.updateSubscription(STATE, editingSubId, data);
      showToast(`"${name}" updated.`, 'success');
    } else {
      STATE = Storage.addSubscription(STATE, data);
      showToast(`"${name}" added.`, 'success');
    }

    closeModal('sub-modal');

    // Re-render current view
    const currentView = document.querySelector('.view.active')?.id?.replace('view-', '');
    if (currentView) {
      switch (currentView) {
        case 'dashboard':     renderDashboard(); break;
        case 'subscriptions': renderSubList(); break;
        case 'calendar':      renderCalendar(); break;
      }
    }
  }

  function confirmDeleteSub(id) {
    const sub = STATE.subscriptions.find(s => s.id === id);
    if (!sub) return;
    openConfirm(
      `Delete "${sub.name}"?`,
      'This subscription will be permanently removed. This cannot be undone.',
      () => {
        STATE = Storage.deleteSubscription(STATE, id);
        showToast(`"${sub.name}" deleted.`, 'info');
        renderSubList();
        renderDashboard();
      }
    );
  }

  // ─── Category Modal ───────────────────────────────────────────────────────

  function openCategoryModal(id) {
    editingCatId = id || null;
    const cat = id ? STATE.categories.find(c => c.id === id) : null;
    const modal = $('cat-modal');
    if (!modal) return;

    $('cat-modal-title').textContent = cat ? 'Edit Category' : 'Add Category';
    $('cat-form-name').value  = cat ? cat.name : '';
    $('cat-form-color').value = cat ? cat.color : '#7C6FCD';
    $('cat-form-glyph').value = cat ? cat.glyph : '';
    $('err-cat-name').textContent = '';

    openModal('cat-modal');
  }

  function bindCatForm() {
    const form = $('cat-form');
    if (form) {
      form.addEventListener('submit', e => {
        e.preventDefault();
        saveCatForm();
      });
    }
    const cancelBtn = $('cat-form-cancel');
    if (cancelBtn) cancelBtn.addEventListener('click', () => closeModal('cat-modal'));
  }

  function saveCatForm() {
    const name  = ($('cat-form-name') || {}).value?.trim() || '';
    const color = ($('cat-form-color') || {}).value?.trim() || '#7C6FCD';
    const glyph = ($('cat-form-glyph') || {}).value?.trim().slice(0, 4) || '';

    if (!name) {
      $('err-cat-name').textContent = 'Category name is required.';
      return;
    }
    $('err-cat-name').textContent = '';

    if (editingCatId) {
      STATE = Storage.updateCategory(STATE, editingCatId, { name, color, glyph });
      showToast(`Category "${name}" updated.`, 'success');
    } else {
      STATE = Storage.addCategory(STATE, { name, color, glyph });
      showToast(`Category "${name}" added.`, 'success');
    }

    closeModal('cat-modal');
    renderCategoryList();
  }

  function confirmDeleteCategory(id) {
    const cat = STATE.categories.find(c => c.id === id);
    if (!cat) return;
    const inUse = STATE.subscriptions.filter(s => s.category === cat.name);

    if (inUse.length > 0) {
      // Build reassign select
      const otherCats = STATE.categories.filter(c => c.id !== id).map(c => c.name);
      openCatReassignDialog(cat, inUse, otherCats);
    } else {
      openConfirm(
        `Delete category "${cat.name}"?`,
        'This category has no subscriptions. It will be permanently removed.',
        () => {
          const { state } = Storage.deleteCategory(STATE, id, undefined);
          STATE = state;
          showToast(`Category "${cat.name}" deleted.`, 'info');
          renderCategoryList();
        }
      );
    }
  }

  function openCatReassignDialog(cat, inUse, otherCats) {
    const modal = $('confirm-modal');
    if (!modal) return;
    $('confirm-title').textContent = `Delete category "${cat.name}"?`;

    let reassignHTML = '';
    if (otherCats.length > 0) {
      reassignHTML = `
        <p style="margin-top:12px;font-size:0.85rem;color:var(--text-secondary)">
          ${inUse.length} subscription${inUse.length !== 1 ? 's use' : ' uses'} this category.
          Reassign to:
        </p>
        <select id="cat-reassign-select" class="form-select" style="margin-top:8px;width:100%;height:44px">
          <option value="">Uncategorized</option>
          ${otherCats.map(c => `<option value="${esc(c)}">${esc(c)}</option>`).join('')}
        </select>
      `;
    } else {
      reassignHTML = `<p style="margin-top:12px;font-size:0.85rem;color:var(--text-secondary)">${inUse.length} subscription${inUse.length !== 1 ? 's' : ''} will be moved to "Uncategorized".</p>`;
    }

    $('confirm-message').innerHTML = `All subscriptions in this category will be reassigned.${reassignHTML}`;
    $('confirm-ok').textContent = 'Delete & Reassign';
    $('confirm-ok').className = 'btn btn-danger';

    $('confirm-ok').onclick = () => {
      const sel = $('cat-reassign-select');
      const reassignTo = sel ? sel.value : '';
      const { state, error } = Storage.deleteCategory(STATE, cat.id, reassignTo);
      if (error) { showToast(error, 'error'); return; }
      STATE = state;
      showToast(`Category "${cat.name}" deleted. Subscriptions reassigned.`, 'info');
      closeModal('confirm-modal');
      renderCategoryList();
    };

    openModal('confirm-modal');
  }

  // ─── Payment Method Modal ─────────────────────────────────────────────────

  function openPMModal(id) {
    editingPMId = id || null;
    const pm = id ? STATE.paymentMethods.find(p => p.id === id) : null;
    const modal = $('pm-modal');
    if (!modal) return;

    $('pm-modal-title').textContent = pm ? 'Edit Payment Method' : 'Add Payment Method';
    $('pm-form-label').value = pm ? pm.label : '';
    $('err-pm-label').textContent = '';

    openModal('pm-modal');
  }

  function bindPMForm() {
    const form = $('pm-form');
    if (form) {
      form.addEventListener('submit', e => {
        e.preventDefault();
        savePMForm();
      });
    }
    const cancelBtn = $('pm-form-cancel');
    if (cancelBtn) cancelBtn.addEventListener('click', () => closeModal('pm-modal'));
  }

  function savePMForm() {
    const label = ($('pm-form-label') || {}).value?.trim() || '';
    if (!label) {
      $('err-pm-label').textContent = 'Label is required.';
      return;
    }
    $('err-pm-label').textContent = '';

    if (editingPMId) {
      const oldPM = STATE.paymentMethods.find(p => p.id === editingPMId);
      const oldLabel = oldPM ? oldPM.label : '';
      STATE = Storage.updatePaymentMethod(STATE, editingPMId, { label });
      // Update subscriptions that used old label
      if (oldLabel && oldLabel !== label) {
        STATE.subscriptions.forEach((s, i) => {
          if (s.paymentMethod === oldLabel) {
            STATE = Storage.updateSubscription(STATE, s.id, { paymentMethod: label });
          }
        });
      }
      showToast(`Payment method updated.`, 'success');
    } else {
      STATE = Storage.addPaymentMethod(STATE, { label });
      showToast(`Payment method "${label}" added.`, 'success');
    }

    closeModal('pm-modal');
    renderPMList();
  }

  function confirmDeletePM(id) {
    const pm = STATE.paymentMethods.find(p => p.id === id);
    if (!pm) return;
    const inUse = STATE.subscriptions.filter(s => s.paymentMethod === pm.label);

    if (inUse.length > 0) {
      openPMReassignDialog(pm, inUse);
    } else {
      openConfirm(
        `Delete "${pm.label}"?`,
        'This payment method will be permanently removed.',
        () => {
          const { state } = Storage.deletePaymentMethod(STATE, id, undefined);
          STATE = state;
          showToast(`"${pm.label}" deleted.`, 'info');
          renderPMList();
        }
      );
    }
  }

  function openPMReassignDialog(pm, inUse) {
    const otherPMs = STATE.paymentMethods.filter(p => p.id !== pm.id).map(p => p.label);
    const modal = $('confirm-modal');
    if (!modal) return;

    $('confirm-title').textContent = `Delete "${pm.label}"?`;

    let reassignHTML = '';
    if (otherPMs.length > 0) {
      reassignHTML = `
        <p style="margin-top:12px;font-size:0.85rem;color:var(--text-secondary)">${inUse.length} subscription${inUse.length !== 1 ? 's use' : ' uses'} this method. Reassign to:</p>
        <select id="pm-reassign-select" class="form-select" style="margin-top:8px;width:100%;height:44px">
          <option value="">None</option>
          ${otherPMs.map(l => `<option value="${esc(l)}">${esc(l)}</option>`).join('')}
        </select>
      `;
    } else {
      reassignHTML = `<p style="margin-top:12px;font-size:0.85rem;color:var(--text-secondary)">${inUse.length} subscription${inUse.length !== 1 ? 's' : ''} will have no payment method.</p>`;
    }

    $('confirm-message').innerHTML = `Subscriptions using this method will be affected.${reassignHTML}`;
    $('confirm-ok').textContent = 'Delete & Reassign';
    $('confirm-ok').className = 'btn btn-danger';

    $('confirm-ok').onclick = () => {
      const sel = $('pm-reassign-select');
      const reassignTo = sel ? sel.value : '';
      const { state, error } = Storage.deletePaymentMethod(STATE, pm.id, reassignTo);
      if (error) { showToast(error, 'error'); return; }
      STATE = state;
      showToast(`"${pm.label}" deleted.`, 'info');
      closeModal('confirm-modal');
      renderPMList();
    };

    openModal('confirm-modal');
  }

  // ─── Confirm Dialog ───────────────────────────────────────────────────────

  function openConfirm(title, message, onConfirm) {
    const modal = $('confirm-modal');
    if (!modal) return;
    $('confirm-title').textContent = title;
    $('confirm-message').textContent = message;
    $('confirm-ok').textContent = 'Confirm';
    $('confirm-ok').className = 'btn btn-danger';
    $('confirm-ok').onclick = () => {
      onConfirm();
      closeModal('confirm-modal');
    };
    openModal('confirm-modal');
  }

  function bindConfirmModal() {
    const cancelBtn = $('confirm-cancel');
    if (cancelBtn) cancelBtn.addEventListener('click', () => closeModal('confirm-modal'));
  }

  // ─── Modal utilities ──────────────────────────────────────────────────────

  let _focusBeforeModal = null;
  let _focusTrapElements = [];

  function openModal(id) {
    const modal = $(id);
    if (!modal) return;
    _focusBeforeModal = document.activeElement;
    modal.classList.add('open');
    modal.removeAttribute('hidden');
    modal.setAttribute('aria-modal', 'true');
    // Focus first focusable element
    const focusable = modal.querySelectorAll('button, input, select, textarea, [tabindex]:not([tabindex="-1"])');
    _focusTrapElements = Array.from(focusable);
    if (_focusTrapElements.length > 0) _focusTrapElements[0].focus();
  }

  function closeModal(id) {
    const modal = $(id);
    if (!modal) return;
    modal.classList.remove('open');
    modal.setAttribute('hidden', '');
    if (_focusBeforeModal) {
      _focusBeforeModal.focus();
      _focusBeforeModal = null;
    }
  }

  function bindKeyboard() {
    document.addEventListener('keydown', e => {
      if (e.key === 'Escape') {
        // Close topmost open modal
        const openModals = $$('.modal-overlay.open');
        if (openModals.length > 0) {
          closeModal(openModals[openModals.length - 1].id);
        }
      }

      // Focus trap in modals
      const openModal = document.querySelector('.modal-overlay.open');
      if (openModal && e.key === 'Tab') {
        const focusable = Array.from(openModal.querySelectorAll('button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'));
        if (focusable.length === 0) return;
        const first = focusable[0];
        const last = focusable[focusable.length - 1];
        if (e.shiftKey) {
          if (document.activeElement === first) { e.preventDefault(); last.focus(); }
        } else {
          if (document.activeElement === last) { e.preventDefault(); first.focus(); }
        }
      }
    });
  }

  // ─── Export / Import ──────────────────────────────────────────────────────

  function bindExportImport() {
    const exportJSON = $('btn-export-json');
    if (exportJSON) {
      exportJSON.addEventListener('click', () => {
        const json = Storage.exportJSON(STATE);
        downloadBlob(json, 'renewal-backup.json', 'application/json');
        showToast('JSON exported.', 'success');
      });
    }

    const exportCSV = $('btn-export-csv');
    if (exportCSV) {
      exportCSV.addEventListener('click', () => {
        const csv = Storage.exportCSV(STATE);
        downloadBlob(csv, 'renewal-subscriptions.csv', 'text/csv');
        showToast('CSV exported.', 'success');
      });
    }

    const importBtn = $('btn-import-json');
    const importFile = $('import-file');
    if (importBtn && importFile) {
      importBtn.addEventListener('click', () => importFile.click());
      importFile.addEventListener('change', () => {
        const file = importFile.files[0];
        if (!file) return;
        showLoading(true);
        const reader = new FileReader();
        reader.onload = e => {
          const { state, error } = Storage.importJSON(e.target.result);
          showLoading(false);
          if (error) {
            showToast(`Import failed: ${error}`, 'error');
          } else {
            STATE = state;
            applyTheme(STATE.settings.theme);
            applyReducedMotion(STATE.settings.reducedMotion);
            navigateTo(STATE.settings.lastView || 'dashboard');
            showToast('Data imported successfully.', 'success');
          }
          importFile.value = '';
        };
        reader.onerror = () => {
          showLoading(false);
          showToast('Could not read file.', 'error');
          importFile.value = '';
        };
        reader.readAsText(file);
      });
    }

    // Drag and drop on import area
    const dropArea = $('import-drop-area');
    if (dropArea) {
      dropArea.addEventListener('dragover', e => { e.preventDefault(); dropArea.classList.add('dragover'); });
      dropArea.addEventListener('dragleave', () => dropArea.classList.remove('dragover'));
      dropArea.addEventListener('drop', e => {
        e.preventDefault();
        dropArea.classList.remove('dragover');
        const file = e.dataTransfer.files[0];
        if (!file || !file.name.endsWith('.json')) {
          showToast('Please drop a .json file.', 'error');
          return;
        }
        showLoading(true);
        const reader = new FileReader();
        reader.onload = ev => {
          const { state, error } = Storage.importJSON(ev.target.result);
          showLoading(false);
          if (error) {
            showToast(`Import failed: ${error}`, 'error');
          } else {
            STATE = state;
            applyTheme(STATE.settings.theme);
            applyReducedMotion(STATE.settings.reducedMotion);
            navigateTo(STATE.settings.lastView || 'dashboard');
            showToast('Data imported successfully.', 'success');
          }
        };
        reader.onerror = () => { showLoading(false); showToast('Could not read file.', 'error'); };
        reader.readAsText(file);
      });
    }
  }

  function downloadBlob(content, filename, mimeType) {
    const blob = new Blob([content], { type: mimeType });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 5000);
  }

  // ─── Loading overlay ──────────────────────────────────────────────────────

  function showLoading(show) {
    const overlay = $('loading-overlay');
    if (overlay) overlay.classList.toggle('open', show);
  }

  // ─── Toast notifications ──────────────────────────────────────────────────

  function bindToastRegion() {
    // Ensure aria-live region is announced
    const region = $('toast-region');
    if (region) region.setAttribute('aria-live', 'polite');
  }

  function showToast(message, type) {
    const region = $('toast-region');
    if (!region) return;

    const toast = document.createElement('div');
    toast.className = `toast toast-${type || 'info'}`;
    toast.setAttribute('role', 'status');
    toast.textContent = message;
    region.appendChild(toast);

    setTimeout(() => {
      toast.classList.add('toast-out');
      toast.addEventListener('animationend', () => toast.remove(), { once: true });
      // Fallback removal
      setTimeout(() => { if (toast.parentNode) toast.remove(); }, 500);
    }, 3500);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  function esc(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function isEmoji(str) {
    if (!str) return false;
    return /\p{Emoji}/u.test(str);
  }

  function categoryGlyph(catName) {
    const cat = STATE.categories.find(c => c.name === catName);
    if (cat && cat.glyph) return cat.glyph;
    const glyphs = {
      'Entertainment':  '🎬',
      'Software':       '💻',
      'Utilities':      '⚡',
      'Health':         '🏃',
      'News & Reading': '📰',
      'Storage':        '☁️',
      'Uncategorized':  '📦',
    };
    return glyphs[catName] || '📦';
  }

  // ─── Boot ─────────────────────────────────────────────────────────────────

  // Bind all forms on DOM content loaded
  document.addEventListener('DOMContentLoaded', () => {
    // If no data at all, seed with sample
    if (STATE.subscriptions.length === 0 && STATE.categories.length === 0) {
      const seed = Seed.makeSeedState();
      STATE = Object.assign({}, seed);
      Storage.save(STATE);
    }

    bindSubForm();
    bindCatForm();
    bindPMForm();
    bindConfirmModal();
    init();
  });

})();
