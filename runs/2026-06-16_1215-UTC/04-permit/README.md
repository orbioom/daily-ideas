# Permit — DMV Driving Theory Practice Test

## What it is

**Permit** is a clean, ad-free iOS app for studying for the learner's permit / driver
knowledge test. It pairs realistic, timed mock exams with plain-language explanations
and weak-area focus.

- **One-liner:** Pass your permit test with realistic mock exams, clear explanations, and weak-area focus — no ads, no nagging subscription.
- **Problem:** The popular permit-prep apps are ad-heavy or lock the basics behind recurring subscriptions. New drivers want a focused, trustworthy tool that simulates the real exam and explains the answers.
- **Audience:** New drivers (teens and adults) preparing for the learner's permit or driver knowledge test.

> Permit's content covers **general US rules of the road**, written as best practice.
> Exact speed limits, blood-alcohol limits and penalties vary by state — always confirm
> specifics in your **official state driver handbook**. This disclaimer appears in
> onboarding, the home screen, the paywall and the About screen.

## Features

- **Study home** — exam-readiness ring, a big *Start Full Mock Exam* CTA, plus Quick Practice, Weak Areas and Review Missed shortcuts, a study streak, and your last result.
- **Practice by topic** — all 8 categories with live mastery bars and question counts; the practice player gives **instant feedback** (correct/incorrect highlight + explanation card + Next).
- **Mock exams** — full-screen player: question x/N, no feedback until you submit, a live timer, a progress bar, and per-question flagging. Full mock = up to 40 questions sampled across categories; **pass mark 80%** (e.g. 32/40). On finish: a pass/fail badge, score %, time, per-topic breakdown and *Review missed*.
- **Adaptive weak-area sessions** — selection is weighted toward unseen and low-accuracy questions.
- **Road Signs library** — ~30 common US signs, each **drawn with SwiftUI shapes/Canvas + SF Symbols** (no image files): octagon STOP, triangle YIELD, diamond warnings, pentagon school zone, route shields and more. Searchable, grouped by type, with a detail screen and study tip.
- **Progress analytics (Swift Charts)** — mock-score trend line with the 80% pass mark, per-topic accuracy bars, readiness/pass-rate/mock-count tiles, and a flagged-&-missed review list.
- **Onboarding** — 4 pages explaining the value, an optional "where are you studying" state label, and the handbook disclaimer.
- **Settings** — Appearance (System/Light/Dark), Mock length (20/30/40), Instant-explanation toggle, Show-timer toggle, Haptics + Sound toggles, study-state field, Reset progress (confirmed), Unlock Pro / Restore, and About.
- **Question bank: 126 questions** across 8 categories (Road Signs, Traffic Signals & Markings, Rules of the Road, Right-of-Way, Speed & Safe Driving, Parking & Turning, Alcohol/Drugs & Safety, Sharing the Road) — each with 4 options, a correct answer and a 1–2 sentence factual explanation.
- **Seeded sample data** on first run (a set of question stats + 4 mock results across recent days) so Progress isn't empty; guarded to run once.
- **Polish** — empty/loading/error/success states, success toasts, haptics gated by preference, light + dark themes, full Dynamic Type, VoiceOver labels/values on options and charts, and animations that honor Reduce Motion.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root if present).
3. Open `Permit.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

## Free signing

The project uses no paid capabilities. To run on a device, select the **Permit** target →
**Signing & Capabilities** → choose your personal Apple ID team and let Xcode manage
signing automatically. The bundle id is `com.orbioom.permit` (change it if it collides).

## Tech notes

- **Platform:** iOS 17.0+, SwiftUI, `NavigationStack` + `TabView`, Swift Charts.
- **Data:** SwiftData (`@Model` `QuestionStat`, `ExamResult`; both registered in the app `Schema`) for user progress; `@AppStorage` for preferences and the simulated Pro flag. Persistence survives relaunch.
- **Architecture:** Pure engines (`ExamEngine` for session building/grading, `ProgressEngine` for readiness/mastery/streak/trends) kept separate from views; content lives in `QuestionBank` and `SignLibrary`; a `StatStore` mediates SwiftData writes safely (fetch-or-create, guarded saves).
- **Design language:** a trustworthy "study green" identity (`Theme.accent = Color(hex: 0x178A4C)`, matching the AccentColor asset), dynamic light/dark colors via `Color.dyn`, rounded type, and consistent card surfaces.
- **Safety:** no `try!` / `as!` / force-unwraps / unchecked indexing / unguarded division on user paths; the only `fatalError` is the documented-unreachable in-memory `ModelContainer` fallback.
- **Monetization:** one-time **Permit Pro** unlock at **$4.99** (simulated, StoreKit-ready) — free tier gives 2 of 8 topics, one full mock per day, and practice explanations; Pro unlocks all topics, unlimited mocks, explanations in exam review, the full Signs library and Progress analytics. The free core is genuinely useful on its own.
- **Why it can boom:** permit prep is a recurring, high-intent need with millions of new drivers each year, and the dominant apps are ad-clogged or subscription-only. A clean, one-time-purchase app with realistic mock exams and explanations is exactly what frustrated learners (and their parents) search for — strong word-of-mouth and app-store-review potential.
- **Content scope:** general US rules of the road as best practice; **always confirm state-specific limits and laws in your official state driver handbook.**

## Self-review

I re-read every Swift source by hand and verified:

- **iOS 17 only:** `NavigationStack` throughout (no `NavigationView`); no `@Previewable`; no single-parameter `.onChange` (in fact no `.onChange` modifier is used); Swift Charts, SwiftData and SF Symbols APIs are all iOS 16/17-available. Risky SF Symbol names were replaced with well-established ones (e.g. `gauge.medium`, `figure.and.child.holdinghands`, `arrow.triangle.merge`).
- **SwiftData:** both `@Model` types (`QuestionStat`, `ExamResult`) are listed in `Schema([QuestionStat.self, ExamResult.self])`; `@Query` and `modelContainer` usage type-checks; `#Predicate` captures locals correctly; seeding is guarded to run once.
- **Observation:** `AppSettings` and `ProStore` are `ObservableObject` injected via `@StateObject`/`@EnvironmentObject`; no `@Observable` is mixed with `@StateObject`.
- **Crash-proofing:** no `try!`, `as!`, force-unwraps, unchecked array indexing, or unguarded division on user paths; all option access is bounds-checked (`Question.option(at:)`, guarded `current`), all percentages guard against zero totals. The sole `fatalError` is the documented-unreachable container fallback.
- **No placeholders:** searched for and found no `TODO`/`FIXME`/`placeholder`/`stub`/`lorem`/`coming soon`/`not implemented` strings; every button and screen is wired.
- **Content sanity:** programmatically verified all **126** questions have unique IDs, exactly **4** options each, and a `correctIndex` within 0–3; all 25 sign-question `relatedSign` references resolve to real entries in the 31-sign library. Spot-checked answers for correctness under general US norms (e.g. four-way stop → yield to the right; uphill parking with a curb → wheels away from curb; flashing red → treat as a stop sign; safe following distance → 3–4 seconds; only time lowers BAC).
- **Definition of Done:** 5 substantive tab screens (Study, Practice, Signs, Progress, plus full-screen Exam) beyond Onboarding/Settings; onboarding gated by `hasOnboarded`; empty/loading/error/success states; ≥3 real persisted prefs; lazy containers with stable `Identifiable` IDs; full accessibility (Dynamic Type, VoiceOver labels/values, decorative images hidden, chart labels) and Reduce-Motion fallbacks; gated haptics; Swift Charts on the analytics screen.
- **Balance:** braces and parentheses balanced in every file (the only apparent paren delta is `1)`/`2)` text inside comments).

**Attestation:** To the best of my hand review, the sources are internally consistent, free of the forbidden patterns above, and target the iOS 17 SDK. No Swift toolchain is available in this environment, so this attestation is based on careful manual and scripted review rather than a compiler run.
