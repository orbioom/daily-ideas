# 04 — Fable: Kids Bedtime Story Creator

A magical story-making app for parents and kids — create original bedtime stories with custom characters, or use built-in templates with full text-to-speech narration. 100% offline.

## Features

- **Story Library** — create and organize stories by genre, age group, and favorites
- **6 Built-in Templates** — adventure, space, fantasy, mystery, silly, friendship stories ready to read
- **Custom Characters** — add heroes, sidekicks, villains with emoji avatars and personality traits
- **Story Reader** — immersive dark-mode reader with page-by-page navigation
- **Text-to-Speech** — AVSpeechSynthesizer narration with adjustable speed
- **Age Groups** — 2–4, 4–6, 6–8, 8–10 year ranges
- **Read Counter** — tracks how many times each story has been read
- **3-step Onboarding** — welcome → child's name → age group preference

## Screens

1. Onboarding (3 steps: welcome, child name, age group)
2. Stories List (genre filter chips, favorites toggle, search)
3. Story Detail (story text / characters tab picker)
4. Templates Gallery (6 pre-built stories, genre filter)
5. Story Reader (dark/light mode toggle, TTS narration, page navigation)
6. Add/Edit Story form
7. Add Character form (emoji picker, role selector)
8. Settings (narration speed, dark mode default, age group)

## Tech

- SwiftUI 5 + SwiftData (iOS 17+)
- AVSpeechSynthesizer for TTS narration
- XcodeGen `project.yml`
- No external dependencies, no API keys

## Monetization

One-time Pro unlock ($2.99): unlimited story creation (free = 3 stories), custom character photos, export story as PDF to print.

## Market Signal

"Bedtime story app" gets 22K+ monthly searches. Parents of young children are a high-LTV demographic. Competitors (StoryBird, Storytime) are subscription-based and require internet. Fable is one-time purchase, fully offline, and lets parents personalize stories with their child's name and real characters — a key differentiator.
