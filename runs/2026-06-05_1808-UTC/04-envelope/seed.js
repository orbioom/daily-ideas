/**
 * seed.js — Realistic sample dataset for Envelope budgeting app.
 * buildSeedData() returns a complete state object ready to save.
 */

function buildSeedData() {
  var id = window.Storage.generateId;

  var today = new Date();
  var currentYYYYMM = today.toISOString().slice(0, 7);
  var prevMonthDate = new Date(today.getFullYear(), today.getMonth() - 1, 1);
  var prevYYYYMM = prevMonthDate.toISOString().slice(0, 7);

  // Accounts
  var checkingId = id();
  var savingsId = id();
  var cashId = id();

  var twoMonthsAgo = new Date(today.getFullYear(), today.getMonth() - 2, 1).toISOString();

  var accounts = [
    {
      id: checkingId,
      name: 'Main Checking',
      type: 'checking',
      startingBalance: 2400.00,
      createdAt: twoMonthsAgo,
    },
    {
      id: savingsId,
      name: 'Emergency Fund',
      type: 'savings',
      startingBalance: 8500.00,
      createdAt: twoMonthsAgo,
    },
    {
      id: cashId,
      name: 'Wallet',
      type: 'cash',
      startingBalance: 120.00,
      createdAt: twoMonthsAgo,
    },
  ];

  // Envelopes
  var rentId = id();
  var groceriesId = id();
  var utilitiesId = id();
  var transportId = id();
  var diningId = id();
  var entertainmentId = id();
  var savingsEnvId = id();
  var clothingId = id();
  var healthId = id();

  var envelopes = [
    // Essentials group
    {
      id: rentId,
      name: 'Rent & Housing',
      icon: '🏠',
      budgetedAmount: 1200.00,
      group: 'Essentials',
      rollover: false,
      createdAt: twoMonthsAgo,
    },
    {
      id: groceriesId,
      name: 'Groceries',
      icon: '🛒',
      budgetedAmount: 350.00,
      group: 'Essentials',
      rollover: false,
      createdAt: twoMonthsAgo,
    },
    {
      id: utilitiesId,
      name: 'Utilities',
      icon: '💡',
      budgetedAmount: 120.00,
      group: 'Essentials',
      rollover: false,
      createdAt: twoMonthsAgo,
    },
    {
      id: healthId,
      name: 'Health & Medical',
      icon: '🏥',
      budgetedAmount: 100.00,
      group: 'Essentials',
      rollover: true,
      createdAt: twoMonthsAgo,
    },
    // Lifestyle group
    {
      id: transportId,
      name: 'Transport',
      icon: '🚌',
      budgetedAmount: 80.00,
      group: 'Lifestyle',
      rollover: false,
      createdAt: twoMonthsAgo,
    },
    {
      id: diningId,
      name: 'Dining Out',
      icon: '🍜',
      budgetedAmount: 150.00,
      group: 'Lifestyle',
      rollover: false,
      createdAt: twoMonthsAgo,
    },
    {
      id: entertainmentId,
      name: 'Entertainment',
      icon: '🎬',
      budgetedAmount: 60.00,
      group: 'Lifestyle',
      rollover: true,
      createdAt: twoMonthsAgo,
    },
    {
      id: clothingId,
      name: 'Clothing',
      icon: '👕',
      budgetedAmount: 80.00,
      group: 'Lifestyle',
      rollover: true,
      createdAt: twoMonthsAgo,
    },
    // Savings group
    {
      id: savingsEnvId,
      name: 'Savings Goal',
      icon: '🛡️',
      budgetedAmount: 300.00,
      group: 'Savings',
      rollover: false,
      createdAt: twoMonthsAgo,
    },
  ];

  function d(yyyymm, day) {
    return yyyymm + '-' + String(day).padStart(2, '0');
  }

  var prevBase = new Date(prevMonthDate.getFullYear(), prevMonthDate.getMonth(), 1);

  var transactions = [
    // Previous month
    {
      id: id(), date: d(prevYYYYMM, 1), payee: 'Monthly Salary',
      amount: 3800.00, type: 'income', accountId: checkingId,
      envelopeId: null, toAccountId: null, notes: 'Net pay after deductions',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 1).toISOString(),
    },
    {
      id: id(), date: d(prevYYYYMM, 2), payee: 'Sunrise Apartments',
      amount: 1200.00, type: 'expense', accountId: checkingId,
      envelopeId: rentId, toAccountId: null, notes: 'Monthly rent',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 2).toISOString(),
    },
    {
      id: id(), date: d(prevYYYYMM, 4), payee: 'Whole Foods',
      amount: 87.50, type: 'expense', accountId: checkingId,
      envelopeId: groceriesId, toAccountId: null, notes: '',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 4).toISOString(),
    },
    {
      id: id(), date: d(prevYYYYMM, 8), payee: "Trader Joe's",
      amount: 64.20, type: 'expense', accountId: checkingId,
      envelopeId: groceriesId, toAccountId: null, notes: '',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 8).toISOString(),
    },
    {
      id: id(), date: d(prevYYYYMM, 10), payee: 'City Electric Co.',
      amount: 94.60, type: 'expense', accountId: checkingId,
      envelopeId: utilitiesId, toAccountId: null, notes: '',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 10).toISOString(),
    },
    {
      id: id(), date: d(prevYYYYMM, 12), payee: 'Metro Card',
      amount: 33.00, type: 'expense', accountId: cashId,
      envelopeId: transportId, toAccountId: null, notes: 'Monthly transit top-up',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 12).toISOString(),
    },
    {
      id: id(), date: d(prevYYYYMM, 14), payee: 'Sakura Ramen',
      amount: 28.40, type: 'expense', accountId: checkingId,
      envelopeId: diningId, toAccountId: null, notes: 'Lunch with Mia',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 14).toISOString(),
    },
    {
      id: id(), date: d(prevYYYYMM, 16), payee: 'Netflix',
      amount: 15.99, type: 'expense', accountId: checkingId,
      envelopeId: entertainmentId, toAccountId: null, notes: '',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 16).toISOString(),
    },
    {
      id: id(), date: d(prevYYYYMM, 19), payee: 'Whole Foods',
      amount: 112.30, type: 'expense', accountId: checkingId,
      envelopeId: groceriesId, toAccountId: null, notes: '',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 19).toISOString(),
    },
    {
      id: id(), date: d(prevYYYYMM, 20), payee: 'Transfer to Savings',
      amount: 300.00, type: 'transfer', accountId: checkingId,
      envelopeId: null, toAccountId: savingsId, notes: 'Monthly savings transfer',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 20).toISOString(),
    },
    {
      id: id(), date: d(prevYYYYMM, 22), payee: 'City Pharmacy',
      amount: 32.00, type: 'expense', accountId: cashId,
      envelopeId: healthId, toAccountId: null, notes: 'Vitamins',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 22).toISOString(),
    },
    {
      id: id(), date: d(prevYYYYMM, 25), payee: 'Uniqlo',
      amount: 55.00, type: 'expense', accountId: checkingId,
      envelopeId: clothingId, toAccountId: null, notes: 'Work shirts',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 25).toISOString(),
    },
    {
      id: id(), date: d(prevYYYYMM, 27), payee: 'Corner Café',
      amount: 19.80, type: 'expense', accountId: cashId,
      envelopeId: diningId, toAccountId: null, notes: '',
      createdAt: new Date(prevBase.getFullYear(), prevBase.getMonth(), 27).toISOString(),
    },

    // Current month
    {
      id: id(), date: d(currentYYYYMM, 1), payee: 'Monthly Salary',
      amount: 3800.00, type: 'income', accountId: checkingId,
      envelopeId: null, toAccountId: null, notes: 'Net pay after deductions',
      createdAt: new Date(today.getFullYear(), today.getMonth(), 1).toISOString(),
    },
    {
      id: id(), date: d(currentYYYYMM, 2), payee: 'Sunrise Apartments',
      amount: 1200.00, type: 'expense', accountId: checkingId,
      envelopeId: rentId, toAccountId: null, notes: 'Monthly rent',
      createdAt: new Date(today.getFullYear(), today.getMonth(), 2).toISOString(),
    },
    {
      id: id(), date: d(currentYYYYMM, 3), payee: 'Whole Foods',
      amount: 92.40, type: 'expense', accountId: checkingId,
      envelopeId: groceriesId, toAccountId: null, notes: '',
      createdAt: new Date(today.getFullYear(), today.getMonth(), 3).toISOString(),
    },
    {
      id: id(), date: d(currentYYYYMM, 5), payee: 'Metro Card',
      amount: 33.00, type: 'expense', accountId: cashId,
      envelopeId: transportId, toAccountId: null, notes: '',
      createdAt: new Date(today.getFullYear(), today.getMonth(), 5).toISOString(),
    },
    {
      id: id(), date: d(currentYYYYMM, 7), payee: 'City Electric Co.',
      amount: 108.20, type: 'expense', accountId: checkingId,
      envelopeId: utilitiesId, toAccountId: null, notes: '',
      createdAt: new Date(today.getFullYear(), today.getMonth(), 7).toISOString(),
    },
    {
      id: id(), date: d(currentYYYYMM, 9), payee: 'Netflix',
      amount: 15.99, type: 'expense', accountId: checkingId,
      envelopeId: entertainmentId, toAccountId: null, notes: '',
      createdAt: new Date(today.getFullYear(), today.getMonth(), 9).toISOString(),
    },
    {
      id: id(), date: d(currentYYYYMM, 10), payee: "Trader Joe's",
      amount: 78.90, type: 'expense', accountId: checkingId,
      envelopeId: groceriesId, toAccountId: null, notes: '',
      createdAt: new Date(today.getFullYear(), today.getMonth(), 10).toISOString(),
    },
    {
      id: id(), date: d(currentYYYYMM, 12), payee: 'Thai Garden',
      amount: 42.60, type: 'expense', accountId: checkingId,
      envelopeId: diningId, toAccountId: null, notes: 'Dinner with friends',
      createdAt: new Date(today.getFullYear(), today.getMonth(), 12).toISOString(),
    },
    {
      id: id(), date: d(currentYYYYMM, 14), payee: 'Transfer to Savings',
      amount: 300.00, type: 'transfer', accountId: checkingId,
      envelopeId: null, toAccountId: savingsId, notes: 'Monthly savings transfer',
      createdAt: new Date(today.getFullYear(), today.getMonth(), 14).toISOString(),
    },
    {
      id: id(), date: d(currentYYYYMM, 15), payee: 'Dr. Chen Co-pay',
      amount: 25.00, type: 'expense', accountId: cashId,
      envelopeId: healthId, toAccountId: null, notes: 'Annual checkup',
      createdAt: new Date(today.getFullYear(), today.getMonth(), 15).toISOString(),
    },
    {
      id: id(), date: d(currentYYYYMM, 17), payee: 'Whole Foods',
      amount: 66.15, type: 'expense', accountId: checkingId,
      envelopeId: groceriesId, toAccountId: null, notes: '',
      createdAt: new Date(today.getFullYear(), today.getMonth(), 17).toISOString(),
    },
    {
      id: id(), date: d(currentYYYYMM, 19), payee: 'Cinema Paradiso',
      amount: 22.50, type: 'expense', accountId: checkingId,
      envelopeId: entertainmentId, toAccountId: null, notes: 'Two tickets',
      createdAt: new Date(today.getFullYear(), today.getMonth(), 19).toISOString(),
    },
  ];

  return {
    version: 1,
    accounts: accounts,
    envelopes: envelopes,
    transactions: transactions,
    settings: {
      currency: '$',
      firstDayOfMonth: 1,
      theme: 'system',
      reducedMotion: false,
    },
    currentMonth: null,
  };
}

window.Seed = { buildSeedData: buildSeedData };
