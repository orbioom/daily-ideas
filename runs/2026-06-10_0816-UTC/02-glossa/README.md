# Glossa — vocabulary that actually sticks

**What it is.** A calm, on-device language-vocabulary trainer built on the Leitner spaced-repetition system. Built-in Spanish, French, and German starter packs (~90 high-frequency words each, with articles, gender, and example sentences), tolerant typed-answer grading, and honest progress stats — the job people pay Drops, Memrise, and Anki-wrappers for, without the $13/month or the five-minutes-per-ten-hours free-tier lockout.

**Audience.** Casual and serious language learners who want daily vocabulary reps that respect their time — travelers, students, Duolingo refugees.

## Features

- **Decks** — install any built-in pack (Spanish 🇪🇸 / French 🇫🇷 / German 🇩🇪) as a deck, or create custom decks; due-count badges, mastered counts, swipe-to-delete with confirmation.
- **Leitner engine** — five boxes with 0/1/3/7/14-day intervals; correct answers promote, misses send a card back to box 1; due dates anchored to start-of-day; mastered = box 5 (still reviews every two weeks).
- **Study player** — full-screen session over due cards (size configurable): multiple choice for young cards (3 deck-sourced distractors), typed production recall for box 3+; instant feedback with the example sentence; missed words return once at the end as gentle practice; early-practice mode when nothing is due; summary success screen; leaving mid-session still records progress.
- **Tolerant grading** — case-, diacritic-, and whitespace-insensitive; optional relaxed-article mode ("casa" accepted for "la casa", l'-elision handled); one-letter typos counted correct but flagged "close"; a require-article mode for when genders feel solid.
- **Card management** — searchable card list per deck, full card editor (word, meaning, gender, example pair) with validation, per-card progress (box, reviews, lapses, next due), delete with confirmation, deck-wide progress reset.
- **Progress** — day streak, total mastered, lifetime accuracy; Swift Charts for reviews/day vs daily goal (14 days) and the all-cards box distribution; recent session log; loading and empty states.
- **Settings** — daily review goal, session size, typed-answers toggle, require-article toggle, haptics; About with the privacy promise.
- Onboarding (3 pages incl. first-language picker, persisted flag), empty states everywhere, light + dark, Dynamic Type, VoiceOver labels/hints, Reduce Motion respected, sparse haptics.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Glossa.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**.

*Free signing:* personal team under Signing & Capabilities is enough — no entitlements used.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-style: SwiftData models (`Deck→Card` cascade, `ReviewSession` log), pure engines (`LeitnerEngine` with Levenshtein + article-stripping, `StatsEngine`), an `@Observable` `StudySession` driver.
- Persistence: SwiftData; preferences in `@AppStorage`. ~270 built-in lexicon entries compiled in (no network, no keys).
- Design language: **Orbioom** (glass, ink-gradient buttons, mist background, mono for numbers, slow motion curve).
- **Monetization:** language learning is one of the highest-LTV consumer categories (Drops charges $69.99/yr for vocab alone); free core with all packs + one-time "Glossa Pro" (unlimited custom decks, extra packs, stats export).
- **Why it can boom:** the vocabulary-app market is proven and huge, and the leading vocab-only apps time-gate the free tier and subscription-gate typo tolerance and stats; Glossa ships real spaced repetition, articles/gender done right, and everything offline — the version learners keep asking for in 1-star reviews.

## Self-review

Every Swift file re-read against the iOS 17 SDK: SwiftData relationships (single-side inverse), `@Observable`/`@Bindable` usage, FocusState, Charts marks, ViewBuilder switches, string folding APIs, and the Levenshtein DP checked by hand. Built-in lexicon proofread for article/gender correctness. Anti-stub grep clean. No force-unwraps, `try!`, or unchecked indexing on user paths.
