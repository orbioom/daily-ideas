/**
 * seed.js — Realistic sample data for Renewal.
 * ~10 subscriptions across categories with varied cycles and anchor dates.
 * Some renewing within days, one trial ending soon, one paused.
 */

'use strict';

const Seed = (() => {

  /**
   * Build seed state anchored around `referenceDate` (defaults to today).
   * Anchor dates are computed relative to today so renewal dates are always
   * near-future, keeping dashboard/calendar immediately meaningful.
   */
  function makeSeedState(referenceDate) {
    const ref = referenceDate || new Date();
    const refStr = Billing.formatLocalDate(Billing.startOfDay(ref));

    // Helper: date offset from today
    function offsetDate(days) {
      const d = new Date(ref);
      d.setDate(d.getDate() + days);
      return Billing.formatLocalDate(d);
    }

    // Helper: anchor that makes next renewal land on offsetDate(daysAhead)
    // For monthly: anchor = same day last month (or a few months back)
    function monthlyAnchor(daysAhead) {
      // Put anchor ~1 month before the target next-renewal date
      const nextRenewal = new Date(ref);
      nextRenewal.setDate(nextRenewal.getDate() + daysAhead);
      const anchor = new Date(nextRenewal);
      anchor.setMonth(anchor.getMonth() - 1);
      return Billing.formatLocalDate(anchor);
    }

    function yearlyAnchor(daysAhead) {
      const nextRenewal = new Date(ref);
      nextRenewal.setDate(nextRenewal.getDate() + daysAhead);
      const anchor = new Date(nextRenewal);
      anchor.setFullYear(anchor.getFullYear() - 1);
      return Billing.formatLocalDate(anchor);
    }

    function quarterlyAnchor(daysAhead) {
      const nextRenewal = new Date(ref);
      nextRenewal.setDate(nextRenewal.getDate() + daysAhead);
      const anchor = new Date(nextRenewal);
      anchor.setMonth(anchor.getMonth() - 3);
      return Billing.formatLocalDate(anchor);
    }

    function weeklyAnchor(daysAhead) {
      const nextRenewal = new Date(ref);
      nextRenewal.setDate(nextRenewal.getDate() + daysAhead);
      const anchor = new Date(nextRenewal);
      anchor.setDate(anchor.getDate() - 7);
      return Billing.formatLocalDate(anchor);
    }

    // Categories
    const categories = [
      { id: 'cat-entertainment', name: 'Entertainment', color: '#7C6FCD', glyph: '🎬' },
      { id: 'cat-software',      name: 'Software',      color: '#4A90D9', glyph: '💻' },
      { id: 'cat-utilities',     name: 'Utilities',     color: '#E8A245', glyph: '⚡' },
      { id: 'cat-health',        name: 'Health',        color: '#86C79A', glyph: '🏃' },
      { id: 'cat-news',          name: 'News & Reading', color: '#D97B6C', glyph: '📰' },
      { id: 'cat-storage',       name: 'Storage',       color: '#6BBFCF', glyph: '☁️' },
    ];

    // Payment methods
    const paymentMethods = [
      { id: 'pm-visa',   label: 'Visa ··4321' },
      { id: 'pm-paypal', label: 'PayPal' },
      { id: 'pm-amex',   label: 'Amex ··9876' },
    ];

    // Subscriptions
    const subscriptions = [
      {
        id:            'sub-netflix',
        name:          'Netflix',
        vendor:        'Netflix Inc.',
        amount:        15.99,
        currency:      '$',
        cycle:         'monthly',
        customDays:    30,
        anchorDate:    monthlyAnchor(3),   // renews in 3 days
        category:      'Entertainment',
        paymentMethod: 'Visa ··4321',
        status:        'active',
        trialEnds:     '',
        notes:         'Standard HD plan, shared with family.',
        createdAt:     new Date(ref.getTime() - 180 * 86400000).toISOString(),
      },
      {
        id:            'sub-spotify',
        name:          'Spotify Premium',
        vendor:        'Spotify AB',
        amount:        9.99,
        currency:      '$',
        cycle:         'monthly',
        customDays:    30,
        anchorDate:    monthlyAnchor(12),  // renews in 12 days
        category:      'Entertainment',
        paymentMethod: 'PayPal',
        status:        'active',
        trialEnds:     '',
        notes:         'Individual plan.',
        createdAt:     new Date(ref.getTime() - 365 * 86400000).toISOString(),
      },
      {
        id:            'sub-github',
        name:          'GitHub Pro',
        vendor:        'GitHub Inc.',
        amount:        4.00,
        currency:      '$',
        cycle:         'monthly',
        customDays:    30,
        anchorDate:    monthlyAnchor(1),   // renews tomorrow
        category:      'Software',
        paymentMethod: 'Visa ··4321',
        status:        'active',
        trialEnds:     '',
        notes:         'Pro plan for private repos.',
        createdAt:     new Date(ref.getTime() - 90 * 86400000).toISOString(),
      },
      {
        id:            'sub-jb',
        name:          'JetBrains All Products',
        vendor:        'JetBrains s.r.o.',
        amount:        249.00,
        currency:      '$',
        cycle:         'yearly',
        customDays:    365,
        anchorDate:    yearlyAnchor(45),   // renews in 45 days
        category:      'Software',
        paymentMethod: 'Amex ··9876',
        status:        'active',
        trialEnds:     '',
        notes:         'All products pack. Includes WebStorm, PyCharm, etc.',
        createdAt:     new Date(ref.getTime() - 320 * 86400000).toISOString(),
      },
      {
        id:            'sub-icloud',
        name:          'iCloud+ 200 GB',
        vendor:        'Apple Inc.',
        amount:        2.99,
        currency:      '$',
        cycle:         'monthly',
        customDays:    30,
        anchorDate:    monthlyAnchor(18),  // renews in 18 days
        category:      'Storage',
        paymentMethod: 'Visa ··4321',
        status:        'active',
        trialEnds:     '',
        notes:         '',
        createdAt:     new Date(ref.getTime() - 400 * 86400000).toISOString(),
      },
      {
        id:            'sub-nyt',
        name:          'NY Times Digital',
        vendor:        'The New York Times',
        amount:        17.00,
        currency:      '$',
        cycle:         'quarterly',
        customDays:    91,
        anchorDate:    quarterlyAnchor(6),  // renews in 6 days
        category:      'News & Reading',
        paymentMethod: 'PayPal',
        status:        'active',
        trialEnds:     '',
        notes:         'All-access digital subscription.',
        createdAt:     new Date(ref.getTime() - 200 * 86400000).toISOString(),
      },
      {
        id:            'sub-1pw',
        name:          '1Password Families',
        vendor:        'AgileBits Inc.',
        amount:        4.99,
        currency:      '$',
        cycle:         'monthly',
        customDays:    30,
        anchorDate:    monthlyAnchor(22),   // renews in 22 days
        category:      'Software',
        paymentMethod: 'Visa ··4321',
        status:        'active',
        trialEnds:     '',
        notes:         'Family plan, 5 members.',
        createdAt:     new Date(ref.getTime() - 500 * 86400000).toISOString(),
      },
      {
        id:            'sub-peloton',
        name:          'Peloton App+',
        vendor:        'Peloton Interactive',
        amount:        12.99,
        currency:      '$',
        cycle:         'monthly',
        customDays:    30,
        anchorDate:    monthlyAnchor(5),   // renews in 5 days
        category:      'Health',
        paymentMethod: 'Amex ··9876',
        status:        'active',
        trialEnds:     offsetDate(9),       // trial ends in 9 days — highlight!
        notes:         'App-only plan, no hardware required.',
        createdAt:     new Date(ref.getTime() - 25 * 86400000).toISOString(),
      },
      {
        id:            'sub-electricity',
        name:          'Green Power Co.',
        vendor:        'Green Power Co.',
        amount:        89.00,
        currency:      '$',
        cycle:         'monthly',
        customDays:    30,
        anchorDate:    monthlyAnchor(15),   // renews in 15 days
        category:      'Utilities',
        paymentMethod: 'Visa ··4321',
        status:        'active',
        trialEnds:     '',
        notes:         'Monthly estimated bill auto-pay.',
        createdAt:     new Date(ref.getTime() - 730 * 86400000).toISOString(),
      },
      {
        id:            'sub-adobe',
        name:          'Adobe Creative Cloud',
        vendor:        'Adobe Inc.',
        amount:        54.99,
        currency:      '$',
        cycle:         'monthly',
        customDays:    30,
        anchorDate:    monthlyAnchor(8),   // renews in 8 days (paused)
        category:      'Software',
        paymentMethod: 'Amex ··9876',
        status:        'paused',           // paused — excluded from totals
        trialEnds:     '',
        notes:         'Paused while on sabbatical. Will reactivate in fall.',
        createdAt:     new Date(ref.getTime() - 600 * 86400000).toISOString(),
      },
      {
        id:            'sub-dropbox',
        name:          'Dropbox Plus',
        vendor:        'Dropbox Inc.',
        amount:        11.99,
        currency:      '$',
        cycle:         'monthly',
        customDays:    30,
        anchorDate:    monthlyAnchor(0),   // renews today
        category:      'Storage',
        paymentMethod: 'PayPal',
        status:        'canceled',          // canceled — excluded from totals
        trialEnds:     '',
        notes:         'Switched to iCloud. Cancellation effective end of period.',
        createdAt:     new Date(ref.getTime() - 1200 * 86400000).toISOString(),
      },
    ];

    return {
      version: 1,
      subscriptions,
      categories,
      paymentMethods,
      settings: {
        currencySymbol: '$',
        monthStartsOn: 0,
        theme: 'system',
        reducedMotion: false,
        lastView: 'dashboard',
      },
    };
  }

  return { makeSeedState };

})();
