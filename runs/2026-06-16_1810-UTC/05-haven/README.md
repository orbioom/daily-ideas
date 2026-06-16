# Haven

A calm, private, in-the-moment companion for anxiety and panic attacks. When a hard moment rises, Haven helps you **breathe**, **ground**, and **feel safe again** — then quietly learns the patterns of what helps *you*. It's designed to feel like a safe place, not a clinical tool: soft blush-and-lavender gradients, very rounded shapes, generous spacing, and slow, gentle motion that fully steps aside when you need stillness.

> Haven is a **self-help companion** — not a medical device, and not a substitute for professional care or crisis services. If you're in crisis, contact emergency services or a crisis line (in the US, call or text **988**).

## What it is

Most calming apps charge a monthly subscription for what is, in the hardest moment, a single tap of help. Haven is the opposite: a one-time, on-device SOS toolkit — breathing, 5-4-3-2-1 grounding, reassurance, a personal safety plan, a gentle episode log, and supportive insights — that's yours for good.

## Full feature list

- **Home / SOS** — one large, reassuring "I'm having a hard time" action plus one-tap tiles to Breathe, Grounding, Reassurance, Call my person, Log a moment, and your Safety plan. A warm "X days since your last hard moment" line, and an optional always-visible crisis-line row.
- **Breathe** (full-screen player) — a slowly breathing orb eased to a wall-clock phase timeline, with phase word, countdown, minutes & breath count. Patterns: **Calm** (4-6), **Coherent** (5-5), **Box** (4-4-4-4), **4-7-8**. Optional gentle haptic cues at each phase change. Pause / resume / restart.
- **Grounding** — an interactive **5-4-3-2-1** senses walkthrough you tap through and note as you go, ending in a warm success state, plus a small library of other techniques (cold water, temperature, body scan, count backwards).
- **Toolbox** — coping reminders (favorites first), a swipeable reassurance-card deck, the safety-plan editor, "Call my person," and add-your-own custom coping tools & cards (free up to a small cap, unlimited with Plus).
- **Log** — month-grouped history of hard moments and a gentle logging flow: intensity-before slider, where you were, trigger chips, what helped (multi-select), intensity-after, and a private note. Full edit & delete. Warm, encouraging empty state.
- **Insights** — Swift Charts framed as progress, not judgment: a days-since-last hero, calm-streak, hard moments per week, average relief (intensity drop), top triggers, time-of-day distribution, and what helps you most.
- **Onboarding** — a gentle three-step intro (welcome, optional safe-person contact, calm disclaimer), shown only on first run.
- **Settings** — emergency contact (name + phone), default breathing pattern, gentle-haptics toggle, extra-calm-visuals toggle, show-crisis-line toggle, Plus management + daily check-ins, safety-plan editor, About/disclaimer, and a non-destructive reset.
- **Haven Plus** — a tasteful, kindly-framed **one-time $4.99** unlock (simulated): all breathing patterns, full insights, unlimited custom items, and gentle reminders.
- **Reduce-Motion-first** — every animation degrades to a calm static state under the system Reduce Motion setting (or the in-app "extra-calm visuals" toggle); the breathing orb becomes a still progress ring.
- **Accessibility** — Dynamic Type throughout, descriptive labels / hints / values, decorative images hidden, large tap targets, and an AA-legible palette in both light and dark.

## Run steps

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh`).
3. Open `Haven.xcodeproj` in **Xcode 15+**, pick an **iOS 17+** simulator, and press **Cmd+R**.

### Free-signing note

The project uses a `com.orbioom.haven` bundle id. To run on a physical device with a free Apple ID, open the **Haven** target → **Signing & Capabilities**, select your personal team, and let Xcode adjust the bundle identifier if it reports one is already in use. No paid developer account is required for the simulator.

## Tech notes

- **iOS 17+**, **SwiftUI 5**, **MVVM** with `@Observable` engines (`BreathEngine`, `StatsEngine`).
- **SwiftData** for records (`PanicEpisode`, `Trigger`, `CopingItem`, `ReassuranceCard`) registered in a single `Schema`; `@AppStorage` for small preferences and the free-text safety plan. Persistence survives relaunch; the container falls back gracefully to an in-memory store if the on-disk store can't be opened, so the app never crash-loops.
- **Trigger ↔ PanicEpisode** is a true many-to-many: `PanicEpisode.triggers` is the owning side, `Trigger.episodes` declares the `@Relationship(inverse:)`.
- **BreathEngine** computes the current phase from wall-clock elapsed time, so it stays correct across backgrounding and view re-creation — no timer drift. `TimelineView(.animation)` drives the orb; under Reduce Motion it renders a static ring instead of scaling.
- **Swift Charts** powers Insights. Seed data primes ~12 triggers, ~16 coping items, ~20 reassurance cards, and ~14 past episodes over ~8 weeks so insights feel alive immediately.
- **Design language** — soft violet accent `#8A7CD8`, blush/lavender ambient gradients, continuous-rounded surfaces, generous spacing, low-contrast-but-AA-legible calm palette, slow gentle motion; first-class light & dark via a central `HavenTheme`.
- **Monetization** — a single in-app one-time **Haven Plus $4.99** unlock (simulated via `@AppStorage("isPro")`); free tier covers SOS tools, basic logging, two breathing patterns, and capped custom items.
- **Why it can boom** — anxiety is a massive, proven paying market and incumbents (Rootd, Calm) charge recurring subscriptions; Haven is the private, **one-time** alternative built around the in-the-moment SOS + grounding + episode insights people actually reach for during a panic attack.

## Self-review attestation

I re-read every Swift source file and verified by hand (no Xcode in the build sandbox):

- **Anti-stub:** clean — zero TODO/FIXME/XXX/placeholder-marker/"coming soon"/"not implemented"/stub text. (The only `placeholder` occurrences are legitimate `TextField` placeholder parameters and a UI helper name.)
- **No unsafe user paths:** zero `fatalError`, `try!`, `as!`, or force-unwraps; SwiftData saves use `try?`, the `ModelContainer` has a calm in-memory fallback, and all array indexing on user paths is bounds-guarded.
- **Braces/parens/brackets:** balanced across all 22 files.
- **Many-to-many inverse:** correct — `Trigger.episodes` carries `@Relationship(inverse: \PanicEpisode.triggers)`.
- **iOS 17 APIs:** `NavigationStack` only (no `NavigationView`), two-parameter `.onChange`, `@Observable` engines, `@Query`/`modelContainer`, `TimelineView(.animation)`, Swift Charts.
- **Reduce-Motion fallbacks wired everywhere there's motion:** breathing orb → static ring; onboarding/grounding/reassurance/paywall transitions and the root onboarding swap all check `accessibilityReduceMotion`; the looping onboarding mark is suppressed under Reduce Motion. An in-app "extra-calm visuals" toggle layers on top of the system setting.

## Disclaimer

Haven is a self-help companion — not a medical device, and not a substitute for professional care or crisis services. If you're in crisis or thinking about harming yourself, please reach out for real-time support. In the US, you can call or text **988** anytime. In an emergency, call your local emergency number. The disclaimer is shown calmly during onboarding and in Settings → About.
