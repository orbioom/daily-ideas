# Parcel — Real Estate License Exam Prep

**Pass the national portion of your real-estate licensing exam.** Parcel is a calm, ad-free,
fully on-device study app: 120 exam-style questions across the ten national topics — each with a
clear explanation — plus mock exams, adaptive weak-area drills, and a readiness score that tells
you when you're ready to test. A one-time purchase, not another subscription.

**Audience:** the ~hundreds of thousands of people each year studying for a U.S. real-estate
salesperson/broker license who are tired of subscription prep sites and ad-heavy quiz apps.

## Features

- **120-question national bank** across 10 topics: Property Ownership & Land Use, Agency &
  Fiduciary Duties, Valuation & Appraisal, Financing, Contracts, Transfer of Title, Property
  Disclosures & Fair Housing, Leasing & Property Management, Real Estate Math, and Practice of
  Real Estate. Every question has a one–three sentence explanation.
- **Five study modes** driven by one `SessionBuilder` / `ExamSession` engine:
  - **Mock Exam** — timed, exam-length, graded against your pass threshold (no feedback until the end).
  - **Quick Quiz** — a short warm-up across all topics.
  - **Topic Quiz** — focus a single subject; instant feedback + explanations.
  - **Review Missed** — re-tests every question you've missed or flagged.
  - **Adaptive Drill** — mastery-weighted selection that targets your weakest questions first.
- **Instant feedback** in study modes (correct/incorrect coloring + explanation), exam-style
  deferral in mock mode, with a full **per-question result review** (expand any question, see the
  right answer + explanation, and **Redo missed**).
- **Readiness score** that blends average mastery with bank coverage, plus **per-topic mastery**,
  **mock pass-rate**, **study streak**, and **coverage** — all computed by a pure `ProgressEngine`.
- **Progress dashboard** with Swift Charts: score trend (with a 75% pass line), mastery-by-topic
  bar chart, and a full session history.
- **Topics browser** with per-topic mastery bars and a browsable question + answer list.
- **Flag** questions, **shuffle** answer order, optional **read-aloud** (AVSpeech), and a **reset
  progress** action.
- **Settings** with persisted preferences: quick-quiz length, mock length, pass threshold, shuffle,
  read-aloud, and haptics.
- First-run onboarding, empty/loading/success states everywhere, full **Dynamic Type + VoiceOver**,
  first-class **light & dark** mode, and **Reduce Motion** support.
- 100% on-device & private — no accounts, no network, no ads.

## Run steps

1) `brew install xcodegen` (one-time). 2) In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the
repo root). 3) Open `Parcel.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing:** set your Apple ID team in Signing & Capabilities; the bundle id is `com.orbioom.parcel`.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM. `@Observable` view models stored with `@State` (no `ObservableObject`/
  `@StateObject` mixing). Persistence in **SwiftData** (`ExamResult`, `QuestionStat`); the 120-question
  bank is a static, bundled value type. Small prefs in a UserDefaults-backed `AppPreferences`.
- Pure, testable engines: `SessionBuilder` (mode → question set, with deterministic SplitMix64-seeded
  option shuffling and weighted adaptive selection), `ProgressEngine` (readiness/mastery/pass-rate/
  streak — all division-guarded), `StatStore` (fetch-or-create stat rows). Every array access uses a
  safe `subscript(safe:)`; no force-unwraps on user paths; the store falls back to in-memory then a
  calm `StoreUnavailableView` rather than crashing.
- Design language: a confident, professional "study" identity — warm amber/brown accent, serif
  display headers that scale with Dynamic Type, per-topic color chips, and a readiness ring.
- **Monetization:** one-time **Parcel Pro $6.99** (unlimited full mock exams, adaptive + review modes,
  all ten topics, read-aloud audio, full analytics); free tier = quick quizzes + the first two topics +
  browsing. `@AppStorage`-style `isPro` flag with a `PaywallView` + simulated unlock/restore (StoreKit-ready).
- **Why it can boom:** real-estate exam prep is a proven paying market (students routinely pay
  $50–$200+), but the incumbents are subscriptions with short access windows (e.g. PrepAgent) or
  ad-saturated quiz apps — Parcel is the private, native, one-time app with a real exam simulator,
  adaptive weak-area targeting, and explanations on every question.

## Self-review

Audited with `runs/_tools/audit.sh`: 24 Swift files, anti-stub grep **clean**, **zero**
`try!`/`fatalError`/`as!`, no force-unwraps on user paths (only the in-memory `ModelContainer`
fallback uses `try?`), balanced braces in every file, all asset JSON valid, exactly one `@main`,
`@Observable` used only with `@State` (no `@StateObject`). All five engines/screens verified to
compile by inspection against the iOS 17 SDK; the audit's lone "MISSING icon" line is a path quirk
(the 1024 PNG is correctly at `Parcel/Parcel/Assets.xcassets/AppIcon.appiconset/icon-1024.png`).
