/*
 * seed.js — starter palettes for Chroma.
 * Includes an Orbioom-brand palette built from the real studio tokens.
 */
(function (global) {
  'use strict';

  function makeSwatch(name, hex, role) {
    return {
      id: 'seed-' + name.toLowerCase().replace(/[^a-z0-9]+/g, '-') + '-' + hex.replace('#', ''),
      name: name,
      hex: hex,
      role: role || ''
    };
  }

  // Orbioom brand palette — uses the studio's exact chrome tokens as data.
  const orbioom = {
    id: 'seed-orbioom',
    name: 'Orbioom Studio',
    swatches: [
      makeSwatch('Mist 1', '#EDEEF3', 'bg'),
      makeSwatch('Surface', '#FFFFFF', 'surface'),
      makeSwatch('Ink', '#23262F', 'accent'),
      makeSwatch('Text', '#1B1D2A', 'text'),
      makeSwatch('Text 2', '#565A70', ''),
      makeSwatch('Text 3', '#8B8FA3', ''),
      makeSwatch('Live', '#86C79A', '')
    ]
  };

  // A second, vivid palette to demonstrate harmonies & CVD.
  const sunset = {
    id: 'seed-sunset',
    name: 'Sunset Lab',
    swatches: [
      makeSwatch('Indigo', '#2B2D42', 'bg'),
      makeSwatch('Paper', '#F8F7FF', 'surface'),
      makeSwatch('Coral', '#EF476F', 'accent'),
      makeSwatch('Ink', '#1A1B2E', 'text'),
      makeSwatch('Saffron', '#FFD166', ''),
      makeSwatch('Teal', '#06D6A0', ''),
      makeSwatch('Sky', '#118AB2', '')
    ]
  };

  function samplePalettes() {
    // Deep clone so seeded state never shares references with stored state.
    return JSON.parse(JSON.stringify([orbioom, sunset]));
  }

  global.Seed = { samplePalettes: samplePalettes };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = global.Seed;
  }
})(typeof window !== 'undefined' ? window : this);
