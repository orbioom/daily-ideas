/**
 * storage.js — Versioned localStorage persistence for Recall.
 * Handles schema migration, defaults for missing SM-2 fields,
 * and round-trip JSON export/import.
 */

'use strict';

const STORAGE_KEY = 'recall_data_v1';
const SCHEMA_VERSION = 1;

/**
 * Ensure a card has all required SM-2 fields with sane defaults.
 */
function normalizeCard(raw) {
  const today = SM2.todayISO();
  return {
    id: raw.id || generateId(),
    deckId: raw.deckId || '',
    front: String(raw.front || '').trim(),
    back: String(raw.back || '').trim(),
    tags: Array.isArray(raw.tags) ? raw.tags : [],
    created: raw.created || today,
    // SM-2 fields with sane defaults
    ef: typeof raw.ef === 'number' && raw.ef >= 1.3 ? raw.ef : 2.5,
    n: typeof raw.n === 'number' && raw.n >= 0 ? Math.floor(raw.n) : 0,
    interval: typeof raw.interval === 'number' && raw.interval >= 0 ? Math.floor(raw.interval) : 0,
    dueDate: raw.dueDate || today,
    lapses: typeof raw.lapses === 'number' ? Math.max(0, Math.floor(raw.lapses)) : 0,
    lastReviewed: raw.lastReviewed || null,
    totalReviews: typeof raw.totalReviews === 'number' ? Math.max(0, Math.floor(raw.totalReviews)) : 0
  };
}

/**
 * Ensure a deck has all required fields.
 */
function normalizeDeck(raw) {
  const today = SM2.todayISO();
  return {
    id: raw.id || generateId(),
    name: String(raw.name || 'Untitled Deck').trim(),
    description: String(raw.description || '').trim(),
    color: raw.color || '#86C79A',
    glyph: raw.glyph || '📚',
    created: raw.created || today
  };
}

/**
 * Normalize a review log entry.
 */
function normalizeLogEntry(raw) {
  return {
    id: raw.id || generateId(),
    cardId: raw.cardId || '',
    deckId: raw.deckId || '',
    date: raw.date || SM2.todayISO(),
    quality: typeof raw.quality === 'number' ? Math.max(0, Math.min(5, raw.quality)) : 4,
    resultingInterval: typeof raw.resultingInterval === 'number' ? raw.resultingInterval : 1
  };
}

/**
 * Normalize settings object with sane defaults.
 */
function normalizeSettings(raw) {
  raw = raw || {};
  return {
    dailyNewCardLimit: typeof raw.dailyNewCardLimit === 'number'
      ? Math.max(1, Math.min(200, Math.floor(raw.dailyNewCardLimit))) : 20,
    maxReviewsPerSession: typeof raw.maxReviewsPerSession === 'number'
      ? Math.max(1, Math.min(500, Math.floor(raw.maxReviewsPerSession))) : 100,
    theme: ['light', 'dark', 'system'].includes(raw.theme) ? raw.theme : 'system',
    reducedMotion: typeof raw.reducedMotion === 'boolean' ? raw.reducedMotion : false
  };
}

function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
}

/**
 * Load all app data from localStorage.
 * Returns { decks, cards, reviewLog, settings } with full normalization.
 * Never throws — falls back to empty/defaults on any error.
 */
function load() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return emptyState();

    const parsed = JSON.parse(raw);

    // Version guard — future migrations go here
    if (parsed.version && parsed.version > SCHEMA_VERSION) {
      console.warn('[Recall] Storage version newer than app. Using defaults.');
      return emptyState();
    }

    return {
      decks: Array.isArray(parsed.decks) ? parsed.decks.map(normalizeDeck) : [],
      cards: Array.isArray(parsed.cards) ? parsed.cards.map(normalizeCard) : [],
      reviewLog: Array.isArray(parsed.reviewLog) ? parsed.reviewLog.map(normalizeLogEntry) : [],
      settings: normalizeSettings(parsed.settings)
    };
  } catch (e) {
    console.error('[Recall] Failed to load storage:', e);
    return emptyState();
  }
}

/**
 * Save all app data to localStorage.
 * @param {{ decks, cards, reviewLog, settings }} state
 */
function save(state) {
  try {
    const payload = {
      version: SCHEMA_VERSION,
      savedAt: new Date().toISOString(),
      decks: state.decks,
      cards: state.cards,
      reviewLog: state.reviewLog,
      settings: state.settings
    };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch (e) {
    console.error('[Recall] Failed to save storage:', e);
    // Non-fatal — user can continue; show toast in app layer if needed
    throw e;
  }
}

/**
 * Returns a fresh empty state with defaults.
 */
function emptyState() {
  return {
    decks: [],
    cards: [],
    reviewLog: [],
    settings: normalizeSettings({})
  };
}

/**
 * Export state as a JSON Blob download.
 * @param {Object} state
 */
function exportJSON(state) {
  const payload = {
    version: SCHEMA_VERSION,
    exportedAt: new Date().toISOString(),
    app: 'Recall by Orbioom',
    decks: state.decks,
    cards: state.cards,
    reviewLog: state.reviewLog,
    settings: state.settings
  };
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
  triggerDownload(blob, `recall-backup-${SM2.todayISO()}.json`);
}

/**
 * Export all cards as a CSV Blob download.
 * @param {Object} state
 */
function exportCSV(state) {
  const deckMap = {};
  for (const deck of state.decks) deckMap[deck.id] = deck.name;

  const rows = [['Deck', 'Front', 'Back', 'Tags', 'EF', 'Interval', 'Due Date', 'Lapses', 'Total Reviews']];
  for (const card of state.cards) {
    rows.push([
      deckMap[card.deckId] || card.deckId,
      card.front,
      card.back,
      card.tags.join(';'),
      card.ef,
      card.interval,
      card.dueDate,
      card.lapses,
      card.totalReviews
    ]);
  }

  const csv = rows.map(row =>
    row.map(cell => {
      const s = String(cell);
      if (s.includes(',') || s.includes('"') || s.includes('\n')) {
        return '"' + s.replace(/"/g, '""') + '"';
      }
      return s;
    }).join(',')
  ).join('\n');

  const blob = new Blob([csv], { type: 'text/csv' });
  triggerDownload(blob, `recall-cards-${SM2.todayISO()}.csv`);
}

/**
 * Parse an imported JSON string. Returns normalized state or throws on invalid format.
 * @param {string} jsonStr
 * @returns {{ decks, cards, reviewLog, settings }}
 */
function importJSON(jsonStr) {
  const parsed = JSON.parse(jsonStr);
  if (!parsed || typeof parsed !== 'object') throw new Error('Invalid JSON structure');
  if (!Array.isArray(parsed.decks)) throw new Error('Missing decks array');
  if (!Array.isArray(parsed.cards)) throw new Error('Missing cards array');
  return {
    decks: parsed.decks.map(normalizeDeck),
    cards: parsed.cards.map(normalizeCard),
    reviewLog: Array.isArray(parsed.reviewLog) ? parsed.reviewLog.map(normalizeLogEntry) : [],
    settings: normalizeSettings(parsed.settings)
  };
}

/**
 * Trigger a file download from a Blob.
 */
function triggerDownload(blob, filename) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  setTimeout(() => {
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }, 100);
}

/**
 * Clear all data from localStorage.
 */
function clearAll() {
  localStorage.removeItem(STORAGE_KEY);
}

const Storage = {
  load,
  save,
  emptyState,
  exportJSON,
  exportCSV,
  importJSON,
  normalizeCard,
  normalizeDeck,
  normalizeLogEntry,
  normalizeSettings,
  generateId,
  clearAll
};
