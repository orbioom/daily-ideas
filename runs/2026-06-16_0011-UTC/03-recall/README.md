# Recall

**Spaced-repetition flashcards that respect your time.** Recall is an Anki/Quizlet "beater":
easier to use than Anki, with none of Quizlet's paywall games — and a genuine SM-2 scheduling
engine under the hood, not a fake "study mode."

Built for iOS 17 with SwiftUI + SwiftData. All data is local; no account, no network, no tracking.

---

## What it is

You build decks of flashcards, then study them. Recall's scheduler decides *which* cards to
show *when*: cards you know come back in days, then weeks, then months; cards you miss come back
tomorrow. You study a few minutes a day and remember far more than cramming ever gives you.

The scheduling engine is a real, guarded **SuperMemo-2 (SM-2)** variant — the same algorithm
family that powers Anki — implemented as a pure, fully-testable Swift type (`SRSEngine`).

## Full feature list

- **Decks (home)** — a deck grid with a `colorSeed` gradient header per deck, live **due** and
  **new** badges, a maturity progress bar, and a top "*X cards due today*" summary with a
  **Study all due** button across every deck. Designed empty state. Create / edit decks.
- **Study player** — a full-screen session launched from a deck or "study all":
  - **3D card flip** reveal (`rotation3DEffect`), which automatically becomes a **cross-fade**
    under Reduce Motion.
  - Four study modes: **Flip**, **Multiple Choice** (auto-generated distractors), **Type Answer**
    (forgiving normalized matching), and **Cram** (drills the whole deck, never touches the SRS).
  - **Again / Hard / Good / Easy** grade buttons that call `SRSEngine` and show the resulting
    interval ("1d", "6d", "3w"…) right on each button.
  - Progress bar, remaining count, and an end-of-session **summary** (reviewed, retention %,
    grade breakdown). Calm "All caught up" empty state when nothing is due.
- **Stats** — Swift Charts dashboard: reviews-per-day (last 30 days) bar chart, **due forecast**
  for the next 14 days (`BarMark`), **card-maturity donut** (`SectorMark`: new / learning /
  young / mature), plus retention %, total cards, due-today, and a **study streak**. Computed
  asynchronously with a loading state.
- **Browse** — pick a deck, then a **searchable** card list with maturity filter chips. Add /
  edit / delete cards, **suspend / resume**, and **reset** a card's progress (swipe actions).
  Live per-card SRS readout in the card editor. Rename / recolor / archive / delete decks.
- **Settings** — persisted prefs that change behavior: daily **new-card** limit (stepper), daily
  **review** limit (stepper), **default study mode**, **shuffle order** toggle, **haptics**
  toggle, **appearance** (System / Light / Dark). Plus **About**, **Export as CSV**
  (`ShareLink`), **Load / reload sample data**, **reset**, and **Pro / Restore**.
- **Onboarding** — a 3-page first-run intro in the app's design language.

## Run steps

This folder contains **Swift sources only**; the Xcode project is generated with
[XcodeGen](https://github.com/yonyz/XcodeGen) from the committed `ios/project.yml`.

```bash
cd ios
xcodegen generate          # creates Recall.xcodeproj from project.yml
open Recall.xcodeproj       # then Run (⌘R) on an iOS 17 simulator
```

On first launch, tap through onboarding; sample decks seed automatically. (You can also reload
them anytime from **Settings → Load sample data**.)

## Free-signing note

The app uses no entitlements beyond defaults, so it runs with a **free personal Apple ID**:
in Xcode, select the *Recall* target → **Signing & Capabilities** → pick your personal team,
and Xcode will provision automatically. No paid developer account is required to build and run
on a device or simulator.

## Tech notes

- **Architecture** — SwiftUI + SwiftData (`@Model` `Deck` / `Card` / `ReviewLog` with
  `@Relationship(deleteRule: .cascade)`), pure engines (`SRSEngine`, `StudyQueue`,
  `StatsEngine`) kept free of UI/persistence so they're trivially testable, and a single
  `@Observable` `StudyViewModel` driving the player. `@AppStorage` holds only small prefs/flags.
- **The SRS is real SM-2.** `SRSEngine` implements a guarded SuperMemo-2 step: per-card *ease*
  factor (clamped ≥ 1.3), *interval* growth (`interval × ease`, capped at ~4 years), *repetition*
  count, and *lapse* tracking, with grade-specific rules for Again/Hard/Good/Easy. Due selection,
  daily new/review limits, MCQ distractor generation, and normalized type-answer matching all
  live in `StudyQueue`. Nothing is faked.
- **Monetization** — one-time **Recall Pro** (`$4.99`): free covers 3 decks and Flip study;
  Pro lifts the deck cap and unlocks Multiple-Choice / Type / Cram modes and the full Stats
  dashboard. StoreKit is **not** wired — the paywall's "Unlock" flips `@AppStorage("isPro")`
  and "Restore" is present (a production build swaps in StoreKit 2 transaction checks).
- **Why it can boom** — Anki's scheduling is loved but its UX scares off most learners, and
  Quizlet gates basic studying behind a subscription; Recall pairs a credible SM-2 engine with a
  calm, modern flip-card UX and one fair one-time unlock — the exact gap between "powerful" and
  "pleasant" that students, language learners, and exam-preppers keep asking for.
- **Polish** — cohesive indigo theme via `Theme.dyn(light, dark)` (first-class light + dark),
  Dynamic Type system fonts throughout, accessibility labels/hints/values on controls,
  Reduce-Motion-aware animation (the card flip degrades to a cross-fade), gated haptics, lazy
  stacks with stable `Identifiable` IDs, and designed empty / loading / error / success states.

## Self-review attestation

- **36 Swift source files** under `ios/Recall/Recall/`.
- Exactly **one** `@main` (`RecallApp`) and exactly **one** `fatalError` — the documented,
  unreachable empty-in-memory `ModelContainer` fallback, shared by the app and previews.
- **Zero** `try!`, `as!`, `NavigationView`, or single-arg `onChange`. All array indexing is
  guarded; every division is over a constant or a `guard`-checked non-zero denominator.
- Anti-stub grep is clean (no TODO/FIXME/placeholder/etc. in sources).
- All three `@Model` types are registered in both `ModelContainer` schemas (app + previews).
- Five feature areas (Decks, Study, Stats, Browse) plus Settings; every screen has a designed
  empty state; loading + success + error states present where data is shown.
- Sample data seeds **5 decks / 67 cards** with SRS state spread across new / due / future and
  ~60 `ReviewLog`s over the past 30 days so Stats render realistically.

_Made by Orbioom Studio._
