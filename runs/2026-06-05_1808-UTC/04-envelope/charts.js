/**
 * charts.js — Canvas/SVG spending charts for Envelope.
 * No external chart libraries. Drawn natively with Canvas 2D and inline SVG.
 */

function getStyleVar(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}

function escSVG(str) {
  return String(str || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

window.Charts = {
  /**
   * Draw a donut chart on a <canvas> element.
   * @param {HTMLCanvasElement} canvas
   * @param {Array<{label: string, value: number, color: string}>} segments
   * @param {string} centerLabel - big number text in the middle
   * @param {string} centerSub - smaller label beneath
   */
  drawDonut: function(canvas, segments, centerLabel, centerSub) {
    if (!canvas) return;
    var ctx = canvas.getContext('2d');
    if (!ctx) return;

    var dpr = window.devicePixelRatio || 1;
    var size = canvas.clientWidth || 220;
    canvas.width = Math.round(size * dpr);
    canvas.height = Math.round(size * dpr);
    ctx.scale(dpr, dpr);

    var cx = size / 2;
    var cy = size / 2;
    var outerR = size * 0.42;
    var innerR = size * 0.26;

    ctx.clearRect(0, 0, size, size);

    var total = segments.reduce(function(s, seg) { return s + (seg.value > 0 ? seg.value : 0); }, 0);

    if (total <= 0) {
      // Empty ring
      ctx.beginPath();
      ctx.arc(cx, cy, outerR, 0, Math.PI * 2, false);
      ctx.arc(cx, cy, innerR, 0, Math.PI * 2, true);
      ctx.fillStyle = 'rgba(139,143,163,0.15)';
      ctx.fill();
      renderCenter(ctx, cx, cy, centerLabel, centerSub, size);
      return;
    }

    var gap = segments.length > 1 ? 0.03 : 0;
    var totalGap = gap * segments.length;
    var startAngle = -Math.PI / 2;

    for (var i = 0; i < segments.length; i++) {
      var seg = segments[i];
      if (!seg.value || seg.value <= 0) continue;
      var slice = (seg.value / total) * (Math.PI * 2 - totalGap);
      var endAngle = startAngle + slice;

      ctx.beginPath();
      ctx.moveTo(cx + Math.cos(startAngle) * innerR, cy + Math.sin(startAngle) * innerR);
      ctx.arc(cx, cy, outerR, startAngle, endAngle, false);
      ctx.arc(cx, cy, innerR, endAngle, startAngle, true);
      ctx.closePath();
      ctx.fillStyle = seg.color;
      ctx.fill();

      startAngle = endAngle + gap;
    }

    renderCenter(ctx, cx, cy, centerLabel, centerSub, size);

    function renderCenter(ctx, cx, cy, label, sub, size) {
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';

      var primaryColor = getStyleVar('--text-primary') || '#1B1D2A';
      var secondaryColor = getStyleVar('--text-secondary') || '#565A70';

      ctx.font = 'bold ' + Math.round(size * 0.125) + "px 'JetBrains Mono', ui-monospace, monospace";
      ctx.fillStyle = primaryColor;
      ctx.fillText(String(label || ''), cx, cy - (sub ? size * 0.05 : 0));

      if (sub) {
        ctx.font = Math.round(size * 0.065) + "px 'Manrope', system-ui, sans-serif";
        ctx.fillStyle = secondaryColor;
        ctx.fillText(String(sub), cx, cy + size * 0.095);
      }
    }
  },

  /**
   * Build an inline SVG bar chart for spending by group.
   * @param {Array<{label: string, value: number, color: string}>} bars
   * @param {string} currency
   * @param {number} width
   * @returns {string} SVG markup string
   */
  buildGroupBarSVG: function(bars, currency, width) {
    currency = currency || '$';
    width = width || 480;

    if (!bars || bars.length === 0) {
      return '<svg width="' + width + '" height="60" aria-label="No spending data" xmlns="http://www.w3.org/2000/svg">'
        + '<text x="' + (width / 2) + '" y="34" text-anchor="middle" '
        + 'font-family="Manrope,system-ui,sans-serif" font-size="13" fill="#8B8FA3">'
        + 'No spending data for this month.</text></svg>';
    }

    var barH = 30;
    var gap = 12;
    var labelW = 130;
    var amountW = 80;
    var barAreaW = width - labelW - amountW - 12;
    var height = bars.length * (barH + gap) + 16;
    var maxVal = Math.max.apply(null, bars.map(function(b) { return b.value; }));
    if (maxVal <= 0) maxVal = 1;

    var parts = [
      '<svg width="' + width + '" height="' + height + '" role="img" '
      + 'aria-label="Spending by group" xmlns="http://www.w3.org/2000/svg" style="overflow:visible">'
    ];

    bars.forEach(function(bar, i) {
      var y = 8 + i * (barH + gap);
      var barW = bar.value > 0 ? Math.max((bar.value / maxVal) * barAreaW, 4) : 0;
      var bx = labelW;

      // Label text
      parts.push(
        '<text x="' + (labelW - 10) + '" y="' + (y + barH / 2 + 5) + '" '
        + 'text-anchor="end" font-family="Manrope,system-ui,sans-serif" font-size="13" '
        + 'fill="var(--text-secondary,#565A70)">' + escSVG(bar.label) + '</text>'
      );

      // Track background
      parts.push(
        '<rect x="' + bx + '" y="' + y + '" width="' + barAreaW + '" height="' + barH + '" '
        + 'rx="6" fill="rgba(139,143,163,0.12)"/>'
      );

      // Value bar
      if (barW > 0) {
        parts.push(
          '<rect x="' + bx + '" y="' + y + '" width="' + barW.toFixed(1) + '" height="' + barH + '" '
          + 'rx="6" fill="' + escSVG(bar.color) + '"/>'
        );
      }

      // Amount label
      parts.push(
        '<text x="' + (bx + barAreaW + 8) + '" y="' + (y + barH / 2 + 5) + '" '
        + "font-family=\"'JetBrains Mono',ui-monospace,monospace\" font-size=\"12\" "
        + 'fill="var(--text-primary,#1B1D2A)">'
        + escSVG(currency) + escSVG(bar.value.toFixed(2)) + '</text>'
      );
    });

    parts.push('</svg>');
    return parts.join('\n');
  },

  /**
   * Build an SVG showing top envelopes by spending, with progress bars.
   * @param {Array<{name: string, icon: string, spent: number, budgeted: number}>} envelopes
   * @param {string} currency
   * @param {number} width
   * @returns {string} SVG markup string
   */
  buildTopEnvelopesSVG: function(envelopes, currency, width) {
    currency = currency || '$';
    width = width || 480;

    if (!envelopes || envelopes.length === 0) {
      return '<svg width="' + width + '" height="40" xmlns="http://www.w3.org/2000/svg">'
        + '<text x="' + (width / 2) + '" y="24" text-anchor="middle" '
        + 'font-family="Manrope,system-ui,sans-serif" font-size="13" fill="#8B8FA3">'
        + 'No envelopes yet.</text></svg>';
    }

    var rowH = 38;
    var height = envelopes.length * rowH + 8;
    var nameW = 140;
    var trackW = width - nameW - 90;

    var parts = [
      '<svg width="' + width + '" height="' + height + '" role="img" '
      + 'aria-label="Top envelopes by spending" xmlns="http://www.w3.org/2000/svg">'
    ];

    envelopes.forEach(function(env, i) {
      var y = 4 + i * rowH;
      var mid = y + rowH / 2;
      var pct = (env.budgeted > 0) ? Math.min(env.spent / env.budgeted, 1) : (env.spent > 0 ? 1 : 0);
      var overspent = env.spent > env.budgeted && env.budgeted > 0;
      var fillColor = overspent ? '#EF6C6C' : '#86C79A';
      var barFillW = Math.max(pct * trackW, env.spent > 0 ? 4 : 0);

      // Icon
      parts.push(
        '<text x="2" y="' + (mid + 6) + '" font-size="16" font-family="sans-serif">'
        + escSVG(env.icon) + '</text>'
      );

      // Name
      parts.push(
        '<text x="28" y="' + (mid + 5) + '" font-family="Manrope,system-ui,sans-serif" '
        + 'font-size="13" fill="var(--text-primary,#1B1D2A)">' + escSVG(env.name) + '</text>'
      );

      // Track
      parts.push(
        '<rect x="' + nameW + '" y="' + (mid - 7) + '" width="' + trackW + '" height="14" '
        + 'rx="4" fill="rgba(139,143,163,0.15)"/>'
      );

      // Fill
      if (barFillW > 0) {
        parts.push(
          '<rect x="' + nameW + '" y="' + (mid - 7) + '" width="' + barFillW.toFixed(1) + '" height="14" '
          + 'rx="4" fill="' + fillColor + '"/>'
        );
      }

      // Percent
      parts.push(
        '<text x="' + (nameW + trackW + 8) + '" y="' + (mid + 5) + '" '
        + "font-family=\"'JetBrains Mono',ui-monospace,monospace\" font-size=\"11\" "
        + 'fill="var(--text-secondary,#565A70)">'
        + Math.round(pct * 100) + '%</text>'
      );
    });

    parts.push('</svg>');
    return parts.join('\n');
  },
};
