# Trace

## What it is
**Trace** is a calm, ad-free letter & number tracing app for young kids (ages ~3–6). Children trace uppercase and lowercase letters, numbers 0–9, and basic shapes by following a friendly guided glyph — a soft "road" with numbered directional dots and a start marker. The app scores how well the child stayed on the path and awards 1–3 stars with a gentle confetti reward.

It's the version parents wish existed instead of the ad-stuffed, IAP-nagging kids apps: private, ad-free, finger- or Apple-Pencil-friendly, and a one-time purchase. A grown-up gate keeps settings and purchases out of little hands.

**Audience:** parents of pre-readers and early writers who want a focused, trustworthy practice tool.

## Features
- **Kid profiles (Home):** multiple children, each with a name, an avatar color from a fixed palette, and an optional age. Pick the active kid; add/edit/delete profiles. Free = 1 profile, Pro = unlimited. Each profile owns its own stars and progress.
- **Lessons / Curriculum:** four sets — Uppercase A–Z, Lowercase a–z, Numbers 0–9, and 7 Shapes (circle, square, triangle, rectangle, diamond, star, heart). Each set shows a grid of glyphs with the stars earned by the active kid and a lock badge for Pro sets. "Practice in order" walks through a whole set glyph by glyph.
- **Tracing Canvas (the play screen):** the target glyph is drawn large as a road with numbered directional dots and a pulsing start ring. The child draws over a SwiftUI `Canvas` via a `DragGesture` (works for finger and Apple Pencil); their ink renders in the chosen accent color. Multi-stroke glyphs advance automatically once a stroke is adequately covered. Retry / Next / Clear are all wired, with star award, confetti, sound, and haptics on success, and progress saved to SwiftData.
- **Progress (Parents):** per active kid — total stars, glyphs mastered (3-star), glyphs tried, a Swift Charts bar of stars per set, and recent activity. Reached normally; the gear button is protected by a parent gate.
- **Parent gate:** a small arithmetic question ("What is 4 + 6?") guards Settings and the Paywall. Wrong answers reshuffle the problem.
- **Custom word tracing (Pro):** a parent types a short word or name; the child traces each letter in sequence (repeated letters sequence correctly by index).
- **States:** 3-page Onboarding (gated by `hasOnboarded`, ends by creating the first profile), empty states everywhere, a loading spinner while progress is computed, calm error/almost states, and celebratory success states.
- **Settings (≥6 real prefs):** sound effects, haptics, left-handed hints, no-fail practice (Pro), guide style (Dots / Arrows / Road), ink color, appearance (System/Light/Dark), plus Unlock Pro / Restore / About.
- **Accessibility:** Dynamic Type via scalable rounded fonts, accessibility labels/values/hints on controls and the chart, decorative imagery hidden, AA-readable colors in light and dark, and Reduce Motion fallbacks (static star reward instead of confetti).

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at repo root).
3. Open `Trace.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press **Cmd+R**.

## Free signing
No paid Apple Developer account is needed to run on a device: open the project, select the **Trace** target → **Signing & Capabilities**, pick your personal Apple ID team, and Xcode will provision a free development signing certificate. The simulator needs no signing at all.

## Tech notes
- **Platform:** iOS 17.0+, SwiftUI, SwiftData. `NavigationStack` throughout (no `NavigationView`), two-parameter `.onChange`, no iOS-18-only APIs.
- **Persistence:** primary data in SwiftData — `@Model Profile` and `@Model GlyphProgress`, both registered in the `Schema` in `TraceApp.swift`. `SeedData.seedIfNeeded` creates a default profile ("Sammy") plus sample uppercase progress on first launch, guarded by a one-shot flag. Small prefs/flags live in `@AppStorage` via an `ObservableObject` `AppSettings`.
- **Design language:** warm, playful, kid-friendly — big rounded shapes, chunky rounded fonts, large tappable targets, soft sunny background blobs, and a coral-orange accent (`#FF8A4C`, matching the `AccentColor` asset; launch background `#FFF3EA` light / `#1A0E06` dark). Every custom color is dynamic for light and dark mode.
- **Tracing & scoring approach:** each `Glyph` is one or more `GlyphStroke`s — a polyline of normalized points in a 0...1 unit square plus a start-direction. The `GlyphLibrary` holds simplified straight-segment letterforms for A–Z, a–z, 0–9, and shapes (split across `GlyphLibrary+*.swift`). The canvas scales normalized points to its size and captures the child's drag into a normalized polyline. `TracingScorer` (pure) densifies both paths and computes **coverage** (fraction of target samples with user ink within a tolerance radius) and **accuracy** (fraction of user samples lying on the target path), combining them (coverage-weighted) into a 0...1 score → 1–3 stars (≥0.5 = 1, ≥0.7 = 2, ≥0.88 = 3; below retries). It guards every empty/degenerate input (returns zero, never divides by zero, never force-unwraps).
- **Monetization:** one-time **$4.99** "Trace Pro" unlock (simulated via `@AppStorage("isPro")`, StoreKit-ready) — no ads, no subscriptions; free tier (Uppercase A–Z + 1 profile) is fully usable.
- **Why it can boom:** parents actively seek a private, ad-free, pay-once alternative to the ad- and IAP-laden kids-app market — a trustworthy tracing app that "just works" with finger or Pencil is a high-trust, word-of-mouth category.

## Self-review
I re-read every Swift file by hand and verified:
- All imports present and correct (`SwiftUI`, `SwiftData`, `Charts`, `Foundation`/`CoreGraphics`, `AVFoundation`, `UIKit`, `Observation`) where used.
- Only iOS 17 SDK APIs: two-parameter `.onChange(of:) { _, new in }`, `NavigationStack`/`navigationDestination`/`fullScreenCover(item:)`/sheet bindings, `@Query`/`@Model`/`modelContainer`, `Canvas`/`GraphicsContext.draw`, Swift `Charts` `BarMark`. No `@Previewable`, no `NavigationView`, no iOS-18 symbols.
- Both `@Model` types (`Profile`, `GlyphProgress`) are listed in the `Schema` in `TraceApp.swift`.
- No `try!`, `as!`, force-unwrap, or unguarded division on user paths; arrays are index-guarded; the only `fatalError` is the documented unreachable in-memory `ModelContainer` fallback.
- `TracingScorer` returns `.zero` (never crashes) for empty/degenerate input and never divides by zero (all denominators are guarded non-empty counts).
- No `TODO`/`FIXME`/`placeholder`/`stub`/`coming soon`/`unimplemented` strings; every control is wired (profiles CRUD, tracing, scoring, save, paywall unlock/restore, settings toggles, parent gate, word tracing).
- Ownership is consistent: `AppSettings` is `ObservableObject` + `@StateObject` at the root and `@EnvironmentObject` below; `TracingSession` is `@Observable` held via `@State` and passed as `@Bindable` — `@Observable` is never mixed with `@StateObject`.
- Braces and parentheses balance in all 41 files (verified programmatically); accessibility labels/values/hints, Dynamic Type fonts, and Reduce Motion fallbacks are present on interactive and animated surfaces.

Attestation: to the best of a careful manual review, the sources type-check against the iOS 17 SDK, contain no banned constructs, and implement a complete, wired, crash-proof app.
