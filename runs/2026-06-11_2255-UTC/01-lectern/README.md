# Lectern — pocket teleprompter

**What it is.** A native iOS teleprompter for creators, speakers, teachers and officiants: write or paste a script, hit play, and read at a perfectly steady pace past a fixed guide line. The teleprompter category is full of proven money-makers whose users hate them — $65/yr trial traps, scrolling locked behind paywalls — so Lectern is the version people wish existed: everything works, nothing nags, everything stays on device.

## Features

- **Scripts library** — full CRUD with search across titles and bodies, pin-to-top favorites (leading swipe), duplicate and delete (trailing swipes), live word count and spoken-duration estimate per script; three sample scripts seeded on first launch.
- **Script editor** — serif writing surface with placeholder, live word count + duration footer, validation (title and body required, calm alert), "Save & prompt" that drops you straight into the player.
- **Prompter stage** — always near-black like real prompter glass; time-anchored scroll engine (`PrompterEngine`) that converts your words-per-minute setting into points/second for *this* script's measured layout, so the pace is honest; 3-2-1 countdown (configurable 0–10 s); tap to toggle controls; live speed (60–300 wpm) and text size (20–64 pt) adjustment mid-read with no visual jump; drag to seek; progress bar with elapsed/remaining; guide line as amber band, arrows, or none; horizontal mirror + vertical flip for beam-splitter glass; keep-awake; end-of-script success overlay with "Again"/"Done".
- **Rehearsals** — every meaningful run (≥5 s) is logged with duration, words covered, effective wpm and completion; stat tiles (total practice, full reads, average wpm), 14-day practice bar chart (Swift Charts), recent session list that survives script deletion.
- **Settings** — default speed, text size, countdown length, guide style, mirroring defaults, keep-awake, haptics (8 persisted preferences).
- Onboarding gated by a persisted flag; empty states on every data surface; light & dark first-class (the stage is intentionally dark in both); Dynamic Type in all chrome; Reduce Motion respected (countdown transition, control fades).

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Lectern.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

Free Apple ID signing works — set your team in Signing & Capabilities and run on device.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM-ish: `@Observable PrompterEngine` (deterministic wall-clock scroll: pause/seek/speed-change re-anchoring without drift), SwiftData (`Script` 1→N `RehearsalSession`, cascade), `@AppStorage` for prefs.
- Design language: "broadcast studio" — amber on deep charcoal, serif display for script content, rounded sans chrome.
- **Monetization:** creators/speakers pay; one-time Pro unlock (mirroring + rehearsal analytics) vs. incumbents' $50–65/yr subscriptions.
- **Why it can boom:** teleprompter apps are proven top-grossers (Teleprompter.com, PromptSmart) with 1–3★ reviews dominated by pricing rage and paywalled basics — a fair, polished alternative converts that anger directly.

## Self-review

Re-read every Swift file before commit: imports, iOS 17 API surface (`TimelineView(.animation(paused:))`, `.contentTransition(.numericText)`, Swift Charts, SwiftData macros), state ownership, navigation/sheet/fullScreenCover bindings, no force-unwraps/`try!` on user paths, anti-stub grep clean.
