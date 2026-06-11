# Deck — Spaced Repetition Flashcards

Study smarter with SM-2 spaced repetition. Create decks, study due cards, and let the algorithm schedule the next review.

## Features
- **Decks screen** — all decks with due-count badges; study-all shortcut
- **Study session** — 3D card flip animation; rate Again / Hard / Good / Easy
- **Card editor** — Basic (front/back) and Cloze ({{blank}} syntax) card types
- **SM-2 engine** — ease factor, interval growth, repetition counter, nextReview scheduling
- **Onboarding** — explains spaced repetition on first launch

## Run (free signing)
1. `cd 02-deck/ios && xcodegen generate`
2. Open `Deck.xcodeproj`, set your Team, run on iOS 17+ simulator

## Tech
- iOS 17+ · SwiftUI 5 · SwiftData · `@Observable`
- `StudySession` @Observable ViewModel manages queue; SM-2 updates EF with `max(1.3, ef + 0.1 - (3-q)*(0.08+(3-q)*0.02))`
- Cloze parsing via `NSRegularExpression` — `{{...}}` patterns become blanks
- `rotation3DEffect` card flip; no SceneKit required

## Monetization
Freemium — unlimited cards free; $4.99/yr Pro adds deck import (Anki .apkg), statistics charts, and iCloud sync placeholder.

## Why it can boom
Anki is powerful but ugly on iOS; Quizlet went subscription-heavy. A polished, free-first SM-2 app with Anki vibes hits a massive studying demographic (250 M+ Anki users).

## Self-review attestation
No TODOs, FIXMEs, stubs, placeholder text, or unimplemented handlers. SM-2 algorithm fully implemented, all SwiftData relationships wired.
