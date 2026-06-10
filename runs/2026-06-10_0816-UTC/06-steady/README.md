# Steady — thoughts aren't verdicts

**What it is.** A calm CBT thought diary and anxiety toolbox: a guided seven-step thought record (situation → feelings → automatic thought → thinking traps → evidence → balanced thought → re-rate), the ten classic cognitive distortions with challenge questions, five short coping exercises, a one-tap daily mood check-in, and insights that show — from your own data — how much each reframe actually lowers belief and intensity. The evidence-based job Clarity, Stoic, and Bloom monetize with subscriptions, built private and complete.

**Audience.** The very large anxiety/overthinking market — people who want the technique therapists actually assign, without a $70/yr subscription or their inner life in someone's cloud.

## Features

- **Guided thought record** — seven steps with per-step validation and progress: situation; multi-emotion picker (16 common + custom) with 0–100 intensity sliders; the automatic thought with a belief-percentage slider; the ten Burns/Beck thinking traps (tap to tag, each explained); evidence for/against; a balanced-thought editor that surfaces the challenge questions for *your* tagged traps; re-rate (sliders seeded from your before-ratings). Nothing saves until the end; leaving asks first.
- **The receipt** — every saved record shows belief before → after and feeling before → after, so the technique proves itself with your own numbers; a calm message handles the no-change case (tone configurable).
- **Records journal** — month-grouped list (thought, top emotion, belief-drop badge), full detail view of all seven columns, swipe-delete with confirmation.
- **Coping tools** — five guided step-by-step exercises (5-4-3-2-1 grounding, box breathing, thought-vs-fact, talk-to-a-friend, urge surfing) in a full-screen one-step player with progress and Reduce-Motion-aware transitions.
- **Mood check-in** — one-tap 1–5 face on Today (one per day, updatable), feeding the trend chart; can be hidden in Settings.
- **Insights** — total reframes, average belief drop, activity streak; a 30-day mood line (check-ins + post-reframe feelings); a "your thinking traps" frequency chart with your signature trap named; a does-this-work card quoting your own average intensity drop.
- **Settings** — mood check-in toggle, default starting belief slider, gentle-summaries toggle, haptics — all functional; About with the self-help (not therapy) disclaimer and crisis note.
- Onboarding (3 pages incl. an honest care/crisis page, persisted flag), empty/loading states, light + dark, Dynamic Type, VoiceOver labels/values throughout, Reduce Motion, sparse haptics.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Steady.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**.

*Free signing:* personal team is enough — no entitlements used.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-style: SwiftData models (`ThoughtRecord` with Codable emotion/distortion payloads, `MoodLog`), pure `InsightEngine`, content (distortions, emotions, coping scripts) compiled in.
- Persistence: SwiftData; preferences in `@AppStorage`. Zero network, zero analytics — load-bearing for a mental-health app.
- Design language: **Orbioom** (glass, ink gradient, mist background, green reserved for relief/success).
- **Monetization:** mental-wellness journaling is a proven subscription category (Stoic, Clarity, Bloom); Steady sells a one-time "Steady Plus" (extra tools, export, themes) with the core record + tools free forever — the trust position incumbents can't take.
- **Why it can boom:** anxiety self-help is enormous and evergreen; CBT thought records are the single most evidence-backed technique in the space, and the leading apps wrap them in subscriptions and cloud accounts. "The real worksheet, beautifully done, private by architecture, with your own efficacy numbers" is a sharp wedge — and the belief-drop receipt is inherently shareable.

## Self-review

Every Swift file re-read against the iOS 17 SDK: SwiftData `@Model` with `Data`-backed Codable accessors, binding-`ForEach` over Identifiable structs, custom `Binding(get:set:)` slider bridges, Charts line/point/bar marks with custom axis labels, `fullScreenCover(item:)` over Identifiable content, and the step state machine traced through every path (back, leave, save). All four settings verified functional. Anti-stub grep clean. No force-unwraps, `try!`, or unchecked indexing on user paths.
