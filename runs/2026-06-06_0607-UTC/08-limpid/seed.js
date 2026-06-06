/*
 * seed.js — Limpid sample documents.
 *
 * Three realistic documents of varying clarity, used to populate the editor
 * on first open and available via "Load sample". All prose is original and
 * plausible (no placeholder text).
 */
(function (root) {
  'use strict';

  var SAMPLES = [
    {
      title: 'Clear: A short note',
      content:
'We met at the river before dawn. The water was calm. Mist sat low on the banks, and the air felt cool against our skin.\n\n' +
'We did not talk much. We watched the light change. A heron lifted off the far shore and crossed the sky in a slow line.\n\n' +
'When the sun came up, we walked home. The day was easy. We made tea and read by the window until noon.'
    },
    {
      title: 'Mixed: A product update',
      content:
'Today we are shipping a small but meaningful update to the editor. It loads faster, and it handles large documents without stalling.\n\n' +
'The new analysis panel was rebuilt from scratch so that scores update smoothly as you type. We also fixed several bugs that were reported by early testers, and we genuinely appreciate the detailed notes they sent us.\n\n' +
'In order to keep things calm, we deliberately avoided adding flashy animations. The goal is a tool that gets out of your way. There is still plenty of work ahead, but this release marks a real step forward for the team.'
    },
    {
      title: 'Dense: A policy paragraph',
      content:
'Notwithstanding the aforementioned considerations, it should be noted that the implementation of the proposed regulatory framework necessitates a comprehensive reconceptualization of the fundamental methodological presuppositions that have historically underpinned the institutional decision-making apparatus, particularly insofar as such presuppositions are inextricably intertwined with antecedent epistemological commitments.\n\n' +
'The committee was subsequently directed to undertake an exhaustive evaluation, and the findings were ultimately determined to be inconclusive, which is unfortunate. Recommendations are expected to be formulated by the appointed subcommittee in due course.'
    }
  ];

  function buildSeedDocuments(createDocument) {
    return SAMPLES.map(function (s) {
      return createDocument(s.title, s.content);
    });
  }

  var api = { SAMPLES: SAMPLES, buildSeedDocuments: buildSeedDocuments };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
  } else {
    root.LimpidSeed = api;
  }
})(typeof self !== 'undefined' ? self : this);
