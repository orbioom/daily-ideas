# Latest run — 2026-06-17_0611-UTC

Folder: `runs/2026-06-17_0611-UTC/` — 6 production-ready native iOS apps, all **built** (none deferred).
Each ships a XcodeGen `project.yml` (no hand-written `.xcodeproj`), a real designed 1024 AppIcon
(per-app glyph on a gradient) + AccentColor + LaunchBackground (light+dark), SwiftData persistence,
onboarding/empty/loading/error/success states, ≥3 persisted Settings prefs, full accessibility
(Dynamic Type + VoiceOver + Reduce Motion), first-class light+dark, and a simulated one-time Pro
unlock. **181 Swift files total** (Lexicon 29, Pitch 28, Lace 38, Hush 26, Arcana 33, Abode 27).

Self-reviewed compile-by-inspection per app, then audited at the top level across all six:
**zero** `try!`/`as!`/`fatalError`/`NavigationView`/`@Previewable`; no single-arg `.onChange`;
no force-unwrap suspects on user paths; every `@Model` registered in its app's `Schema` (verified
per app — Lexicon 2, Pitch 3, Lace 5, Hush 3, Arcana 3, Abode 2, all matching); no duplicate
top-level type names per app; every `Chart {}` has `import Charts`; all six `project.yml` parse as
valid YAML naming the real source folder; all six `Info.plist` parse valid (Pitch adds
`NSMicrophoneUsageDescription`; Hush adds `UIBackgroundModes: [audio]`); all six 1024 AppIcons present.

This batch targets **proven, large, monetizable markets the 261-entry registry had not touched** —
a daily word game, an audio/music utility, a fitness-coaching program, a sleep/ambient-audio engine,
a spiritual/reflection app, and a high-intent finance tool. Each is "the version people wish existed":
same proven job, dramatically better terms (one-time / free core vs the incumbent's subscription/ads).

## The six apps

- **Lexicon** — built — `runs/2026-06-17_0611-UTC/01-lexicon` — daily word-guess game with a correct two-pass duplicate-letter evaluator, real word lists, deterministic daily puzzle, hard mode, full archive, and shareable emoji grids — Monetization: one-time **$2.99** Pro (full archive, 6-letter words); unlimited daily+practice free — Why it can boom: Wordle proved billions want a daily word game, but NYT gates it behind an account/limits; Lexicon is unlimited, offline, ad-free, multi-length, with a full playable archive and colorblind palette.
- **Pitch** — built — `runs/2026-06-17_0611-UTC/02-pitch` — accurate on-device autocorrelation tuner (cents + string highlight) + a sample-accurate metronome with synthesized clicks + a reference-tone pipe — Monetization: one-time **$4.99** Pro (custom tunings, advanced meters, full tone range); core tuner+metronome free — Why it can boom: GuitarTuna has 100M+ installs but is ad-bloated and pushes a ~$12/mo subscription for basics; Pitch is one-time, ad-free, more instruments, real DSP.
- **Lace** — built — `runs/2026-06-17_0611-UTC/03-lace` — Couch-to-5K coaching with a relaunch-safe wall-clock guided player that speaks run/walk transitions, plus a gentler beginner plan and custom builder — Monetization: one-time **$4.99** Pro (Easy Start, 5K→10K bridge, custom plans); the whole C25K plan is free — Why it can boom: beginner running is a huge evergreen market and the popular C25K apps are "fake free" (paywall after a few sessions) or ad-laden; Lace gives the entire plan free, offline, no account.
- **Hush** — built — `runs/2026-06-17_0611-UTC/04-hush` — a sleep-sound mixer where all 10 sounds are synthesized in real time by one AVAudioSourceNode (no audio files), with infinite layering and a fade-out sleep timer — Monetization: one-time **$3.99** Pro (full library, unlimited layers/mixes); core noises + 3 ambients free — Why it can boom: sleep/relaxation is a massive, sticky category and BetterSleep et al. charge ~$60/yr with the library locked; Hush is one-time, tiny (no downloads), fully offline, infinitely mixable.
- **Arcana** — built — `runs/2026-06-17_0611-UTC/05-arcana` — full 78-card tarot with genuine upright/reversed meanings, a deterministic daily card, multiple spreads, Canvas-generated card art, and a real reading journal — Monetization: one-time **$4.99** Pro (Celtic Cross + advanced spreads, unlimited journal); daily + Three-Card + full library free — Why it can boom: tarot/astrology is a large, high-retention spiritual market and Labyrinthos charges up to $89.99; Arcana gives the full deck meanings free, one-time, offline, with beautiful generated art and a journal.
- **Abode** — built — `runs/2026-06-17_0611-UTC/06-abode` — an all-Decimal mortgage engine (amortization, PMI auto-drop, extra payments, refinance break-even, DTI affordability) with saved/compared scenarios — Monetization: one-time **$3.99** Pro (save/compare scenarios, refinance, affordability, export); calculator + schedule free — Why it can boom: home-buying is extremely high-intent and the popular calculators are web-only/ad-laden/clunky; Abode is native, instant, private, scenario-saving, one-time.

## Top recommendation

**Lexicon** is the strongest "boom" bet: the daily-word-game format is the most virally proven of the six
(built-in social sharing via the emoji grid drives organic installs), the audience is the broadest, and
the incumbent's weaknesses (account-gating, single daily puzzle, NYT bundle friction) are exactly what a
free, unlimited, offline, multi-length version with a full archive fixes. Runner-up for revenue quality is
**Hush** — the on-device-synthesis angle is a genuine technical moat (tiny app, no content licensing/CDN)
against a category that otherwise monetizes hard via $60/yr subscriptions.

## Research signals worth following next run

- **Wordle-adjacent dailies** still mint engagement (Connections/Strands-style grouping games, daily logic
  dailies) — a "daily puzzle hub" of several distinct mechanics is unbuilt and on-trend.
- **One-time-purchase as the wedge**: every incumbent we beat this run leans on subscriptions users resent
  (GuitarTuna $12/mo, BetterSleep $60/yr, Labyrinthos to $89.99) — "the no-subscription version of <hit>"
  remains a repeatable, high-signal play across categories.
- **On-device audio DSP** (AVAudioSourceNode synthesis) and **on-device pitch/sound analysis** are
  underexploited moats that keep apps tiny and fully offline — candidates: a guided-vocal warm-up trainer,
  a real-time drone/tanpura for musicians, a snore/sleep-noise classifier.
- **High-intent finance calculators** (auto-loan/lease, rent-vs-buy, retirement-drawdown, FIRE) convert
  well as one-time native tools versus ad-laden web calculators.
