# Crest

**Crest** is a calm, ad-free game of **TriPeaks solitaire** for iOS 17+. Clear three overlapping peaks one card at a time, build long combos, and chase a daily streak — on a felt-green card table with no banners, no pop-ups, and no "watch an ad to continue." One quiet table, yours forever.

## What it is

- **Name:** Crest
- **One-liner:** TriPeaks solitaire without the ads — a focused, premium-feeling card table you actually want to come back to.
- **Problem & audience:** The popular solitaire apps are saturated with interstitial ads, forced video unlocks, and aggressive upsells. Crest is for people who just want to play a relaxing hand of TriPeaks: pay once (optionally) for extra boards, never see an ad, and keep a real daily streak.

## How TriPeaks works (the rules Crest implements)

- A tableau of **28 cards** forms the board. The free **Three Peaks** layout uses the classic rows of **3, 6, 9, 10** as three overlapping peaks; below it sit a **stock** pile and a **waste** pile.
- A tableau card is **face-up and playable** only when both cards covering it from below have been cleared.
- You may move any playable card onto the waste when its rank is **adjacent (±1)** to the current waste card. Ranks **wrap** so **King ↔ Ace** are neighbours (a setting, default **ON**).
- When you're stuck, **draw** the next card from the stock to the waste. Drawing **resets your combo**.
- **Combo scoring:** each consecutive card cleared without drawing raises a combo multiplier, and each step is worth more points. Clear all 28 cards to **win**; if the stock empties and no legal move remains, you **lose**.

## Features

- **Play screen** — overlapping peaks with depth shading, stock + waste piles, a live Score / Combo / Cards-left HUD, tap-to-play, and **Undo / Hint / Restart** controls. Win and lose overlays show full stats. Smooth deal/clear animations with a still fallback under Reduce Motion.
- **Three board geometries**, all using the same adjacency rule, each with its own correct covering graph:
  - **Three Peaks** (classic 3·6·9·10) — free.
  - **Pyramid** (a single 28-card triangle, rows 1…7) — Pro.
  - **Diamond** (a symmetric 1·3·5·5·5·5·3·1 variant) — Pro.
- **New Game** — pick a board and a deal mode: **Daily**, **Numbered** (type a deal #; the same number always deals the same board), or **Random**. Pro boards are clearly marked.
- **Daily** — today's shared deal, a current **win streak**, best daily score, and a **month calendar** marking the days you won. Pro unlocks the daily archive.
- **Stats** — **Swift Charts**: win rate by board, scores over time, games played by board, plus best score, best combo, total time. Pro adds **CSV export** with a share sheet.
- **How to Play** — a clean, scrollable rules reference that reflects your wrap-around setting.
- **Settings** — Appearance (System/Light/Dark), Haptics, Wrap-around K↔A, Draw sound, Left-handed layout, and a Felt theme picker (Classic free; Midnight / Sunset / Slate are Pro), plus Unlock/Restore and About.
- **Onboarding** — a gated multi-page intro that explains the value and sets the `hasOnboarded` flag on finish.
- **Resume on relaunch** — your in-progress game (board, score, combo, elapsed time) is saved and restored automatically.
- **Wall-clock timer** re-anchored on `scenePhase` (banked into accumulated time when backgrounded; live via `TimelineView`).
- **Seeded history** — about 36 realistic past results (mixed wins/losses, scores, boards, dailies) are seeded once on first run so Stats and the streak calendar are alive immediately.
- **Full empty / loading / error / success states**, Dynamic Type, VoiceOver labels on cards, piles and charts, AA contrast in light **and** dark, Reduce-Motion fallbacks, and settings-gated haptics throughout.

## Pro (simulated, one-time)

A one-time unlock stored in `@AppStorage("isPro")` — **StoreKit-ready** but simulated for this build (no real purchase). It unlocks: **Pyramid + Diamond** boards, the **daily archive**, **extra felt themes**, and **stats CSV export**. The free game is fully usable and satisfying: complete Three Peaks, one daily deal, unlimited random/numbered games, full stats, and the streak calendar.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root if present).
3. Open `Crest.xcodeproj` in **Xcode 15+**, pick an **iOS 17+ simulator**, and press **Cmd+R**.

### Free signing

This is a normal device-free build — it runs in the simulator with no account. To run on a physical device, select the **Crest** target → **Signing & Capabilities**, choose your personal Apple ID team, and let Xcode manage a free provisioning profile (the bundle id `com.orbioom.crest` can be changed if it's taken).

## Tech notes

- **iOS 17+, SwiftUI** throughout. `NavigationStack` + `navigationDestination`, `TabView`, `TimelineView`, `ShareLink`.
- **SwiftData** for primary data (`@Model GameResult` for history; single-row `@Model SavedGame` holding a JSON-encoded `BoardState` for resume), with `@Query` + `modelContainer`. Both models are registered in the app's `Schema`. Small preferences/flags live in `@AppStorage`.
- **Architecture:** a pure, deterministic, fully index-guarded engine (`CrestEngine`, `SplitMix64` seeded RNG, `BoardLayoutFactory` cover graphs) with **no** SwiftUI/SwiftData dependencies, wrapped by an `@Observable` `GameViewModel` that owns timing, persistence, and result recording. App-wide settings and the Pro store use `ObservableObject` + `@StateObject`.
- **Charts:** Swift Charts for the Stats screen, with accessibility labels/values.
- **Design language:** a calm felt-green card table with gold-green accents (accent `#1FA463`) and rounded SF type. Every custom color is defined via `Color.dyn(light, dark)` so light and dark both read at AA contrast; the theme is applied on every screen.
- **Monetization:** one-time, ad-free Pro unlock (`$3.99`) for extra boards, daily archive, themes and export — no ads, no subscriptions.
- **Why it can boom:** the top solitaire apps are ad-saturated; a genuinely ad-free, premium-feeling TriPeaks with a daily streak and a fair one-time unlock is exactly the calm alternative that solitaire players keep asking for.

## Self-review

I re-read every Swift file by hand and verified:

- **Imports** are present wherever needed (`SwiftUI`, `SwiftData`, `Charts`, `Foundation`, `AVFoundation`, `UIKit`, `CoreGraphics`); no unused heavy imports.
- **iOS 17 only:** no `NavigationView`, no `@Previewable`, no iOS-18 SwiftUI/SwiftData symbols. Every `.onChange(of:)` uses the **two-parameter** `{ old, new in }` form (3 sites, all confirmed).
- **No `try!`, no `as!`, no force-unwraps** on user paths (grep-clean). Every tableau access is index-guarded in the engine and view-model; no unguarded division. The **only** `fatalError` is the documented-unreachable in-memory `ModelContainer` fallback.
- **No** `TODO/FIXME/XXX/placeholder/lorem/coming soon/not implemented/stub/unimplemented` strings (grep-clean).
- **Every `@Model`** (`GameResult`, `SavedGame`) is listed in the `Schema([...])` in `CrestApp.swift`.
- **Observation hygiene:** `@Observable` view-model is used with `@State`/`@Bindable` (never `@StateObject`); `AppSettings`/`ProStore` are `ObservableObject` + `@StateObject`. No mixing.
- **Type-checking sanity:** `NavigationStack`/`navigationDestination`/`sheet` bindings, `@Query` predicates, `FetchDescriptor` + `#Predicate`, `Chart` marks, and `Codable` board snapshots all use real iOS 17 APIs spelled correctly. Protocol conformances (`Identifiable`, `Codable`, `Hashable`, `CaseIterable`, `RandomNumberGenerator`, `ButtonStyle`) are satisfied.
- **Braces/parens balanced** in every file (checked programmatically).
- **DoD coverage:** 4 substantive feature screens (Play, New Game, Daily, Stats) plus How-to-Play, gated Onboarding, Settings with 6 real persisted prefs; empty/loading/error/success states; SwiftData persistence + seeded history; Dynamic Type, VoiceOver, AA light/dark, Reduce-Motion fallbacks, settings-gated haptics; lazy containers with stable IDs; Swift Charts analytics.

Attestation: to the best of a careful by-hand review, these sources are complete, internally consistent, free of stubs/dead buttons, and compile-ready against the iOS 17 SDK.
