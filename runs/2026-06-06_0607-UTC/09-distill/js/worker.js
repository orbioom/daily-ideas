/*
 * Distill Web Worker.
 *
 * Runs the heavy PPM compression / decompression and the gzip comparison
 * off the main thread so the UI never locks. Communicates with main.js via
 * structured-clone messages.
 *
 * Messages IN:
 *   { type: 'compress', id, bytes: Uint8Array }
 *   { type: 'decompress', id, bytes: Uint8Array }   // a .distill payload
 *
 * Messages OUT:
 *   { type: 'progress', id, phase, value }          // value 0..1
 *   { type: 'result',   id, ...payload }
 *   { type: 'error',    id, message }
 */
'use strict';

importScripts('ppm.js');

// gzip via the browser's built-in CompressionStream, run inside the worker.
async function gzipBytes(bytes) {
  if (typeof CompressionStream === 'undefined') return null;
  const cs = new CompressionStream('gzip');
  const writer = cs.writable.getWriter();
  writer.write(bytes);
  writer.close();
  const reader = cs.readable.getReader();
  const chunks = [];
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    total += value.length;
  }
  const out = new Uint8Array(total);
  let off = 0;
  for (const c of chunks) { out.set(c, off); off += c.length; }
  return out;
}

async function gunzipBytes(bytes) {
  if (typeof DecompressionStream === 'undefined') return null;
  const ds = new DecompressionStream('gzip');
  const writer = ds.writable.getWriter();
  writer.write(bytes);
  writer.close();
  const reader = ds.readable.getReader();
  const chunks = [];
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    total += value.length;
  }
  const out = new Uint8Array(total);
  let off = 0;
  for (const c of chunks) { out.set(c, off); off += c.length; }
  return out;
}

self.onmessage = async function (e) {
  const msg = e.data;
  const id = msg.id;
  try {
    if (msg.type === 'compress') {
      await handleCompress(id, msg.bytes);
    } else if (msg.type === 'decompress') {
      handleDecompress(id, msg.bytes);
    } else {
      self.postMessage({ type: 'error', id: id, message: 'Unknown request: ' + msg.type });
    }
  } catch (err) {
    self.postMessage({ type: 'error', id: id, message: (err && err.message) || String(err) });
  }
};

async function handleCompress(id, input) {
  const bytes = input instanceof Uint8Array ? input : new Uint8Array(input);

  // --- Distill compress (timed) ---
  self.postMessage({ type: 'progress', id: id, phase: 'compress', value: 0 });
  const t0 = nowMs();
  const compressed = Distill.compress(bytes, function (p) {
    self.postMessage({ type: 'progress', id: id, phase: 'compress', value: p });
  });
  const t1 = nowMs();
  const compressMs = t1 - t0;

  // --- Round-trip verification (decompress + byte-exact compare) ---
  self.postMessage({ type: 'progress', id: id, phase: 'verify', value: 0 });
  const td0 = nowMs();
  const restored = Distill.decompress(compressed, function (p) {
    self.postMessage({ type: 'progress', id: id, phase: 'verify', value: p });
  });
  const td1 = nowMs();
  const decompressMs = td1 - td0;

  let roundTrip = restored.length === bytes.length;
  if (roundTrip) {
    for (let i = 0; i < bytes.length; i++) {
      if (bytes[i] !== restored[i]) { roundTrip = false; break; }
    }
  }

  // --- gzip comparison (browser CompressionStream) ---
  self.postMessage({ type: 'progress', id: id, phase: 'gzip', value: 0 });
  let gzipSize = null;
  const tg0 = nowMs();
  const gz = await gzipBytes(bytes);
  const tg1 = nowMs();
  if (gz) gzipSize = gz.length;
  self.postMessage({ type: 'progress', id: id, phase: 'gzip', value: 1 });

  // Transfer the compressed bytes back so main can offer a .distill download.
  const buf = compressed.buffer.slice(compressed.byteOffset, compressed.byteOffset + compressed.byteLength);
  self.postMessage({
    type: 'result',
    id: id,
    kind: 'compress',
    originalSize: bytes.length,
    distillSize: compressed.length,
    gzipSize: gzipSize,
    compressMs: compressMs,
    decompressMs: decompressMs,
    gzipMs: tg1 - tg0,
    roundTrip: roundTrip,
    compressed: buf
  }, [buf]);
}

function handleDecompress(id, input) {
  const bytes = input instanceof Uint8Array ? input : new Uint8Array(input);
  const t0 = nowMs();
  const restored = Distill.decompress(bytes, function (p) {
    self.postMessage({ type: 'progress', id: id, phase: 'decompress', value: p });
  });
  const t1 = nowMs();
  const buf = restored.buffer.slice(restored.byteOffset, restored.byteOffset + restored.byteLength);
  self.postMessage({
    type: 'result',
    id: id,
    kind: 'decompress',
    originalSize: bytes.length,
    restoredSize: restored.length,
    decompressMs: t1 - t0,
    restored: buf
  }, [buf]);
}

function nowMs() {
  return (typeof performance !== 'undefined' && performance.now)
    ? performance.now() : Date.now();
}
