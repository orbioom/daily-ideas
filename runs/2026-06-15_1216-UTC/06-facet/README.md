# Facet

A native, private personality test & self-discovery app built on a real, transparent psychometric engine.

## What it is

**Facet** lets you take a short, research-grounded questionnaire and instantly see your **Big Five (OCEAN)** trait profile *and* a friendly, shareable **4-letter type + named archetype** — then explore what it means and compare profiles for compatibility.

It targets the huge audience that loves online personality tests (the kind that have driven **1B+ tests** on incumbents like 16Personalities). Facet beats those incumbents by being:

- **Native & fast** — SwiftUI, smooth, no web pages or sign-up walls.
- **Fully private & offline** — every answer and result is computed and stored on your device. No account, no network, no tracking.
- **Honestly priced** — one fair **one-time** unlock for the full report, instead of a recurring paywall on "the good parts."
- **Transparent** — public-domain IPIP items, documented scoring, and clear framing that the Big Five is research-based while the "type" is a friendly summary, not a diagnosis.

## Features

- **Onboarding** (gated by `hasOnboarded`) — explains private/offline design and sets up your name.
- **Home** — your primary profile's result card (type + archetype + mini trait bars), take/resume/retake the test, and a list of saved profiles. True empty state with a clear CTA.
- **Test runner** — one IPIP question per screen on a calm, tappable 5-point agree–disagree scale, with progress, back, and **resume-if-interrupted** (draft persisted), a brief **computing** state, and a Reduce-Motion-aware **result reveal**.
- **Result detail** — Big Five visualization via **Swift Charts** (horizontal bars) **and** a **Canvas radar**, plus the 4-letter type, dimension breakdown, and Pro-gated **strengths / growth / careers / relationships** sections. **Share card** export via `ImageRenderer` + share sheet.
- **Profiles & Compatibility** — full CRUD on saved profiles (rename, set primary, delete via swipe/context menu); pick any two profiles for a **compatibility breakdown** (overall score + per-trait aligned/complementary commentary + dual-overlay radar).
- **Explore** — browse the five Big Five traits (with the exact items used to score each), a library of all **16 archetypes**, and an **About / methodology** note.
- **Settings** — name, appearance (System/Light/Dark), haptics toggle, show-percentages-vs-bands, emphasize-Turbulent-identity, reset in-progress draft, Pro status.
- App-wide Dynamic Type, VoiceOver (Likert options, trait bars, and charts described via `accessibilityValue`), Reduce Motion, light + dark, and sparse gated haptics.

## Substantive core logic (the real engine)

- **`ItemBank`** — 40 public-domain **IPIP Big Five** items (8 per trait), each tagged with its trait and a positive/reverse key. Deterministically interleaved so the test doesn't feel like five blocks.
- **`ScoringEngine`** — Likert 1–5, reverse-keyed items recoded as `6 − response`, summed per trait (8–40), linearly normalized to **0–100** (neutral midpoint = 50), with a low/moderate/high band + descriptor. Pure, deterministic, crash-proofed (clamped responses, guarded division).
- **`TypeMapper`** — maps the five trait scores to a 4-letter code (Mind E/I from Extraversion, Energy N/S from Openness, Nature F/T from Agreeableness, Tactics J/P from Conscientiousness) plus an **Assertive/Turbulent** identity from Neuroticism → one of **16 named archetypes**.
- **`Archetype`** catalog — 16 rich entries (name, tagline, description, strengths, growth areas, careers, relationship notes, representative color).
- **`CompatibilityEngine`** — per-trait similarity (`100 − |a−b|`), a weighted overall score (Agreeableness & Neuroticism weighted higher), aligned-vs-complementary classification, and tailored per-trait commentary. All divisions guarded.

Persistence is **SwiftData** (`Profile` `@Model`: name, createdAt, cached 5 trait scores, typeCode, isPrimary, and the raw responses encoded as `Data`). The in-progress test **draft** (responses + index) is persisted to `UserDefaults` so an interrupted test resumes exactly.

## Run

1. `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. `open Facet.xcodeproj` — select an iOS 17+ simulator and press **Cmd+R**.

**Free signing:** open the target's Signing & Capabilities, pick your personal team; the bundle id `com.orbioom.facet` builds and runs on a device with a free Apple ID.

## Tech notes

- **iOS 17+**, **SwiftUI 5**, MVVM-ish (pure engine structs/enums + a `TestViewModel` `@MainActor ObservableObject`), **SwiftData** for primary data and `@AppStorage` for small prefs/flags.
- **Design language:** elegant gem/facet motif, violet-blue accent (`#5A52C8`), calm hero gradients, rounded typography, consistent card surfaces; first-class light + dark via a semantic `Theme`.
- **Charts** + a hand-drawn **Canvas** pentagon radar; `ImageRenderer` share cards.
- **Monetization:** one-time **Facet Pro** ($4.99) simulated locally via `@AppStorage("isPro")` with a tailored `PaywallView`/`PaywallReason`; **StoreKit 2** wires in here for production (no ads, no subscription, no account).
- **Why it can boom:** personality tests are evergreen, endlessly shareable, and command 1B+ runs on incumbents — a native, private, transparent, fairly-priced take with built-in share cards is primed for organic, viral self-discovery growth.

## Self-review

Re-read every Swift file and verified by hand: all `import`s present (added explicit `UIKit` where `UIActivityViewController` is used); every type/initializer/enum case/modifier exists in the iOS 17 SDK; `@State`/`@StateObject`/`@Bindable`/`@EnvironmentObject`/`@Environment`/`@Query`/`modelContainer`/`modelContext` ownership and wiring type-check; `Charts` (`BarMark`, categorical `AxisMarks`) and the `Canvas` radar are iOS-17-valid; `Codable` responses round-trip via string-keyed JSON; `ImageRenderer` + share sheet path is sound; the two-parameter `.onChange(of:)` form is used. Anti-stub grep (`TODO`/`FIXME`/`XXX`/`placeholder`/`lorem`/`coming soon`/`not implemented`/`stub`) is **clean**. No `try!`/`as!`/force-unwrap on user paths; the only `fatalError` is the documented unreachable `ModelContainer` fallback from the build spec. Divisions and array indexing are guarded; incomplete test responses cannot be saved. Empty / computing / error / success states, onboarding gate, 5+ persisted settings, SwiftData persistence + test-resume, full accessibility, Reduce-Motion handling, and light/dark are all present.
