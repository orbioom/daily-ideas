/*
 * analysis.js — Limpid prose analysis engine (pure, no DOM).
 *
 * Exposes tokenizers, a heuristic syllable counter, six readability
 * formulas, and span detectors (long sentences, passive voice, adverbs,
 * filler/weasel words, complex words). Loadable in the browser (attaches
 * to window.LimpidAnalysis) and in Node (module.exports).
 *
 * All span detectors return objects: { start, end, type, ... } where
 * start/end are character offsets into the ORIGINAL text, so an overlay
 * highlight layer can align them precisely with a textarea.
 */
(function (root, factory) {
  var api = factory();
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
  } else {
    root.LimpidAnalysis = api;
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  // ---------------------------------------------------------------------------
  // Tokenization
  // ---------------------------------------------------------------------------

  // Abbreviations that should NOT end a sentence even when followed by a period.
  var ABBREVIATIONS = {
    'mr': 1, 'mrs': 1, 'ms': 1, 'dr': 1, 'prof': 1, 'sr': 1, 'jr': 1,
    'st': 1, 'vs': 1, 'etc': 1, 'inc': 1, 'ltd': 1, 'co': 1, 'corp': 1,
    'e.g': 1, 'i.e': 1, 'a.m': 1, 'p.m': 1, 'u.s': 1, 'u.k': 1, 'no': 1,
    'fig': 1, 'al': 1, 'approx': 1, 'dept': 1, 'est': 1, 'gov': 1
  };

  /**
   * Split text into sentences. Returns array of { text, start, end } with
   * character offsets into the original text. Robust to abbreviations,
   * decimals, ellipses, and trailing punctuation. Never throws.
   */
  function splitSentences(text) {
    var sentences = [];
    if (!text) return sentences;
    var n = text.length;
    var i = 0;
    var sentenceStart = 0;

    function lastWordBefore(idx) {
      // Grab the alphanumeric/dot token immediately before idx (the terminator).
      var j = idx - 1;
      var end = j + 1;
      while (j >= 0 && /[A-Za-z0-9.]/.test(text[j])) j--;
      return text.slice(j + 1, end).toLowerCase().replace(/\.+$/, '');
    }

    while (i < n) {
      var ch = text[i];
      if (ch === '.' || ch === '!' || ch === '?') {
        // Group consecutive terminators (?!, ..., !!).
        var termEnd = i;
        while (termEnd + 1 < n && /[.!?]/.test(text[termEnd + 1])) termEnd++;

        var isBoundary = true;

        // Decimal number like 3.14 — period between digits is not a boundary.
        if (ch === '.' && i > 0 && i + 1 < n &&
            /[0-9]/.test(text[i - 1]) && /[0-9]/.test(text[i + 1])) {
          isBoundary = false;
        }

        // Abbreviation before a single period.
        if (isBoundary && ch === '.' && termEnd === i) {
          var word = lastWordBefore(i);
          if (ABBREVIATIONS[word]) isBoundary = false;
          // Single capital initial like "J." in "J. Smith".
          if (word.length === 1 && /[a-z]/.test(word)) isBoundary = false;
        }

        if (isBoundary) {
          // Include trailing closing quotes/brackets in the sentence.
          var k = termEnd + 1;
          while (k < n && /["'”’\)\]]/.test(text[k])) k++;
          var raw = text.slice(sentenceStart, k);
          var trimmed = raw.replace(/^\s+/, '');
          var lead = raw.length - trimmed.length;
          var s = sentenceStart + lead;
          var e = k;
          if (text.slice(s, e).trim().length > 0) {
            sentences.push({ text: text.slice(s, e).replace(/\s+$/, ''), start: s, end: e });
          }
          // Advance over following whitespace to next sentence start.
          sentenceStart = k;
          i = k;
          continue;
        } else {
          i = termEnd + 1;
          continue;
        }
      }
      i++;
    }

    // Trailing text with no terminator counts as a sentence.
    if (sentenceStart < n) {
      var tail = text.slice(sentenceStart);
      if (tail.trim().length > 0) {
        var t2 = tail.replace(/^\s+/, '');
        var lead2 = tail.length - t2.length;
        var st = sentenceStart + lead2;
        sentences.push({ text: text.slice(st).replace(/\s+$/, ''), start: st, end: n });
      }
    }
    return sentences;
  }

  // Match words including internal apostrophes/hyphens. Captures offsets.
  var WORD_RE = /[A-Za-z](?:[A-Za-z'’\-]*[A-Za-z])?/g;

  /**
   * Tokenize words with offsets. Returns array of { text, start, end }.
   */
  function tokenizeWords(text) {
    var words = [];
    if (!text) return words;
    WORD_RE.lastIndex = 0;
    var m;
    while ((m = WORD_RE.exec(text)) !== null) {
      words.push({ text: m[0], start: m.index, end: m.index + m[0].length });
      if (m.index === WORD_RE.lastIndex) WORD_RE.lastIndex++; // guard zero-width
    }
    return words;
  }

  function countParagraphs(text) {
    if (!text || !text.trim()) return 0;
    var blocks = text.split(/\n{2,}/);
    var count = 0;
    for (var i = 0; i < blocks.length; i++) {
      if (blocks[i].trim().length > 0) count++;
    }
    return count || 1;
  }

  // ---------------------------------------------------------------------------
  // Syllable counter (heuristic vowel-group algorithm + adjustments)
  // ---------------------------------------------------------------------------

  // Small table of words the heuristic gets wrong; values are correct counts.
  var SYLLABLE_EXCEPTIONS = {
    'syllable': 3, 'syllables': 3,
    'queue': 1, 'create': 2, 'simile': 3, 'business': 2, 'people': 2,
    'wednesday': 2, 'every': 2, 'different': 3, 'evening': 2, 'special': 2,
    'really': 2, 'area': 3, 'idea': 3, 'being': 2, 'science': 2,
    'quiet': 2, 'poem': 2, 'poet': 2, 'coyote': 3, 'choir': 1,
    'colonel': 2, 'february': 4, 'family': 3, 'camera': 3, 'chocolate': 3,
    'comfortable': 4, 'naive': 2, 'cooperate': 4, 'reality': 4, 'theatre': 2,
    'aria': 3, 'lion': 2, 'ones': 1, 'shoreline': 2, 'riverbed': 3
  };

  /**
   * Count syllables in a single word using a vowel-group heuristic with
   * common English adjustments (silent trailing 'e', 'le' endings, leading
   * 'y' handling, diphthong collapse). Always returns >= 1 for a word with
   * letters. Pure and fast.
   */
  function countSyllables(word) {
    if (!word) return 0;
    var w = word.toLowerCase().replace(/[^a-z]/g, '');
    if (!w) return 0;
    if (SYLLABLE_EXCEPTIONS[w] != null) return SYLLABLE_EXCEPTIONS[w];
    if (w.length <= 3) {
      // Short words: count vowel groups but never below 1.
      var vg = w.match(/[aeiouy]+/g);
      return vg ? Math.max(1, vg.length) : 1;
    }

    var s = w;
    var leBonus = 0;

    // Consonant + 'le' / 'les' ending forms its own syllable (table, cradle,
    // simple). Strip it first so its 'e' is not also counted as a vowel group.
    if (/[^aeiouy]les$/.test(s)) { s = s.slice(0, -3); leBonus = 1; }
    else if (/[^aeiouy]le$/.test(s)) { s = s.slice(0, -2); leBonus = 1; }
    else {
      // Otherwise drop a silent trailing 'e' / 'es' / 'ed' (make, makes, baked).
      s = s.replace(/(?:es|ed|e)$/, '');
    }

    var groups = s.match(/[aeiouy]+/g);
    var count = (groups ? groups.length : 0) + leBonus;

    if (count <= 0) count = 1;
    return count;
  }

  function countSyllablesInText(text) {
    var words = tokenizeWords(text);
    var total = 0;
    for (var i = 0; i < words.length; i++) total += countSyllables(words[i].text);
    return total;
  }

  // ---------------------------------------------------------------------------
  // Readability formulas
  // ---------------------------------------------------------------------------
  // Each returns null when inputs are degenerate (0 words / 0 sentences).

  function fleschReadingEase(stats) {
    if (stats.words === 0 || stats.sentences === 0) return null;
    var asl = stats.words / stats.sentences;
    var asw = stats.syllables / stats.words;
    return 206.835 - 1.015 * asl - 84.6 * asw;
  }

  function fleschKincaidGrade(stats) {
    if (stats.words === 0 || stats.sentences === 0) return null;
    var asl = stats.words / stats.sentences;
    var asw = stats.syllables / stats.words;
    return 0.39 * asl + 11.8 * asw - 15.59;
  }

  function gunningFog(stats) {
    if (stats.words === 0 || stats.sentences === 0) return null;
    var asl = stats.words / stats.sentences;
    var pct = (stats.complexWords / stats.words) * 100;
    return 0.4 * (asl + pct);
  }

  function smog(stats) {
    // SMOG is defined for 30+ sentences; we apply the standard formula and
    // scale the polysyllable count to 30 sentences so it works on any length.
    if (stats.sentences === 0) return null;
    var poly = stats.polysyllables * (30 / stats.sentences);
    return 1.0430 * Math.sqrt(poly) + 3.1291;
  }

  function automatedReadabilityIndex(stats) {
    if (stats.words === 0 || stats.sentences === 0) return null;
    return 4.71 * (stats.characters / stats.words) +
           0.5 * (stats.words / stats.sentences) - 21.43;
  }

  function colemanLiau(stats) {
    if (stats.words === 0) return null;
    var L = (stats.characters / stats.words) * 100; // letters per 100 words
    var S = (stats.sentences / stats.words) * 100;  // sentences per 100 words
    return 0.0588 * L - 0.296 * S - 15.8;
  }

  // ---------------------------------------------------------------------------
  // Span detectors
  // ---------------------------------------------------------------------------

  // Filler / weasel words and phrases (curated). Multi-word phrases first.
  var FILLER_PHRASES = [
    'in order to', 'a number of', 'for all intents and purposes',
    'at the end of the day', 'needless to say', 'it should be noted that',
    'due to the fact that', 'in the event that', 'a lot of', 'kind of',
    'sort of', 'as a matter of fact'
  ];
  var FILLER_WORDS = {
    'very': 1, 'really': 1, 'just': 1, 'actually': 1, 'basically': 1,
    'literally': 1, 'simply': 1, 'quite': 1, 'rather': 1, 'somewhat': 1,
    'fairly': 1, 'totally': 1, 'definitely': 1, 'certainly': 1, 'probably': 1,
    'perhaps': 1, 'maybe': 1, 'seems': 1, 'somehow': 1, 'various': 1,
    'several': 1, 'many': 1, 'most': 1, 'generally': 1, 'usually': 1,
    'often': 1, 'sometimes': 1, 'essentially': 1, 'virtually': 1,
    'practically': 1, 'arguably': 1, 'relatively': 1, 'particularly': 1,
    'stuff': 1, 'things': 1, 'overall': 1, 'utilize': 1
  };

  // Adverbs ending in -ly that are NOT manner adverbs worth flagging.
  var ADVERB_STOPLIST = {
    'only': 1, 'family': 1, 'reply': 1, 'apply': 1, 'supply': 1, 'rely': 1,
    'imply': 1, 'comply': 1, 'multiply': 1, 'july': 1, 'italy': 1, 'ugly': 1,
    'early': 1, 'holy': 1, 'fly': 1, 'ally': 1, 'rally': 1, 'lovely': 1,
    'likely': 1, 'lonely': 1, 'silly': 1, 'jelly': 1, 'belly': 1, 'bully': 1,
    'fully': 1, 'daily': 1, 'oily': 1, 'curly': 1, 'friendly': 1, 'deadly': 1,
    'hilly': 1, 'wholly': 1
  };

  var BE_VERBS = {
    'be': 1, 'is': 1, 'are': 1, 'was': 1, 'were': 1, 'been': 1, 'being': 1,
    'am': 1, "isn't": 1, "aren't": 1, "wasn't": 1, "weren't": 1,
    "wasnt": 1, "werent": 1, "isnt": 1, "arent": 1
  };

  // Irregular past participles for passive detection (be + participle).
  var IRREGULAR_PARTICIPLES = {
    'given': 1, 'taken': 1, 'seen': 1, 'done': 1, 'made': 1, 'known': 1,
    'shown': 1, 'written': 1, 'broken': 1, 'chosen': 1, 'driven': 1,
    'eaten': 1, 'fallen': 1, 'forgotten': 1, 'frozen': 1, 'gotten': 1,
    'hidden': 1, 'held': 1, 'kept': 1, 'led': 1, 'left': 1, 'lost': 1,
    'meant': 1, 'met': 1, 'paid': 1, 'put': 1, 'read': 1, 'said': 1,
    'sent': 1, 'set': 1, 'sold': 1, 'spent': 1, 'stolen': 1, 'taught': 1,
    'told': 1, 'thrown': 1, 'understood': 1, 'worn': 1, 'won': 1, 'built': 1,
    'bought': 1, 'brought': 1, 'caught': 1, 'cut': 1, 'dealt': 1, 'drawn': 1,
    'felt': 1, 'found': 1, 'heard': 1, 'hit': 1, 'hurt': 1, 'laid': 1,
    'beaten': 1, 'begun': 1, 'bound': 1, 'dug': 1, 'grown': 1, 'hung': 1,
    'run': 1, 'shut': 1, 'spun': 1, 'spread': 1, 'sung': 1, 'sunk': 1,
    'torn': 1, 'worn': 1
  };

  // Words that look like participles but rarely indicate passive after "be".
  var PARTICIPLE_BLOCKLIST = {
    'used': 1, 'supposed': 1, 'based': 1, 'pleased': 1, 'interested': 1,
    'tired': 1, 'excited': 1, 'worried': 1, 'concerned': 1, 'involved': 1,
    'located': 1, 'related': 1, 'limited': 1, 'detailed': 1, 'aged': 1,
    'red': 1, 'bed': 1, 'wed': 1, 'fed': 1, 'led': 1, 'bred': 1, 'sled': 1,
    'embed': 1, 'shed': 1, 'shred': 1
  };

  function looksLikePastParticiple(word) {
    var w = word.toLowerCase();
    if (PARTICIPLE_BLOCKLIST[w]) return false;
    if (IRREGULAR_PARTICIPLES[w]) return true;
    // Regular -ed participle, length filter avoids "red", "bed".
    if (/ed$/.test(w) && w.length >= 4 && !PARTICIPLE_BLOCKLIST[w]) return true;
    return false;
  }

  function isPureLetters(w) { return /^[A-Za-z'’]+$/.test(w); }

  /**
   * Detect passive-voice spans: a be-verb followed (optionally with one or
   * two intervening adverbs/words) by a past participle. Returns spans that
   * cover from the be-verb start to the participle end.
   */
  function detectPassive(words, text) {
    var spans = [];
    for (var i = 0; i < words.length; i++) {
      var w = words[i].text.toLowerCase();
      if (!BE_VERBS[w]) continue;
      // Look ahead up to 2 tokens for a participle.
      for (var j = i + 1; j <= i + 2 && j < words.length; j++) {
        var cand = words[j].text;
        if (looksLikePastParticiple(cand)) {
          spans.push({
            start: words[i].start,
            end: words[j].end,
            type: 'passive',
            text: text.slice(words[i].start, words[j].end)
          });
          break;
        }
        // Only skip over a single adverb/short word; otherwise stop.
        if (!/ly$/.test(cand.toLowerCase()) && j > i + 1) break;
      }
    }
    return spans;
  }

  function detectAdverbs(words) {
    var spans = [];
    for (var i = 0; i < words.length; i++) {
      var w = words[i].text.toLowerCase();
      if (w.length >= 4 && /ly$/.test(w) && !ADVERB_STOPLIST[w] &&
          isPureLetters(w)) {
        spans.push({
          start: words[i].start,
          end: words[i].end,
          type: 'adverb',
          text: words[i].text
        });
      }
    }
    return spans;
  }

  function detectFiller(text, words) {
    var spans = [];
    var lower = text.toLowerCase();
    // Multi-word phrases via regex on word boundaries.
    for (var p = 0; p < FILLER_PHRASES.length; p++) {
      var phrase = FILLER_PHRASES[p];
      var re = new RegExp('\\b' + phrase.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\b', 'g');
      var m;
      while ((m = re.exec(lower)) !== null) {
        spans.push({
          start: m.index,
          end: m.index + phrase.length,
          type: 'filler',
          text: text.slice(m.index, m.index + phrase.length)
        });
        if (m.index === re.lastIndex) re.lastIndex++;
      }
    }
    // Single words.
    for (var i = 0; i < words.length; i++) {
      var lw = words[i].text.toLowerCase();
      if (FILLER_WORDS[lw]) {
        spans.push({
          start: words[i].start,
          end: words[i].end,
          type: 'filler',
          text: words[i].text
        });
      }
    }
    return spans;
  }

  function detectComplex(words) {
    var spans = [];
    for (var i = 0; i < words.length; i++) {
      if (countSyllables(words[i].text) >= 3 && isPureLetters(words[i].text)) {
        spans.push({
          start: words[i].start,
          end: words[i].end,
          type: 'complex',
          text: words[i].text
        });
      }
    }
    return spans;
  }

  function detectLongSentences(sentences, threshold) {
    var spans = [];
    for (var i = 0; i < sentences.length; i++) {
      var wc = tokenizeWords(sentences[i].text).length;
      if (wc > threshold) {
        spans.push({
          start: sentences[i].start,
          end: sentences[i].end,
          type: 'long',
          words: wc,
          text: sentences[i].text
        });
      }
    }
    return spans;
  }

  // ---------------------------------------------------------------------------
  // Per-sentence readability + full analysis
  // ---------------------------------------------------------------------------

  function statsForText(text) {
    var words = tokenizeWords(text);
    var syllables = 0, complexWords = 0, polysyllables = 0, characters = 0;
    for (var i = 0; i < words.length; i++) {
      var sy = countSyllables(words[i].text);
      syllables += sy;
      if (sy >= 3) { complexWords++; polysyllables++; }
      characters += words[i].text.replace(/[^A-Za-z0-9]/g, '').length;
    }
    var sentences = splitSentences(text);
    return {
      words: words.length,
      sentences: sentences.length,
      syllables: syllables,
      complexWords: complexWords,
      polysyllables: polysyllables,
      characters: characters
    };
  }

  function readabilityScores(stats) {
    return {
      fleschReadingEase: fleschReadingEase(stats),
      fleschKincaidGrade: fleschKincaidGrade(stats),
      gunningFog: gunningFog(stats),
      smog: smog(stats),
      automatedReadabilityIndex: automatedReadabilityIndex(stats),
      colemanLiau: colemanLiau(stats)
    };
  }

  // Map Flesch Reading Ease to a calm qualitative label.
  function easeLabel(score) {
    if (score == null) return '—';
    if (score >= 90) return 'Very easy';
    if (score >= 70) return 'Easy';
    if (score >= 60) return 'Plain';
    if (score >= 50) return 'Fairly hard';
    if (score >= 30) return 'Hard';
    return 'Very hard';
  }

  /**
   * Full analysis. Returns stats, scores, per-sentence detail (ranked by
   * difficulty), sentence-length distribution, and highlight spans by type.
   * `options`: { longThreshold }.
   */
  function analyze(text, options) {
    options = options || {};
    var longThreshold = options.longThreshold || 25;
    text = text == null ? '' : String(text);

    var words = tokenizeWords(text);
    var sentences = splitSentences(text);
    var stats = statsForText(text);
    var scores = readabilityScores(stats);

    // Per-sentence detail.
    var perSentence = [];
    var lengths = [];
    for (var i = 0; i < sentences.length; i++) {
      var st = statsForText(sentences[i].text);
      var wc = st.words;
      lengths.push(wc);
      var fk = fleschKincaidGrade(st);
      perSentence.push({
        index: i,
        text: sentences[i].text,
        start: sentences[i].start,
        end: sentences[i].end,
        words: wc,
        grade: fk,
        ease: fleschReadingEase(st)
      });
    }

    // Ranked hardest sentences (by FK grade, tie-break on length). Only
    // sentences with at least 3 words to avoid noise.
    var ranked = perSentence
      .filter(function (s) { return s.words >= 3 && s.grade != null; })
      .slice()
      .sort(function (a, b) {
        if (b.grade !== a.grade) return b.grade - a.grade;
        return b.words - a.words;
      });

    // Sentence-length distribution (histogram buckets).
    var buckets = [
      { label: '1-5', min: 1, max: 5, count: 0 },
      { label: '6-10', min: 6, max: 10, count: 0 },
      { label: '11-15', min: 11, max: 15, count: 0 },
      { label: '16-20', min: 16, max: 20, count: 0 },
      { label: '21-25', min: 21, max: 25, count: 0 },
      { label: '26-30', min: 26, max: 30, count: 0 },
      { label: '31+', min: 31, max: Infinity, count: 0 }
    ];
    for (var L = 0; L < lengths.length; L++) {
      for (var b = 0; b < buckets.length; b++) {
        if (lengths[L] >= buckets[b].min && lengths[L] <= buckets[b].max) {
          buckets[b].count++;
          break;
        }
      }
    }

    // Mean and variance of sentence length.
    var mean = 0, variance = 0;
    if (lengths.length > 0) {
      var sum = 0;
      for (var a = 0; a < lengths.length; a++) sum += lengths[a];
      mean = sum / lengths.length;
      var sq = 0;
      for (var c = 0; c < lengths.length; c++) {
        sq += (lengths[c] - mean) * (lengths[c] - mean);
      }
      variance = sq / lengths.length;
    }

    var longest = null;
    for (var d = 0; d < perSentence.length; d++) {
      if (!longest || perSentence[d].words > longest.words) longest = perSentence[d];
    }

    // Reading time at 220 wpm.
    var readingMinutes = stats.words / 220;

    // Highlight spans.
    var highlights = {
      long: detectLongSentences(sentences, longThreshold),
      passive: detectPassive(words, text),
      adverb: detectAdverbs(words),
      filler: detectFiller(text, words),
      complex: detectComplex(words)
    };

    return {
      stats: {
        words: stats.words,
        sentences: stats.sentences,
        paragraphs: countParagraphs(text),
        characters: text.length,
        letters: stats.characters,
        syllables: stats.syllables,
        complexWords: stats.complexWords,
        avgSentenceLength: mean,
        sentenceLengthVariance: variance,
        sentenceLengthStdDev: Math.sqrt(variance),
        readingMinutes: readingMinutes
      },
      scores: scores,
      easeLabel: easeLabel(scores.fleschReadingEase),
      perSentence: perSentence,
      rankedHardest: ranked,
      longestSentence: longest,
      distribution: buckets,
      highlights: highlights
    };
  }

  return {
    splitSentences: splitSentences,
    tokenizeWords: tokenizeWords,
    countParagraphs: countParagraphs,
    countSyllables: countSyllables,
    countSyllablesInText: countSyllablesInText,
    statsForText: statsForText,
    readabilityScores: readabilityScores,
    fleschReadingEase: fleschReadingEase,
    fleschKincaidGrade: fleschKincaidGrade,
    gunningFog: gunningFog,
    smog: smog,
    automatedReadabilityIndex: automatedReadabilityIndex,
    colemanLiau: colemanLiau,
    detectPassive: detectPassive,
    detectAdverbs: detectAdverbs,
    detectFiller: detectFiller,
    detectComplex: detectComplex,
    detectLongSentences: detectLongSentences,
    easeLabel: easeLabel,
    analyze: analyze
  };
});
