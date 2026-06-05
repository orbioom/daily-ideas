/**
 * storage.js — localStorage layer for Envelope Budget
 * Versioned key, tolerant decode, sane defaults for missing fields.
 */

const STORAGE_KEY = 'envelope_budget_v1';
const STORAGE_VERSION = 1;

const DEFAULT_SETTINGS = {
  currency: '$',
  firstDayOfMonth: 1,
  theme: 'system',
  reducedMotion: false,
};

const DEFAULT_STATE = {
  version: STORAGE_VERSION,
  accounts: [],
  envelopes: [],
  transactions: [],
  settings: Object.assign({}, DEFAULT_SETTINGS),
  currentMonth: null, // YYYY-MM string, null = today
};

function deepClone(obj) {
  try {
    return JSON.parse(JSON.stringify(obj));
  } catch (_) {
    return obj;
  }
}

function generateId() {
  return 'id_' + Math.random().toString(36).slice(2, 11) + '_' + Date.now().toString(36);
}

function sanitizeAccount(a) {
  if (!a || typeof a !== 'object') return null;
  const name = String(a.name || '').trim();
  if (!name) return null;
  return {
    id: String(a.id || generateId()),
    name,
    type: ['checking', 'savings', 'cash'].includes(a.type) ? a.type : 'checking',
    startingBalance: typeof a.startingBalance === 'number' && isFinite(a.startingBalance) ? a.startingBalance : 0,
    createdAt: String(a.createdAt || new Date().toISOString()),
  };
}

function sanitizeEnvelope(e) {
  if (!e || typeof e !== 'object') return null;
  const name = String(e.name || '').trim();
  if (!name) return null;
  return {
    id: String(e.id || generateId()),
    name,
    icon: String(e.icon || '📁'),
    budgetedAmount: typeof e.budgetedAmount === 'number' && isFinite(e.budgetedAmount) && e.budgetedAmount >= 0 ? e.budgetedAmount : 0,
    group: String(e.group || 'General').trim() || 'General',
    rollover: Boolean(e.rollover),
    createdAt: String(e.createdAt || new Date().toISOString()),
  };
}

function sanitizeTransaction(t) {
  if (!t || typeof t !== 'object') return null;
  if (!String(t.date || '').match(/^\d{4}-\d{2}-\d{2}$/)) return null;
  const amount = typeof t.amount === 'number' && isFinite(t.amount) ? Math.abs(t.amount) : null;
  if (amount === null) return null;
  return {
    id: String(t.id || generateId()),
    date: String(t.date),
    payee: String(t.payee || '').trim(),
    amount,
    type: ['income', 'expense', 'transfer'].includes(t.type) ? t.type : 'expense',
    accountId: t.accountId ? String(t.accountId) : null,
    envelopeId: t.envelopeId ? String(t.envelopeId) : null,
    toAccountId: t.toAccountId ? String(t.toAccountId) : null,
    notes: String(t.notes || '').trim(),
    createdAt: String(t.createdAt || new Date().toISOString()),
  };
}

function sanitizeSettings(s) {
  if (!s || typeof s !== 'object') return Object.assign({}, DEFAULT_SETTINGS);
  return {
    currency: (typeof s.currency === 'string' && s.currency.trim()) ? s.currency.trim() : '$',
    firstDayOfMonth: typeof s.firstDayOfMonth === 'number' && isFinite(s.firstDayOfMonth)
      ? Math.min(28, Math.max(1, Math.floor(s.firstDayOfMonth))) : 1,
    theme: ['light', 'dark', 'system'].includes(s.theme) ? s.theme : 'system',
    reducedMotion: typeof s.reducedMotion === 'boolean' ? s.reducedMotion : false,
  };
}

function migrateState(raw) {
  if (!raw || typeof raw !== 'object') return deepClone(DEFAULT_STATE);
  // Future: if (raw.version < 2) { ... }
  return {
    version: STORAGE_VERSION,
    settings: sanitizeSettings(raw.settings),
    accounts: Array.isArray(raw.accounts)
      ? raw.accounts.map(sanitizeAccount).filter(Boolean)
      : [],
    envelopes: Array.isArray(raw.envelopes)
      ? raw.envelopes.map(sanitizeEnvelope).filter(Boolean)
      : [],
    transactions: Array.isArray(raw.transactions)
      ? raw.transactions.map(sanitizeTransaction).filter(Boolean)
      : [],
    currentMonth: (typeof raw.currentMonth === 'string' && /^\d{4}-\d{2}$/.test(raw.currentMonth))
      ? raw.currentMonth : null,
  };
}

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return deepClone(DEFAULT_STATE);
    const parsed = JSON.parse(raw);
    return migrateState(parsed);
  } catch (err) {
    console.warn('[storage] Failed to load state, using defaults:', err);
    return deepClone(DEFAULT_STATE);
  }
}

function saveState(state) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(Object.assign({}, state, { version: STORAGE_VERSION })));
    return true;
  } catch (err) {
    console.warn('[storage] Failed to save state:', err);
    return false;
  }
}

function clearState() {
  try {
    localStorage.removeItem(STORAGE_KEY);
    return true;
  } catch (_) {
    return false;
  }
}

function exportJSON(state) {
  const blob = new Blob([JSON.stringify(state, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'envelope-budget-' + new Date().toISOString().slice(0, 10) + '.json';
  document.body.appendChild(a);
  a.click();
  setTimeout(function() {
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }, 150);
}

function exportCSV(state) {
  var rows = [['Date', 'Payee/Description', 'Amount', 'Type', 'Account', 'Envelope', 'Notes']];
  var accountMap = {};
  state.accounts.forEach(function(a) { accountMap[a.id] = a.name; });
  var envelopeMap = {};
  state.envelopes.forEach(function(e) { envelopeMap[e.id] = e.name; });

  state.transactions.forEach(function(t) {
    rows.push([
      t.date,
      csvEscape(t.payee),
      t.amount.toFixed(2),
      t.type,
      csvEscape(t.accountId ? (accountMap[t.accountId] || '') : ''),
      csvEscape(t.envelopeId ? (envelopeMap[t.envelopeId] || '') : ''),
      csvEscape(t.notes),
    ]);
  });

  var csv = rows.map(function(r) { return r.join(','); }).join('\n');
  var blob = new Blob([csv], { type: 'text/csv' });
  var url = URL.createObjectURL(blob);
  var a = document.createElement('a');
  a.href = url;
  a.download = 'envelope-transactions-' + new Date().toISOString().slice(0, 10) + '.csv';
  document.body.appendChild(a);
  a.click();
  setTimeout(function() {
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }, 150);
}

function csvEscape(str) {
  if (str === null || str === undefined) return '';
  var s = String(str);
  if (s.indexOf(',') >= 0 || s.indexOf('"') >= 0 || s.indexOf('\n') >= 0) {
    return '"' + s.replace(/"/g, '""') + '"';
  }
  return s;
}

function importJSON(jsonString) {
  try {
    var parsed = JSON.parse(jsonString);
    var migrated = migrateState(parsed);
    return { ok: true, state: migrated };
  } catch (err) {
    return { ok: false, error: 'Could not parse this file. Please make sure it is a valid Envelope export.' };
  }
}

// Expose as globals (classic script, no bundler required)
window.Storage = {
  load: loadState,
  save: saveState,
  clear: clearState,
  exportJSON: exportJSON,
  exportCSV: exportCSV,
  importJSON: importJSON,
  generateId: generateId,
  DEFAULT_SETTINGS: Object.assign({}, DEFAULT_SETTINGS),
};
