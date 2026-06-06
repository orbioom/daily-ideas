/*
 * analysis.test.js — documented verification harness for the Limpid engine.
 *
 * Run with:  node analysis.test.js
 *
 * This is a developer test file (NOT shipped to / loaded by the browser
 * app). It exercises the pure analysis engine in analysis.js: the syllable
 * counter, the six readability formulas (sanity ranges + direction), and the
 * passive / adverb / filler / complex span detectors. It exits non-zero if
 * any assertion fails so it can gate a build.
 */
'use strict';

var A = require('./analysis.js');

var failures = 0;
function check(name, cond, detail) {
  if (cond) {
    console.log('  ok   ' + name + (detail ? '  (' + detail + ')' : ''));
  } else {
    failures++;
    console.log('  FAIL ' + name + (detail ? '  (' + detail + ')' : ''));
  }
}
function approx(a, b, tol) { return Math.abs(a - b) <= tol; }

console.log('Syllable counter:');
var sylCases = {
  syllable: 3, queue: 1, create: 2, happy: 2, table: 2, year: 1,
  the: 1, business: 2, people: 2, reality: 4, simple: 2, strength: 1,
  university: 5, idea: 3
};
Object.keys(sylCases).forEach(function (w) {
  var got = A.countSyllables(w);
  check('syllable("' + w + '") = ' + sylCases[w], got === sylCases[w], 'got ' + got);
});

console.log('\nTokenizers:');
var tk = 'Dr. Smith went home. He left at 3.14 p.m. Did he? Yes!';
var sents = A.splitSentences(tk);
check('sentence split ignores abbreviations/decimals', sents.length === 3, sents.length + ' sentences');
check('word tokenizer counts words', A.tokenizeWords('one two three').length === 3);

console.log('\nReadability — simple vs dense (direction + sane ranges):');
var simple = 'The cat sat on the mat. The dog ran fast. We had fun.';
var dense = 'The aforementioned epistemological framework necessitates a comprehensive reconceptualization of fundamental methodological presuppositions.';
var sStats = A.statsForText(simple);
var dStats = A.statsForText(dense);
var sFre = A.fleschReadingEase(sStats), dFre = A.fleschReadingEase(dStats);
var sFk = A.fleschKincaidGrade(sStats), dFk = A.fleschKincaidGrade(dStats);
check('simple Flesch Reading Ease is high (>= 80)', sFre >= 80, sFre.toFixed(1));
check('dense Flesch Reading Ease is low (< 30)', dFre < 30, dFre.toFixed(1));
check('simple FK grade < dense FK grade', sFk < dFk, sFk.toFixed(1) + ' < ' + dFk.toFixed(1));
check('all six formulas return numbers on real text',
  ['fleschReadingEase', 'fleschKincaidGrade', 'gunningFog', 'smog', 'automatedReadabilityIndex', 'colemanLiau']
    .every(function (k) { var v = A.readabilityScores(dStats)[k]; return typeof v === 'number' && isFinite(v); }));

console.log('\nKnown-reference sentence (textstat-style ranges):');
// "The quick brown fox jumps over the lazy dog." — a common reference line.
var ref = A.statsForText('The quick brown fox jumps over the lazy dog.');
var refFre = A.fleschReadingEase(ref);
check('reference line Flesch Reading Ease in plausible 90-120 band', refFre >= 90 && refFre <= 120, refFre.toFixed(1));

console.log('\nDegenerate input returns null scores (no divide-by-zero):');
var empty = A.statsForText('');
check('empty text Flesch Reading Ease is null', A.fleschReadingEase(empty) === null);
check('only-punctuation text has 0 words', A.statsForText('!?!! ... ;;;').words === 0);
check('analyze("") does not throw and reports 0 words', A.analyze('').stats.words === 0);

console.log('\nSpan detectors:');
var passT = 'The report was written by the committee and the door was opened.';
var passSpans = A.detectPassive(A.tokenizeWords(passT), passT).map(function (s) { return s.text; });
check('passive detects "was written"', passSpans.indexOf('was written') !== -1, passSpans.join(' | '));
check('passive detects "was opened"', passSpans.indexOf('was opened') !== -1);

var advT = 'She quickly and carefully opened it, but only barely.';
var advSpans = A.detectAdverbs(A.tokenizeWords(advT)).map(function (s) { return s.text; });
check('adverb detects quickly/carefully/barely', advSpans.indexOf('quickly') !== -1 && advSpans.indexOf('carefully') !== -1 && advSpans.indexOf('barely') !== -1, advSpans.join(' | '));
check('adverb stoplist excludes "only"', advSpans.indexOf('only') === -1);

var fillT = 'This is very really just basically in order to test things.';
var fillSpans = A.detectFiller(fillT, A.tokenizeWords(fillT)).map(function (s) { return s.text; });
check('filler detects single words', ['very', 'really', 'just', 'basically'].every(function (w) { return fillSpans.indexOf(w) !== -1; }), fillSpans.join(' | '));
check('filler detects "in order to" phrase', fillSpans.indexOf('in order to') !== -1);

var cmpT = 'The extraordinary committee deliberated.';
var cmpSpans = A.detectComplex(A.tokenizeWords(cmpT)).map(function (s) { return s.text; });
check('complex detects 3+ syllable words', cmpSpans.indexOf('extraordinary') !== -1 && cmpSpans.indexOf('committee') !== -1, cmpSpans.join(' | '));

console.log('\nSpan offsets align to original text:');
var alignT = 'It was clearly done.';
var aSpans = A.analyze(alignT).highlights.passive;
var aligned = aSpans.length > 0 && alignT.slice(aSpans[0].start, aSpans[0].end) === aSpans[0].text;
check('passive span slice matches its text field', aligned, aSpans.length ? aSpans[0].text : 'none');

var longT = 'one two three four five six seven eight nine ten eleven twelve.';
var longSpans = A.analyze(longT, { longThreshold: 5 }).highlights.long;
check('long-sentence threshold flags a 12-word sentence at threshold 5', longSpans.length === 1, longSpans.length + ' spans');

console.log('\n' + (failures === 0 ? 'ALL CHECKS PASSED' : failures + ' CHECK(S) FAILED'));
process.exit(failures === 0 ? 0 : 1);
