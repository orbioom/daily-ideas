/**
 * app.js — Recall spaced-repetition flashcard app.
 * Main application controller: routing, CRUD, study sessions, settings.
 * Depends on: sm2.js, storage.js, seed.js, stats.js (loaded before this file).
 */

'use strict';

// ──────────────────────────────────────────────────────────────
// App State
// ──────────────────────────────────────────────────────────────

var AppState = {
  decks: [],
  cards: [],
  reviewLog: [],
  settings: {},

  // UI state (not persisted)
  currentPage: 'decks',
  activeDeckId: null,       // deck being viewed/studied
  session: null,            // active study session object
};

// ──────────────────────────────────────────────────────────────
// Initialization
// ──────────────────────────────────────────────────────────────

function init() {
  var loaded = Storage.load();
  AppState.decks = loaded.decks;
  AppState.cards = loaded.cards;
  AppState.reviewLog = loaded.reviewLog;
  AppState.settings = loaded.settings;

  // Seed if empty
  if (AppState.decks.length === 0) {
    var seedData = SEED.generateSeedData();
    AppState.decks = seedData.decks;
    AppState.cards = seedData.cards;
    AppState.reviewLog = seedData.reviewLog;
    persist();
  }

  applyTheme(AppState.settings.theme);
  applyReducedMotion(AppState.settings.reducedMotion);

  bindNav();
  bindKeyboard();
  navigateTo('decks');
}

// ──────────────────────────────────────────────────────────────
// Persistence
// ──────────────────────────────────────────────────────────────

function persist() {
  try {
    Storage.save({
      decks: AppState.decks,
      cards: AppState.cards,
      reviewLog: AppState.reviewLog,
      settings: AppState.settings
    });
  } catch (e) {
    showToast('Could not save — storage may be full.', 'error');
  }
}

// ──────────────────────────────────────────────────────────────
// Theme
// ──────────────────────────────────────────────────────────────

function applyTheme(theme) {
  if (theme === 'dark') {
    document.documentElement.setAttribute('data-theme', 'dark');
  } else if (theme === 'light') {
    document.documentElement.removeAttribute('data-theme');
  } else {
    // System
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      document.documentElement.setAttribute('data-theme', 'dark');
    } else {
      document.documentElement.removeAttribute('data-theme');
    }
  }
}

function applyReducedMotion(on) {
  if (on) {
    document.documentElement.setAttribute('data-reduced-motion', 'true');
  } else {
    document.documentElement.removeAttribute('data-reduced-motion');
  }
}

// ──────────────────────────────────────────────────────────────
// Navigation
// ──────────────────────────────────────────────────────────────

function bindNav() {
  document.querySelectorAll('.nav-tab').forEach(function(btn) {
    btn.addEventListener('click', function() {
      navigateTo(btn.dataset.page);
    });
  });
}

function navigateTo(page, extra) {
  AppState.currentPage = page;

  // Update nav tabs
  document.querySelectorAll('.nav-tab').forEach(function(btn) {
    btn.classList.toggle('active', btn.dataset.page === page);
    btn.setAttribute('aria-current', btn.dataset.page === page ? 'page' : 'false');
  });

  // Show correct page
  document.querySelectorAll('.page').forEach(function(el) {
    el.classList.remove('active');
  });

  var pageEl = document.getElementById('page-' + page);
  if (pageEl) {
    pageEl.classList.add('active');
  }

  // Render page content
  switch (page) {
    case 'decks':
      renderDecksPage();
      break;
    case 'study':
      renderStudyPageStart(extra);
      break;
    case 'stats':
      renderStatsPage();
      break;
    case 'settings':
      renderSettingsPage();
      break;
    case 'deck-detail':
      // Rendered directly by openDeckDetail — no extra rendering needed here
      break;
    default:
      renderDecksPage();
  }
}

// ──────────────────────────────────────────────────────────────
// Global Keyboard
// ──────────────────────────────────────────────────────────────

function bindKeyboard() {
  document.addEventListener('keydown', function(e) {
    // Don't steal keys from inputs/textareas
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') return;

    // Study session keyboard shortcuts
    if (AppState.session && AppState.session.phase === 'review') {
      if (e.key === ' ' || e.key === 'Enter') {
        e.preventDefault();
        if (!AppState.session.revealed) {
          revealCard();
        }
        return;
      }
      if (AppState.session.revealed) {
        var ratingMap = { '1': 'again', '2': 'hard', '3': 'good', '4': 'easy' };
        if (ratingMap[e.key]) {
          e.preventDefault();
          rateCard(ratingMap[e.key]);
          return;
        }
      }
    }

    // Esc closes any open modal
    if (e.key === 'Escape') {
      var backdrop = document.querySelector('.modal-backdrop:not(.hidden)');
      if (backdrop) {
        closeModal(backdrop);
      }
    }
  });
}

// ──────────────────────────────────────────────────────────────
// Toast notifications
// ──────────────────────────────────────────────────────────────

function showToast(msg, type, duration) {
  duration = duration || 3000;
  var container = document.getElementById('toast-container');
  var toast = document.createElement('div');
  toast.className = 'toast' + (type === 'success' ? ' toast-success' : type === 'error' ? ' toast-error' : '');
  toast.textContent = msg;
  toast.setAttribute('role', 'status');
  toast.setAttribute('aria-live', 'polite');
  toast.style.setProperty('--toast-delay', duration + 'ms');

  container.appendChild(toast);

  setTimeout(function() {
    if (toast.parentNode) toast.parentNode.removeChild(toast);
  }, duration + 400);
}

// ──────────────────────────────────────────────────────────────
// Modal helpers
// ──────────────────────────────────────────────────────────────

var _prevFocus = null;

function openModal(modalId) {
  _prevFocus = document.activeElement;
  var backdrop = document.getElementById(modalId);
  backdrop.classList.remove('hidden');
  // Focus first focusable element
  var first = backdrop.querySelector('input, select, textarea, button, [tabindex]');
  if (first) first.focus();

  // Trap focus
  backdrop.addEventListener('keydown', trapFocus);
}

function closeModal(backdropOrId) {
  var backdrop = typeof backdropOrId === 'string'
    ? document.getElementById(backdropOrId)
    : backdropOrId;
  if (!backdrop) return;
  backdrop.classList.add('hidden');
  backdrop.removeEventListener('keydown', trapFocus);
  if (_prevFocus) { _prevFocus.focus(); _prevFocus = null; }
}

function trapFocus(e) {
  if (e.key !== 'Tab') return;
  var focusable = Array.from(e.currentTarget.querySelectorAll(
    'button, input, select, textarea, [href], [tabindex]:not([tabindex="-1"])'
  )).filter(function(el) { return !el.disabled && el.offsetParent !== null; });

  if (focusable.length === 0) return;
  var first = focusable[0];
  var last = focusable[focusable.length - 1];

  if (e.shiftKey) {
    if (document.activeElement === first) { e.preventDefault(); last.focus(); }
  } else {
    if (document.activeElement === last) { e.preventDefault(); first.focus(); }
  }
}

// Generic confirm dialog
function showConfirm(title, message, onConfirm) {
  var modal = document.getElementById('modal-confirm');
  modal.querySelector('.confirm-title').textContent = title;
  modal.querySelector('.confirm-message').textContent = message;

  var confirmBtn = modal.querySelector('.confirm-ok');
  var cancelBtn = modal.querySelector('.confirm-cancel');

  // Remove old listeners by cloning
  var newConfirm = confirmBtn.cloneNode(true);
  confirmBtn.parentNode.replaceChild(newConfirm, confirmBtn);
  var newCancel = cancelBtn.cloneNode(true);
  cancelBtn.parentNode.replaceChild(newCancel, cancelBtn);

  newConfirm.addEventListener('click', function() {
    closeModal('modal-confirm');
    onConfirm();
  });
  newCancel.addEventListener('click', function() { closeModal('modal-confirm'); });

  openModal('modal-confirm');
}

// ──────────────────────────────────────────────────────────────
// Decks Page
// ──────────────────────────────────────────────────────────────

function renderDecksPage() {
  var container = document.getElementById('decks-container');
  container.innerHTML = '';

  if (AppState.decks.length === 0) {
    container.innerHTML = renderEmptyState(
      '🗂️',
      'No decks yet',
      'Create your first deck to start building a study set.',
      null
    );
    return;
  }

  var today = SM2.todayISO();

  AppState.decks.forEach(function(deck) {
    var deckCards = AppState.cards.filter(function(c) { return c.deckId === deck.id; });
    var dueCards = deckCards.filter(function(c) { return SM2.isDue(c, today); });
    var dueCount = Math.min(dueCards.length, AppState.settings.maxReviewsPerSession);

    var div = document.createElement('div');
    div.className = 'glass card deck-card';
    div.setAttribute('role', 'article');
    div.setAttribute('aria-label', deck.name + ' deck');

    div.innerHTML =
      '<div class="deck-card-header">' +
        '<span class="deck-glyph" aria-hidden="true">' + escHtml(deck.glyph) + '</span>' +
        '<div class="flex-col" style="min-width:0;flex:1">' +
          '<div class="deck-card-title">' + escHtml(deck.name) + '</div>' +
          '<div class="deck-card-desc">' + escHtml(deck.description || 'No description.') + '</div>' +
        '</div>' +
      '</div>' +
      '<div class="deck-card-footer">' +
        '<span class="deck-stat mono">' + deckCards.length + ' card' + (deckCards.length !== 1 ? 's' : '') + '</span>' +
        (dueCount > 0
          ? '<span class="badge-due" aria-label="' + dueCount + ' due">● ' + dueCount + ' due</span>'
          : '<span class="deck-stat mono" style="color:var(--text-tertiary)">Nothing due</span>'
        ) +
        '<div class="deck-actions">' +
          '<button class="btn btn-sm btn-glass" data-action="edit-deck" data-id="' + deck.id + '" aria-label="Edit ' + escHtml(deck.name) + '">Edit</button>' +
          '<button class="btn btn-sm btn-glass" data-action="view-deck" data-id="' + deck.id + '" aria-label="View cards in ' + escHtml(deck.name) + '">Cards</button>' +
          '<button class="btn btn-sm btn-primary" data-action="study-deck" data-id="' + deck.id + '" aria-label="Study ' + escHtml(deck.name) + '">' +
            (dueCount > 0 ? 'Study' : 'Review') +
          '</button>' +
        '</div>' +
      '</div>';

    container.appendChild(div);
  });

  // Event delegation is set up once at init (see DOMContentLoaded)

}

// ──────────────────────────────────────────────────────────────
// Deck CRUD
// ──────────────────────────────────────────────────────────────

var DECK_COLORS = ['#86C79A','#7AADCC','#C79A86','#C7A27A','#9A86C7','#C786C7','#C7C086','#6FA8C9'];
var DECK_GLYPHS = ['📚','🗂️','🌍','⚡','🧪','🎯','🔬','🌱','🏛️','🎨','💡','🧩'];

function openCreateDeckModal() {
  var modal = document.getElementById('modal-deck');
  modal.querySelector('.modal-title').textContent = 'New Deck';
  modal.querySelector('#deck-name').value = '';
  modal.querySelector('#deck-desc').value = '';

  // Reset color/glyph selections
  setDeckColorSelection('#86C79A');
  setDeckGlyphSelection('📚');

  modal.dataset.editId = '';
  openModal('modal-deck');
}

function openEditDeckModal(deckId) {
  var deck = AppState.decks.find(function(d) { return d.id === deckId; });
  if (!deck) return;

  var modal = document.getElementById('modal-deck');
  modal.querySelector('.modal-title').textContent = 'Edit Deck';
  modal.querySelector('#deck-name').value = deck.name;
  modal.querySelector('#deck-desc').value = deck.description || '';

  setDeckColorSelection(deck.color);
  setDeckGlyphSelection(deck.glyph);

  modal.dataset.editId = deckId;
  openModal('modal-deck');
}

function setDeckColorSelection(color) {
  document.querySelectorAll('.color-option').forEach(function(btn) {
    btn.classList.toggle('selected', btn.dataset.color === color);
    btn.setAttribute('aria-pressed', btn.dataset.color === color ? 'true' : 'false');
  });
}

function setDeckGlyphSelection(glyph) {
  document.querySelectorAll('.glyph-option').forEach(function(btn) {
    btn.classList.toggle('selected', btn.dataset.glyph === glyph);
    btn.setAttribute('aria-pressed', btn.dataset.glyph === glyph ? 'true' : 'false');
  });
}

function getSelectedColor() {
  var btn = document.querySelector('.color-option.selected');
  return btn ? btn.dataset.color : '#86C79A';
}

function getSelectedGlyph() {
  var btn = document.querySelector('.glyph-option.selected');
  return btn ? btn.dataset.glyph : '📚';
}

function saveDeck() {
  var modal = document.getElementById('modal-deck');
  var name = modal.querySelector('#deck-name').value.trim();
  var desc = modal.querySelector('#deck-desc').value.trim();
  var color = getSelectedColor();
  var glyph = getSelectedGlyph();

  // Validation
  if (!name) {
    modal.querySelector('#deck-name').focus();
    showFieldError(modal.querySelector('#deck-name'), 'Deck name is required.');
    return;
  }

  clearFieldErrors(modal);

  var editId = modal.dataset.editId;

  if (editId) {
    // Update existing
    var deck = AppState.decks.find(function(d) { return d.id === editId; });
    if (deck) {
      deck.name = name;
      deck.description = desc;
      deck.color = color;
      deck.glyph = glyph;
    }
    showToast('Deck updated.', 'success');
  } else {
    // Create new
    var newDeck = Storage.normalizeDeck({
      name: name,
      description: desc,
      color: color,
      glyph: glyph
    });
    AppState.decks.push(newDeck);
    showToast('Deck created.', 'success');
  }

  persist();
  closeModal('modal-deck');
  renderDecksPage();
}

function deleteDeck(deckId) {
  var deck = AppState.decks.find(function(d) { return d.id === deckId; });
  if (!deck) return;
  var cardCount = AppState.cards.filter(function(c) { return c.deckId === deckId; }).length;

  showConfirm(
    'Delete "' + deck.name + '"?',
    'This will permanently delete the deck and all ' + cardCount + ' card' + (cardCount !== 1 ? 's' : '') + '. This cannot be undone.',
    function() {
      AppState.decks = AppState.decks.filter(function(d) { return d.id !== deckId; });
      AppState.cards = AppState.cards.filter(function(c) { return c.deckId !== deckId; });
      AppState.reviewLog = AppState.reviewLog.filter(function(e) { return e.deckId !== deckId; });
      persist();
      navigateTo('decks');
      showToast('Deck deleted.', 'success');
    }
  );
}

// ──────────────────────────────────────────────────────────────
// Deck Detail (Cards list)
// ──────────────────────────────────────────────────────────────

function openDeckDetail(deckId) {
  AppState.activeDeckId = deckId;
  navigateTo('deck-detail');

  var deck = AppState.decks.find(function(d) { return d.id === deckId; });
  if (!deck) { navigateTo('decks'); return; }

  var page = document.getElementById('page-deck-detail');
  var today = SM2.todayISO();
  var deckCards = AppState.cards.filter(function(c) { return c.deckId === deckId; });
  var dueCards = deckCards.filter(function(c) { return SM2.isDue(c, today); });

  page.innerHTML =
    '<div class="deck-detail-header">' +
      '<span class="deck-detail-glyph" aria-hidden="true">' + escHtml(deck.glyph) + '</span>' +
      '<div class="deck-detail-info">' +
        '<h2>' + escHtml(deck.name) + '</h2>' +
        '<p>' + escHtml(deck.description || '') + '</p>' +
        '<div style="display:flex;gap:12px;margin-top:8px;">' +
          '<span class="deck-stat mono">' + deckCards.length + ' cards total</span>' +
          '<span class="badge-due">● ' + dueCards.length + ' due</span>' +
        '</div>' +
      '</div>' +
      '<div class="deck-detail-actions">' +
        '<button class="btn btn-ghost btn-sm" id="btn-back-decks" aria-label="Back to decks">← Back</button>' +
        '<button class="btn btn-glass btn-sm" id="btn-edit-this-deck">Edit Deck</button>' +
        '<button class="btn btn-danger btn-sm" id="btn-delete-deck">Delete Deck</button>' +
        '<button class="btn btn-primary" id="btn-study-this-deck">Study</button>' +
      '</div>' +
    '</div>' +
    '<div class="toolbar">' +
      '<button class="btn btn-glass btn-sm" id="btn-add-card">+ Add Card</button>' +
      '<button class="btn btn-glass btn-sm" id="btn-import-cards">Bulk Import</button>' +
    '</div>' +
    '<div id="deck-card-list"></div>';

  document.getElementById('btn-back-decks').addEventListener('click', function() { navigateTo('decks'); });
  document.getElementById('btn-edit-this-deck').addEventListener('click', function() { openEditDeckModal(deckId); });
  document.getElementById('btn-delete-deck').addEventListener('click', function() { deleteDeck(deckId); });
  document.getElementById('btn-study-this-deck').addEventListener('click', function() { navigateTo('study', { deckId: deckId }); });
  document.getElementById('btn-add-card').addEventListener('click', function() { openAddCardModal(deckId); });
  document.getElementById('btn-import-cards').addEventListener('click', function() { openBulkImportModal(deckId); });

  renderCardList(deckId);
}

function renderCardList(deckId) {
  var container = document.getElementById('deck-card-list');
  if (!container) return;
  var deckCards = AppState.cards.filter(function(c) { return c.deckId === deckId; });
  var today = SM2.todayISO();

  if (deckCards.length === 0) {
    container.innerHTML = renderEmptyState('🃏', 'No cards yet', 'Add your first card to this deck.', null);
    return;
  }

  var list = document.createElement('div');
  list.className = 'card-list';
  list.setAttribute('role', 'list');
  list.setAttribute('aria-label', 'Cards in deck');
  container.innerHTML = '';
  container.appendChild(list);

  deckCards.forEach(function(card) {
    var due = SM2.isDue(card, today);
    var item = document.createElement('div');
    item.className = 'card-item';
    item.setAttribute('role', 'listitem');

    item.innerHTML =
      '<div class="card-item-content">' +
        '<div class="card-item-front">' + escHtml(card.front) + '</div>' +
        '<div class="card-item-back">' + escHtml(card.back) + '</div>' +
        (card.tags && card.tags.length > 0
          ? '<div style="margin-top:4px;">' + card.tags.map(function(t) {
              return '<span class="tag-chip">' + escHtml(t) + '</span>';
            }).join('') + '</div>'
          : ''
        ) +
      '</div>' +
      '<div class="card-item-meta">' +
        '<span class="card-meta-ef mono" title="Easiness Factor">EF ' + card.ef.toFixed(2) + '</span>' +
        '<span class="card-meta-due mono' + (due ? ' due-now' : '') + '" title="Due date">' +
          (due ? 'Due' : card.dueDate) +
        '</span>' +
        '<button class="btn btn-sm btn-glass" data-action="edit-card" data-id="' + card.id + '" aria-label="Edit card">Edit</button>' +
        '<button class="btn btn-sm btn-danger" data-action="delete-card" data-id="' + card.id + '" aria-label="Delete card">✕</button>' +
      '</div>';

    list.appendChild(item);
  });

  // Single listener on freshly created list element — no stacking
  list.addEventListener('click', function(e) {
    var btn = e.target.closest('[data-action]');
    if (!btn) return;
    if (btn.dataset.action === 'edit-card') openEditCardModal(btn.dataset.id);
    if (btn.dataset.action === 'delete-card') deleteCard(btn.dataset.id);
  });
}

// ──────────────────────────────────────────────────────────────
// Card CRUD
// ──────────────────────────────────────────────────────────────

function openAddCardModal(deckId) {
  var modal = document.getElementById('modal-card');
  modal.querySelector('.modal-card-title').textContent = 'Add Card';
  modal.querySelector('#card-front').value = '';
  modal.querySelector('#card-back').value = '';
  modal.querySelector('#card-tags').value = '';
  modal.dataset.editId = '';
  modal.dataset.deckId = deckId;
  clearFieldErrors(modal);
  openModal('modal-card');
}

function openEditCardModal(cardId) {
  var card = AppState.cards.find(function(c) { return c.id === cardId; });
  if (!card) return;

  var modal = document.getElementById('modal-card');
  modal.querySelector('.modal-card-title').textContent = 'Edit Card';
  modal.querySelector('#card-front').value = card.front;
  modal.querySelector('#card-back').value = card.back;
  modal.querySelector('#card-tags').value = (card.tags || []).join(', ');
  modal.dataset.editId = cardId;
  modal.dataset.deckId = card.deckId;
  clearFieldErrors(modal);
  openModal('modal-card');
}

function saveCard() {
  var modal = document.getElementById('modal-card');
  var front = modal.querySelector('#card-front').value.trim();
  var back = modal.querySelector('#card-back').value.trim();
  var tagsRaw = modal.querySelector('#card-tags').value.trim();
  var tags = tagsRaw ? tagsRaw.split(',').map(function(t) { return t.trim(); }).filter(Boolean) : [];
  var deckId = modal.dataset.deckId;
  var editId = modal.dataset.editId;

  clearFieldErrors(modal);

  if (!front) {
    showFieldError(modal.querySelector('#card-front'), 'Front is required.');
    return;
  }
  if (!back) {
    showFieldError(modal.querySelector('#card-back'), 'Back is required.');
    return;
  }

  // Deduplicate check
  var deckCards = AppState.cards.filter(function(c) { return c.deckId === deckId; });
  var duplicate = deckCards.find(function(c) {
    return c.front.toLowerCase() === front.toLowerCase() && c.id !== editId;
  });
  if (duplicate) {
    showToast('A card with that front already exists in this deck.', 'error');
    return;
  }

  if (editId) {
    var card = AppState.cards.find(function(c) { return c.id === editId; });
    if (card) {
      card.front = front;
      card.back = back;
      card.tags = tags;
    }
    showToast('Card updated.', 'success');
  } else {
    var newCard = Storage.normalizeCard({
      deckId: deckId,
      front: front,
      back: back,
      tags: tags
    });
    AppState.cards.push(newCard);
    showToast('Card added.', 'success');
  }

  persist();
  closeModal('modal-card');
  if (AppState.activeDeckId) renderCardList(AppState.activeDeckId);
}

function deleteCard(cardId) {
  var card = AppState.cards.find(function(c) { return c.id === cardId; });
  if (!card) return;

  showConfirm(
    'Delete card?',
    'Delete "' + card.front + '"? This cannot be undone.',
    function() {
      AppState.cards = AppState.cards.filter(function(c) { return c.id !== cardId; });
      persist();
      if (AppState.activeDeckId) renderCardList(AppState.activeDeckId);
      showToast('Card deleted.', 'success');
    }
  );
}

// ──────────────────────────────────────────────────────────────
// Bulk Import
// ──────────────────────────────────────────────────────────────

function openBulkImportModal(deckId) {
  var modal = document.getElementById('modal-bulk');
  modal.querySelector('#bulk-text').value = '';
  modal.dataset.deckId = deckId;
  modal.querySelector('.bulk-preview').innerHTML = '';
  modal.querySelector('.bulk-result').textContent = '';
  openModal('modal-bulk');
}

function previewBulkImport() {
  var modal = document.getElementById('modal-bulk');
  var text = modal.querySelector('#bulk-text').value;
  var lines = text.split('\n').map(function(l) { return l.trim(); }).filter(Boolean);
  var preview = modal.querySelector('.bulk-preview');
  var result = modal.querySelector('.bulk-result');

  if (lines.length === 0) {
    preview.innerHTML = '';
    result.textContent = 'No valid lines yet.';
    return;
  }

  var valid = [];
  var invalid = [];

  lines.forEach(function(line) {
    var sep = line.indexOf('|');
    if (sep < 0) { invalid.push(line); return; }
    var front = line.slice(0, sep).trim();
    var back = line.slice(sep + 1).trim();
    if (!front || !back) { invalid.push(line); return; }
    valid.push({ front: front, back: back });
  });

  result.textContent = valid.length + ' valid card' + (valid.length !== 1 ? 's' : '') +
    (invalid.length > 0 ? ', ' + invalid.length + ' skipped (missing " | " separator or empty side).' : '.');

  preview.innerHTML = valid.slice(0, 5).map(function(c) {
    return '<div style="padding:6px 0;border-bottom:1px solid var(--border);font-size:0.8125rem;">' +
      '<strong>' + escHtml(c.front) + '</strong> → ' + escHtml(c.back) + '</div>';
  }).join('') + (valid.length > 5 ? '<div style="font-size:0.75rem;color:var(--text-tertiary);padding-top:6px;">…and ' + (valid.length - 5) + ' more</div>' : '');
}

function commitBulkImport() {
  var modal = document.getElementById('modal-bulk');
  var text = modal.querySelector('#bulk-text').value;
  var deckId = modal.dataset.deckId;
  var lines = text.split('\n').map(function(l) { return l.trim(); }).filter(Boolean);

  if (lines.length === 0) {
    showToast('Nothing to import.', 'error');
    return;
  }

  var added = 0;
  var skipped = 0;
  var deckCards = AppState.cards.filter(function(c) { return c.deckId === deckId; });

  lines.forEach(function(line) {
    var sep = line.indexOf('|');
    if (sep < 0) { skipped++; return; }
    var front = line.slice(0, sep).trim();
    var back = line.slice(sep + 1).trim();
    if (!front || !back) { skipped++; return; }

    // Deduplicate
    var exists = deckCards.find(function(c) { return c.front.toLowerCase() === front.toLowerCase(); }) ||
                 AppState.cards.find(function(c) {
                   return c.deckId === deckId && c.front.toLowerCase() === front.toLowerCase();
                 });
    if (exists) { skipped++; return; }

    var newCard = Storage.normalizeCard({ deckId: deckId, front: front, back: back });
    AppState.cards.push(newCard);
    deckCards.push(newCard);
    added++;
  });

  persist();
  closeModal('modal-bulk');
  if (AppState.activeDeckId) renderCardList(AppState.activeDeckId);
  showToast('Imported ' + added + ' card' + (added !== 1 ? 's' : '') + (skipped > 0 ? ', ' + skipped + ' skipped.' : '.'), 'success');
}

// ──────────────────────────────────────────────────────────────
// Study Session
// ──────────────────────────────────────────────────────────────

function renderStudyPageStart(extra) {
  var page = document.getElementById('page-study');
  page.innerHTML = '';

  var deckId = extra && extra.deckId;
  var today = SM2.todayISO();

  // Gather due cards
  var allDueCards;
  if (deckId) {
    var deckCards = AppState.cards.filter(function(c) { return c.deckId === deckId; });
    allDueCards = deckCards.filter(function(c) { return SM2.isDue(c, today); });
  } else {
    allDueCards = AppState.cards.filter(function(c) { return SM2.isDue(c, today); });
  }

  // Sort by due date (most overdue first)
  allDueCards = SM2.sortByDue(allDueCards);

  // Apply session limit
  var limit = AppState.settings.maxReviewsPerSession || 100;
  var sessionCards = allDueCards.slice(0, limit);

  if (sessionCards.length === 0) {
    renderNothingDue(page, deckId);
    return;
  }

  var deck = deckId ? AppState.decks.find(function(d) { return d.id === deckId; }) : null;

  // Initialise session object
  AppState.session = {
    deckId: deckId || null,
    queue: sessionCards.map(function(c) { return c.id; }),
    currentIndex: 0,
    revealed: false,
    phase: 'review',
    startTime: Date.now(),
    results: [],  // { cardId, quality, interval }
  };

  renderStudyCard(page);
}

function renderNothingDue(page, deckId) {
  var deckName = '';
  if (deckId) {
    var d = AppState.decks.find(function(x) { return x.id === deckId; });
    deckName = d ? ' in "' + d.name + '"' : '';
  }

  var nextDue = getNextDueDate();

  page.innerHTML =
    '<div class="study-container">' +
      '<div class="nothing-due">' +
        '<div class="nothing-due-graphic" aria-hidden="true">✓</div>' +
        '<h2 style="font-size:1.5rem;font-weight:800;margin-bottom:12px;">All caught up' + escHtml(deckName) + '!</h2>' +
        '<p style="color:var(--text-secondary);margin-bottom:24px;">' +
          (nextDue
            ? 'Your next review is scheduled for <strong>' + nextDue + '</strong>. Great work!'
            : 'You have no cards scheduled yet. Add some cards to get started.') +
        '</p>' +
        '<div style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap;">' +
          '<button class="btn btn-glass" id="btn-back-from-study">← Back to Decks</button>' +
          (deckId
            ? '<button class="btn btn-primary" id="btn-add-from-study">+ Add Cards</button>'
            : ''
          ) +
        '</div>' +
      '</div>' +
    '</div>';

  page.querySelector('#btn-back-from-study').addEventListener('click', function() { navigateTo('decks'); });
  if (deckId) {
    page.querySelector('#btn-add-from-study').addEventListener('click', function() {
      openDeckDetail(deckId);
    });
  }
}

function getNextDueDate() {
  var today = SM2.todayISO();
  var future = AppState.cards
    .filter(function(c) { return c.dueDate > today; })
    .map(function(c) { return c.dueDate; })
    .sort();
  return future[0] || null;
}

function renderStudyCard(page) {
  var session = AppState.session;
  if (!session || session.phase !== 'review') return;

  var cardId = session.queue[session.currentIndex];
  var card = AppState.cards.find(function(c) { return c.id === cardId; });
  if (!card) {
    advanceSession();
    return;
  }

  var total = session.queue.length;
  var done = session.currentIndex;
  var pct = total > 0 ? Math.round((done / total) * 100) : 0;

  var previews = SM2.previewIntervals(card);

  page.innerHTML =
    '<div class="study-container">' +
      '<div class="study-progress-text" aria-live="polite" aria-atomic="true">' +
        '<span class="mono">' + done + '</span> / <span class="mono">' + total + '</span>' +
      '</div>' +
      '<div class="study-progress-bar-wrap" role="progressbar" aria-valuenow="' + pct + '" aria-valuemin="0" aria-valuemax="100" aria-label="Session progress">' +
        '<div class="study-progress-bar" style="width:' + pct + '%"></div>' +
      '</div>' +

      '<div class="flashcard-scene" id="flashcard-scene">' +
        '<div class="flashcard" id="flashcard" tabindex="0" role="button" aria-label="Flashcard: press Space or click to reveal answer">' +
          '<div class="flashcard-face flashcard-front">' +
            '<div class="flashcard-label">Question</div>' +
            '<div class="flashcard-content" aria-live="polite">' + escHtml(card.front) + '</div>' +
            (card.tags && card.tags.length > 0
              ? '<div class="flashcard-tags">' + card.tags.map(function(t) { return '<span class="tag-chip">' + escHtml(t) + '</span>'; }).join('') + '</div>'
              : '') +
            '<div class="flashcard-hint"><kbd>Space</kbd> to reveal</div>' +
          '</div>' +
          '<div class="flashcard-face flashcard-back" aria-hidden="true">' +
            '<div class="flashcard-label">Answer</div>' +
            '<div class="flashcard-content">' + escHtml(card.back) + '</div>' +
            (card.tags && card.tags.length > 0
              ? '<div class="flashcard-tags">' + card.tags.map(function(t) { return '<span class="tag-chip">' + escHtml(t) + '</span>'; }).join('') + '</div>'
              : '') +
            '<div class="flashcard-hint">Rate your recall below</div>' +
          '</div>' +
        '</div>' +
      '</div>' +

      '<div id="study-actions">' +
        '<button class="btn-reveal" id="btn-reveal" aria-label="Reveal answer">Show Answer</button>' +
      '</div>' +

      '<div id="rating-section" class="hidden">' +
        '<div class="rating-buttons" role="group" aria-label="Rate your recall">' +
          renderRatingBtn('again', 'Again', SM2.formatInterval(previews.AGAIN), '1', 'btn-rating-again') +
          renderRatingBtn('hard', 'Hard', SM2.formatInterval(previews.HARD), '2', 'btn-rating-hard') +
          renderRatingBtn('good', 'Good', SM2.formatInterval(previews.GOOD), '3', 'btn-rating-good') +
          renderRatingBtn('easy', 'Easy', SM2.formatInterval(previews.EASY), '4', 'btn-rating-easy') +
        '</div>' +
      '</div>' +

      '<div style="text-align:right;margin-top:16px;">' +
        '<button class="btn btn-ghost btn-sm" id="btn-end-session">End Session</button>' +
      '</div>' +
    '</div>';

  // Bind events
  var flashcard = page.querySelector('#flashcard');
  var revealBtn = page.querySelector('#btn-reveal');

  flashcard.addEventListener('click', revealCard);
  flashcard.addEventListener('keydown', function(e) {
    if (e.key === ' ' || e.key === 'Enter') { e.preventDefault(); revealCard(); }
  });
  revealBtn.addEventListener('click', revealCard);

  page.querySelectorAll('[data-rating]').forEach(function(btn) {
    btn.addEventListener('click', function() { rateCard(btn.dataset.rating); });
  });

  page.querySelector('#btn-end-session').addEventListener('click', function() {
    showConfirm('End session?', 'End the current study session early?', function() {
      showSessionSummary();
    });
  });
}

function renderRatingBtn(rating, label, interval, key, cls) {
  return '<button class="btn-rating ' + cls + '" data-rating="' + rating + '" ' +
    'aria-label="' + label + ': next review in ' + interval + '">' +
    '<span class="btn-rating-label">' + label + '</span>' +
    '<span class="btn-rating-interval mono">' + interval + '</span>' +
    '<span class="btn-rating-key mono">[' + key + ']</span>' +
    '</button>';
}

function revealCard() {
  if (!AppState.session || AppState.session.revealed) return;
  AppState.session.revealed = true;

  var page = document.getElementById('page-study');
  var flashcard = page.querySelector('#flashcard');
  var revealBtn = page.querySelector('#btn-reveal');
  var ratingSection = page.querySelector('#rating-section');
  var studyActions = page.querySelector('#study-actions');
  var backFace = page.querySelector('.flashcard-back');

  flashcard.classList.add('revealed');
  flashcard.setAttribute('aria-label', 'Answer revealed. Rate your recall.');
  if (backFace) backFace.removeAttribute('aria-hidden');

  studyActions.classList.add('hidden');
  ratingSection.classList.remove('hidden');

  // Move focus to first rating button
  var firstRating = ratingSection.querySelector('[data-rating]');
  if (firstRating) firstRating.focus();

  // Live announce
  announceToScreenReader('Answer revealed. Rate your recall.');
}

function rateCard(ratingKey) {
  var session = AppState.session;
  if (!session || !session.revealed) return;

  var qualityMap = { again: SM2.QUALITY.AGAIN, hard: SM2.QUALITY.HARD, good: SM2.QUALITY.GOOD, easy: SM2.QUALITY.EASY };
  var q = qualityMap[ratingKey];
  if (q === undefined) return;

  var cardId = session.queue[session.currentIndex];
  var cardIdx = AppState.cards.findIndex(function(c) { return c.id === cardId; });
  if (cardIdx < 0) { advanceSession(); return; }

  var card = AppState.cards[cardIdx];
  var today = SM2.todayISO();
  var newState = SM2.applyReview(card, q, today);

  // Update card
  Object.assign(AppState.cards[cardIdx], newState);

  // Log the review
  var logEntry = Storage.normalizeLogEntry({
    cardId: cardId,
    deckId: card.deckId,
    date: today,
    quality: q,
    resultingInterval: newState.interval
  });
  AppState.reviewLog.push(logEntry);

  session.results.push({ cardId: cardId, quality: q, interval: newState.interval });
  persist();

  advanceSession();
}

function advanceSession() {
  var session = AppState.session;
  if (!session) return;

  session.currentIndex++;
  session.revealed = false;

  if (session.currentIndex >= session.queue.length) {
    showSessionSummary();
    return;
  }

  var page = document.getElementById('page-study');
  renderStudyCard(page);
}

function showSessionSummary() {
  var session = AppState.session;
  var page = document.getElementById('page-study');
  if (!session) return;

  session.phase = 'summary';

  var results = session.results;
  var reviewed = results.length;
  var again = results.filter(function(r) { return r.quality < 3; }).length;
  var againPct = reviewed > 0 ? Math.round((again / reviewed) * 100) : 0;
  var elapsed = Math.round((Date.now() - session.startTime) / 1000);
  var minutes = Math.floor(elapsed / 60);
  var seconds = elapsed % 60;
  var timeStr = minutes > 0
    ? minutes + 'm ' + seconds + 's'
    : seconds + 's';

  var icon = againPct < 20 ? '🎉' : againPct < 50 ? '✓' : '💪';

  page.innerHTML =
    '<div class="study-container session-summary">' +
      '<div class="session-summary-icon" aria-hidden="true">' + icon + '</div>' +
      '<h2 style="font-size:1.5rem;font-weight:800;margin-bottom:8px;">Session Complete</h2>' +
      '<p style="color:var(--text-secondary);margin-bottom:0;">Well done on completing your review session.</p>' +

      '<div class="summary-stats" role="list">' +
        '<div class="summary-stat" role="listitem">' +
          '<span class="summary-stat-num mono">' + reviewed + '</span>' +
          '<div class="summary-stat-label">Cards reviewed</div>' +
        '</div>' +
        '<div class="summary-stat" role="listitem">' +
          '<span class="summary-stat-num mono">' + againPct + '%</span>' +
          '<div class="summary-stat-label">Again rate</div>' +
        '</div>' +
        '<div class="summary-stat" role="listitem">' +
          '<span class="summary-stat-num mono">' + timeStr + '</span>' +
          '<div class="summary-stat-label">Time taken</div>' +
        '</div>' +
      '</div>' +

      '<div style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap;">' +
        '<button class="btn btn-glass" id="btn-summary-back">Back to Decks</button>' +
        (reviewed > 0
          ? '<button class="btn btn-primary" id="btn-study-again">Study More</button>'
          : ''
        ) +
      '</div>' +
    '</div>';

  page.querySelector('#btn-summary-back').addEventListener('click', function() {
    AppState.session = null;
    navigateTo('decks');
  });

  var studyAgainBtn = page.querySelector('#btn-study-again');
  if (studyAgainBtn) {
    studyAgainBtn.addEventListener('click', function() {
      AppState.session = null;
      navigateTo('study', session.deckId ? { deckId: session.deckId } : undefined);
    });
  }

  announceToScreenReader('Session complete. ' + reviewed + ' cards reviewed.');
}

// ──────────────────────────────────────────────────────────────
// Stats Page
// ──────────────────────────────────────────────────────────────

function renderStatsPage() {
  var page = document.getElementById('page-stats');
  var today = SM2.todayISO();

  var totalCards = AppState.cards.length;
  var totalDecks = AppState.decks.length;
  var totalReviews = AppState.reviewLog.length;
  var dueToday = AppState.cards.filter(function(c) { return SM2.isDue(c, today); }).length;
  var retention = Stats.computeRetention(AppState.reviewLog);
  var dateCounts = Stats.buildDateCounts(AppState.reviewLog);
  var streak = Stats.computeStreak(dateCounts, today);
  var reviews7 = Stats.totalReviewsInDays(AppState.reviewLog, today, 7);

  // Update stat cards
  document.getElementById('stat-total-cards').textContent = totalCards;
  document.getElementById('stat-total-decks').textContent = totalDecks;
  document.getElementById('stat-due-today').textContent = dueToday;
  document.getElementById('stat-streak').textContent = streak + 'd';
  document.getElementById('stat-retention').textContent = totalReviews > 0 ? retention + '%' : '—';
  document.getElementById('stat-reviews-7').textContent = reviews7;

  // Heatmap
  var heatmapSvg = document.getElementById('heatmap-svg');
  Stats.renderHeatmap(heatmapSvg, AppState.reviewLog, today);

  // Forecast
  var forecastSvg = document.getElementById('forecast-svg');
  Stats.renderForecast(forecastSvg, AppState.cards, today);
}

// ──────────────────────────────────────────────────────────────
// Settings Page
// ──────────────────────────────────────────────────────────────

function renderSettingsPage() {
  var s = AppState.settings;

  document.getElementById('setting-new-limit').value = s.dailyNewCardLimit;
  document.getElementById('setting-max-reviews').value = s.maxReviewsPerSession;
  document.getElementById('setting-reduced-motion').checked = s.reducedMotion;

  // Theme buttons
  document.querySelectorAll('.theme-option').forEach(function(btn) {
    btn.classList.toggle('active', btn.dataset.theme === s.theme);
    btn.setAttribute('aria-pressed', btn.dataset.theme === s.theme ? 'true' : 'false');
  });
}

function saveSettings() {
  var newLimit = parseInt(document.getElementById('setting-new-limit').value, 10);
  var maxReviews = parseInt(document.getElementById('setting-max-reviews').value, 10);
  var reducedMotion = document.getElementById('setting-reduced-motion').checked;

  // Validate & clamp
  if (!isFinite(newLimit) || newLimit < 1) newLimit = 1;
  if (newLimit > 200) newLimit = 200;
  if (!isFinite(maxReviews) || maxReviews < 1) maxReviews = 1;
  if (maxReviews > 500) maxReviews = 500;

  AppState.settings.dailyNewCardLimit = newLimit;
  AppState.settings.maxReviewsPerSession = maxReviews;
  AppState.settings.reducedMotion = reducedMotion;

  applyReducedMotion(reducedMotion);
  persist();
  showToast('Settings saved.', 'success');
  renderSettingsPage();
}

function setTheme(theme) {
  AppState.settings.theme = theme;
  applyTheme(theme);
  persist();
  renderSettingsPage();
}

// ──────────────────────────────────────────────────────────────
// Export / Import
// ──────────────────────────────────────────────────────────────

function doExportJSON() {
  Storage.exportJSON({
    decks: AppState.decks,
    cards: AppState.cards,
    reviewLog: AppState.reviewLog,
    settings: AppState.settings
  });
  showToast('JSON exported successfully.', 'success');
}

function doExportCSV() {
  Storage.exportCSV({
    decks: AppState.decks,
    cards: AppState.cards,
    reviewLog: AppState.reviewLog,
    settings: AppState.settings
  });
  showToast('CSV exported successfully.', 'success');
}

function doImportJSON(file) {
  if (!file) return;
  showToast('Importing…');
  var reader = new FileReader();
  reader.onload = function(e) {
    try {
      var newState = Storage.importJSON(e.target.result);
      showConfirm(
        'Replace all data?',
        'Importing will replace all current decks, cards and history. This cannot be undone.',
        function() {
          AppState.decks = newState.decks;
          AppState.cards = newState.cards;
          AppState.reviewLog = newState.reviewLog;
          AppState.settings = newState.settings;
          applyTheme(AppState.settings.theme);
          applyReducedMotion(AppState.settings.reducedMotion);
          persist();
          navigateTo('decks');
          showToast('Import complete: ' + newState.decks.length + ' decks, ' + newState.cards.length + ' cards.', 'success');
        }
      );
    } catch (err) {
      showToast('Import failed: ' + err.message, 'error');
    }
  };
  reader.onerror = function() {
    showToast('Could not read file.', 'error');
  };
  reader.readAsText(file);
}

function doResetToSample() {
  showConfirm(
    'Reset to sample data?',
    'This will replace all your data with the built-in sample decks. All your cards and history will be lost.',
    function() {
      var seedData = SEED.generateSeedData();
      AppState.decks = seedData.decks;
      AppState.cards = seedData.cards;
      AppState.reviewLog = seedData.reviewLog;
      persist();
      navigateTo('decks');
      showToast('Reset to sample data.', 'success');
    }
  );
}

function doClearAll() {
  showConfirm(
    'Clear all data?',
    'This will permanently delete all decks, cards, and review history. You will start fresh.',
    function() {
      Storage.clearAll();
      AppState.decks = [];
      AppState.cards = [];
      AppState.reviewLog = [];
      navigateTo('decks');
      showToast('All data cleared.', 'success');
    }
  );
}

// ──────────────────────────────────────────────────────────────
// Utilities
// ──────────────────────────────────────────────────────────────

function escHtml(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function renderEmptyState(icon, title, message, actionHtml) {
  return '<div class="empty-state">' +
    '<div class="empty-state-icon" aria-hidden="true">' + icon + '</div>' +
    '<h3>' + escHtml(title) + '</h3>' +
    '<p>' + escHtml(message) + '</p>' +
    (actionHtml || '') +
    '</div>';
}

function showFieldError(inputEl, message) {
  var existing = inputEl.parentNode.querySelector('.form-error');
  if (existing) existing.remove();
  var err = document.createElement('div');
  err.className = 'form-error';
  err.setAttribute('role', 'alert');
  err.textContent = message;
  inputEl.parentNode.appendChild(err);
  inputEl.focus();
}

function clearFieldErrors(containerEl) {
  containerEl.querySelectorAll('.form-error').forEach(function(el) { el.remove(); });
}

function announceToScreenReader(msg) {
  var region = document.getElementById('live-region');
  if (!region) return;
  region.textContent = '';
  // Small delay to ensure change is announced
  setTimeout(function() { region.textContent = msg; }, 50);
}

// ──────────────────────────────────────────────────────────────
// DOM Ready — wire up static UI elements
// ──────────────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', function() {
  // ── Deck modal ──
  var deckModal = document.getElementById('modal-deck');

  // Color options
  var colorContainer = deckModal.querySelector('.color-options');
  DECK_COLORS.forEach(function(color) {
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'color-option';
    btn.dataset.color = color;
    btn.style.background = color;
    btn.setAttribute('aria-label', 'Color: ' + color);
    btn.setAttribute('aria-pressed', 'false');
    btn.addEventListener('click', function() { setDeckColorSelection(color); });
    colorContainer.appendChild(btn);
  });

  // Glyph options
  var glyphContainer = deckModal.querySelector('.glyph-options');
  DECK_GLYPHS.forEach(function(glyph) {
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'glyph-option';
    btn.dataset.glyph = glyph;
    btn.textContent = glyph;
    btn.setAttribute('aria-label', 'Icon: ' + glyph);
    btn.setAttribute('aria-pressed', 'false');
    btn.addEventListener('click', function() { setDeckGlyphSelection(glyph); });
    glyphContainer.appendChild(btn);
  });

  deckModal.querySelector('.btn-save-deck').addEventListener('click', saveDeck);
  deckModal.querySelector('.btn-cancel-modal').addEventListener('click', function() { closeModal('modal-deck'); });
  deckModal.querySelector('.btn-close-modal').addEventListener('click', function() { closeModal('modal-deck'); });
  deckModal.addEventListener('click', function(e) { if (e.target === deckModal) closeModal('modal-deck'); });

  // ── Card modal ──
  var cardModal = document.getElementById('modal-card');
  cardModal.querySelector('.btn-save-card').addEventListener('click', saveCard);
  cardModal.querySelector('.btn-cancel-card').addEventListener('click', function() { closeModal('modal-card'); });
  cardModal.querySelector('.btn-close-card').addEventListener('click', function() { closeModal('modal-card'); });
  cardModal.addEventListener('click', function(e) { if (e.target === cardModal) closeModal('modal-card'); });

  // ── Bulk modal ──
  var bulkModal = document.getElementById('modal-bulk');
  bulkModal.querySelector('#bulk-text').addEventListener('input', previewBulkImport);
  bulkModal.querySelector('.btn-commit-bulk').addEventListener('click', commitBulkImport);
  bulkModal.querySelector('.btn-cancel-bulk').addEventListener('click', function() { closeModal('modal-bulk'); });
  bulkModal.querySelector('.btn-close-bulk').addEventListener('click', function() { closeModal('modal-bulk'); });
  bulkModal.addEventListener('click', function(e) { if (e.target === bulkModal) closeModal('modal-bulk'); });

  // ── Confirm modal ──
  var confirmModal = document.getElementById('modal-confirm');
  confirmModal.addEventListener('click', function(e) { if (e.target === confirmModal) closeModal('modal-confirm'); });

  // ── Decks page: event delegation (single listener for all deck action buttons) ──
  document.getElementById('decks-container').addEventListener('click', function(e) {
    var btn = e.target.closest('[data-action]');
    if (!btn) return;
    var action = btn.dataset.action;
    var id = btn.dataset.id;
    if (action === 'edit-deck') openEditDeckModal(id);
    if (action === 'view-deck') openDeckDetail(id);
    if (action === 'study-deck') navigateTo('study', { deckId: id });
  });

  // ── Decks page: New Deck button ──
  document.getElementById('btn-new-deck').addEventListener('click', openCreateDeckModal);

  // ── Decks page: Study All button ──
  document.getElementById('btn-study-all').addEventListener('click', function() {
    navigateTo('study');
  });

  // ── Settings ──
  document.getElementById('btn-save-settings').addEventListener('click', saveSettings);

  document.querySelectorAll('.theme-option').forEach(function(btn) {
    btn.addEventListener('click', function() { setTheme(btn.dataset.theme); });
  });

  document.getElementById('setting-reduced-motion').addEventListener('change', function() {
    applyReducedMotion(this.checked);
  });

  // Export/Import buttons
  document.getElementById('btn-export-json').addEventListener('click', doExportJSON);
  document.getElementById('btn-export-csv').addEventListener('click', doExportCSV);

  document.getElementById('btn-import-json').addEventListener('click', function() {
    document.getElementById('import-json-file').click();
  });

  document.getElementById('import-json-file').addEventListener('change', function(e) {
    if (e.target.files && e.target.files[0]) {
      doImportJSON(e.target.files[0]);
      e.target.value = ''; // reset so same file can be re-imported
    }
  });

  document.getElementById('btn-reset-sample').addEventListener('click', doResetToSample);
  document.getElementById('btn-clear-all').addEventListener('click', doClearAll);

  // ── Listen for system theme changes ──
  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function() {
      if (AppState.settings.theme === 'system') {
        applyTheme('system');
      }
    });
  }

  // Boot
  init();
});
