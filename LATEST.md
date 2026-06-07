# Orbioom Daily Ideas — Latest Run

**Run:** 2026-06-07_0010-UTC
**Folder:** `runs/2026-06-07_0010-UTC/`
**Output:** 6 production-ready native iOS apps (SwiftUI 5, iOS 17+, SwiftData), all Orbioom design language with distinct per-app accents.

Each app ships a XcodeGen `project.yml` (no hand-written `.xcodeproj`), a real 1024² on-brand `AppIcon`, `AccentColor`, launch screen, onboarding gate, ≥4 substantive feature screens, a Settings screen with ≥3 persisted prefs, empty/loading/success/error states, light + dark, Dynamic Type, VoiceOver, Reduce Motion, and gated haptics. Build locally: `brew install xcodegen` → `cd <app>/ios && xcodegen generate` → open in Xcode 15+ → Cmd+R.

## The six apps

- **Oche** — built — `runs/2026-06-07_0010-UTC/01-oche` — a calm darts companion: a pure checkout engine that solves any 2–170 finish on a double (with bogey-number detection and a full 170→2 chart), match logging leg-by-leg into three-dart average / checkout % / best leg, and a live double-practice mode that surfaces the finish you keep missing.
- **Caliber** — built — `runs/2026-06-07_0010-UTC/02-caliber` — a mechanical-watch accuracy log: a least-squares regression of your timing readings into a true daily rate, a per-position breakdown (a timegrapher built from the wrist), COSC-style grading, drift projection, and service-due tracking across the collection.
- **Tilth** — built — `runs/2026-06-07_0010-UTC/03-tilth` — a frost-date succession garden planner: your two frost dates drive every sow / transplant / harvest / last-safe-sow date and a guarded succession series; beds own plantings with a status flow, and a harvest-by-month forecast.
- **Riffle** — built — `runs/2026-06-07_0010-UTC/04-riffle` — a fly-tying and fishing log: patterns own their tying recipes and box stock, catches log conditions and the fly that worked, and a hatch chart matches what's emerging this month to the flies in your box by type and hook size.
- **Zenith** — built — `runs/2026-06-07_0010-UTC/05-zenith` — a telescope optics companion: magnification / true field / exit pupil for any scope-and-eyepiece combination, per-scope resolving power and limiting magnitude, an observing log, and a seasonal target list with a framing-aware eyepiece recommender.
- **Plateau** — built — `runs/2026-06-07_0010-UTC/06-plateau` — a sous-vide companion that times a cook from first principles: a Heisler heat-equation come-up time plus a D/z pasteurization hold, a relaunch-safe countdown timer, a doneness/pasteurization guide, and a cook log.

## Top recommendation

**Plateau.** It's the strongest mix of a genuinely hard, correct engine and an
everyday hook. The come-up time is a real one-term transient-conduction solution
(shape-aware, calibrated to Baldwin's water-bath tables) and the safety hold is a
real D/z thermal-death-time model — yet the surface is a single number every
sous-vide cook actually wants ("how long, minimum?"), wrapped in a timer that
survives a relaunch. Runner-up: **Caliber**, whose least-squares daily-rate and
positional analysis turn a watch enthusiast's scattered readings into a clean,
chartable answer that no free app does calmly.

## Research signals worth following next run

- **Validated hobby/profession verticals still without a calm offline app** (after
  this run took darts, watch-accuracy, frost-succession gardening, fly-fishing,
  visual astronomy, and sous-vide): pottery is *served* (Glaizit, Pottery Notes), so
  skip it; remaining strong gaps are leathercraft project/leather-yield planning,
  model-paint inventory (Warhammer ranges), darts *contesting*/checkout already done
  so pivot to **archery sight-tape interpolation**, **disc-golf handicap scorecards**,
  **sailing rule-of-twelfths tide + passage timing**, **cycling gear-inch/Q-factor +
  component wear log**, and **fountain-pen/ink pairing inventory**.
- **"A calculator that's actually a tool" keeps over-delivering** — every standout
  this run is a domain where practitioners do real math by hand (checkout set-cover,
  least-squares rate, frost-relative date algebra, optics, heat equation). Pick a
  field with hand-math and make it calm.
- **Persisted, relaunch-safe live timers** (Plateau's countdown computed from a
  stored start date) are a reusable pattern worth carrying forward to any
  cook/brew/interval domain.

## Notes

- All engines are pure value types off the view layer — `CheckoutEngine`, `RateEngine`,
  `FrostMath`, `RiffleLogic`/`Optics`, `PlateauMath` — so they're independently
  testable.
- The icon generator gained six new glyphs (dart, dial, sprout, fly, scope, thermo)
  in `_tools/make_icon.py`; each app has its own accent glow (green, brass, green,
  water-blue, indigo, amber) over the shared mist→ink orb ground.
- The only `try!` in any app is the in-memory `ModelContainer` bootstrap fallback in
  each `@main` — not a user path. No force-unwraps on user paths; anti-stub grep
  clean across all 103 Swift files.
