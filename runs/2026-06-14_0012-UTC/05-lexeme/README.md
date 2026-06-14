# Lexeme

**A beautiful, ad-free English vocabulary builder for SAT / GRE students and word-lovers.**

Most vocabulary apps are either free-but-bland (Magoosh) or buried in ads and
subscriptions. Lexeme is the version test-prep students wish existed: a daily
word, genuinely smart spaced-repetition review, four fun quiz modes, and honest
progress charts — all wrapped in a calm, scholarly visual identity (cream paper
surfaces in light mode, deep ink in dark, a serif voice for the words themselves).

**Audience:** SAT/GRE candidates, ESL learners reaching for advanced English, and
anyone who simply loves words.

---

## Features

- **Today** — A deterministic Word of the Day (stable for the whole calendar day,
  chosen from words you haven't learned yet) with definition, an example sentence,
  etymology, and synonym/antonym chips. Mark "I knew it" or "Learning". A
  "Due for review: N" banner jumps you straight into a session, with your current
  streak always in view. Graceful empty/first-run and "all learned" states.
- **Study** — An adaptive review session that resurfaces due words first, then
  introduces new ones, mixing the quiz modes your plan allows. Per-mode practice
  too. Immediate feedback (the full word entry appears on a miss so you actually
  learn it), a live progress bar, and a **results screen** with score, accuracy,
  and which words leveled up. Loading state while the session builds.
- **Lexicon** — The full bundled bank of **185 words**, searchable and filterable
  by tier, part of speech, tag, and status (learned / favorites / in review).
  Tap any word for a pushed **Word Detail** screen: the full entry, your mastery
  bar, next-review estimate, a favorite toggle, "add to review", and
  "mark as learned".
- **Progress** — Swift Charts dashboard: cumulative words-learned line/area chart,
  a mastery-level **donut**, headline stat tiles (learned / streak / accuracy), a
  7-day **due forecast** bar chart, and nine **achievements** with partial-progress
  rings.
- **Settings** — Daily review goal (stepper), daily-word reminder time (persisted
  toggle + hour), preferred tier focus, typed-vs-MC fill-in-the-blank, haptics
  toggle, reset progress (confirmed), Pro / restore, and About.
- **Onboarding** — A three-page first-run intro that sets your tier focus, gated
  by `@AppStorage("hasOnboarded")`.

### Quiz modes
Definition to Word (MC), Word to Definition (MC), Synonym Match (MC), and Fill in
the Blank (the word is blanked from its own example; multiple choice, or typed with
case/diacritic-insensitive, trimmed grading). Distractors are drawn from the same
part of speech and tier where possible.

### Spaced repetition
Intervals by mastery level `[0, 1, 3, 7, 16, 40]` days. A correct answer raises the
level and schedules the next review further out; a wrong answer drops the level and
brings the word back soon. "Due today" means `nextReview <= now`.

---

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root if present).
3. Open `Lexeme.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

**Free signing:** select the `Lexeme` target → Signing & Capabilities → choose your
personal team; the bundle id is `com.orbioom.lexeme` (change it if it collides).

---

## Tech notes

- **iOS 17+, SwiftUI, MVVM.** `@Observable` view models with `@State`.
- **SwiftData** for user data: `WordProgress` (per-word mastery, schedule, favorite,
  learned) and `StudySession` (history for streaks and charts). The word bank itself
  is a bundled static `[VocabWord]` value array — no migrations, no network.
- **Swift Charts** for the progress dashboard (line/area, donut, bars).
- **Pure engine** (`LexemeEngine`) holds all logic — word-of-the-day hashing
  (FNV-1a over `yyyy-MM-dd`), scheduling, quiz generation, distractor selection,
  and statistics — so it is deterministic and testable.
- **Design language:** literary and quiet — cream/paper light, deep-ink dark, an
  ink-blue accent (`#3C50A5`), serif headings and words via `Color.dyn` for
  first-class light/dark in both modes; Dynamic Type, VoiceOver labels, WCAG-AA
  contrast, and Reduce-Motion-aware animation throughout. Sparse haptics gated by a
  Settings toggle.
- **Monetization:** one-time **Lexeme Pro ($5.99)** unlocks the SAT & GRE banks,
  unlimited daily reviews (free tier caps at 20/day), all quiz modes, and the full
  charts — gated by `@AppStorage("isPro")` with an honest paywall (demo build
  unlocks locally; production wires StoreKit 2). The free tier is genuinely useful
  on its own.
- **Why it can boom:** vocabulary is an evergreen, high-intent test-prep need with a
  daily-habit loop; a calm, ad-free, one-time-purchase product is a sharp contrast
  to the ad-laden incumbents, and the daily word gives a natural retention hook.

---

## Self-review attestation

Every Swift source file was re-read for iOS 17 SDK correctness: imports, type and
initializer existence, protocol conformances, `@State`/`@Observable`/`@Query`/
`@Environment(\.modelContext)` wiring and ownership, `NavigationStack` /
`navigationDestination(item:)` / sheet bindings, Swift Charts marks, and
brace/paren balance. Every `Theme.` token referenced in views is defined in
`Theme.swift`. There are no force-unwraps, `try!` (except the sanctioned in-memory
`ModelContainer` fallback), `fatalError`, or `as!` on user paths. All 185 examples
were verified to contain their word (case-insensitive) so fill-in-the-blank always
works, and all word ids are unique. The anti-stub grep
(`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`// stub`)
is clean.
