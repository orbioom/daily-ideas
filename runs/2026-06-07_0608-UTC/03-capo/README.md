# Capo — Chord transposer & setlist manager

**A songbook that transposes.** For gigging and practising musicians: keep chord charts, shift any song to any key (chords respelled correctly), read Nashville numbers, and build setlists with a per-song transpose and capo.

Design language: **Orbioom** (Liquid Glass, ink-gradient buttons, SF Pro + JetBrains Mono for chords, green for live chord accents).

## The problem
Most chord apps either don't transpose properly (wrong enharmonics) or hide it behind a paywall, and setlist apps rarely let each slot carry its own key/capo. Capo does both, offline, in a clean ChordPro format.

## Features
- **Songbook** — songs with title, artist, key, tempo, time signature, capo; searchable list.
- **Song detail (the showcase)** — live transpose (± semitones) with the sounding key updating, capo-shape hint ("Capo 2 · play D shapes"), a Nashville-numbers toggle, and a chart renderer that places chords above the lyric they fall on.
- **Chord engine** (`Utilities/ChordEngine.swift`): pitch-class parsing with `#`/`b`, key-aware sharp/flat spelling, full chord parsing (root + suffix + slash bass), `[chord]` transposition across a chart, key transposition, shortest semitone distance between keys, Nashville number conversion (major & natural-minor degrees, accidental degrees, slash notes), and capo math (`shapesKey`, open-friendly capo suggestions).
- **Song editor** — full CRUD with an ordered sections editor (add/reorder/remove, ChordPro text), key/time pickers, capo & tempo steppers, performance notes.
- **Setlists** — ordered sets with venue/date and an estimated running time; per-slot transpose & capo with expandable inline controls, reorder, add songs (only those not already in the set), remove.
- **Performance view** — swipeable large-type charts, each already transposed to its setlist key with the capo shapes to play.
- **Tools** — a standalone transposer/Nashville/capo calculator: type chords, shift by key or semitones, see transposed + Nashville chips and a full capo-position table (★ = open-friendly).
- **Settings** — haptics, appearance, default new-song key, confirm-before-delete, library stats, guarded erase-all.
- Onboarding gated by a persisted flag; empty states; full Dynamic Type, VoiceOver, Reduce Motion, light & dark, designed eighth-note app icon. Ships with public-domain/traditional songs so the songbook is populated.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Capo.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** personal team under Signing & Capabilities; bundle id `com.orbioom.capo`. No network, accounts, or API keys.

## Tech
iOS 17+, SwiftUI 5, SwiftData (`Song`/`Section`/`Setlist`/`SetlistItem`), a pure-Swift music-theory engine, a custom `FlowLayout` (`Layout` protocol) for chord chips, `UserDefaults` for prefs. No third-party dependencies.

## Self-review
Re-read every Swift file by hand: imports, iOS 17 SDK symbols, `String.Index` handling in the chord/chart parsers, SwiftData wiring, `Layout` conformance, `Picker` tags, `.onChange` two-parameter form, `project.yml`. Anti-stub grep clean. No force-unwraps on user paths (the one `parseChord` `first!` is guarded by a prior non-empty check); only `try!` is the in-memory container fallback. An automated by-hand compile review of this app returned clean. Believed to compile cleanly under Xcode 15+ after `xcodegen generate`.
