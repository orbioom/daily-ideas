// worker.js — Spectra
// Off-main-thread STFT compute so the spectrogram never blocks the UI.
// Receives {signal, Fs, winSize, hop, windowType}, returns the spectrogram
// matrix (transferring the underlying buffer for speed).

'use strict';

/* global importScripts, SpectraFFT */
importScripts('fft.js');

self.onmessage = function (e) {
  const msg = e.data || {};
  if (msg.type !== 'stft') return;
  try {
    const sig = msg.signal; // Float64Array (copied across the boundary)
    const result = SpectraFFT.spectrogram(
      sig, msg.Fs, msg.winSize, msg.hop, msg.windowType
    );
    self.postMessage(
      { type: 'stft-result', id: msg.id, result },
      [result.data.buffer, result.times.buffer, result.freqs.buffer]
    );
  } catch (err) {
    self.postMessage({ type: 'stft-error', id: msg.id, error: String(err && err.message || err) });
  }
};
