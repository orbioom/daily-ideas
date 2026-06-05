/*
 * color.js — Chroma color math
 * --------------------------------
 * Pure, dependency-free color utilities. All functions are crash-proofed:
 * invalid input returns a sensible clamped/fallback value or null where noted,
 * never NaN and never an uncaught throw.
 *
 * Math references:
 *  - sRGB <-> linear & WCAG 2.1 relative luminance:
 *    https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
 *  - Contrast ratio: https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
 *  - CVD simulation matrices: Machado, Oliveira & Fernandes (2009),
 *    "A Physiologically-based Model for Simulation of Color Vision Deficiency",
 *    IEEE Transactions on Visualization and Computer Graphics 15(6):1291-1298.
 *    Matrices below are the severity=1.0 (dichromat) operators from that paper,
 *    applied in linear-RGB space.
 */

(function (global) {
  'use strict';

  // ---- numeric helpers -------------------------------------------------

  function clamp(n, lo, hi) {
    n = Number(n);
    if (!isFinite(n)) return lo;
    return n < lo ? lo : n > hi ? hi : n;
  }

  function round(n, dp) {
    if (!isFinite(n)) return 0;
    const f = Math.pow(10, dp || 0);
    return Math.round(n * f) / f;
  }

  // ---- hex <-> rgb -----------------------------------------------------

  // Normalize arbitrary user hex input. Accepts: "abc", "#abc", "aabbcc",
  // "#AABBCC", with surrounding whitespace, case-insensitive.
  // Returns a canonical "#aabbcc" string, or null if not parseable.
  function normalizeHex(input) {
    if (typeof input !== 'string') return null;
    let s = input.trim().replace(/^#/, '').toLowerCase();
    if (/^[0-9a-f]{3}$/.test(s)) {
      s = s[0] + s[0] + s[1] + s[1] + s[2] + s[2];
    }
    if (/^[0-9a-f]{6}$/.test(s)) {
      return '#' + s;
    }
    return null;
  }

  function isValidHex(input) {
    return normalizeHex(input) !== null;
  }

  // hex -> {r,g,b} 0-255. Returns null on bad input.
  function hexToRgb(input) {
    const hex = normalizeHex(input);
    if (!hex) return null;
    const n = parseInt(hex.slice(1), 16);
    return {
      r: (n >> 16) & 255,
      g: (n >> 8) & 255,
      b: n & 255
    };
  }

  // {r,g,b} -> "#rrggbb". Clamps channels.
  function rgbToHex(r, g, b) {
    const ri = Math.round(clamp(r, 0, 255));
    const gi = Math.round(clamp(g, 0, 255));
    const bi = Math.round(clamp(b, 0, 255));
    const v = (ri << 16) | (gi << 8) | bi;
    return '#' + v.toString(16).padStart(6, '0');
  }

  // ---- rgb <-> hsl -----------------------------------------------------

  // {r,g,b} 0-255 -> {h:0-360, s:0-100, l:0-100}
  function rgbToHsl(r, g, b) {
    r = clamp(r, 0, 255) / 255;
    g = clamp(g, 0, 255) / 255;
    b = clamp(b, 0, 255) / 255;
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    const d = max - min;
    let h = 0;
    const l = (max + min) / 2;
    let s = 0;
    if (d !== 0) {
      s = d / (1 - Math.abs(2 * l - 1));
      switch (max) {
        case r:
          h = ((g - b) / d) % 6;
          break;
        case g:
          h = (b - r) / d + 2;
          break;
        default:
          h = (r - g) / d + 4;
          break;
      }
      h *= 60;
      if (h < 0) h += 360;
    }
    return {
      h: round(h, 1),
      s: round(s * 100, 1),
      l: round(l * 100, 1)
    };
  }

  // {h,s,l} (deg, %, %) -> {r,g,b} 0-255
  function hslToRgb(h, s, l) {
    h = ((Number(h) % 360) + 360) % 360;
    if (!isFinite(h)) h = 0;
    s = clamp(s, 0, 100) / 100;
    l = clamp(l, 0, 100) / 100;
    const c = (1 - Math.abs(2 * l - 1)) * s;
    const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
    const m = l - c / 2;
    let r = 0, g = 0, b = 0;
    if (h < 60) { r = c; g = x; b = 0; }
    else if (h < 120) { r = x; g = c; b = 0; }
    else if (h < 180) { r = 0; g = c; b = x; }
    else if (h < 240) { r = 0; g = x; b = c; }
    else if (h < 300) { r = x; g = 0; b = c; }
    else { r = c; g = 0; b = x; }
    return {
      r: Math.round((r + m) * 255),
      g: Math.round((g + m) * 255),
      b: Math.round((b + m) * 255)
    };
  }

  function hexToHsl(input) {
    const rgb = hexToRgb(input);
    if (!rgb) return null;
    return rgbToHsl(rgb.r, rgb.g, rgb.b);
  }

  function hslToHex(h, s, l) {
    const rgb = hslToRgb(h, s, l);
    return rgbToHex(rgb.r, rgb.g, rgb.b);
  }

  // ---- sRGB <-> linear & relative luminance ----------------------------

  // Linearize one 0-1 sRGB channel per WCAG 2.1.
  function srgbToLinearChannel(c) {
    c = clamp(c, 0, 1);
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  }

  // Inverse: linear 0-1 -> sRGB 0-1.
  function linearToSrgbChannel(c) {
    c = clamp(c, 0, 1);
    return c <= 0.0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
  }

  // {r,g,b} 0-255 -> WCAG relative luminance 0-1.
  function relativeLuminance(rgb) {
    if (!rgb) return 0;
    const R = srgbToLinearChannel(clamp(rgb.r, 0, 255) / 255);
    const G = srgbToLinearChannel(clamp(rgb.g, 0, 255) / 255);
    const B = srgbToLinearChannel(clamp(rgb.b, 0, 255) / 255);
    return 0.2126 * R + 0.7152 * G + 0.0722 * B;
  }

  // ---- WCAG contrast ---------------------------------------------------

  // Contrast ratio between two hex (or rgb) colors. Range 1..21.
  function contrastRatio(fg, bg) {
    const a = typeof fg === 'string' ? hexToRgb(fg) : fg;
    const b = typeof bg === 'string' ? hexToRgb(bg) : bg;
    if (!a || !b) return 1;
    const la = relativeLuminance(a);
    const lb = relativeLuminance(b);
    const lighter = Math.max(la, lb);
    const darker = Math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  // Format as "4.73:1".
  function formatRatio(ratio) {
    if (!isFinite(ratio)) ratio = 1;
    return round(ratio, 2).toFixed(2) + ':1';
  }

  // Pass/fail object for the four WCAG levels.
  function wcagLevels(ratio) {
    if (!isFinite(ratio)) ratio = 1;
    return {
      aaNormal: ratio >= 4.5,
      aaLarge: ratio >= 3,
      aaaNormal: ratio >= 7,
      aaaLarge: ratio >= 4.5
    };
  }

  // ---- CVD simulation (Machado et al. 2009, severity 1.0) --------------
  // Operates in LINEAR RGB. Source: Table in Machado, Oliveira & Fernandes
  // (2009), IEEE TVCG. Severity 1.0 (full dichromacy) matrices.

  const CVD_MATRICES = {
    protanopia: [
      [0.152286, 1.052583, -0.204868],
      [0.114503, 0.786281, 0.099216],
      [-0.003882, -0.048116, 1.051998]
    ],
    deuteranopia: [
      [0.367322, 0.860646, -0.227968],
      [0.280085, 0.672501, 0.047413],
      [-0.011820, 0.042940, 0.968881]
    ],
    tritanopia: [
      [1.255528, -0.076749, -0.178779],
      [-0.078411, 0.930809, 0.147602],
      [0.004733, 0.691367, 0.303900]
    ]
  };

  const CVD_DESCRIPTIONS = {
    none: 'No simulation — colors shown as authored.',
    protanopia: 'Protanopia — absent long-wavelength (red) cones; reds appear dark/muddy.',
    deuteranopia: 'Deuteranopia — absent medium-wavelength (green) cones; reds and greens confuse.',
    tritanopia: 'Tritanopia — absent short-wavelength (blue) cones; blues and yellows confuse.'
  };

  // Apply a CVD matrix to a single hex/rgb color. type: 'none' returns input.
  function simulateCvd(color, type) {
    const rgb = typeof color === 'string' ? hexToRgb(color) : color;
    if (!rgb) return rgbToHex(0, 0, 0);
    if (!type || type === 'none' || !CVD_MATRICES[type]) {
      return rgbToHex(rgb.r, rgb.g, rgb.b);
    }
    const m = CVD_MATRICES[type];
    // Convert to linear RGB
    const lin = [
      srgbToLinearChannel(clamp(rgb.r, 0, 255) / 255),
      srgbToLinearChannel(clamp(rgb.g, 0, 255) / 255),
      srgbToLinearChannel(clamp(rgb.b, 0, 255) / 255)
    ];
    const out = [0, 0, 0];
    for (let i = 0; i < 3; i++) {
      out[i] = m[i][0] * lin[0] + m[i][1] * lin[1] + m[i][2] * lin[2];
    }
    // Back to sRGB 0-255
    return rgbToHex(
      linearToSrgbChannel(out[0]) * 255,
      linearToSrgbChannel(out[1]) * 255,
      linearToSrgbChannel(out[2]) * 255
    );
  }

  // ---- scale & harmony generation --------------------------------------

  // Standard tint/shade scale keyed 50..900 derived from a base color by
  // mapping to fixed HSL lightness targets while preserving hue/saturation.
  const SCALE_STEPS = [
    { key: '50', l: 96 },
    { key: '100', l: 90 },
    { key: '200', l: 80 },
    { key: '300', l: 68 },
    { key: '400', l: 56 },
    { key: '500', l: 46 },
    { key: '600', l: 38 },
    { key: '700', l: 30 },
    { key: '800', l: 22 },
    { key: '900', l: 14 }
  ];

  function generateScale(baseHex) {
    const hsl = hexToHsl(baseHex);
    if (!hsl) return [];
    return SCALE_STEPS.map(function (step) {
      return {
        key: step.key,
        hex: hslToHex(hsl.h, hsl.s, step.l)
      };
    });
  }

  function rotateHue(baseHex, deg) {
    const hsl = hexToHsl(baseHex);
    if (!hsl) return baseHex;
    return hslToHex(hsl.h + deg, hsl.s, hsl.l);
  }

  // Returns named harmony sets, each an array of hex strings incl. the base.
  function generateHarmonies(baseHex) {
    const norm = normalizeHex(baseHex);
    if (!norm) return { complementary: [], analogous: [], triadic: [] };
    return {
      complementary: [norm, rotateHue(norm, 180)],
      analogous: [rotateHue(norm, -30), norm, rotateHue(norm, 30)],
      triadic: [norm, rotateHue(norm, 120), rotateHue(norm, 240)]
    };
  }

  // Pick readable text color (black or white) for a given background.
  function bestTextOn(bgHex) {
    const black = contrastRatio('#000000', bgHex);
    const white = contrastRatio('#ffffff', bgHex);
    return white >= black ? '#ffffff' : '#000000';
  }

  global.Color = {
    clamp: clamp,
    round: round,
    normalizeHex: normalizeHex,
    isValidHex: isValidHex,
    hexToRgb: hexToRgb,
    rgbToHex: rgbToHex,
    rgbToHsl: rgbToHsl,
    hslToRgb: hslToRgb,
    hexToHsl: hexToHsl,
    hslToHex: hslToHex,
    srgbToLinearChannel: srgbToLinearChannel,
    linearToSrgbChannel: linearToSrgbChannel,
    relativeLuminance: relativeLuminance,
    contrastRatio: contrastRatio,
    formatRatio: formatRatio,
    wcagLevels: wcagLevels,
    simulateCvd: simulateCvd,
    CVD_DESCRIPTIONS: CVD_DESCRIPTIONS,
    generateScale: generateScale,
    rotateHue: rotateHue,
    generateHarmonies: generateHarmonies,
    bestTextOn: bestTextOn
  };

  // CommonJS export for any test harness
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = global.Color;
  }
})(typeof window !== 'undefined' ? window : this);
