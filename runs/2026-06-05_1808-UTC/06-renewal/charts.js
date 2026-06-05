/**
 * charts.js — Self-contained SVG/Canvas chart rendering.
 * Donut chart (category breakdown), bar chart, calendar grid.
 * No CDN dependencies. Pure DOM manipulation.
 */

'use strict';

const Charts = (() => {

  // ─── Color palette ────────────────────────────────────────────────────────

  const PALETTE = [
    '#7C6FCD', '#4A90D9', '#86C79A', '#E8A245',
    '#D97B6C', '#6BBFCF', '#B57EDC', '#5DA88B',
    '#E8C34A', '#C06B9A', '#7AB8E8', '#96C96B',
  ];

  function getCategoryColor(categories, catName, index) {
    const cat = categories.find(c => c.name === catName);
    if (cat && cat.color) return cat.color;
    return PALETTE[index % PALETTE.length];
  }

  // ─── Donut Chart (SVG) ────────────────────────────────────────────────────

  /**
   * Draw a donut chart for category breakdown.
   * @param {SVGElement} svg  — target SVG element
   * @param {Object} byCategory  — { catName: monthlyAmount }
   * @param {Array} categories   — category objects with color
   * @param {string} currencySymbol
   */
  function drawDonut(svg, byCategory, categories, currencySymbol) {
    // Clear
    while (svg.firstChild) svg.removeChild(svg.firstChild);

    const W = svg.clientWidth || 220;
    const H = svg.clientHeight || 220;
    const cx = W / 2;
    const cy = H / 2;
    const outerR = Math.min(cx, cy) - 8;
    const innerR = outerR * 0.58;

    const entries = Object.entries(byCategory).filter(([, v]) => v > 0);
    if (entries.length === 0) {
      _svgText(svg, cx, cy - 8, 'No data', '13px', 'var(--text-secondary)', 'middle');
      return;
    }

    const total = entries.reduce((s, [, v]) => s + v, 0);
    if (total <= 0) return;

    const ns = 'http://www.w3.org/2000/svg';
    let startAngle = -Math.PI / 2; // Start from top

    entries.forEach(([catName, amount], i) => {
      const frac = amount / total;
      const angle = frac * 2 * Math.PI;
      const endAngle = startAngle + angle;

      const color = getCategoryColor(categories, catName, i);

      // Slice path
      const path = document.createElementNS(ns, 'path');
      const d = _donutSlicePath(cx, cy, innerR, outerR, startAngle, endAngle);
      path.setAttribute('d', d);
      path.setAttribute('fill', color);
      path.setAttribute('opacity', '0.9');
      path.setAttribute('role', 'img');
      path.setAttribute('aria-label', `${catName}: ${(frac * 100).toFixed(1)}%`);

      // Hover tooltip via title
      const title = document.createElementNS(ns, 'title');
      title.textContent = `${catName}: ${currencySymbol}${amount.toFixed(2)}/mo (${(frac * 100).toFixed(1)}%)`;
      path.appendChild(title);

      path.style.transition = 'opacity 0.2s';
      path.addEventListener('mouseenter', () => { path.setAttribute('opacity', '1'); path.style.transform = 'scale(1.02)'; path.style.transformOrigin = `${cx}px ${cy}px`; });
      path.addEventListener('mouseleave', () => { path.setAttribute('opacity', '0.9'); path.style.transform = ''; });

      svg.appendChild(path);
      startAngle = endAngle;
    });

    // Center text
    const sym = currencySymbol || '$';
    _svgText(svg, cx, cy - 6, `${sym}${total.toFixed(0)}`, '16px', 'var(--text-primary)', 'middle', 'bold', '"JetBrains Mono", monospace');
    _svgText(svg, cx, cy + 14, 'per month', '11px', 'var(--text-secondary)', 'middle');
  }

  function _donutSlicePath(cx, cy, ir, or_, startA, endA) {
    const cos = Math.cos, sin = Math.sin;
    const x1 = cx + or_ * cos(startA);
    const y1 = cy + or_ * sin(startA);
    const x2 = cx + or_ * cos(endA);
    const y2 = cy + or_ * sin(endA);
    const x3 = cx + ir * cos(endA);
    const y3 = cy + ir * sin(endA);
    const x4 = cx + ir * cos(startA);
    const y4 = cy + ir * sin(startA);
    const large = endA - startA > Math.PI ? 1 : 0;
    return [
      `M ${x1} ${y1}`,
      `A ${or_} ${or_} 0 ${large} 1 ${x2} ${y2}`,
      `L ${x3} ${y3}`,
      `A ${ir} ${ir} 0 ${large} 0 ${x4} ${y4}`,
      'Z',
    ].join(' ');
  }

  function _svgText(svg, x, y, text, size, fill, anchor, weight, fontFamily) {
    const ns = 'http://www.w3.org/2000/svg';
    const el = document.createElementNS(ns, 'text');
    el.setAttribute('x', x);
    el.setAttribute('y', y);
    el.setAttribute('font-size', size);
    el.setAttribute('fill', fill);
    el.setAttribute('text-anchor', anchor || 'middle');
    el.setAttribute('dominant-baseline', 'auto');
    if (weight) el.setAttribute('font-weight', weight);
    if (fontFamily) el.setAttribute('font-family', fontFamily);
    el.textContent = text;
    svg.appendChild(el);
    return el;
  }

  // ─── Bar Chart (SVG) ──────────────────────────────────────────────────────

  /**
   * Draw a horizontal bar chart for category breakdown.
   * @param {HTMLElement} container  — target container div
   * @param {Object} byCategory      — { catName: monthlyAmount }
   * @param {Array} categories       — category objects
   * @param {string} currencySymbol
   */
  function drawBars(container, byCategory, categories, currencySymbol) {
    container.innerHTML = '';

    const entries = Object.entries(byCategory)
      .filter(([, v]) => v > 0)
      .sort((a, b) => b[1] - a[1]);

    if (entries.length === 0) {
      container.innerHTML = '<p class="empty-note">No active subscriptions to chart.</p>';
      return;
    }

    const maxVal = entries[0][1];
    const sym = currencySymbol || '$';

    entries.forEach(([catName, amount], i) => {
      const color = getCategoryColor(categories, catName, i);
      const pct = maxVal > 0 ? (amount / maxVal) * 100 : 0;

      const row = document.createElement('div');
      row.className = 'bar-row';
      row.innerHTML = `
        <span class="bar-label" title="${catName}">${catName}</span>
        <div class="bar-track" role="progressbar" aria-valuenow="${amount.toFixed(2)}" aria-valuemin="0" aria-valuemax="${maxVal.toFixed(2)}" aria-label="${catName}: ${sym}${amount.toFixed(2)}/mo">
          <div class="bar-fill" style="width:${pct}%;background:${color};"></div>
        </div>
        <span class="bar-value">${sym}${amount.toFixed(2)}</span>
      `;
      container.appendChild(row);
    });
  }

  // ─── Calendar Grid ────────────────────────────────────────────────────────

  /**
   * Draw a month calendar grid showing renewal days.
   *
   * @param {HTMLElement} container   — target div
   * @param {number} year
   * @param {number} month            — 0-indexed
   * @param {Object} renewalMap       — { "YYYY-MM-DD": [sub, ...] }
   * @param {number} weekStartsOn     — 0=Sun, 1=Mon
   * @param {Function} onDayClick     — (dateStr, subs) => void
   * @param {string} selectedDay      — "YYYY-MM-DD" or null
   */
  function drawCalendar(container, year, month, renewalMap, weekStartsOn, onDayClick, selectedDay) {
    container.innerHTML = '';

    const today = Billing.startOfDay(new Date());
    const todayStr = Billing.formatLocalDate(today);

    // Day headers
    const dayNames = weekStartsOn === 1
      ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    const headerRow = document.createElement('div');
    headerRow.className = 'cal-header-row';
    headerRow.setAttribute('aria-hidden', 'true');
    dayNames.forEach(d => {
      const cell = document.createElement('div');
      cell.className = 'cal-day-name';
      cell.textContent = d;
      headerRow.appendChild(cell);
    });
    container.appendChild(headerRow);

    // Compute first day of month and its weekday
    const firstOfMonth = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0).getDate();

    // Weekday index of the 1st (0=Sun … 6=Sat)
    let startWeekday = firstOfMonth.getDay(); // 0=Sun
    // Adjust for weekStartsOn
    const offset = ((startWeekday - weekStartsOn) + 7) % 7;

    const grid = document.createElement('div');
    grid.className = 'cal-grid';
    grid.setAttribute('role', 'grid');
    grid.setAttribute('aria-label', `${firstOfMonth.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}`);

    // Empty cells before 1st
    for (let i = 0; i < offset; i++) {
      const empty = document.createElement('div');
      empty.className = 'cal-cell cal-cell--empty';
      empty.setAttribute('role', 'gridcell');
      empty.setAttribute('aria-hidden', 'true');
      grid.appendChild(empty);
    }

    // Day cells
    for (let day = 1; day <= lastDay; day++) {
      const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
      const subs = renewalMap[dateStr] || [];
      const isToday = dateStr === todayStr;
      const isSelected = dateStr === selectedDay;
      const hasRenewals = subs.length > 0;

      const cell = document.createElement('button');
      cell.className = [
        'cal-cell',
        isToday ? 'cal-cell--today' : '',
        isSelected ? 'cal-cell--selected' : '',
        hasRenewals ? 'cal-cell--has-renewals' : '',
      ].filter(Boolean).join(' ');
      cell.setAttribute('role', 'gridcell');
      cell.setAttribute('type', 'button');
      cell.setAttribute('aria-pressed', isSelected ? 'true' : 'false');

      const label = [
        `${day}`,
        isToday ? '(today)' : '',
        hasRenewals ? `${subs.length} renewal${subs.length !== 1 ? 's' : ''}` : '',
      ].filter(Boolean).join(' ');
      cell.setAttribute('aria-label', label);

      const numEl = document.createElement('span');
      numEl.className = 'cal-day-num';
      numEl.textContent = day;
      cell.appendChild(numEl);

      if (hasRenewals) {
        const dotsEl = document.createElement('span');
        dotsEl.className = 'cal-dots';
        dotsEl.setAttribute('aria-hidden', 'true');
        // Show up to 3 dots
        const showCount = Math.min(subs.length, 3);
        for (let j = 0; j < showCount; j++) {
          const dot = document.createElement('span');
          dot.className = 'cal-dot';
          dotsEl.appendChild(dot);
        }
        if (subs.length > 3) {
          const more = document.createElement('span');
          more.className = 'cal-dot-more';
          more.textContent = `+${subs.length - 3}`;
          dotsEl.appendChild(more);
        }
        cell.appendChild(dotsEl);
      }

      if (onDayClick) {
        cell.addEventListener('click', () => onDayClick(dateStr, subs));
      }

      grid.appendChild(cell);
    }

    container.appendChild(grid);
  }

  // ─── Legend ───────────────────────────────────────────────────────────────

  /**
   * Build a legend element for the donut/bar chart.
   * @param {Object} byCategory
   * @param {Array} categories
   * @param {string} currencySymbol
   * @returns {HTMLElement}
   */
  function buildLegend(byCategory, categories, currencySymbol) {
    const total = Object.values(byCategory).reduce((s, v) => s + v, 0);
    const sym = currencySymbol || '$';

    const ul = document.createElement('ul');
    ul.className = 'chart-legend';
    ul.setAttribute('aria-label', 'Category breakdown legend');

    Object.entries(byCategory)
      .filter(([, v]) => v > 0)
      .sort((a, b) => b[1] - a[1])
      .forEach(([catName, amount], i) => {
        const color = getCategoryColor(categories, catName, i);
        const pct = total > 0 ? ((amount / total) * 100).toFixed(1) : '0.0';
        const li = document.createElement('li');
        li.className = 'legend-item';
        li.innerHTML = `
          <span class="legend-dot" style="background:${color}" aria-hidden="true"></span>
          <span class="legend-name">${_escHtml(catName)}</span>
          <span class="legend-pct">${pct}%</span>
          <span class="legend-amount">${sym}${amount.toFixed(2)}</span>
        `;
        ul.appendChild(li);
      });

    return ul;
  }

  function _escHtml(str) {
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  return {
    drawDonut,
    drawBars,
    drawCalendar,
    buildLegend,
    PALETTE,
    getCategoryColor,
  };

})();
