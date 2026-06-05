/**
 * seed.js — Sample decks and cards for Recall.
 * Provides 3 realistic decks with ~30 cards total,
 * some with varied SM-2 scheduling states.
 */

'use strict';

function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
}

/**
 * Generate seed data. Called fresh each time so IDs are unique.
 * Returns { decks: [...], cards: [...], reviewLog: [] }
 */
function generateSeedData() {
  const today = SM2.todayISO();

  // Helper: card due N days ago (negative = future)
  function dueOffset(n) {
    return SM2.addDays(today, n);
  }

  // Build a card with full SM-2 state
  function makeCard(deckId, front, back, tags, sm2Override) {
    const base = SM2.newCardState();
    return {
      id: generateId(),
      deckId,
      front,
      back,
      tags: tags || [],
      ...base,
      ...sm2Override,
      lapses: (sm2Override && sm2Override.lapses) || 0,
      lastReviewed: (sm2Override && sm2Override.lastReviewed) || null,
      totalReviews: (sm2Override && sm2Override.totalReviews) || 0,
      created: today
    };
  }

  // ── Deck 1: Spanish Essentials ──────────────────────────────────────────
  const d1 = { id: generateId(), name: 'Spanish Essentials', description: 'Core vocabulary and phrases for everyday Spanish conversation.', color: '#86C79A', glyph: '🇪🇸', created: today };

  const d1cards = [
    makeCard(d1.id, 'hola', 'hello', ['greeting'], { ef: 2.8, n: 5, interval: 21, dueDate: dueOffset(2), totalReviews: 5 }),
    makeCard(d1.id, 'gracias', 'thank you', ['courtesy'], { ef: 2.6, n: 4, interval: 12, dueDate: dueOffset(-1), totalReviews: 4 }),
    makeCard(d1.id, 'por favor', 'please', ['courtesy'], { ef: 2.5, n: 3, interval: 6, dueDate: dueOffset(0), totalReviews: 3 }),
    makeCard(d1.id, '¿Cómo estás?', 'How are you?', ['greeting', 'question'], { ef: 2.4, n: 2, interval: 6, dueDate: dueOffset(-2), totalReviews: 2 }),
    makeCard(d1.id, 'buenos días', 'good morning', ['greeting', 'time'], { ef: 2.5, n: 1, interval: 1, dueDate: dueOffset(0), totalReviews: 1 }),
    makeCard(d1.id, 'buenas noches', 'good night', ['greeting', 'time'], { ef: 2.5, n: 0, interval: 0, dueDate: dueOffset(0), totalReviews: 0 }),
    makeCard(d1.id, 'sí / no', 'yes / no', ['basics'], { ef: 2.9, n: 6, interval: 30, dueDate: dueOffset(8), totalReviews: 6 }),
    makeCard(d1.id, '¿Dónde está el baño?', 'Where is the bathroom?', ['travel', 'question'], { ef: 2.2, n: 1, interval: 1, dueDate: dueOffset(-3), totalReviews: 3, lapses: 2 }),
    makeCard(d1.id, 'Me llamo…', 'My name is…', ['introduction'], { ef: 2.5, n: 0, interval: 0, dueDate: dueOffset(0), totalReviews: 0 }),
    makeCard(d1.id, 'No entiendo', 'I don\'t understand', ['communication'], { ef: 2.3, n: 2, interval: 4, dueDate: dueOffset(-1), totalReviews: 2 }),
  ];

  // ── Deck 2: Capital Cities ───────────────────────────────────────────────
  const d2 = { id: generateId(), name: 'Capital Cities', description: 'Match every country to its capital city. Geography trivia for the curious.', color: '#7AADCC', glyph: '🌍', created: today };

  const d2cards = [
    makeCard(d2.id, 'Capital of France', 'Paris', ['europe'], { ef: 2.7, n: 4, interval: 15, dueDate: dueOffset(3), totalReviews: 4 }),
    makeCard(d2.id, 'Capital of Japan', 'Tokyo', ['asia'], { ef: 2.6, n: 3, interval: 9, dueDate: dueOffset(0), totalReviews: 3 }),
    makeCard(d2.id, 'Capital of Brazil', 'Brasília', ['south-america'], { ef: 2.2, n: 2, interval: 3, dueDate: dueOffset(-1), totalReviews: 4, lapses: 1 }),
    makeCard(d2.id, 'Capital of Australia', 'Canberra', ['oceania'], { ef: 1.8, n: 1, interval: 1, dueDate: dueOffset(-2), totalReviews: 6, lapses: 3 }),
    makeCard(d2.id, 'Capital of Canada', 'Ottawa', ['north-america'], { ef: 2.5, n: 0, interval: 0, dueDate: dueOffset(0), totalReviews: 0 }),
    makeCard(d2.id, 'Capital of Egypt', 'Cairo', ['africa', 'middle-east'], { ef: 2.4, n: 2, interval: 6, dueDate: dueOffset(1), totalReviews: 2 }),
    makeCard(d2.id, 'Capital of Germany', 'Berlin', ['europe'], { ef: 2.8, n: 5, interval: 20, dueDate: dueOffset(5), totalReviews: 5 }),
    makeCard(d2.id, 'Capital of South Korea', 'Seoul', ['asia'], { ef: 2.5, n: 1, interval: 1, dueDate: dueOffset(0), totalReviews: 1 }),
    makeCard(d2.id, 'Capital of Argentina', 'Buenos Aires', ['south-america'], { ef: 2.3, n: 2, interval: 5, dueDate: dueOffset(-1), totalReviews: 3 }),
    makeCard(d2.id, 'Capital of Nigeria', 'Abuja', ['africa'], { ef: 1.9, n: 1, interval: 1, dueDate: dueOffset(-4), totalReviews: 4, lapses: 2 }),
  ];

  // ── Deck 3: JS Array Methods ─────────────────────────────────────────────
  const d3 = { id: generateId(), name: 'JS Array Methods', description: 'Master JavaScript\'s built-in array methods — signatures, return values, mutation.', color: '#C79A86', glyph: '⚡', created: today };

  const d3cards = [
    makeCard(d3.id, 'Array.prototype.map(fn)', 'Returns a NEW array with fn applied to each element. Does not mutate.', ['transform'], { ef: 2.7, n: 3, interval: 9, dueDate: dueOffset(2), totalReviews: 3 }),
    makeCard(d3.id, 'Array.prototype.filter(fn)', 'Returns a NEW array of elements where fn returns truthy. Does not mutate.', ['filter'], { ef: 2.5, n: 2, interval: 6, dueDate: dueOffset(0), totalReviews: 2 }),
    makeCard(d3.id, 'Array.prototype.reduce(fn, init)', 'Accumulates array to single value. fn(acc, cur, idx, arr). Returns final accumulator.', ['reduce'], { ef: 2.1, n: 2, interval: 3, dueDate: dueOffset(-1), totalReviews: 5, lapses: 2 }),
    makeCard(d3.id, 'Array.prototype.find(fn)', 'Returns the FIRST element where fn is truthy, or undefined.', ['search'], { ef: 2.5, n: 1, interval: 1, dueDate: dueOffset(0), totalReviews: 1 }),
    makeCard(d3.id, 'Array.prototype.some(fn)', 'Returns true if at least ONE element satisfies fn. Short-circuits.', ['predicate'], { ef: 2.5, n: 0, interval: 0, dueDate: dueOffset(0), totalReviews: 0 }),
    makeCard(d3.id, 'Array.prototype.every(fn)', 'Returns true if ALL elements satisfy fn. Short-circuits on first false.', ['predicate'], { ef: 2.5, n: 0, interval: 0, dueDate: dueOffset(0), totalReviews: 0 }),
    makeCard(d3.id, 'Array.prototype.flat(depth)', 'Flattens nested arrays up to depth (default 1). Returns new array.', ['transform'], { ef: 2.4, n: 1, interval: 1, dueDate: dueOffset(-1), totalReviews: 2 }),
    makeCard(d3.id, 'Array.prototype.includes(val)', 'Returns boolean — whether val is in the array. Uses SameValueZero.', ['search'], { ef: 2.6, n: 2, interval: 7, dueDate: dueOffset(3), totalReviews: 2 }),
    makeCard(d3.id, 'Array.prototype.splice(start, dc, ...items)', 'MUTATES array: removes dc elements from start, optionally inserts items. Returns removed elements.', ['mutation'], { ef: 1.9, n: 2, interval: 2, dueDate: dueOffset(-2), totalReviews: 6, lapses: 3 }),
    makeCard(d3.id, 'Array.from(arrayLike, mapFn?)', 'Creates array from iterable/array-like. Optional mapFn applied element-wise.', ['creation'], { ef: 2.3, n: 1, interval: 1, dueDate: dueOffset(0), totalReviews: 2 }),
  ];

  const decks = [d1, d2, d3];
  const cards = [...d1cards, ...d2cards, ...d3cards];

  // Build a minimal review log for the pre-scheduled cards
  const reviewLog = [];
  const logDate = SM2.addDays(today, -1);
  for (const card of cards) {
    if (card.totalReviews > 0) {
      reviewLog.push({
        id: generateId(),
        cardId: card.id,
        deckId: card.deckId,
        date: logDate,
        quality: 4,
        resultingInterval: card.interval
      });
    }
  }

  return { decks, cards, reviewLog };
}

// Exposed globally
const SEED = { generateSeedData };
