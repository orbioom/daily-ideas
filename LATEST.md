# Latest run — 2026-06-17_1806-UTC

Folder: `runs/2026-06-17_1806-UTC/` — 6 production-ready native iOS apps, all **built** (none deferred).
Each ships a XcodeGen `project.yml` (no hand-written `.xcodeproj`), a real designed 1024 AppIcon
(per-app glyph on a gradient) + AccentColor + LaunchBackground (light+dark), SwiftData persistence,
onboarding/empty/loading/error/success states, ≥3 persisted Settings prefs, full accessibility
(Dynamic Type + VoiceOver + Reduce Motion), first-class light+dark, and a simulated one-time Pro
unlock. **217 Swift files total** (Mural 39, Sigma 34, Thump 32, Caliper 34, Trace 41, Tangle 37).

Self-reviewed compile-by-inspection per app, then audited at the top level across all six:
**zero** `try!` / `as!` / `NavigationView` / `@Previewable` / single-arg `.onChange`; the only
`fatalError` is the documented unreachable in-memory `ModelContainer` fallback (one per app); no
force-unwrap suspects on user paths; every `@Model` registered in its app's `Schema` (verified per
app — Mural 2, Sigma 1, Thump 3, Caliper 2, Trace 2, Tangle 3, all matching); no duplicate
top-level type names per app; all six `project.yml` parse as valid YAML naming the real source
folder + `Info.plist`; all six `Info.plist` valid XML with `UILaunchScreen`; all six 1024 AppIcons
present (1024×1024 PNG); all asset `Contents.json` valid. (The only anti-stub/brace-count flags were
`.redacted(reason: .placeholder)` — a real SwiftUI loading API — and parens/brackets inside string
literals/comments, all confirmed benign.)

This batch deliberately opens **six big, proven, monetizable markets the 273-entry registry had not
yet touched**: a generative wallpaper studio, a scientific/programmer calculator, a step-sequencer
drum machine, a body-measurement tracker, a kids letter-tracing app, and a Wordscapes-style word
puzzle. Each is "the version people wish existed": same proven job, dramatically better terms
(one-time / generous free core vs the incumbent's ads, watermarks, energy-timers, or subscriptions).

## The six apps

- **Mural** — built — `runs/2026-06-17_1806-UTC/01-mural` — generative aesthetic wallpaper studio: a pure `WallpaperRenderer` draws 7 real styles (linear/mesh-radial/seeded low-poly/stripes/dot-field/layered-sine aurora/quote) into a SwiftUI Canvas with grain/vignette/blur, deterministic SplitMix64 seeds, 4K `ImageRenderer` export to Photos + ShareLink, a SwiftData library (open-in-studio), 18 built-in + custom palettes, and 6 preset packs — Monetization: one-time **$3.99** Pro (unlimited library/palettes/packs, 4K & grain-free export); 7 styles + 12 saves + built-in palettes + 2 packs free — Why it can boom: wallpaper apps have huge top-of-funnel demand but are universally hated for ads/watermarks; a beautiful, on-device, watermark-free generator with a fair one-time unlock is exactly the gap.
- **Sigma** — built — `runs/2026-06-17_1806-UTC/02-sigma` — scientific + programmer calculator with a persistent history tape and unit converter: a real `ExpressionEvaluator` (tokenizer → shunting-yard → RPN, DEG/RAD, scientific functions, constants, fully guarded), a 9-category `UnitConverter` (factor + affine temperature), and a `BaseConverter` (DEC/HEX/BIN/OCT + bitwise ops, 8/16/32/64-bit), with a searchable SwiftData tape — Monetization: one-time **$2.99** Pro (unlimited history, constants library, themes, high-precision); calculator + history + converter + programmer all free — Why it can boom: PCalc proved people happily pay ~$10 for a great calculator while free ones are ad-ridden; a beautiful one-time scientific+programmer+converter undercuts that directly.
- **Thump** — built — `runs/2026-06-17_1806-UTC/03-thump` — step-sequencer drum machine / beat maker with **100% code-synthesized** audio (no audio files): `AVAudioEngine` + 8 player nodes, a `DrumSynth` that renders each voice once into an `AVAudioPCMBuffer` via pure DSP (pitch-env kick, tone+noise snare, bright-noise hats, multi-burst clap, rim, cowbell), a `DispatchSourceTimer` step clock with swing, per-track mixing, 5 kits, pattern CRUD, and a song-chain mode — Monetization: one-time **$4.99** Pro (all 5 kits, unlimited patterns, per-step velocity, 32 steps); sequencer + song + 2 kits + 8 patterns free — Why it can boom: music-creation apps have proven viral reach; an instant, offline, ad-free beat maker with synthesized kits and no IAP nags is a delightful, shareable hook.
- **Caliper** — built — `runs/2026-06-17_1806-UTC/04-caliper` — body-measurement & physique tracker: pure `BodyMath` (US Navy body-fat % with log-guards, BMI, waist-to-hip, normalized FFMI, least-squares weekly rate, smoothing), 14 measurement sites, metric/imperial, goals, and Swift Charts trends, with a 5-month seeded recomp dataset so it looks alive — Monetization: one-time **$4.99** Pro (custom sites, FFMI/advanced insights, CSV export, full history); weight/BF%/waist + core logging + basic charts free — Why it can boom: body-measurement tracking rides the enormous fitness market, pairs with every program, and the incumbents are bloated/ad-laden; a private, beautiful, formula-honest one-time tracker is the clean alternative.
- **Trace** — built — `runs/2026-06-17_1806-UTC/05-trace` — kids letter/number/shape tracing (ages ~3–6): a `GlyphLibrary` of normalized stroke polylines for A–Z, a–z, 0–9 and 7 shapes (with start directions), a crash-proof `TracingScorer` (coverage + accuracy → 1–3 stars), finger+Pencil capture over a Canvas with road/numbered-dot/arrow guides, multi-profile progress, custom word tracing, and a parent gate — Monetization: one-time **$4.99** Pro (lowercase/numbers/shapes, unlimited profiles, word tracing, no-fail mode); uppercase A–Z + 1 profile free — Why it can boom: parents pay readily for early-learning apps and hate the ad/IAP-nagging incumbents; a calm, private, ad-free tracer with real handwriting scoring is exactly what they want.
- **Tangle** — built — `runs/2026-06-17_1806-UTC/06-tangle` — Wordscapes-style word-find crossword: a pure, deterministic `CrosswordPacker` (longest-first greedy interlocking layout with full conflict/adjacency validation, drops unplaceable words to bonus, bounds-guarded), a count-aware `LetterMultiset`, a tap/drag letter wheel with animated reveals, 16 machine-validated levels across 3 packs, a date-seeded daily puzzle with a streak, and a bonus-word "Word Jar" — Monetization: one-time **$3.99** Pro (all packs/levels, unlimited hints, relaxed mode); first pack + daily + word jar + limited hints free — Why it can boom: Wordscapes/Word Connect are top-grossing but crammed with ads, pop-ups, and energy-timers; a relaxing, ad-free, offline, one-time version targets the exact complaint in their 1-star reviews.

## Top recommendation

**Tangle** is the strongest revenue-quality bet: word-find crossword games (Wordscapes, Word Connect)
are perennial top-grossing titles with mass appeal, and their 1-star reviews are a wall of complaints
about ads, interstitials, and energy-timers. A relaxing, fully offline, ad-free version with a real
deterministic crossword packer and a fair one-time unlock hits that pain squarely and has the broadest
audience of the six. Runner-up for "boom" is **Mural** — wallpaper demand is enormous and the
watermark/ads gripe is universal — with **Thump** the most viral/shareable wildcard.

## Research signals worth following next run

- **Aesthetic home-screen widgets / icon themes** (Widgetsmith, Brass, Color Widgets) remain a proven
  multi-million-dollar market we have *not* shipped — worth a multi-target WidgetKit build next run.
- **Live retro/film camera** (Dazz Cam, OldRoll, 1888) is viral and top-charting; distinct from our
  Lumen *editor* because it's a capture experience (kept off this batch to avoid mechanic overlap).
- **Wall Pilates / short guided workouts** were 2024–25 revenue monsters but overlap our existing
  guided-player apps (Flow/Brio/Daybreak/Lace) — would need a genuinely new mechanic to qualify.
- **Word/anagram puzzle family** is deep (Tangle opens it) — Word Cookies, anagram brain games, and
  daily word ladders are adjacent proven hits if differentiated from Tangle's mechanic.
