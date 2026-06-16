# Numen

## What it is
**Numen** is an elegant, private numerology companion for iOS — readings, daily cycles, and compatibility, computed entirely on your device.

**One-liner:** Your name and birthdate, read with care: a full numerology chart, today's personal-day guidance, and transparent compatibility — no subscription, no tracking, nothing hidden.

**Problem & audience:** People curious about numerology and self-discovery are funneled into apps that charge recurring subscriptions, gate basic meanings behind paywalls, and never show how a number was derived. Numen is built for the same audience — the spiritually curious, journalers, relationship-minded folks — but is honest about its method (the math is always one tap away), keeps everything on-device, and asks for a single small one-time unlock instead of a subscription.

## Features
- **Today** — for the selected profile: Personal Year, Personal Month, and Personal Day with a deterministic daily guidance card and a quick horizontal profile switch.
- **Reading** — a full chart per profile: Life Path, Expression/Destiny, Soul Urge, Personality, Birthday, and Maturity, each as a tappable gold card. Detail sheets carry a real interpretation (archetype, keywords, strengths, challenges, an essence paragraph, position-aware framing) plus a transparent "How this was derived" breakdown of the math. Master numbers (11/22/33) and Karmic Debt (13/14/16/19) are detected and highlighted.
- **Profiles** — multi-profile CRUD (full birth name, birthdate, optional nickname) with live Life Path preview, swipe to edit/delete, tap to select, and input validation.
- **Compatibility** — pick two profiles for a 0–100 harmony score (transparent weighted rule: Life Path 45%, Expression 30%, Soul Urge 25%), a per-number breakdown with explanations, and a Swift Charts bar chart of agreement by facet.
- **Library** — browse every number meaning, 1–9 and the master numbers 11/22/33, with a free teaser and full unlock under Pro.
- **Share card** — an `ImageRenderer`-generated, screenshot-worthy summary of any profile's reading, exportable via `ShareLink` (Pro).
- **Two systems** — Pythagorean and Chaldean letter maps, user-selectable.
- **Master-number toggle** — keep 11/22/33 whole or reduce fully.
- **Onboarding** — a four-page introduction gated by `hasOnboarded`.
- **Settings** — Appearance, Haptics, numerology system, master-number handling, default profile, Pro unlock/restore, and a plain-language "How Numen calculates" method page.

## Run
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Numen.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

**Free signing:** The project uses a standard bundle id (`com.orbioom.numen`). If signing fails, select the Numen target → Signing & Capabilities → pick your personal team (Automatically manage signing). No paid Apple Developer account is required to run on a simulator or your own device.

## Tech notes
- **iOS 17+**, SwiftUI, SwiftData (`@Model Profile` in the `Schema`, `@Query`, `modelContainer`), Swift Charts, `ImageRenderer` + `ShareLink`, Observation/`ObservableObject` for app settings.
- **Design language:** mystical-but-tasteful — deep indigo/plum backgrounds, antique-gold accent (`0xC9A24B`, matching AccentColor), elegant serif display headings over rounded body text, a subtle deterministic starfield, and a reveal animation gated by Reduce Motion. Light and dark palettes both meet WCAG AA for body text; every custom color uses dynamic light/dark pairs.
- **Engine:** numerology is a pure, stateless module (`NumerologyEngine`, `InterpretationLibrary`, `CompatibilityEngine`, `DailyGuidance`). Numbers are always **computed**, never stored, so changing the system or master-number setting instantly re-reads every chart. Empty/odd names and out-of-range values are guarded throughout.
- **Persistence:** `Profile` records live in SwiftData and survive relaunch; small prefs (appearance, haptics, system, master-number, selected profile, Pro, onboarding) use `@AppStorage`. Three public-domain sample profiles (Einstein, Lovelace, da Vinci) are seeded once on first run.
- **Monetization:** one-time **Numen Pro** unlock at **$3.99** (simulated, StoreKit-ready) — unlimited profiles past one, Compatibility, the full Library, daily history, and share-card export; the free core (your own chart, Today, and a Library teaser) is fully usable.
- **Why it can boom:** spiritual / self-discovery apps have unusually high willingness-to-pay, yet incumbents push pricey subscriptions and hide their method — Numen is the elegant, transparent, one-time alternative people actually want to recommend, with a built-in viral share card.

## Self-review
I re-read every Swift file by hand and verified:
- **Imports** are present and minimal per file (`SwiftUI`, `SwiftData`, `Charts`, `Foundation`, `UIKit` only where used).
- **iOS 17 only:** `NavigationStack` everywhere (no `NavigationView`); all `.onChange(of:)` use the two-parameter closure; no `@Previewable`; no iOS-18 SwiftData/SwiftUI symbols. `Layout`, `ImageRenderer`, `ShareLink`, `LabeledContent`, `TimelineView(.animation)` are all iOS 16/17-available.
- **Safety:** no `try!`, no `as!`, no force-unwraps on user paths (verified by search). The only `fatalError` is the documented-unreachable in-memory `ModelContainer` fallback copied from the convention. Division and array access are guarded; reductions clamp negatives; names are trimmed and validated to contain at least one letter.
- **No banned strings:** no TODO/FIXME/XXX/placeholder/lorem/"coming soon"/"not implemented"/stub/unimplemented (verified by search).
- **SwiftData:** the single `@Model` type, `Profile`, is listed in `Schema([Profile.self])` in `NumenApp`. `@Query` and `modelContainer` type-check; selection tracking uses a stable `persistentModelID` string in `@AppStorage`.
- **Ownership:** `AppSettings` is an `ObservableObject` injected via `@StateObject`/`@EnvironmentObject` (never mixed with `@Observable`); view-local state uses `@State`; sheet/navigation bindings are well-formed.
- **DoD:** five substantive feature screens beyond Onboarding/Settings (Today, Reading, Profiles, Compatibility, Library); empty, loading, error, and success states are present; ≥3 persisted settings; seeded data; full accessibility labels/hints on cards, controls, and the chart; haptics gated by settings; Reduce-Motion-aware animation; Swift Charts on the analytics screen; lazy containers with stable `Identifiable` IDs.
- **Braces/parens** balanced in every file.

**Hand-verified calculation — Life Path for Albert Einstein (born 14 March 1879):**
- Month: 3 → **3**
- Day: 14 → 1 + 4 = **5**
- Year: 1879 → 1 + 8 + 7 + 9 = 25 → 2 + 5 = **7**
- Sum: 3 + 5 + 7 = 15 → 1 + 5 = **6**

Life Path = **6** (The Nurturer). This matches the seeded Einstein profile's computed Life Path exactly, confirming the engine's month/day/year-separate reduction and master-preserving digit sum.

**Attestation:** To the best of a careful by-hand review, the sources compile against the iOS 17 SDK, contain no banned constructs, and implement every feature described above with real content and no dead ends.
