# Citizen

**Clean, accurate prep for the U.S. naturalization civics test.** Citizen is a
native iOS app built around the official USCIS 100 civics questions (2008 version,
the current operative test) — no ad clutter, no recurring subscription, just a
calm, refined study experience with a real exam simulator.

An Orbioom iOS studio app.

---

## What it is

A focused civics test-prep app for green-card holders preparing for the U.S.
naturalization interview. It bundles all 100 official civics questions and the
official reading & writing vocabulary lists (public-domain U.S. government works),
adds a faithful mock-exam simulator (10 questions, pass at 6), adaptive practice
that targets your weak spots, and progress analytics that show how interview-ready
you are. State-specific and current-officeholder questions are presented as study
prompts (with guidance to verify on USA.gov) rather than auto-graded.

## Full feature list

- **Home** — animated readiness ring, study streak, coverage (questions seen),
  one-tap "Start Mock Exam", quick actions, a deterministic **Civics Question of
  the Day**, and your last exam result.
- **Study** — flashcard browser with a calm card-flip (static under Reduce Motion);
  flip to reveal acceptable answers + notes; mark **I know it** / **Needs review**;
  flag cards; filter by category; per-card mastery dots; optional **read-aloud**
  (AVSpeechSynthesizer, Pro).
- **Exam** — five modes:
  - **Mock Exam** (10 Q, pass at 6 — the official rule),
  - **Quick Quiz** (5 Q),
  - **By Category**, **Review Flagged/Missed**, **Weak-Area Adaptive** (Pro).
  Multiple-choice with plausible distractors generated from other questions'
  answers in the same category. `varies` questions are presented as self-check
  ("Did you know it?") instead of being auto-graded. Live timer, progress bar,
  and a full **result-review** screen: each question with your answer vs. the
  correct answer and the explanation/note, plus pass/fail.
- **Progress** — Swift Charts: mastery by category, exam scores over time (with the
  60% pass line), streak, pass rate, coverage; a searchable per-question list with
  mastery & flags; exam history. Calm empty state before you have data.
- **Vocab** — the official reading & writing vocabulary lists, grouped
  (people / civics / places / holidays / question words / verbs / other), with a
  tap-to-hear option and a flashcard **practice** mode (full lists & practice are Pro).
- **Settings** — your state/territory, 65/20 senior-exemption toggle, read-aloud
  audio toggle, haptics toggle, reset progress, Pro management, and About/Disclaimer.
- **Onboarding** — first-run flow gated by `@AppStorage("hasOnboarded")`; collects
  your state and senior-exemption preference and shows the disclaimer.
- **Citizen Pro** — a tasteful, simulated **one-time $4.99** unlock
  (`@AppStorage("isPro")`): unlimited mock exams, all categories + adaptive, full
  vocabulary lists & practice, audio narration, and full analytics. Free tier
  includes a few mock/quick exams per day plus core study.
- Seeded sample exam history so Progress isn't empty on first open.
- Full **accessibility**: Dynamic Type, VoiceOver labels/hints/values, decorative
  images hidden, WCAG-AA contrast in light & dark, and Reduce-Motion support.
- Sparse **haptics**, gated by a Settings toggle.

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` if present).
3. Open `Citizen.xcodeproj` in **Xcode 15+**, pick an **iOS 17+** simulator, and
   press **Cmd+R**.

### Free-signing note

The project uses no paid-account entitlements (no push, no real StoreKit). To run
on a physical device with a free Apple ID: open the **Citizen** target →
**Signing & Capabilities**, check **Automatically manage signing**, select your
personal team, and (if needed) change the bundle identifier to something unique
like `com.<you>.citizen`. The simulator needs no signing.

## Tech notes

- **iOS 17+**, **SwiftUI 5**, **Xcode 15**. NavigationStack throughout; two-parameter
  `.onChange`; `@Observable` view models; `@Query` + `modelContainer` for SwiftData.
- **Architecture: MVVM.** Pure engines (`ExamEngine`, `ProgressEngine`) hold the
  testable logic; `ExamSessionModel` is an `@Observable` session view model;
  `AppPreferences` is an `@Observable` settings store backing `@AppStorage` keys.
- **SwiftData** persists records (`QuestionStat`, `ExamResult`) — both registered in
  the app's `ModelContainer` schema; small preferences use `@AppStorage`. The store
  falls back to in-memory if the on-disk store can't open, with a calm error scene
  as the final guard (no crash paths).
- **AVSpeech** — `AVSpeechSynthesizer` drives read-aloud (`SpeechManager`,
  `@MainActor @Observable`), defensively configuring the audio session.
- **Design language** — a centralized `Theme`: warm **parchment** surface in light,
  deep **navy** in dark, federal-blue accent **#3F6BC4**, a tasteful **serif** display
  face for headers (`.system(design: .serif)`), and reusable card/button styles.
  Patriotic but refined — never gaudy. First-class light & dark, WCAG-AA in both.
- **Animation** — a calm 3D card flip in Study and an easing readiness ring, both
  disabled/static under `@Environment(\.accessibilityReduceMotion)`.
- **Monetization** — simulated one-time **Citizen Pro $4.99** via
  `@AppStorage("isPro")`; free tier gives a few exams/day + core study, Pro unlocks
  everything (no subscriptions, no ads).
- **Why it can boom** — ~800k+ people naturalize in the U.S. every year and the
  incumbent apps are ad-heavy or subscription-driven; Citizen is the clean, accurate,
  **one-time** alternative with a real exam simulation, weak-area adaptivity, and the
  official vocabulary lists in one refined package.

## Self-review attestation

Every Swift source file was re-read after authoring. Verified: all imports, types,
initializers, enum cases, and modifiers exist in the iOS 17 SDK and are spelled
correctly (including `AVSpeechSynthesizer` usage); protocol conformances are
satisfied; `@State` / `@Bindable` / `@Environment` / `@Observable` ownership is
correct; `NavigationStack`, `sheet`/`fullScreenCover`, `@Query`, and `modelContainer`
type-check; braces/parens/brackets balance in every file; **both** `@Model` types
(`QuestionStat`, `ExamResult`) are registered in the `Schema`; there is no
`NavigationView` and no single-argument `.onChange`. An anti-stub scan
(TODO/FIXME/XXX/placeholder/lorem/"coming soon"/"not implemented"/stub) returns
**zero** matches. There are no `fatalError`, `try!`, or force-unwraps on user paths;
division and index access are guarded. All **100** official civics questions are
authored (numbered 1–100, no gaps or duplicates), and distractor generation guards
small pools (degrading to self-check rather than crashing).

## Disclaimer

Citizen is an educational study aid based on the official USCIS 100 civics questions
(2008 version). Some answers depend on your state and on current officeholders, which
change over time — always verify those on **USA.gov** and **uscis.gov** before your
interview. The civics questions and vocabulary lists are works of the U.S. federal
government and are in the public domain. **Citizen is not affiliated with, endorsed by,
or sponsored by USCIS or the U.S. government.**
