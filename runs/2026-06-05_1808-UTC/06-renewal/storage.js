/**
 * storage.js — Versioned localStorage persistence with tolerant decode.
 * All reads return sane defaults if data is absent or corrupt.
 */

'use strict';

const Storage = (() => {

  const SCHEMA_VERSION = 1;
  const KEY = 'renewal_app_v1';

  // ─── Defaults ─────────────────────────────────────────────────────────────

  function defaultState() {
    return {
      version: SCHEMA_VERSION,
      subscriptions: [],
      categories: [],
      paymentMethods: [],
      settings: defaultSettings(),
    };
  }

  function defaultSettings() {
    return {
      currencySymbol: '$',
      monthStartsOn: 1,      // 1 = Monday, 0 = Sunday
      theme: 'system',       // 'light' | 'dark' | 'system'
      reducedMotion: false,
      lastView: 'dashboard',
    };
  }

  // ─── Core read/write ──────────────────────────────────────────────────────

  function save(state) {
    try {
      const payload = Object.assign({}, state, { version: SCHEMA_VERSION });
      localStorage.setItem(KEY, JSON.stringify(payload));
    } catch (e) {
      console.warn('[Storage] save failed:', e.message);
    }
  }

  function load() {
    try {
      const raw = localStorage.getItem(KEY);
      if (!raw) return defaultState();
      const parsed = JSON.parse(raw);
      return migrate(parsed);
    } catch (e) {
      console.warn('[Storage] load/parse failed, using defaults:', e.message);
      return defaultState();
    }
  }

  /** Migrate older schema versions forward. */
  function migrate(data) {
    if (!data || typeof data !== 'object') return defaultState();

    const state = defaultState();

    // Version migration: fill in any missing top-level keys
    state.subscriptions = Array.isArray(data.subscriptions) ? data.subscriptions.map(normalizeSub) : [];
    state.categories = Array.isArray(data.categories) ? data.categories.map(normalizeCat) : [];
    state.paymentMethods = Array.isArray(data.paymentMethods) ? data.paymentMethods.map(normalizePM) : [];
    state.settings = Object.assign(defaultSettings(), typeof data.settings === 'object' ? data.settings : {});
    state.version = SCHEMA_VERSION;

    return state;
  }

  // ─── Entity normalizers (fill missing fields gracefully) ──────────────────

  function normalizeSub(s) {
    if (!s || typeof s !== 'object') return null;
    return {
      id:            String(s.id || generateId()),
      name:          String(s.name || 'Unnamed').slice(0, 100),
      vendor:        String(s.vendor || '').slice(0, 50),
      amount:        Number(s.amount) >= 0 ? Number(s.amount) : 0,
      currency:      String(s.currency || '$').slice(0, 5),
      cycle:         ['weekly','monthly','quarterly','semiannual','yearly','custom'].includes(s.cycle)
                       ? s.cycle : 'monthly',
      customDays:    Math.max(1, parseInt(s.customDays, 10) || 30),
      anchorDate:    typeof s.anchorDate === 'string' ? s.anchorDate : '',
      category:      String(s.category || 'Uncategorized').slice(0, 50),
      paymentMethod: String(s.paymentMethod || '').slice(0, 60),
      status:        ['active','paused','canceled'].includes(s.status) ? s.status : 'active',
      trialEnds:     typeof s.trialEnds === 'string' ? s.trialEnds : '',
      notes:         String(s.notes || '').slice(0, 500),
      createdAt:     String(s.createdAt || new Date().toISOString()),
    };
  }

  function normalizeCat(c) {
    if (!c || typeof c !== 'object') return null;
    return {
      id:    String(c.id || generateId()),
      name:  String(c.name || 'Category').slice(0, 50),
      color: String(c.color || '#86C79A').slice(0, 20),
      glyph: String(c.glyph || '').slice(0, 4),
    };
  }

  function normalizePM(p) {
    if (!p || typeof p !== 'object') return null;
    return {
      id:    String(p.id || generateId()),
      label: String(p.label || 'Payment Method').slice(0, 60),
    };
  }

  // ─── ID generation ────────────────────────────────────────────────────────

  function generateId() {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  }

  // ─── Subscription CRUD ────────────────────────────────────────────────────

  function addSubscription(state, subData) {
    const sub = normalizeSub(Object.assign({ id: generateId(), createdAt: new Date().toISOString() }, subData));
    if (!sub) return state;
    const next = Object.assign({}, state, { subscriptions: [...state.subscriptions, sub] });
    save(next);
    return next;
  }

  function updateSubscription(state, id, subData) {
    const subs = state.subscriptions.map(s => {
      if (s.id !== id) return s;
      return normalizeSub(Object.assign({}, s, subData, { id }));
    });
    const next = Object.assign({}, state, { subscriptions: subs.filter(Boolean) });
    save(next);
    return next;
  }

  function deleteSubscription(state, id) {
    const next = Object.assign({}, state, { subscriptions: state.subscriptions.filter(s => s.id !== id) });
    save(next);
    return next;
  }

  // ─── Category CRUD ────────────────────────────────────────────────────────

  function addCategory(state, catData) {
    const cat = normalizeCat(Object.assign({ id: generateId() }, catData));
    if (!cat) return state;
    const next = Object.assign({}, state, { categories: [...state.categories, cat] });
    save(next);
    return next;
  }

  function updateCategory(state, id, catData) {
    const cats = state.categories.map(c => c.id !== id ? c : normalizeCat(Object.assign({}, c, catData, { id })));
    const next = Object.assign({}, state, { categories: cats.filter(Boolean) });
    save(next);
    return next;
  }

  /**
   * Delete a category by ID. If it's in use by subscriptions, returns an error message.
   * If `reassignTo` is provided, reassigns affected subscriptions instead of blocking.
   */
  function deleteCategory(state, id, reassignTo) {
    const cat = state.categories.find(c => c.id === id);
    if (!cat) return { state, error: null };

    const inUse = state.subscriptions.filter(s => s.category === cat.name);
    if (inUse.length > 0 && !reassignTo) {
      return {
        state,
        error: `"${cat.name}" is used by ${inUse.length} subscription${inUse.length !== 1 ? 's' : ''}. Reassign them first or choose a replacement category.`,
        inUse,
      };
    }

    let subs = state.subscriptions;
    if (reassignTo !== undefined) {
      subs = subs.map(s => s.category === cat.name ? Object.assign({}, s, { category: reassignTo || 'Uncategorized' }) : s);
    }
    const next = Object.assign({}, state, {
      categories: state.categories.filter(c => c.id !== id),
      subscriptions: subs,
    });
    save(next);
    return { state: next, error: null };
  }

  // ─── Payment method CRUD ──────────────────────────────────────────────────

  function addPaymentMethod(state, pmData) {
    const pm = normalizePM(Object.assign({ id: generateId() }, pmData));
    if (!pm) return state;
    const next = Object.assign({}, state, { paymentMethods: [...state.paymentMethods, pm] });
    save(next);
    return next;
  }

  function updatePaymentMethod(state, id, pmData) {
    const pms = state.paymentMethods.map(p => p.id !== id ? p : normalizePM(Object.assign({}, p, pmData, { id })));
    const next = Object.assign({}, state, { paymentMethods: pms.filter(Boolean) });
    save(next);
    return next;
  }

  /**
   * Delete a payment method. Blocks if in use unless `reassignTo` is provided.
   */
  function deletePaymentMethod(state, id, reassignTo) {
    const pm = state.paymentMethods.find(p => p.id === id);
    if (!pm) return { state, error: null };

    const inUse = state.subscriptions.filter(s => s.paymentMethod === pm.label);
    if (inUse.length > 0 && !reassignTo) {
      return {
        state,
        error: `"${pm.label}" is used by ${inUse.length} subscription${inUse.length !== 1 ? 's' : ''}. Reassign them first.`,
        inUse,
      };
    }

    let subs = state.subscriptions;
    if (reassignTo !== undefined) {
      subs = subs.map(s => s.paymentMethod === pm.label ? Object.assign({}, s, { paymentMethod: reassignTo || '' }) : s);
    }
    const next = Object.assign({}, state, {
      paymentMethods: state.paymentMethods.filter(p => p.id !== id),
      subscriptions: subs,
    });
    save(next);
    return { state: next, error: null };
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  function updateSettings(state, settingsPatch) {
    const next = Object.assign({}, state, {
      settings: Object.assign({}, state.settings, settingsPatch),
    });
    save(next);
    return next;
  }

  // ─── Import / Export ──────────────────────────────────────────────────────

  function exportJSON(state) {
    return JSON.stringify(state, null, 2);
  }

  function exportCSV(state) {
    const headers = ['Name','Vendor','Amount','Currency','Cycle','CustomDays','AnchorDate','Category','PaymentMethod','Status','TrialEnds','Notes'];
    const rows = state.subscriptions.map(s => [
      csvEscape(s.name),
      csvEscape(s.vendor),
      s.amount,
      csvEscape(s.currency),
      s.cycle,
      s.cycle === 'custom' ? s.customDays : '',
      s.anchorDate,
      csvEscape(s.category),
      csvEscape(s.paymentMethod),
      s.status,
      s.trialEnds || '',
      csvEscape(s.notes),
    ]);
    return [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
  }

  function csvEscape(val) {
    const s = String(val || '');
    if (s.includes(',') || s.includes('"') || s.includes('\n')) {
      return `"${s.replace(/"/g, '""')}"`;
    }
    return s;
  }

  function importJSON(jsonStr) {
    try {
      const parsed = JSON.parse(jsonStr);
      const state = migrate(parsed);
      save(state);
      return { state, error: null };
    } catch (e) {
      return { state: null, error: `Invalid JSON: ${e.message}` };
    }
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  return {
    load,
    save,
    defaultState,
    defaultSettings,
    generateId,
    normalizeSub,
    normalizeCat,
    normalizePM,
    addSubscription,
    updateSubscription,
    deleteSubscription,
    addCategory,
    updateCategory,
    deleteCategory,
    addPaymentMethod,
    updatePaymentMethod,
    deletePaymentMethod,
    updateSettings,
    exportJSON,
    exportCSV,
    importJSON,
  };

})();
