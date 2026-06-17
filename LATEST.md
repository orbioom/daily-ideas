# Latest run — 2026-06-17_1209-UTC

Folder: `runs/2026-06-17_1209-UTC/` — 6 production-ready native iOS apps, all **built** (none deferred).
Each ships a XcodeGen `project.yml` (no hand-written `.xcodeproj`), a real designed 1024 AppIcon
(per-app glyph on a gradient) + AccentColor + LaunchBackground (light+dark), SwiftData persistence,
onboarding/empty/loading/error/success states, ≥3 persisted Settings prefs, full accessibility
(Dynamic Type + VoiceOver + Reduce Motion), first-class light+dark, and a simulated one-time Pro
unlock. **249 Swift files total** (Ascend 44, Wake 40, Nest 37, Sear 51, Upkeep 37, Verbo 40).

Self-reviewed compile-by-inspection per app, then audited at the top level across all six:
**zero** `try!` (other than the in-memory `ModelContainer` fallback) / `as!` / `fatalError` /
`NavigationView` / `@Previewable`; no single-arg `.onChange`; no force-unwrap suspects on user paths;
every `@Model` registered in its app's `Schema` (verified per app — Ascend 6, Wake 4, Nest 2,
Sear 3, Upkeep 3, Verbo 2, all matching); no duplicate top-level type names per app; every
`Chart {}` has `import Charts`; all six `project.yml` parse as valid YAML naming the real source
folder; all six `Info.plist` valid; all six 1024 AppIcons present (1024×1024 RGB PNG).

This batch hunts **large, proven, monetizable markets the 267-entry registry had not yet touched** —
a barbell-strength *program* (distinct from our freeform logger), a pool-swimming tracker, a
savings-goals / sinking-funds planner, a live-fire BBQ & smoking companion, a home-maintenance
scheduler, and a Spanish/French verb-conjugation trainer. Each is "the version people wish existed":
same proven job, dramatically better terms (one-time / free core vs the incumbent's subscription/ads).

## The six apps

- **Ascend** — built — `runs/2026-06-17_1209-UTC/01-ascend` — guided barbell-strength PROGRAM with auto-progression: built-in StrongLifts 5×5/PPL/Upper-Lower/Full-Body, rotation-aware "today's workout" with set-by-set logging + relaunch-safe rest timer, +increment/deload progression, Epley+Brzycki e1RM, plate calculator, progression Charts — Monetization: one-time **$5.99** Pro (custom program builder, accessory/5-3-1 programming, full analytics, CSV export); core programs + logging + plate calc + e1RM free — Why it can boom: StrongLifts/Strong/Jefit proved millions run barbell programs and pay, but incumbents are ad-laden or charge ongoing subscriptions for basics; Ascend gives guided auto-progression one-time, offline, no account.
- **Wake** — built — `runs/2026-06-17_1209-UTC/02-wake` — pool swimming workout tracker: built-in + custom swim workouts (sets × distance × stroke × send-off), relaunch-safe in-pool interval clock recording per-rep splits, pace/100 + SWOLF + stroke breakdown + distance trends — Monetization: one-time **$4.99** Pro (custom builder, pace/SWOLF analytics, unlimited workouts); built-ins + free-swim logging + basic stats free — Why it can boom: swimmers are a passionate paying audience and MySwimPro charges ~$80/yr and is Apple-Watch-centric; Wake is a focused phone tracker with a real workout builder + interval timer, one-time, offline.
- **Nest** — built — `runs/2026-06-17_1209-UTC/03-nest` — savings goals & sinking funds: per-goal target+date → required-monthly pacing, on-track/behind/ahead status, projected completion date, a lump-sum Allocate tool (proportional-to-need / even / by-priority, exact to the cent), contributions+withdrawals, growth Charts — Monetization: one-time **$4.99** Pro (unlimited goals beyond 3, Allocate tool, advanced insights, CSV); up to 3 goals + contributions + pacing free — Why it can boom: sinking-fund/savings-goal planning is a huge evergreen need and Qapital/Digit chase fees & bank links people resent; Nest is private (no bank login), beautiful, with smart pacing + lump-sum allocation, one-time.
- **Sear** — built — `runs/2026-06-17_1209-UTC/04-sear` — live-fire BBQ & smoking companion: a 33-cut doneness guide (pull temps by doneness, USDA-safe flags, smoker temp, time/lb, rest, wood pairing), a live cook timer with a phase timeline (preheat→cook→stall→wrap→pull→rest) + stall detection, a rub-recipe keeper, and a rated cook log — Monetization: one-time **$3.99** Pro (multiple active cooks, unlimited custom rubs, chef doneness + reverse-sear calc, export); full guide + 1 active cook + log free — Why it can boom: grilling/smoking is a massive mainstream hobby with high willingness to pay, and the popular meat apps are ad-laden/paywalled/ugly; Sear gives a live cook timer + a real doneness guide + rub keeper, one-time, offline.
- **Upkeep** — built — `runs/2026-06-17_1209-UTC/05-upkeep` — home maintenance scheduler: smart due/overdue scheduling (everyN days/weeks/months/years + hemisphere-aware seasonal), a priority-weighted home-health gauge, a 24-task homeowner starter checklist, cost tracking + annual forecast, capped reminders — Monetization: one-time **$3.99** Pro (unlimited tasks beyond 10, cost tracking/forecast, reminders, export); scheduling + done-logging + starter checklist + health score free — Why it can boom: homeowners are high-intent and forget recurring upkeep that costs thousands when skipped, while HomeZada/Centriq are clunky/cloud/account-bound; Upkeep is a calm, private, seasonal scheduler with cost tracking + a ready-made checklist, one-time, offline.
- **Verbo** — built — `runs/2026-06-17_1209-UTC/06-verbo` — Spanish & French verb conjugation trainer: a real ConjugationEngine (regular ES/FR endings across core tenses incl. passé composé, + irregular override tables for ~26 verbs), a 68-verb catalog, adaptive mastery-weighted drills (type/choice, accent-strict or lenient), full conjugation reference tables, tense-rule lessons, accuracy/mastery/weakest-verb Charts — Monetization: one-time **$5.99** Pro (French unlock + advanced tenses + full library + advanced stats); Spanish core tenses + ~40 verbs + drills + reference free — Why it can boom: language learning is the biggest learning market (Duolingo) and conjugation is its most painful, under-served gap that apps like Ella Verbs charge ongoing for; Verbo gives a genuine conjugation engine + adaptive drills + reference, one-time, offline.

## Top recommendation

**Ascend** is the strongest revenue-quality bet: barbell-program apps (StrongLifts, Strong, Jefit) are a
huge, sticky, high-retention category where users lift for years and the incumbents monetize hard via
subscriptions and ads for what should be table stakes. A guided, auto-progressing program + plate math +
e1RM analytics, sold once and fully offline, hits exactly the friction lifters complain about. Runner-up
for broad "boom" is **Verbo** — the language market is the largest in learning, conjugation is the
universally-hated gap, and a one-time engine + drills undercuts the subscription incumbents directly.

## Research signals worth following next run

- The registry (273 entries) now covers nearly every obvious proven category. Remaining open, large markets
  worth checking next run: **swim/marathon training PLANS** (periodized, beyond C25K — distinct from logging),
  **frequent-flyer / flight tracking** (Flighty is a top travel subscription — needs an offline-first angle),
  and **photo-library decluttering** (Gemini/duplicate finders — needs Photos-framework on-device work).
- **"Program/plan-driven" vs "log-driven"** is a repeatable wedge inside already-saturated domains: Ascend
  (program) sits cleanly beside our older Forge (logger). The same split likely exists for running, swimming,
  and nutrition — a guided plan is a different, monetizable product from a tracker.
- **One-time-purchase as the wedge** keeps working: every incumbent beaten this run leans on subscriptions
  users resent (MySwimPro ~$80/yr, Ella Verbs, StrongLifts Pro). "The no-subscription version of <hit>"
  remains the highest-signal, most-repeatable play across categories.
