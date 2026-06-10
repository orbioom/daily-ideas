# Biscuit — a dog trainer in your pocket

**What it is.** A positive-reinforcement dog-training app: a 24-skill curriculum across four levels, each broken into concrete trainable steps with a pro tip and the common mistake to avoid; a real **synthesized clicker** (no audio files, no extra gadget) with a guided timed session that counts your clicks; and honest progress tracking. The job Dogo and Puppr monetize at $30–50/quarter, built without the paywall-on-every-command and streak-spam complaints those apps collect.

**Audience.** New puppy owners and anyone teaching an adult dog — a huge, hungry, willing-to-pay market.

## Features

- **Curriculum** — 24 skills (Foundation, Manners, Tricks, Advanced), each with a clear goal, ordered concrete steps you check off in sequence, a pro tip, and a "common mistake" — written in modern positive-reinforcement language.
- **Skill detail** — tap steps as your dog reliably performs them (status flows Not started → Learning → Practicing → Mastered), mark mastered when proofed, unmark to revisit; one-tap launch into a training session.
- **Synthesized clicker** — a crisp two-transient marker rendered into a PCM buffer and played through AVAudioEngine (`.ambient`, mixes with other audio, works on silent with haptics) — genuinely no bundled sound file.
- **Guided session** — full-screen timer + a big clicker button with a live click count, end-on-a-win prompt, then a save card (great/okay/tough rating + notes); keeps the marker latency-free and logs duration, clicks, and rating.
- **Today** — per-dog hero (mastered count, streak, sessions), an intelligent "today's focus" that surfaces the next unmastered skill in curriculum order (a graduation card when all 24 are done), and recent sessions.
- **Progress** — mastered/streak/total-trained stats, per-level progress bars, a 14-day sessions Swift Charts bar chart, and great-rate; empty and loading states.
- **Multi-dog** — full Dog CRUD with avatar/breed/birthday, a nav-bar dog switcher, per-dog progress and history, safe selected-dog fallback on delete.
- **Settings** — clicker sound + clicker haptic toggles, app haptics, dog management; About with the privacy promise. (Three+ persisted prefs.)
- Onboarding (3 pages + first-dog form, persisted flag, gated also on having a dog), empty states everywhere, light + dark, Dynamic Type, VoiceOver labels/hints/values, Reduce Motion, sparse haptics.

## Run it

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Biscuit.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**.

*Free signing:* personal team is enough — the clicker uses the ambient audio session, which needs no entitlement.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-style: SwiftData models (`Dog→SkillProgress`, `Dog→TrainingSession`, both cascade), pure `TrainingEngine` (status, suggested-skill, stats), a `@MainActor` `Clicker` that synthesizes audio with AVAudioEngine, content curriculum compiled in.
- Persistence: SwiftData; clicker/app prefs and selected dog in `@AppStorage`. Zero network.
- Design language: **Orbioom** (glass cards, ink-gradient clicker, mist background, rare green for mastered/live).
- **Monetization:** dog-training apps are proven subscription earners (Dogo $49.99/quarter); Biscuit sells a one-time "Biscuit Pro" (full advanced curriculum, multiple dogs, export) with the foundation course + clicker free forever.
- **Why it can boom:** pet care is a durable, high-spend category, and the incumbents' top complaints are "can't teach more than a few commands without premium," confusing app-vs-web pricing, and relentless upsell notifications — Biscuit's whole-curriculum-plus-real-clicker, no-subscription, no-spam approach is exactly the version frustrated reviewers describe wanting.

## Self-review

Every Swift file re-read against the iOS 17 SDK: SwiftData relationships (single-side inverse) and cascade deletes, `@MainActor` audio with `AVAudioPCMBuffer`/`scheduleBuffer`, TimelineView timer, Charts bar marks, navigationDestination for a `Hashable` `Skill` value, and the selected-dog resolution logic traced by hand. The clicker render math (two exponentially-decaying noise transients) was reasoned through for buffer sizing and channel writes. Anti-stub grep clean. No force-unwraps, `try!`, or unchecked indexing on user paths.
