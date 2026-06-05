/* ============================================================
   seed.js — Sift sample data
   - LIBRARY: ~12 real, correct, useful named patterns. Each
     ships with a sample subject so a click is instantly useful.
   - SEED_SNIPPETS: realistic saved test cases for first open.
   - CHEATSHEET: accurate regex token reference.
   These are plain data objects consumed by app.js.
   ============================================================ */

/* Each library entry: { name, blurb, pattern, flags, sample } */
const LIBRARY = [
  {
    name: 'Email address',
    blurb: 'Common email shape',
    pattern: '[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}',
    flags: 'g',
    sample: 'Reach us at hello@orbioom.studio or support+billing@example.co.uk.\nNot an email: just text. Another: jane.doe99@sub.domain.org'
  },
  {
    name: 'URL (http/https)',
    blurb: 'Web links',
    pattern: 'https?:\\/\\/[^\\s/$.?#].[^\\s]*',
    flags: 'g',
    sample: 'Docs live at https://orbioom.studio/sift and http://example.com/path?q=1#top.\nThis bare word example.com is not matched.'
  },
  {
    name: 'IPv4 address',
    blurb: '0-255 dotted quad',
    pattern: '\\b(?:(?:25[0-5]|2[0-4]\\d|1?\\d?\\d)\\.){3}(?:25[0-5]|2[0-4]\\d|1?\\d?\\d)\\b',
    flags: 'g',
    sample: 'Gateway 192.168.1.1, DNS 8.8.8.8, loopback 127.0.0.1.\nInvalid 999.1.1.1 should not fully match the bad octet.'
  },
  {
    name: 'Hex color',
    blurb: '#RGB or #RRGGBB',
    pattern: '#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\\b',
    flags: 'g',
    sample: 'Brand mist #EDEEF3, ink #23262F, live green #86C79A, shorthand #fff.\nNot a color: #zzz or plain 123456.'
  },
  {
    name: 'ISO date (YYYY-MM-DD)',
    blurb: 'Calendar date',
    pattern: '(?<year>\\d{4})-(?<month>0[1-9]|1[0-2])-(?<day>0[1-9]|[12]\\d|3[01])',
    flags: 'g',
    sample: 'Shipped 2026-06-05, due 2026-12-31, archived 2024-02-29.\nBad: 2026-13-40 will not match.'
  },
  {
    name: 'US phone number',
    blurb: '(NNN) NNN-NNNN & variants',
    pattern: '(?:\\+?1[\\s.\\-]?)?\\(?([2-9]\\d{2})\\)?[\\s.\\-]?(\\d{3})[\\s.\\-]?(\\d{4})\\b',
    flags: 'g',
    sample: 'Call (415) 555-0132 or +1 212-555-0145 or 650.555.0177.\nToo short: 555-0100 will not match.'
  },
  {
    name: 'Slug',
    blurb: 'lowercase-with-dashes',
    pattern: '^[a-z0-9]+(?:-[a-z0-9]+)*$',
    flags: 'gm',
    sample: 'hello-world\nsift-regex-workbench\nproduct-2026\nNot a slug: Hello_World\nalso bad-\n--nope'
  },
  {
    name: 'UUID v4',
    blurb: 'RFC 4122 variant',
    pattern: '\\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\\b',
    flags: 'g',
    sample: 'Session 3f50a2c1-9b7e-4d2a-8f31-1c0de4b9a6f2 and\n9c858901-8a57-4791-81fe-4c455b099bc9.\nNot v4: 3f50a2c1-9b7e-1d2a-0f31-1c0de4b9a6f2'
  },
  {
    name: 'Semver',
    blurb: 'MAJOR.MINOR.PATCH(+meta)',
    pattern: '\\bv?(?<major>0|[1-9]\\d*)\\.(?<minor>0|[1-9]\\d*)\\.(?<patch>0|[1-9]\\d*)(?:-(?<pre>[0-9A-Za-z.\\-]+))?\\b',
    flags: 'g',
    sample: 'Release v1.0.0, hotfix 2.4.1, beta 3.0.0-rc.1, edge 0.9.12-alpha.\nNot semver: 1.2'
  },
  {
    name: 'Time HH:MM (24h)',
    blurb: '00:00 – 23:59',
    pattern: '\\b([01]\\d|2[0-3]):([0-5]\\d)\\b',
    flags: 'g',
    sample: 'Standup 09:30, deploy 17:45, midnight 00:00, last call 23:59.\nBad: 24:00 and 12:60 will not match.'
  },
  {
    name: 'Integer (signed)',
    blurb: 'optional sign, no leading zero',
    pattern: '-?\\b(?:0|[1-9]\\d*)\\b',
    flags: 'g',
    sample: 'Values: 0, 42, -17, 1000000, and -1.\nNot a clean integer: 007 matches only the 7.'
  },
  {
    name: 'Price (USD)',
    blurb: '$ amount with optional cents',
    pattern: '\\$\\s?(?<dollars>\\d{1,3}(?:,\\d{3})*|\\d+)(?:\\.(?<cents>\\d{2}))?',
    flags: 'g',
    sample: 'Total $1,299.00, tax $103.92, tip $20, refund $4.50.\nNot priced: 1299 dollars'
  }
];

/* Seed snippets — used to populate localStorage on first open so the
   workbench is never cold. They mirror the saved-snippet shape. */
const SEED_SNIPPETS = [
  {
    id: 'seed-email-scrub',
    name: 'Redact emails in logs',
    pattern: '[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}',
    flags: 'gi',
    replacement: '[redacted-email]',
    subject: 'user=hello@orbioom.studio action=login ip=192.168.1.20\nuser=jane.doe99@sub.domain.org action=logout\nuser=support+billing@example.co.uk action=reset',
    createdAt: '2026-05-30T09:00:00.000Z',
    updatedAt: '2026-05-30T09:00:00.000Z'
  },
  {
    id: 'seed-iso-to-us',
    name: 'ISO date → US date',
    pattern: '(?<year>\\d{4})-(?<month>\\d{2})-(?<day>\\d{2})',
    flags: 'g',
    replacement: '$<month>/$<day>/$<year>',
    subject: 'Invoice dates: 2026-06-05, 2026-12-31, 2025-01-09.\nReformat each to month/day/year.',
    createdAt: '2026-05-31T14:20:00.000Z',
    updatedAt: '2026-06-01T08:10:00.000Z'
  },
  {
    id: 'seed-csv-cols',
    name: 'Pull first CSV column',
    pattern: '^([^,]+),',
    flags: 'gm',
    replacement: '$1',
    subject: 'sku-001,Widget,12.50,in-stock\nsku-002,Gadget,8.00,backorder\nsku-003,Sprocket,3.25,in-stock',
    createdAt: '2026-06-02T11:45:00.000Z',
    updatedAt: '2026-06-02T11:45:00.000Z'
  }
];

const CHEATSHEET = [
  { tok: '\\d', desc: 'Any digit, 0–9.' },
  { tok: '\\D', desc: 'Any non-digit character.' },
  { tok: '\\w', desc: 'Word character: letters, digits, or underscore.' },
  { tok: '\\W', desc: 'Any non-word character.' },
  { tok: '\\s', desc: 'Whitespace: space, tab, newline, etc.' },
  { tok: '\\S', desc: 'Any non-whitespace character.' },
  { tok: '.', desc: 'Any character except newline (unless the s flag is set).' },
  { tok: '*', desc: 'Zero or more of the preceding token.' },
  { tok: '+', desc: 'One or more of the preceding token.' },
  { tok: '?', desc: 'Zero or one (optional), or makes a quantifier lazy.' },
  { tok: '{n}', desc: 'Exactly n repetitions; {n,} is n or more; {n,m} is a range.' },
  { tok: '[abc]', desc: 'Character set — matches any one listed character.' },
  { tok: '[^a]', desc: 'Negated set — any character not listed.' },
  { tok: '[a-z]', desc: 'Range inside a character set.' },
  { tok: '(…)', desc: 'Capturing group; numbered left-to-right by opening paren.' },
  { tok: '(?:…)', desc: 'Non-capturing group — groups without creating a backreference.' },
  { tok: '(?<n>…)', desc: 'Named capture group, referenced as $<n> in replacements.' },
  { tok: 'a|b', desc: 'Alternation — matches a or b.' },
  { tok: '^', desc: 'Start of string, or start of line with the m flag.' },
  { tok: '$', desc: 'End of string, or end of line with the m flag.' },
  { tok: '\\b', desc: 'Word boundary between a word and non-word character.' },
  { tok: '\\B', desc: 'Non-word-boundary position.' },
  { tok: '(?=…)', desc: 'Lookahead — asserts what follows, without consuming it.' },
  { tok: '(?!…)', desc: 'Negative lookahead — asserts what does not follow.' },
  { tok: '(?<=…)', desc: 'Lookbehind — asserts what precedes the position.' },
  { tok: '(?<!…)', desc: 'Negative lookbehind — asserts what does not precede.' },
  { tok: '\\.', desc: 'Escaped literal — matches a real dot (escape any metachar this way).' }
];

/* Expose for non-module scripts loaded via <script> tags. */
window.SiftSeed = { LIBRARY, SEED_SNIPPETS, CHEATSHEET };
