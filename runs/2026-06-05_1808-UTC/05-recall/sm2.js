/**
 * sm2.js — Pure SuperMemo SM-2 scheduling algorithm
 * Based on: https://www.supermemo.com/en/archives1990-2015/english/ol/sm2
 * Algorithm by Piotr Wozniak. No side effects; all pure functions.
 */

'use strict';

// Quality ratings mapped from UI buttons
const SM2_QUALITY = {
  AGAIN: 1,  // q=1 (complete blackout / again)
  HARD:  3,  // q=3 (correct but significant difficulty)
  GOOD:  4,  // q=4 (correct after hesitation)
  EASY:  5   // q=5 (perfect immediate recall)
};

/**
 * Default SM-2 state for a brand new card.
 */
function newCardState() {
  return {
    ef: 2.5,         // easiness factor
    n: 0,            // repetition count
    interval: 0,     // interval in days
    dueDate: todayISO(), // due immediately
    lapses: 0,       // count of times q < 3
    lastReviewed: null,
    totalReviews: 0
  };
}

/**
 * Get today's date as YYYY-MM-DD string (local time).
 */
function todayISO() {
  const d = new Date();
  return isoDate(d);
}

/**
 * Convert a Date to YYYY-MM-DD string (local time).
 */
function isoDate(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

/**
 * Add N days to a YYYY-MM-DD string, return new YYYY-MM-DD string.
 * Uses local time arithmetic to avoid DST boundary issues.
 */
function addDays(isoStr, n) {
  // Parse as local date to avoid UTC offset issues
  const [y, m, d] = isoStr.split('-').map(Number);
  const date = new Date(y, m - 1, d);
  date.setDate(date.getDate() + n);
  return isoDate(date);
}

/**
 * Compare two ISO date strings. Returns negative if a < b, 0 if equal, positive if a > b.
 */
function compareDates(a, b) {
  return a < b ? -1 : a > b ? 1 : 0;
}

/**
 * Returns true if the card is due on or before today.
 */
function isDue(cardState, today) {
  const ref = today || todayISO();
  return compareDates(cardState.dueDate, ref) <= 0;
}

/**
 * Compute the new interval for a given quality rating and current state.
 * Returns the new interval in days (integer).
 *
 * SM-2 interval rules:
 *   q < 3  → I = 1 (lapse)
 *   q >= 3 → n=0: I=1; n=1: I=6; else: I = round(I_prev * EF)
 */
function computeInterval(state, q) {
  if (q < 3) {
    return 1;
  }
  if (state.n === 0) return 1;
  if (state.n === 1) return 6;
  return Math.max(1, Math.round(state.interval * state.ef));
}

/**
 * Compute the new easiness factor after a review with quality q.
 * EF = EF + (0.1 − (5−q)×(0.08 + (5−q)×0.02))
 * Clamped to minimum 1.3.
 */
function computeEF(currentEF, q) {
  const delta = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
  return Math.max(1.3, currentEF + delta);
}

/**
 * Apply a review to a card's SM-2 state.
 * @param {Object} state - Current SM-2 state (ef, n, interval, dueDate, lapses, lastReviewed, totalReviews)
 * @param {number} q     - Quality rating 0-5
 * @param {string} today - Optional ISO date string for "today" (defaults to actual today)
 * @returns {Object} New state (immutable — does not mutate input)
 */
function applyReview(state, q, today) {
  const ref = today || todayISO();

  // Clamp q to valid range
  q = Math.max(0, Math.min(5, Math.round(q)));

  const newEF = computeEF(state.ef, q);
  const newInterval = computeInterval(state, q);

  let newN;
  let newLapses = state.lapses || 0;

  if (q < 3) {
    newN = 0;
    newLapses = newLapses + 1;
  } else {
    newN = (state.n || 0) + 1;
  }

  const newDueDate = addDays(ref, newInterval);

  return {
    ef: Math.round(newEF * 100) / 100, // round to 2dp for storage
    n: newN,
    interval: newInterval,
    dueDate: newDueDate,
    lapses: newLapses,
    lastReviewed: ref,
    totalReviews: (state.totalReviews || 0) + 1
  };
}

/**
 * Preview what interval would result from each rating choice,
 * given the current card state. Returns an object keyed by rating name.
 * Used to show "Good · 6d" etc. on buttons.
 */
function previewIntervals(state) {
  const ratings = { AGAIN: 1, HARD: 3, GOOD: 4, EASY: 5 };
  const result = {};
  for (const [name, q] of Object.entries(ratings)) {
    result[name] = computeInterval(state, q);
  }
  return result;
}

/**
 * Format an interval in days to a human-readable string.
 * E.g. 1 → "1d", 7 → "7d", 30 → "30d", 365 → "1y"
 */
function formatInterval(days) {
  if (days < 1) return '<1d';
  if (days === 1) return '1d';
  if (days < 365) return `${days}d`;
  const years = Math.round(days / 365 * 10) / 10;
  return `${years}y`;
}

/**
 * Sort cards by due date ascending (most overdue first).
 */
function sortByDue(cards) {
  return [...cards].sort((a, b) => compareDates(a.dueDate, b.dueDate));
}

/**
 * Filter cards that are due on or before today.
 */
function getDueCards(cards, today) {
  const ref = today || todayISO();
  return cards.filter(c => isDue(c, ref));
}

// Expose for global use (no module bundler needed)
const SM2 = {
  newCardState,
  applyReview,
  previewIntervals,
  formatInterval,
  isDue,
  getDueCards,
  sortByDue,
  todayISO,
  addDays,
  isoDate,
  computeInterval,
  computeEF,
  QUALITY: SM2_QUALITY
};
