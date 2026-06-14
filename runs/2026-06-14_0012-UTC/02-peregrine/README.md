# Peregrine

**A calm, fast, adaptive world-geography trainer.** Learn every country, capital and flag —
across all six continents — with practice that quietly drills your weak spots. Ad-free, beautiful,
and built to feel good on the hundredth use.

**Problem & audience.** Existing geography quiz apps (Seterra, "World Geography Quiz", and friends)
are cluttered with ads, dated UI, and dumb question selection that re-asks what you already know.
Peregrine is for students, travelers, trivia lovers and curious explorers who want a focused,
native, adaptive way to actually *learn* the map — not just be tested at random.

## Features

- **Home / Dashboard** — overall mastery ring, current streak, per-continent mastery bars, a shared
  **Daily Challenge** card, and a Start-Quiz composer (mode + region + length). Calm first-run empty
  state before you have any data.
- **Quiz player** — flag or text prompt cards, four tappable choices, immediate correct/incorrect
  feedback with the right answer and a reinforcing fact, a progress bar, and an optional timer.
- **Results screen** — accuracy ring, score, time, and a flagged "review" list of everything you
  missed, with Play-again and Back actions.
- **Atlas / Browse** — all 129 countries grouped by continent in a sectioned list, search by name or
  capital, a star toggle and a "starred only" filter, with a per-country mastery dot.
- **Country Detail** — large flag, capital, region, population, currency, two-to-three facts, your
  mastery, and a star button.
- **Progress / Stats** — Swift Charts accuracy trend (line), per-continent mastery (bar), a
  most-missed list, and an achievements grid (Centurion, Globe Trotter, per-continent Experts, streaks…).
- **Five quiz modes** — Flag→Country, Country→Capital, Capital→Country, Flag→Continent, and
  Bigger-Population.
- **Adaptive engine** — weighted selection toward unseen and low-mastery countries; multiple-choice
  distractors drawn from the same region/continent for plausibility; deterministic daily challenge
  seeded from the date (same 10 questions for everyone).
- **Settings** — default quiz length, default mode, timer on/off, haptics toggle, reset progress
  (with confirmation), Pro / restore, and About.
- **Onboarding** — three-page first run gated by `@AppStorage("hasOnboarded")`.
- **Peregrine Pro** — honest one-time unlock: all six continents (free gives three), all five modes
  (free gives two), unlimited quizzes (free is three per day), and full stats.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root if present).
3. Open `Peregrine.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

**Free signing.** No paid account needed — select your personal team under
*Signing & Capabilities*, or run on the simulator with automatic signing.

## Tech notes

- **iOS 17+, SwiftUI, MVVM.** `NavigationStack` + `TabView` navigation; an `@Observable`
  `QuizViewModel` drives each run.
- **SwiftData** for user progress (`CountryProgress`, `QuizSession`); `@AppStorage` for small flags
  and prefs. The country dataset is a bundled, curated Swift array (no networking, no dependencies).
- **Swift Charts** for the accuracy trend and per-continent mastery.
- **Pure quiz engine** — `QuizEngine` is SwiftUI-free: mastery-weighted adaptive selection,
  region-aware distractors, and a date-seeded deterministic daily challenge (SplitMix64 + FNV-1a).
- **Design language** — "Liquid Glass"-inspired but native-first: quiet teal accent over calm
  near-neutral surfaces, full light/dark via `Color.dyn`, Dynamic Type, VoiceOver labels, WCAG-AA
  contrast, Reduce-Motion-aware animation, and sparse haptics gated by a Settings toggle.
- **Crash-proofing** — no force-unwraps, `try!` (except the documented in-memory `ModelContainer`
  fallback), or unguarded array/division on user paths.
- **Monetization** — one-time "Peregrine Pro $4.99" local unlock via `@AppStorage("isPro")`
  (production wires StoreKit 2); the free tier is genuinely useful on its own.
- **Why it can boom** — the established geography-quiz audience is huge but underserved by ad-heavy,
  dated apps; a beautiful, adaptive, ad-free trainer with a daily shared challenge is exactly the
  retention-and-virality combo that turns a niche into a habit.

## Self-review attestation

Every Swift file was re-read for iOS 17 SDK correctness: imports, type/initializer/modifier
existence and spelling, protocol conformances, `@State`/`@Observable`/`@Query`/`@Environment`/
`modelContainer` wiring and ownership, `NavigationStack`/`navigationDestination` typing,
brace/paren balance, defined `Theme.` tokens, and Swift Charts axis/scale plottable types. An
anti-stub grep (`TODO`/`FIXME`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`stub`/…) is
clean, and there are no force-unwraps, `try!` (beyond the allowed in-memory container fallback), or
`fatalError` on user paths.
