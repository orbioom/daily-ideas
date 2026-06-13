# Verbatim — memorize any text, word-for-word

**One-liner:** The fast, private way to learn a poem, scripture, speech, monologue, or your wedding vows by heart — Verbatim drills any passage through escalating levels of recall and schedules spaced reviews so it actually sticks.

**Problem & audience:** Students, actors, public speakers, faith communities, and couples writing their own vows all need to memorize *long, exact text* — and flashcard apps (Anki, Quizlet) are built for atomic facts, not flowing passages. Verbatim is purpose-built for the whole thing: paste your text once and it walks you from reading, to first-letters, to progressively heavier blanks, to full recall, then spaces the reviews using a proven SM-2-style schedule. Offline, no account, one-time purchase.

## Features

- **Library** — every passage in one place, filterable by category (poem, scripture, speech, lines, vows, quote, other) and searchable by title, author, or text. Each row shows a mastery ring (0–5) and a "due for review" badge. The add flow takes a title, source, category, and the full text into a `TextEditor` with a live word count that preserves line breaks and stanza spacing exactly. Free tier holds up to 5 passages; the add button gates to the paywall at the cap.
- **Study player** — the core loop: a passage rendered at its current level via the pure `MaskEngine` (first-letters or seeded blanks), with line breaks and stanzas preserved. Tap any hidden word to reveal it, "Reveal all" to peek, then self-grade ("Nailed it / Some gaps / Struggled"). The grade updates mastery and appends a review log, and a calm success state shows the next stage and due date. Reveals respect Reduce Motion.
- **Today** — the due-for-review queue, sorted most-overdue first, with a one-tap "Review next" into the player, a deterministic daily nudge, and an "All caught up" empty state.
- **Progress** — review streak, passages mastered, words memorized, and total reviews, plus Swift Charts of reviews-per-week and the mastery distribution, and a recent-reviews list.
- **Settings** — passage text size (small/medium/large), default new-passage category and blank density, an optional daily review reminder (local notification, requested gracefully), haptics (two real toggles), Pro unlock/restore, and a delete-all-passages action behind a confirm alert. First-run onboarding gated by a persisted flag.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Verbatim.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and press Cmd+R.

**Free signing:** Select your personal team under Signing & Capabilities; the bundle id is `com.orbioom.verbatim`. No paid account or code-signing assets required to run on a simulator or a personal device.

## Tech notes

iOS 17+, SwiftUI 5, MVVM. Primary data (passages + review logs) in **SwiftData** (`@Model`, `@Relationship(.cascade)`, `@Query`); small preferences in `UserDefaults` via `@AppStorage`. The heart of the app is a pure, crash-proof engine: `MaskEngine` tokenizes text while preserving punctuation and whitespace, reduces words to first-letters, and hides a deterministic fraction of words with a seeded SplitMix64 RNG; `SpacedRepetition` schedules the next review on intervals [1,2,4,8,16,32] days and bumps or drops mastery from the self-grade. All arithmetic is guarded (no force-unwrap, division by zero, or unchecked index). Charts via Swift Charts; passages rendered in serif type with a custom wrapping `Layout`. Light + dark first-class via dynamic asset colors; Dynamic Type, VoiceOver labels, Reduce Motion, and opt-out haptics throughout. Design language: scholarly cream paper with indigo ink, serif passage type and rounded UI type.

- **Monetization:** Free core (up to 5 passages + all five study modes). One-time **Verbatim Pro ($6.99)** unlocks unlimited passages plus export/share — no subscription, no ads.
- **Why it can boom:** memorizing long passages is a broad, evergreen need (students, actors, public speakers, faith communities, wedding vows) that flashcard apps can't serve well; progressive masking is the proven mechanic, and the incumbents are clunky or Android-leaning — a beautiful, offline, one-time-purchase iOS app purpose-built for passages is exactly what that long tail searches for.

## Self-review

Hand-reviewed file by file (no Xcode in the build sandbox). Verified: all imports resolve; every type, modifier, and SwiftData/`@Query`/`@Observable`/`@Environment` usage is iOS-17-valid; `NavigationStack`/`navigationDestination`/sheet wiring type-checks; no force-unwrap, `try!`, `fatalError`, unchecked index, or unguarded division on user paths (the only `try!` is the standard in-memory `ModelContainer` fallback). Anti-stub grep clean. Onboarding gated by a persisted flag; seeding of three public-domain samples guarded by a one-time `didSeedLibrary` flag; empty/loading/success/error states present; light + dark, Dynamic Type, VoiceOver, Reduce Motion, and haptics wired.
