# Clef — sight-reading trainer

**One-liner:** Learn to read music notes on sight, fast — a beautiful, ad-free note-reading drill across treble, bass, alto, and grand staff.

**The problem + audience:** Sight-reading is the single biggest bottleneck for beginning musicians, and flashcard-style note trainers (Note Rush, Music Tutor, Notes! Learn) prove there's a real market — but they look dated, are full of ads, or charge for the basics. Clef is for piano/guitar/band/choir students (and their teachers) who want a gorgeous, focused trainer that drills exactly the notes they keep missing.

## Full feature list
- **Practice (drill player)** — a `Canvas`-drawn staff shows one note with its clef glyph and ledger lines; answer on an on-screen **piano octave** or **note-name buttons**. Live score / streak / timer ring; correct flashes green and advances, wrong flashes red and shows the correct name; an end-of-drill summary card (accuracy, average response time, best streak).
- **Practice setup / Modes** — choose clef (treble free; bass / alto / grand are Pro), note range presets (staff-only → with ledger lines → full), accidentals on/off, and length (10 / 20 / 50 / Timed 60s), with your best for each config.
- **Learn (reference)** — every natural note rendered on the staff per clef with names and mnemonics (treble EGBDF / FACE, bass GBDFA / ACEG, alto centered on middle C), plus a short ledger-line explainer.
- **Progress** — per-note **mastery** bars/heatmap by clef, session history, and Swift Charts: accuracy over sessions, average-response-time trend, and notes practiced. Loading and empty states.
- **Settings** — default clef, answer style (piano vs letter buttons), note-name style (letters vs Do-Re-Mi solfège), key labels on/off, flat spelling, sound on/off, haptics; plus Pro, stats export, Load sample data, reset, About.
- **Onboarding** (3 pages), first-run gated; **60 seeded sessions** with an upward skill trend + note stats across clefs so Progress is immediately meaningful.
- **Optional tone playback** — an AVAudioEngine sine synth plays the answered note (gated by a sound setting; silently skips if audio can't start).

## Run steps
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Clef.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

**Free-signing note:** No paid account needed — set a Personal Team and use the `com.orbioom.clef` bundle id (or your own). No entitlements required.

## Tech notes
- iOS 17+, SwiftUI 5, MVVM. **SwiftData** (`DrillSession`, `NoteStat`), prefs in `@AppStorage`. The drill is an `@Observable` `DrillEngine` owned by `@State` (never wrapped in `@StateObject`).
- Pure music engine: pitches by MIDI number; `StaffLayout` positions a note by its diatonic step relative to a clef's bottom line (lines = even steps, spaces = odd), generating ledger lines as needed — geometry independently verified for all clefs. Mastery-weighted next-note selection favors notes you miss, guarded against zero total weight.
- Design language: elegant parchment-and-ink — indigo accent, serif headings, a crisp `Canvas` staff legible in both modes; first-class light & dark via `Theme.dyn`; Dynamic Type, a descriptive `accessibilityLabel` on the staff ("Note E, first line of the treble staff"), labeled answer keys, Reduce Motion respected.
- **Monetization:** free is treble clef, naturals, sessions ≤ 20; **bass/alto/grand clefs, accidentals, timed mode, full ranges, and stats export** are a one-time **$4.99** Pro unlock (StoreKit not wired; demo unlock + Restore). Who pays: students and teachers who want the full multi-clef trainer.
- **Why it can boom:** note-reading trainers are a proven, evergreen music-education niche with steady paid downloads, and the incumbents are visually dated and ad-driven. Clef offers a tasteful, multi-clef, adaptive trainer that musicians and teachers will happily recommend.

## Self-review
35 Swift files. Static audit clean: one `@main`, one `try!` (in-memory fallback), anti-stub grep clean, valid asset JSON, real 1024² icon, balanced delimiters, `@Observable` engine not mixed with `@StateObject`. Both `@Model` types registered in both `ModelContainer` calls; ≥4 feature screens + Settings; empty/loading/error/success states; all divisions/indices guarded; AVAudioEngine usage guarded. A dedicated compile-review pass verified Canvas/Path, AVFoundation, and cross-file types against the iOS 17 SDK.
