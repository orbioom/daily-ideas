# Locale — Travel Phrasebook

**Platform:** iOS 17+ · **Stack:** SwiftUI 5, SwiftData, AVFoundation · **Monetization:** One-time Pro IAP ($2.99)

## What it does
Locale is an offline travel phrasebook with 170+ essential phrases across 6 languages. Tap any phrase to hear native-style pronunciation via AVSpeechSynthesizer. Save favorites for instant access when you need them most.

## Key Features
- 170+ phrases across 8 categories: Basics, Numbers, Directions, Transport, Hotel, Restaurant, Shopping, Emergency
- 6 languages: Spanish, French (free) + Italian, German, Japanese, Portuguese (Pro)
- Native-style text-to-speech via AVSpeechSynthesizer for every phrase
- Phonetic transcription for all non-Latin-script languages
- Favorites tab with swipe-to-delete
- Category filter chips and full-text search
- 100% offline — no internet required
- Full dark/light mode, haptics, VoiceOver, dynamic type
- Free: Spanish + French · Pro: all 6 languages ($2.99 one-time)

## Architecture
- `PhraseData` — embedded phrase database: `Language`, `PhraseCategory`, `Phrase` structs + `PhraseDatabase` filter engine
- `PhraseDetailView` — `AVSpeechSynthesizer` + custom `SpeechDelegate` for playback state
- `FavoritePhrase` + `LocalePrefs` — SwiftData models
- `PhrasesView` — searchable list with category chip filter

## Beat
Beats Google Translate (requires internet) and expensive phrasebook apps by being completely offline, purpose-built for travel, and one-time priced.
