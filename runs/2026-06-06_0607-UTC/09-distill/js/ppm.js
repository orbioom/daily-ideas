/*
 * Distill — a real PPM (Prediction by Partial Matching) context-modeling
 * entropy coder driving a carry-less range coder.
 *
 * This file is PURE (no DOM). It works in three environments:
 *   - Node.js                -> module.exports
 *   - a Web Worker           -> importScripts() exposes a global `Distill`
 *   - a plain <script> tag   -> window.Distill
 *
 * Algorithm: order-N PPM with PPMC-style escape estimation and full
 * exclusion. Symbols are bytes (0..255). A virtual EOF symbol (256) marks
 * the end of the stream so decoding knows when to stop. Escapes fall back
 * through shorter contexts down to an order(-1) uniform model over the
 * full alphabet, which guarantees every symbol is always codable —
 * hence the coder is exactly lossless for ANY byte sequence.
 *
 * The range coder is a 32-bit carry-less (Subbotin-style) range coder,
 * which is robust and deterministic: the same input always yields the
 * same compressed bytes.
 */
(function (root) {
  'use strict';

  // ---- Alphabet constants -------------------------------------------------
  var SYMBOLS = 257;     // 0..255 bytes + 256 EOF
  var EOF = 256;
  var ORDER = 3;         // PPM order; orders 3,2,1,0,-1 are tried in turn

  // ---- Range coder constants ---------------------------------------------
  var TOP = 0x01000000;            // 2^24
  var BOT = 0x00010000;            // 2^16
  var MASK32 = 0xFFFFFFFF;

  // -------------------------------------------------------------------------
  // Range Encoder (carry-less, Subbotin style)
  // -------------------------------------------------------------------------
  function Encoder() {
    this.low = 0;            // unsigned 32-bit, tracked via >>> 0
    this.range = MASK32 >>> 0;
    this.bytes = [];
  }
  Encoder.prototype._u = function (x) { return x >>> 0; };
  // encode a symbol given cumulative frequency boundaries within `total`
  Encoder.prototype.encode = function (cumFreq, freq, total) {
    var r = Math.floor(this.range / total);
    this.low = this._u(this.low + r * cumFreq);
    this.range = r * freq;
    // renormalise
    while (true) {
      if ((this._u(this.low ^ this._u(this.low + this.range)) < TOP)) {
        // top byte settled
      } else if (this.range < BOT) {
        // range too small -> force
        this.range = this._u((-this.low >>> 0) & (BOT - 1));
      } else {
        break;
      }
      this.bytes.push((this.low >>> 24) & 0xFF);
      this.low = this._u(this.low << 8);
      this.range = this._u(this.range << 8);
    }
  };
  Encoder.prototype.finish = function () {
    for (var i = 0; i < 4; i++) {
      this.bytes.push((this.low >>> 24) & 0xFF);
      this.low = this._u(this.low << 8);
    }
    return this.bytes;
  };

  // -------------------------------------------------------------------------
  // Range Decoder
  // -------------------------------------------------------------------------
  function Decoder(bytes) {
    this.bytes = bytes;
    this.pos = 0;
    this.low = 0;
    this.range = MASK32 >>> 0;
    this.code = 0;
    for (var i = 0; i < 4; i++) {
      this.code = this._u((this.code << 8) | this._next());
    }
  }
  Decoder.prototype._u = function (x) { return x >>> 0; };
  Decoder.prototype._next = function () {
    return this.pos < this.bytes.length ? this.bytes[this.pos++] : 0;
  };
  // return the cumulative-frequency target for the current code
  Decoder.prototype.getFreq = function (total) {
    this.r = Math.floor(this.range / total);
    var v = Math.floor(this._u(this.code - this.low) / this.r);
    return v >= total ? total - 1 : v;
  };
  Decoder.prototype.decode = function (cumFreq, freq) {
    this.low = this._u(this.low + this.r * cumFreq);
    this.range = this.r * freq;
    while (true) {
      if ((this._u(this.low ^ this._u(this.low + this.range)) < TOP)) {
        // settled
      } else if (this.range < BOT) {
        this.range = this._u((-this.low >>> 0) & (BOT - 1));
      } else {
        break;
      }
      this.code = this._u((this.code << 8) | this._next());
      this.low = this._u(this.low << 8);
      this.range = this._u(this.range << 8);
    }
  };

  // -------------------------------------------------------------------------
  // PPM context model
  //
  // Each context is a map from symbol -> count. We keep them in plain
  // objects keyed by a string context (the preceding up-to-ORDER bytes).
  // For each context we also keep the list of seen symbols in insertion
  // order plus a total. Escape uses PPMC: escape count = number of
  // distinct symbols seen in that context.
  // -------------------------------------------------------------------------
  function Model() {
    // contexts[order] is a Map from contextKey(string) -> ctx object
    this.contexts = [];
    for (var o = 0; o <= ORDER; o++) this.contexts[o] = new Map();
  }
  // ctx object: { counts: {sym:count}, syms: [sym,...], total: n }
  Model.prototype._getCtx = function (order, key) {
    var m = this.contexts[order];
    var c = m.get(key);
    if (!c) { c = { counts: Object.create(null), syms: [], total: 0 }; m.set(key, c); }
    return c;
  };
  Model.prototype._update = function (order, key, sym) {
    var c = this._getCtx(order, key);
    if (c.counts[sym] === undefined) { c.counts[sym] = 0; c.syms.push(sym); }
    c.counts[sym] += 1;
    c.total += 1;
  };

  // Build the context key string for a given order from the history array.
  function ctxKey(history, order) {
    if (order === 0) return '';
    var n = history.length;
    if (n < order) return null; // not enough history for this order
    return history.slice(n - order).join(',');
  }

  // -------------------------------------------------------------------------
  // Compression
  // -------------------------------------------------------------------------
  function compress(inputBytes, onProgress) {
    var enc = new Encoder();
    var model = new Model();
    var history = []; // array of recent symbol values
    var n = inputBytes.length;

    for (var i = 0; i <= n; i++) {
      var sym = (i < n) ? inputBytes[i] : EOF;
      encodeSymbol(enc, model, history, sym);
      // update all orders with the actual symbol, then push to history
      for (var o = 0; o <= ORDER; o++) {
        var key = ctxKey(history, o);
        if (key !== null) model._update(o, key, sym);
      }
      history.push(sym);
      if (history.length > ORDER) history.shift();
      if (onProgress && (i & 0x1fff) === 0) onProgress(i / (n + 1));
    }
    if (onProgress) onProgress(1);
    return enc.finish();
  }

  // Encode one symbol with escape/exclusion down the order chain.
  function encodeSymbol(enc, model, history, sym) {
    var excluded = Object.create(null); // symbols excluded by higher orders

    for (var order = ORDER; order >= 0; order--) {
      var key = ctxKey(history, order);
      if (key === null) continue;
      var c = model.contexts[order].get(key);
      if (!c) continue;

      // Build the effective frequency table honoring exclusions.
      var info = buildTable(c, excluded);
      if (info.total === 0) {
        // every symbol here is excluded -> nothing codable, escape implicitly
        continue;
      }
      if (c.counts[sym] !== undefined && !excluded[sym]) {
        // symbol present and not excluded -> encode it
        var cum = info.cum[sym];
        var f = info.freq[sym];
        enc.encode(cum, f, info.total);
        return;
      } else {
        // encode escape
        enc.encode(info.escCum, info.escFreq, info.total);
        // exclude all symbols seen in this context from lower orders
        for (var s = 0; s < c.syms.length; s++) excluded[c.syms[s]] = true;
      }
    }

    // order(-1): uniform over all SYMBOLS not yet excluded
    var list = [];
    for (var v = 0; v < SYMBOLS; v++) if (!excluded[v]) list.push(v);
    var total = list.length;
    var idx = list.indexOf(sym);
    // sym is always in list because exclusion never removes an unseen symbol
    enc.encode(idx, 1, total);
  }

  // Build cumulative table for a context with PPMC escape and exclusions.
  // Returns { freq:{sym:f}, cum:{sym:cumBefore}, total, escCum, escFreq }
  function buildTable(c, excluded) {
    var freq = Object.create(null);
    var cum = Object.create(null);
    var running = 0;
    var distinct = 0;
    for (var i = 0; i < c.syms.length; i++) {
      var s = c.syms[i];
      if (excluded[s]) continue;
      var f = c.counts[s];
      freq[s] = f;
      cum[s] = running;
      running += f;
      distinct++;
    }
    // PPMC escape frequency = number of distinct (non-excluded) symbols
    var escFreq = distinct > 0 ? distinct : 1;
    var escCum = running;
    var total = running + escFreq;
    return { freq: freq, cum: cum, total: total, escCum: escCum, escFreq: escFreq };
  }

  // -------------------------------------------------------------------------
  // Decompression
  // -------------------------------------------------------------------------
  function decompress(compressedBytes, onProgress) {
    var dec = new Decoder(compressedBytes);
    var model = new Model();
    var history = [];
    var out = [];

    while (true) {
      var sym = decodeSymbol(dec, model, history);
      if (sym === EOF) break;
      out.push(sym);
      for (var o = 0; o <= ORDER; o++) {
        var key = ctxKey(history, o);
        if (key !== null) model._update(o, key, sym);
      }
      history.push(sym);
      if (history.length > ORDER) history.shift();
      if (onProgress && (out.length & 0x1fff) === 0) onProgress(0.99);
      // EOF guarantees termination for valid streams.
    }
    if (onProgress) onProgress(1);
    return out;
  }

  function decodeSymbol(dec, model, history) {
    var excluded = Object.create(null);

    for (var order = ORDER; order >= 0; order--) {
      var key = ctxKey(history, order);
      if (key === null) continue;
      var c = model.contexts[order].get(key);
      if (!c) continue;

      var info = buildTable(c, excluded);
      if (info.total === 0) continue;

      var target = dec.getFreq(info.total);
      if (target >= info.escCum) {
        // escape
        dec.decode(info.escCum, info.escFreq);
        for (var s = 0; s < c.syms.length; s++) excluded[c.syms[s]] = true;
        continue;
      }
      // find the symbol whose cumulative interval contains target
      for (var i = 0; i < c.syms.length; i++) {
        var sym = c.syms[i];
        if (excluded[sym]) continue;
        var cum = info.cum[sym];
        var f = info.freq[sym];
        if (target >= cum && target < cum + f) {
          dec.decode(cum, f);
          return sym;
        }
      }
      // Should not reach here for a valid stream.
    }

    // order(-1)
    var list = [];
    for (var v = 0; v < SYMBOLS; v++) if (!excluded[v]) list.push(v);
    var total = list.length;
    var t = dec.getFreq(total);
    if (t >= total) t = total - 1;
    var chosen = list[t];
    dec.decode(t, 1);
    return chosen;
  }

  // -------------------------------------------------------------------------
  // Convenience: operate on strings via UTF-8, with self-describing output.
  // The compressed payload is just the range-coder bytes; EOF makes it
  // self-terminating, so no length header is required.
  // -------------------------------------------------------------------------
  function utf8Encode(str) {
    if (typeof TextEncoder !== 'undefined') return new TextEncoder().encode(str);
    return new Uint8Array(Buffer.from(str, 'utf8'));
  }
  function utf8Decode(bytes) {
    if (typeof TextDecoder !== 'undefined') {
      return new TextDecoder('utf-8').decode(new Uint8Array(bytes));
    }
    return Buffer.from(bytes).toString('utf8');
  }

  function compressString(str) {
    return new Uint8Array(compress(utf8Encode(str)));
  }
  function decompressString(bytes) {
    return utf8Decode(decompress(Array.from(bytes)));
  }

  var API = {
    ORDER: ORDER,
    EOF: EOF,
    SYMBOLS: SYMBOLS,
    compress: function (u8, onProgress) { return new Uint8Array(compress(Array.from(u8), onProgress)); },
    decompress: function (u8, onProgress) { return new Uint8Array(decompress(Array.from(u8), onProgress)); },
    compressString: compressString,
    decompressString: decompressString,
    utf8Encode: utf8Encode,
    utf8Decode: utf8Decode
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = API;
  } else {
    root.Distill = API;
  }
})(typeof self !== 'undefined' ? self : this);
