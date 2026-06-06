/*
 * Node verification harness for Distill's PPM + range coder.
 * Run:  node js/ppm.test.js
 *
 * Asserts decompress(compress(x)) === x EXACTLY for a variety of inputs,
 * then prints the measured compression ratio on sample.txt against
 * Node's zlib.gzipSync (a stand-in for the browser's CompressionStream).
 */
'use strict';
var Distill = require('./ppm.js');
var zlib = require('zlib');
var fs = require('fs');
var path = require('path');

var pass = 0, fail = 0;

function bytesEqual(a, b) {
  if (a.length !== b.length) return false;
  for (var i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
  return true;
}

function roundTripBytes(name, u8) {
  var comp = Distill.compress(u8);
  var back = Distill.decompress(comp);
  var ok = bytesEqual(u8, back);
  if (ok) { pass++; console.log('  PASS  ' + name + '  (' + u8.length + ' -> ' + comp.length + ' bytes)'); }
  else { fail++; console.log('  FAIL  ' + name + '  round-trip mismatch'); }
  return comp;
}

function roundTripString(name, str) {
  var comp = Distill.compressString(str);
  var back = Distill.decompressString(comp);
  var ok = back === str;
  if (ok) { pass++; console.log('  PASS  ' + name + '  ("' + (str.length > 24 ? str.slice(0, 24) + '…' : str) + '")'); }
  else { fail++; console.log('  FAIL  ' + name + '  string mismatch\n    expected: ' + JSON.stringify(str) + '\n    got:      ' + JSON.stringify(back)); }
}

console.log('Distill round-trip verification (order ' + Distill.ORDER + ')');
console.log('-----------------------------------------------------------');

// (1) variety of inputs
roundTripString('empty string', '');
roundTripString('single char', 'a');
roundTripString('short ascii', 'hello world');
roundTripString('unicode + emoji + accents', 'café — naïve — 日本語 — 🚀🌫️ — Ω');
roundTripBytes('empty bytes', new Uint8Array(0));
roundTripBytes('single byte 0x00', new Uint8Array([0]));
roundTripBytes('all 256 byte values', (function () {
  var a = new Uint8Array(256); for (var i = 0; i < 256; i++) a[i] = i; return a;
})());

// 50KB repetitive string
var rep = '';
var unit = 'The quick brown fox jumps over the lazy dog. ';
while (rep.length < 50000) rep += unit;
rep = rep.slice(0, 50000);
roundTripString('50KB repetitive text', rep);

// random bytes (deterministic LCG so the test is reproducible). We take a
// HIGH byte of the LCG state, not the low byte — the low bits of an LCG are
// strongly periodic, which would fake an unrealistically good ratio. This
// gives genuinely high-entropy bytes so the round-trip is a real stress test
// of the incompressible case (expect the output to be slightly LARGER than
// the input, which is correct and honest for random data).
var rnd = new Uint8Array(20000);
var seed = 0x9e3779b9 >>> 0;
for (var i = 0; i < rnd.length; i++) {
  seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
  rnd[i] = (seed >>> 24) & 0xFF;
}
roundTripBytes('20KB high-entropy bytes', rnd);

// sample.txt
var samplePath = path.join(__dirname, '..', 'data', 'sample.txt');
var sampleText = fs.readFileSync(samplePath, 'utf8');
roundTripString('data/sample.txt', sampleText);

// reproducibility: same input -> identical compressed bytes twice
(function () {
  var a = Distill.compressString(sampleText);
  var b = Distill.compressString(sampleText);
  if (bytesEqual(a, b)) { pass++; console.log('  PASS  deterministic output (sample compressed identically twice)'); }
  else { fail++; console.log('  FAIL  non-deterministic output'); }
})();

console.log('-----------------------------------------------------------');

// (2) ratio vs gzip on the natural-language sample
var sampleBytes = Buffer.from(sampleText, 'utf8');
var origSize = sampleBytes.length;
var distillSize = Distill.compressString(sampleText).length;
var gzipSize = zlib.gzipSync(sampleBytes, { level: 9 }).length;

var distillRatio = origSize / distillSize;
var gzipRatio = origSize / gzipSize;
var bpb = (distillSize * 8) / origSize;

console.log('Sample compression report (data/sample.txt):');
console.log('  original         : ' + origSize + ' bytes');
console.log('  Distill (PPM)    : ' + distillSize + ' bytes  ratio ' + distillRatio.toFixed(3) + 'x  bpb ' + bpb.toFixed(3));
console.log('  gzip (level 9)   : ' + gzipSize + ' bytes  ratio ' + gzipRatio.toFixed(3) + 'x');
var pct = ((gzipSize - distillSize) / gzipSize) * 100;
if (distillSize < gzipSize) console.log('  -> Distill is ' + pct.toFixed(1) + '% smaller than gzip on this sample.');
else console.log('  -> gzip is smaller here by ' + (-pct).toFixed(1) + '%.');

console.log('-----------------------------------------------------------');
console.log('Result: ' + pass + ' passed, ' + fail + ' failed.');
process.exit(fail === 0 ? 0 : 1);
