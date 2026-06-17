# Sigma

## What it is

**Sigma** is a precise, premium scientific + programmer calculator with a searchable history tape and a unit converter — the calculator people wish iOS shipped. It does real expression evaluation (not button-at-a-time accumulation), keeps every result on a persistent tape you can search and reuse, converts across nine unit categories, and reads any integer in DEC/HEX/BIN/OCT with full bitwise operations. Beautiful, one-time purchase, no ads.

**Audience:** students, engineers, developers, scientists, makers — anyone who does actual math on their phone and is tired of the stock calculator and ad-laden free apps.

## Features

- **Calculator (core).** A live display showing the expression and its result, plus a tactile keypad:
  - Digits, decimal, `+ − × ÷`, parentheses, `%` (modulo), `±`, clear (`AC`) and backspace.
  - Scientific rows: `sin cos tan` with a `2nd` shift toggle for `asin acos atan`, `ln`, `log`, `√`, `x²`, `xʸ`, `1/x`, `n!`, `π`, `e`.
  - `DEG`/`RAD` toggle and a full memory register (`MC MR M+ M−`).
  - Tap `=` to evaluate and append to the history tape; tap the result to copy (toast + haptic).
  - Thousands separators in the display; calm inline **Error** on divide-by-zero, √ of a negative, bad expressions — never a crash.
- **History (Tape).** Every `=` is saved (SwiftData) with expression, result and timestamp. Reverse-chronological list, search field, swipe-to-delete, "Clear all", and tap/long-press to insert a result or the original expression back into the calculator. Empty state included. Free tier keeps the most recent 50 (oldest pruned); Pro is unlimited.
- **Converter.** Nine categories — Length, Mass, Temperature, Volume, Area, Speed, Time, Storage, Energy. Pick a category, type a value, choose from/to units (with a swap button), and see both the single conversion and the value in **all** units of that category. Factor tables for everything; affine C/F/K math for temperature; guarded divisions. A brief computing state renders the all-units breakdown.
- **Programmer.** A value shown simultaneously in DEC / HEX / BIN / OCT plus a grouped-binary line, a base-aware keypad (A–F enabled only in HEX, digits gated per base), bitwise `AND OR XOR NOT << >>`, double/halve, set-all-bits, and an 8/16/32/64-bit width selector. Fixed-width unsigned logic; overflow wraps/masks consistently to the chosen width.
- **Onboarding** (3 pages), **Settings**, **Paywall**, and an **About** screen.
- **Constants library (Pro):** 16 physics & math constants (c, g, G, h, Nₐ, k, R, e, …) insertable straight into the calculator.

### States
Onboarding (gated by `hasOnboarded`), empty states (history + search), loading state (seeding on first run, converter all-units compute), error states (calm inline expression errors), and success states (copy/insert toasts + haptics).

### Settings (≥3 real persisted prefs)
Appearance (System/Light/Dark), decimal places (2/4/6/Auto), thousands separator on/off, default angle (DEG/RAD), haptics on/off, plus (Pro) calculator theme and high-precision mode — and Unlock Pro / Restore / About.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at repo root).
3. Open `Sigma.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

## Free signing

No paid Apple Developer account is required to build and run on the simulator. To run on a physical device, select your personal team under **Signing & Capabilities** (free Apple ID signing); the bundle identifier `com.orbioom.sigma` can be changed if it is already taken.

## Tech notes

- **iOS 17+**, **SwiftUI**, **SwiftData** (`@Model CalcEntry`, `@Query`, `modelContainer`) for the primary history data; `@AppStorage` for preferences, memory register, last result and converter selections.
- Pure engines in `Engine/`: `ExpressionEvaluator` (tokenizer → shunting-yard → RPN, `Double` math, DEG/RAD, guarded division/factorial/domains), `UnitConverter` (factor tables + affine temperature), `BaseConverter` (fixed-width `UInt64`, masked bitwise ops).
- **Design language:** a premium calculator — soft warm paper in light, near-black graphite in dark, warm amber (`0xF2A33C`) accent matching the `AccentColor` asset, big rounded-design numerals, and a tactile keypad with subtle key shadows and press scaling. Every color is light/dark adaptive (`Color.dyn`) for AA contrast; full Dynamic Type, VoiceOver labels/values/hints, and Reduce-Motion fallbacks.
- **Monetization:** one-time **Sigma Pro** unlock at $2.99 (simulated, StoreKit-ready) — unlimited history, the constants library, extra themes (Graphite/Paper/Solar) and high-precision mode; the entire calculator core is free.
- **Why it can boom:** the stock iOS calculator is famously weak and the free alternatives are ad-ridden — a beautiful, fast, ad-free calculator that actually evaluates expressions, remembers everything, and converts/programs is exactly the no-subscription paid tool power users happily buy once and recommend.

## Self-review

I re-read every Swift source file by hand and verified:

- **iOS 17 only:** no `NavigationView` (uses `NavigationStack`), no `@Previewable`, no iOS-18 SwiftUI/SwiftData symbols; every `.onChange` uses the two-parameter `{ oldValue, newValue in }` form; `defaultScrollAnchor`/`scrollContentBackground` are iOS 17-valid.
- **Persistence:** the only `@Model` (`CalcEntry`) is registered in `Schema([CalcEntry.self])` in `SigmaApp.swift`; the in-memory `ModelContainer` fallback uses the documented-unreachable `fatalError` pattern verbatim and nothing else.
- **Crash-proofing:** no `try!`, `as!`, force-unwraps, unchecked indices or unguarded division on user paths. The evaluator guards every stack pop, every division/modulo, domains (asin/acos/ln/log/sqrt) and factorial range; the base engine reports parse overflow and masks results; the converter guards divisions and non-finite values.
- **Ownership:** `AppSettings` and `ProStore` are `ObservableObject` injected via `@StateObject`/`@EnvironmentObject`; `CalculatorModel` is `@Observable` owned via `@State` and consumed via `@Bindable` — the two patterns are never mixed.
- **No placeholders:** no TODO/FIXME/stub/"coming soon"/lorem strings; every key, toggle and button is wired to real behavior.
- **Quality bars:** balanced braces/parens, correct imports, ≥4 substantive screens via `TabView`, onboarding gating, empty/loading/error/success states, ≥3 persisted settings, ~30 seeded sample tape entries guarded to run once, lazy `List` rows with stable `Identifiable` ids, full accessibility, haptics gated by `settings.hapticsEnabled`, and a cohesive amber/graphite/paper theme applied on every screen in both light and dark.

**Attestation:** Self-review passed.
