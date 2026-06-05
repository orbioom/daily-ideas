/**
 * billing.js — Pure cost-normalization and next-renewal date math.
 * No DOM, no side effects. Fully testable.
 */

'use strict';

const Billing = (() => {

  // ─── Date helpers ─────────────────────────────────────────────────────────

  /**
   * Parse an ISO date string (YYYY-MM-DD) as a LOCAL date (midnight local).
   * Returns null if invalid.
   */
  function parseLocalDate(str) {
    if (!str || typeof str !== 'string') return null;
    const m = str.match(/^(\d{4})-(\d{2})-(\d{2})$/);
    if (!m) return null;
    const year = parseInt(m[1], 10);
    const month = parseInt(m[2], 10) - 1;
    const day = parseInt(m[3], 10);
    const d = new Date(year, month, day);
    if (d.getFullYear() !== year || d.getMonth() !== month || d.getDate() !== day) return null;
    return d;
  }

  /**
   * Format a Date as YYYY-MM-DD (local).
   */
  function formatLocalDate(d) {
    if (!(d instanceof Date) || isNaN(d.getTime())) return '';
    const y = d.getFullYear();
    const mo = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${mo}-${day}`;
  }

  /** Midnight of any Date (local). */
  function startOfDay(d) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate());
  }

  /**
   * Add N calendar months to a date, preserving the "preferred day" (anchor day).
   * If the target month is shorter, clamp to its last day.
   * e.g. Jan 31 + 1 month  → Feb 28/29
   *      Jan 31 + 2 months → Mar 31
   */
  function addMonths(date, n, preferredDay) {
    const pd = preferredDay !== undefined ? preferredDay : date.getDate();
    const rawMonth = date.getMonth() + n;
    const newYear = date.getFullYear() + Math.floor(rawMonth / 12);
    const newMonth = ((rawMonth % 12) + 12) % 12;
    const lastDay = new Date(newYear, newMonth + 1, 0).getDate();
    const clamped = Math.min(pd, lastDay);
    return new Date(newYear, newMonth, clamped);
  }

  // ─── Cost normalization ────────────────────────────────────────────────────

  /** Monthly-equivalent cost (handle all cycles including custom-N-days). */
  function toMonthly(sub) {
    const amount = Number(sub.amount) || 0;
    if (amount <= 0) return 0;
    switch (sub.cycle) {
      case 'weekly':     return amount * 52 / 12;
      case 'monthly':    return amount;
      case 'quarterly':  return amount / 3;
      case 'semiannual': return amount / 6;
      case 'yearly':     return amount / 12;
      case 'custom': {
        const d = Math.max(1, Number(sub.customDays) || 1);
        return amount * (365 / d) / 12;
      }
      default:           return amount;
    }
  }

  /** Yearly-equivalent cost. */
  function toYearly(sub) {
    const amount = Number(sub.amount) || 0;
    if (amount <= 0) return 0;
    switch (sub.cycle) {
      case 'weekly':     return amount * 52;
      case 'monthly':    return amount * 12;
      case 'quarterly':  return amount * 4;
      case 'semiannual': return amount * 2;
      case 'yearly':     return amount;
      case 'custom': {
        const d = Math.max(1, Number(sub.customDays) || 1);
        return amount * (365 / d);
      }
      default:           return amount * 12;
    }
  }

  // ─── Next renewal date ─────────────────────────────────────────────────────

  function _stepByDays(anchor, today, stepDays) {
    const diffMs = today - anchor;
    const diffDays = Math.ceil(diffMs / 86400000);
    const steps = Math.ceil(diffDays / stepDays);
    return new Date(anchor.getTime() + steps * stepDays * 86400000);
  }

  function _stepByMonths(anchor, today, stepMonths) {
    const preferredDay = anchor.getDate();
    const diffMs = today - anchor;
    const diffDays = diffMs / 86400000;
    const approxPeriodDays = stepMonths * 30.4375;
    let n = Math.max(0, Math.floor(diffDays / approxPeriodDays) - 1);

    let candidate = addMonths(anchor, n * stepMonths, preferredDay);
    // Walk forward until candidate >= today
    while (candidate < today) {
      n++;
      candidate = addMonths(anchor, n * stepMonths, preferredDay);
    }
    return candidate;
  }

  /**
   * Compute the next renewal date >= today for a subscription.
   *
   * Month-end edge cases: anchoring on the 31st will correctly clamp to Feb 28/29
   * for monthly cycles, and step back to Mar 31, Apr 30, etc.
   *
   * Example: Jan 31 monthly anchor →
   *   Feb 28 (or 29 in leap year) → Mar 31 → Apr 30 → May 31 …
   *
   * @param {string} anchorDateStr  YYYY-MM-DD anchor/first billing date
   * @param {string} cycle
   * @param {number} customDays     only used when cycle === 'custom'
   * @param {Date}   [todayOverride] for testing
   * @returns {Date|null}
   */
  function nextRenewal(anchorDateStr, cycle, customDays, todayOverride) {
    const anchor = parseLocalDate(anchorDateStr);
    if (!anchor) return null;

    const today = startOfDay(todayOverride || new Date());

    // Anchor is today or future → that IS the next renewal
    if (anchor >= today) return anchor;

    switch (cycle) {
      case 'weekly':     return _stepByDays(anchor, today, 7);
      case 'monthly':    return _stepByMonths(anchor, today, 1);
      case 'quarterly':  return _stepByMonths(anchor, today, 3);
      case 'semiannual': return _stepByMonths(anchor, today, 6);
      case 'yearly':     return _stepByMonths(anchor, today, 12);
      case 'custom': {
        const d = Math.max(1, Number(customDays) || 1);
        return _stepByDays(anchor, today, d);
      }
      default:           return _stepByMonths(anchor, today, 1);
    }
  }

  /** Days until next renewal (>=0). */
  function daysUntilRenewal(anchorDateStr, cycle, customDays, todayOverride) {
    const next = nextRenewal(anchorDateStr, cycle, customDays, todayOverride);
    if (!next) return null;
    const today = startOfDay(todayOverride || new Date());
    return Math.max(0, Math.round((next - today) / 86400000));
  }

  /** Human-readable relative label. */
  function relativeRenewalLabel(anchorDateStr, cycle, customDays, todayOverride) {
    const days = daysUntilRenewal(anchorDateStr, cycle, customDays, todayOverride);
    if (days === null) return '—';
    if (days === 0) return 'Today';
    if (days === 1) return 'Tomorrow';
    if (days <= 14) return `in ${days} days`;
    const next = nextRenewal(anchorDateStr, cycle, customDays, todayOverride);
    return next ? next.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }) : '—';
  }

  /** Subscriptions renewing within [0, windowDays] from today (active only). */
  function renewingSoon(subscriptions, windowDays, todayOverride) {
    const today = startOfDay(todayOverride || new Date());
    const cutoff = new Date(today.getTime() + windowDays * 86400000);

    return subscriptions
      .filter(s => s.status === 'active')
      .map(s => {
        const next = nextRenewal(s.anchorDate, s.cycle, s.customDays, today);
        return { sub: s, next };
      })
      .filter(({ next }) => next && next <= cutoff)
      .sort((a, b) => a.next - b.next);
  }

  /** Subscriptions with free trial ending within [0, windowDays] (active only). */
  function trialsEndingSoon(subscriptions, windowDays, todayOverride) {
    const today = startOfDay(todayOverride || new Date());
    const cutoff = new Date(today.getTime() + windowDays * 86400000);
    return subscriptions
      .filter(s => s.trialEnds && s.status === 'active')
      .map(s => {
        const trialDate = parseLocalDate(s.trialEnds);
        return { sub: s, trialDate };
      })
      .filter(({ trialDate }) => trialDate && trialDate >= today && trialDate <= cutoff)
      .sort((a, b) => a.trialDate - b.trialDate);
  }

  /** Aggregate totals for active subscriptions only. */
  function computeTotals(subscriptions) {
    const active = subscriptions.filter(s => s.status === 'active');
    let monthly = 0;
    let yearly = 0;
    const byCategory = {};
    const byPayment = {};

    for (const s of active) {
      const m = toMonthly(s);
      const y = toYearly(s);
      monthly += m;
      yearly += y;

      const cat = (s.category || 'Uncategorized').trim() || 'Uncategorized';
      byCategory[cat] = (byCategory[cat] || 0) + m;

      const pm = (s.paymentMethod || 'Unknown').trim() || 'Unknown';
      byPayment[pm] = (byPayment[pm] || 0) + m;
    }

    return { monthly, yearly, byCategory, byPayment, count: active.length };
  }

  /**
   * Get all renewal dates for a given calendar month.
   * Returns a map: { "YYYY-MM-DD": [sub, sub, ...] }
   */
  function renewalsInMonth(subscriptions, year, month) {
    const map = {};
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);

    const relevant = subscriptions.filter(s => s.status === 'active' || s.status === 'paused');

    for (const sub of relevant) {
      const anchor = parseLocalDate(sub.anchorDate);
      if (!anchor) continue;

      // Find first occurrence in or after the first day of this month
      let date = nextRenewal(sub.anchorDate, sub.cycle, sub.customDays, firstDay);
      while (date && date <= lastDay) {
        const key = formatLocalDate(date);
        if (!map[key]) map[key] = [];
        map[key].push(sub);
        // Advance to next occurrence
        date = _nextOccurrenceAfter(date, sub.cycle, sub.customDays, anchor.getDate());
      }
    }
    return map;
  }

  /** One cycle-step after `from`. */
  function _nextOccurrenceAfter(from, cycle, customDays, preferredDay) {
    switch (cycle) {
      case 'weekly':     return new Date(from.getTime() + 7 * 86400000);
      case 'monthly':    return addMonths(from, 1, preferredDay);
      case 'quarterly':  return addMonths(from, 3, preferredDay);
      case 'semiannual': return addMonths(from, 6, preferredDay);
      case 'yearly':     return addMonths(from, 12, preferredDay);
      case 'custom': {
        const d = Math.max(1, Number(customDays) || 1);
        return new Date(from.getTime() + d * 86400000);
      }
      default:           return addMonths(from, 1, preferredDay);
    }
  }

  /** Format amount as currency string. */
  function formatAmount(amount, currencySymbol) {
    const sym = currencySymbol != null ? currencySymbol : '$';
    const n = Number(amount) || 0;
    return `${sym}${n.toFixed(2)}`;
  }

  /** Human-readable cycle label. */
  function cycleLabel(cycle, customDays) {
    switch (cycle) {
      case 'weekly':     return 'Weekly';
      case 'monthly':    return 'Monthly';
      case 'quarterly':  return 'Quarterly';
      case 'semiannual': return 'Semiannual';
      case 'yearly':     return 'Yearly';
      case 'custom':     return `Every ${customDays || '?'} days`;
      default:           return cycle || 'Monthly';
    }
  }

  // ─── Self-test for Jan 31 monthly anchor ──────────────────────────────────
  // nextRenewal('2024-01-31', 'monthly') when today=2024-03-01 should be 2024-03-31
  // (Feb 29 2024 was skipped by _stepByMonths → addMonths(2024-01-31, 2) = Mar 31)

  return {
    toMonthly,
    toYearly,
    nextRenewal,
    daysUntilRenewal,
    relativeRenewalLabel,
    renewingSoon,
    trialsEndingSoon,
    computeTotals,
    renewalsInMonth,
    parseLocalDate,
    formatLocalDate,
    formatAmount,
    cycleLabel,
    addMonths,
    startOfDay,
  };

})();
