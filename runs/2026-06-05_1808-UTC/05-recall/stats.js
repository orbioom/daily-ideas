/**
 * stats.js — SVG/canvas statistics rendering for Recall.
 * Generates: review heatmap (12-week grid), reviews-per-day bars,
 * retention rate, upcoming-due forecast bar chart.
 * All functions are pure renderers — they write to DOM elements.
 */

'use strict';

/**
 * Build a map of date → count from the review log.
 * @param {Array} reviewLog
 * @returns {Object} { 'YYYY-MM-DD': count, ... }
 */
function buildDateCounts(reviewLog) {
  const counts = {};
  for (const entry of reviewLog) {
    const d = entry.date || '';
    if (d) counts[d] = (counts[d] || 0) + 1;
  }
  return counts;
}

/**
 * Compute retention rate: % of reviews with quality >= 3.
 * Guards against division by zero.
 * @param {Array} reviewLog
 * @returns {number} 0-100
 */
function computeRetention(reviewLog) {
  if (!reviewLog || reviewLog.length === 0) return 0;
  const good = reviewLog.filter(e => e.quality >= 3).length;
  return Math.round((good / reviewLog.length) * 100);
}

/**
 * Compute current streak: consecutive days ending today (or yesterday) with at least one review.
 * @param {Object} dateCounts
 * @param {string} today  YYYY-MM-DD
 * @returns {number}
 */
function computeStreak(dateCounts, today) {
  let streak = 0;
  let current = today;
  // Allow starting from yesterday if today has no reviews yet
  if (!dateCounts[current]) {
    current = SM2.addDays(today, -1);
    if (!dateCounts[current]) return 0;
  }
  while (dateCounts[current] > 0) {
    streak++;
    current = SM2.addDays(current, -1);
    if (!dateCounts[current]) break;
  }
  return streak;
}

/**
 * Render the 12-week review heatmap into an SVG element.
 * Weeks run left→right, days run top→bottom (Sun=0 … Sat=6).
 * @param {SVGElement} svgEl
 * @param {Array} reviewLog
 * @param {string} today  YYYY-MM-DD
 */
function renderHeatmap(svgEl, reviewLog, today) {
  const WEEKS = 12;
  const CELL = 14;
  const GAP = 3;
  const STEP = CELL + GAP;
  const PAD_TOP = 22;   // room for month labels
  const PAD_LEFT = 26;  // room for day labels

  svgEl.innerHTML = '';

  const counts = buildDateCounts(reviewLog);

  // Find max count for intensity scaling
  const maxCount = Math.max(1, ...Object.values(counts));

  // Determine the Sunday that starts 12 weeks before today
  // Parse today as local date
  const todayParts = today.split('-').map(Number);
  const todayDate = new Date(todayParts[0], todayParts[1] - 1, todayParts[2]);
  const todayDow = todayDate.getDay(); // 0=Sun
  // Start from the Sunday 12 weeks ago (or more) such that today falls in the last column
  const startDate = new Date(todayDate);
  startDate.setDate(startDate.getDate() - todayDow - (WEEKS - 1) * 7);

  const totalWidth = PAD_LEFT + WEEKS * STEP;
  const totalHeight = PAD_TOP + 7 * STEP;

  svgEl.setAttribute('width', totalWidth);
  svgEl.setAttribute('height', totalHeight);
  svgEl.setAttribute('viewBox', `0 0 ${totalWidth} ${totalHeight}`);
  svgEl.setAttribute('aria-label', 'Review activity heatmap for the last 12 weeks');
  svgEl.setAttribute('role', 'img');

  const ns = 'http://www.w3.org/2000/svg';

  // Day labels (Mon, Wed, Fri to avoid crowding)
  const dayLabels = ['', 'M', '', 'W', '', 'F', ''];
  for (let dow = 0; dow < 7; dow++) {
    if (!dayLabels[dow]) continue;
    const lbl = document.createElementNS(ns, 'text');
    lbl.setAttribute('x', PAD_LEFT - 4);
    lbl.setAttribute('y', PAD_TOP + dow * STEP + CELL - 3);
    lbl.setAttribute('text-anchor', 'end');
    lbl.setAttribute('class', 'heatmap-label');
    lbl.textContent = dayLabels[dow];
    svgEl.appendChild(lbl);
  }

  // Month labels — show month name when week crosses a month boundary
  let lastMonth = -1;
  for (let week = 0; week < WEEKS; week++) {
    const weekStart = new Date(startDate);
    weekStart.setDate(weekStart.getDate() + week * 7);
    const mo = weekStart.getMonth();
    if (mo !== lastMonth) {
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const lbl = document.createElementNS(ns, 'text');
      lbl.setAttribute('x', PAD_LEFT + week * STEP);
      lbl.setAttribute('y', PAD_TOP - 6);
      lbl.setAttribute('class', 'heatmap-label');
      lbl.textContent = months[mo];
      svgEl.appendChild(lbl);
      lastMonth = mo;
    }
  }

  // Draw cells
  for (let week = 0; week < WEEKS; week++) {
    for (let dow = 0; dow < 7; dow++) {
      const cellDate = new Date(startDate);
      cellDate.setDate(cellDate.getDate() + week * 7 + dow);
      const cellStr = SM2.isoDate(cellDate);

      // Skip future dates
      if (cellStr > today) continue;

      const count = counts[cellStr] || 0;
      const intensity = count === 0 ? 0 : Math.ceil((count / maxCount) * 4);

      const rect = document.createElementNS(ns, 'rect');
      rect.setAttribute('x', PAD_LEFT + week * STEP);
      rect.setAttribute('y', PAD_TOP + dow * STEP);
      rect.setAttribute('width', CELL);
      rect.setAttribute('height', CELL);
      rect.setAttribute('rx', 3);
      rect.setAttribute('class', 'heatmap-cell heatmap-cell-' + intensity);
      rect.setAttribute('aria-label', cellStr + ': ' + count + ' review' + (count === 1 ? '' : 's'));

      if (cellStr === today) {
        rect.setAttribute('class', rect.getAttribute('class') + ' heatmap-today');
      }

      // Tooltip via title
      const title = document.createElementNS(ns, 'title');
      title.textContent = cellStr + ': ' + count + (count === 1 ? ' review' : ' reviews');
      rect.appendChild(title);

      svgEl.appendChild(rect);
    }
  }
}

/**
 * Render a simple "upcoming due" bar chart for the next 7 days into an SVG element.
 * @param {SVGElement} svgEl
 * @param {Array} cards
 * @param {string} today YYYY-MM-DD
 */
function renderForecast(svgEl, cards, today) {
  const DAYS = 7;
  const BAR_MAX_H = 80;
  const BAR_W = 28;
  const GAP = 10;
  const PAD_TOP = 10;
  const PAD_BOT = 30; // room for day labels
  const PAD_LEFT = 8;

  svgEl.innerHTML = '';

  const ns = 'http://www.w3.org/2000/svg';
  const dayCounts = [];

  for (let i = 0; i < DAYS; i++) {
    const dateStr = SM2.addDays(today, i);
    // Count cards whose due date falls exactly on this day
    const count = cards.filter(c => c.dueDate === dateStr).length;
    dayCounts.push({ date: dateStr, count: count, label: i === 0 ? 'Today' : dayAbbr(dateStr) });
  }

  const maxCount = Math.max(1, ...dayCounts.map(d => d.count));
  const totalWidth = PAD_LEFT * 2 + DAYS * (BAR_W + GAP) - GAP;
  const totalHeight = PAD_TOP + BAR_MAX_H + PAD_BOT;

  svgEl.setAttribute('width', totalWidth);
  svgEl.setAttribute('height', totalHeight);
  svgEl.setAttribute('viewBox', `0 0 ${totalWidth} ${totalHeight}`);
  svgEl.setAttribute('aria-label', 'Cards due in the next 7 days');
  svgEl.setAttribute('role', 'img');

  dayCounts.forEach((day, i) => {
    const barH = day.count === 0 ? 2 : Math.max(4, Math.round((day.count / maxCount) * BAR_MAX_H));
    const x = PAD_LEFT + i * (BAR_W + GAP);
    const y = PAD_TOP + BAR_MAX_H - barH;

    const rect = document.createElementNS(ns, 'rect');
    rect.setAttribute('x', x);
    rect.setAttribute('y', y);
    rect.setAttribute('width', BAR_W);
    rect.setAttribute('height', barH);
    rect.setAttribute('rx', 4);
    rect.setAttribute('class', i === 0 ? 'forecast-bar forecast-bar-today' : 'forecast-bar');

    const title = document.createElementNS(ns, 'title');
    title.textContent = day.date + ': ' + day.count + ' card' + (day.count === 1 ? '' : 's') + ' due';
    rect.appendChild(title);
    svgEl.appendChild(rect);

    // Count label above bar
    if (day.count > 0) {
      const countLbl = document.createElementNS(ns, 'text');
      countLbl.setAttribute('x', x + BAR_W / 2);
      countLbl.setAttribute('y', y - 4);
      countLbl.setAttribute('text-anchor', 'middle');
      countLbl.setAttribute('class', 'forecast-count');
      countLbl.textContent = day.count;
      svgEl.appendChild(countLbl);
    }

    // Day label below bar
    const dayLbl = document.createElementNS(ns, 'text');
    dayLbl.setAttribute('x', x + BAR_W / 2);
    dayLbl.setAttribute('y', PAD_TOP + BAR_MAX_H + 18);
    dayLbl.setAttribute('text-anchor', 'middle');
    dayLbl.setAttribute('class', 'forecast-label');
    dayLbl.textContent = day.label;
    svgEl.appendChild(dayLbl);
  });
}

/**
 * Returns short day abbreviation (Mon, Tue, …) for a YYYY-MM-DD string.
 */
function dayAbbr(isoStr) {
  const parts = isoStr.split('-').map(Number);
  const d = new Date(parts[0], parts[1] - 1, parts[2]);
  return ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][d.getDay()];
}

/**
 * Compute per-day review counts for the last N days (for a simple text/number display).
 * Returns array of { date, count } sorted ascending.
 * @param {Array} reviewLog
 * @param {string} today
 * @param {number} days
 * @returns {Array}
 */
function reviewsPerDay(reviewLog, today, days) {
  const counts = buildDateCounts(reviewLog);
  const result = [];
  for (let i = days - 1; i >= 0; i--) {
    const d = SM2.addDays(today, -i);
    result.push({ date: d, count: counts[d] || 0 });
  }
  return result;
}

/**
 * Compute total reviews in the last N days.
 */
function totalReviewsInDays(reviewLog, today, days) {
  const counts = buildDateCounts(reviewLog);
  let total = 0;
  for (let i = 0; i < days; i++) {
    total += counts[SM2.addDays(today, -i)] || 0;
  }
  return total;
}

const Stats = {
  renderHeatmap,
  renderForecast,
  computeRetention,
  computeStreak,
  buildDateCounts,
  reviewsPerDay,
  totalReviewsInDays
};
