# Gambit

**A tabletop combat manager with a built-in dice roller.** Build an encounter, roll initiative for everyone at once, step through turns and rounds with the active fighter always in view, and track HP and conditions — plus a fast dice roller for any expression. All offline.

For game masters who want one clean tool for running combat instead of juggling apps at the table.

## Features

- **Encounters** — create encounters, add the party and their foes, and run combat: round/turn header with the active combatant, next/back turn (round auto-advances), and a "roll initiative" / "end combat" menu.
- **Combatants** — initiative-ordered list (tie-broken by bonus then name) with HP bars, side colour (player/ally/enemy), AC, and condition chips. Tap for quick actions: damage (temp-HP soaks first), heal, set temp HP with quick +1/+5/+10/+20 buttons, and a full 5e condition toggle grid. Edit stats inline; downed combatants strike through and (optionally) dim.
- **Bestiary** — a reusable stat-block library (monsters, NPCs, PCs) with HP/AC/initiative bonus and notes; drop one — or several auto-numbered copies — into any encounter in a tap.
- **Dice** — quick dice (d4–d100), a custom expression parser (`2d6+3`, `1d20+5`, `2d8+1d6−2`) with full breakdown, advantage/disadvantage d20 with modifier, and a persisted roll history you can clear.
- **Settings** — auto-roll enemy initiative, dim downed enemies, confirm-before-delete, haptics, appearance, erase-all.

Onboarding gate, empty/loading/success states, light & dark, Dynamic Type, VoiceOver, Reduce Motion, designed app icon.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate`.
3. Open `Gambit.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, **Cmd+R**.

**Free signing:** pick your personal team under Signing & Capabilities; bundle id `com.orbioom.gambit`. No paid account needed.

## Tech notes

iOS 17+, SwiftUI 5, a pure `Dice` engine (signed multi-term notation parser, advantage/disadvantage, injectable RNG). Persistence in **SwiftData** (`Encounter → Combatant`, `StatBlock`, `DiceLog`); conditions stored as a CSV with a `Set<Condition>` accessor; prefs in `@AppStorage`. Orbioom design language. No third-party dependencies; a bestiary, a ready-to-run encounter and some dice history are seeded on first launch.

## Self-review

Anti-stub grep clean (only the in-memory `ModelContainer` fallback uses `try!`). By-hand compile pass: SwiftData relationships, `@Bindable` combatant rows/sheets, initiative-order `ForEach` over `Identifiable` models (no tuple key-path ids), the dice parser's guards (bad expressions return nil, no force-unwraps), and damage/heal/temp-HP math verified against the iOS 17 SDK. Correctness is by inspection (no Xcode in the sandbox).
