# 书 Shu — Mandarin HSK 1 SRS Flashcard Trainer

Shu (书, "book") is a native iOS app for learning the 100 most essential Mandarin Chinese characters from HSK Level 1 using spaced-repetition.

## Killer Features

- **4 Study Modes** — Flashcard flip, Tone Quiz, Meaning Quiz, and freehand Writing practice
- **SM-2 Algorithm** — The same algorithm used by Anki; each card is scheduled at the optimal review interval based on your performance
- **AVSpeechSynthesizer TTS** — Every character is voiced by iOS's built-in Mandarin (zh-CN) engine at a learner-friendly pace
- **100 HSK 1 Words** — Full coverage of the foundational vocabulary: pronouns, verbs, numbers, question words, directionals, and more
- **Streak Tracking** — Consecutive-day streaks with a 7-day bar chart and mastery breakdown
- **Dark Navy / Gold Theme** — Easy on the eyes for late-night study sessions

## Build Instructions

Requirements: Xcode 15+, iOS 17+, `xcodegen` (`brew install xcodegen`)

```bash
cd ios
xcodegen generate          # generates Shu.xcodeproj from project.yml
open Shu.xcodeproj         # open in Xcode
# Select a simulator or device, then Run (⌘R)
```

## File Structure

```
ios/Shu/
├── ShuApp.swift                    # App entry point, SwiftData ModelContainer
├── Theme/
│   └── ShuTheme.swift              # Colors, fonts, radii (dark navy + gold palette)
├── Models/
│   ├── HskData.swift               # 100 HskWord structs + pinyinNoTone extension
│   ├── ShuModels.swift             # @Model CardReview, StudySession (SwiftData)
│   └── SRSEngine.swift             # @Observable SM-2 engine
├── Utilities/
│   └── SpeechManager.swift         # AVSpeechSynthesizer wrapper
└── Views/
    ├── MainTabView.swift            # Tab bar: Study / Stats / Settings
    ├── Onboarding/
    │   └── OnboardingView.swift     # 3-page intro carousel
    ├── Study/
    │   ├── DeckView.swift           # Card grid, due-count badge, start session
    │   ├── SessionView.swift        # Session driver, progress bar, completion screen
    │   ├── FlashcardView.swift      # Flip card with rating buttons (Again/Hard/Good/Easy)
    │   ├── ToneQuizView.swift       # 4-tone multiple-choice with color coding
    │   ├── MeaningQuizView.swift    # English meaning multiple-choice
    │   └── WritingView.swift        # Freehand canvas with ghost-character guide
    ├── Stats/
    │   └── StatsView.swift          # Streak, today count, 7-day chart, mastery breakdown
    └── Settings/
        └── SettingsView.swift       # Session size, pinyin toggle, reset progress
```

## How It Works

1. On first launch, `SRSEngine.bootstrapReviews` creates a `CardReview` record for every HSK word.
2. `DeckView` queries all `CardReview` records and filters for those with `dueDate <= now`.
3. Tapping "Start Session" passes the due cards (capped at the session size) to `SessionView`.
4. `SessionView` randomly picks a study mode per card (flashcard 30%, tone 25%, meaning 30%, writing 15%).
5. After every rating, `SRSEngine.processRating` updates the card's `interval`, `easeFactor`, and next `dueDate`.
6. When the session ends, a `StudySession` record is saved for streak and stats tracking.
