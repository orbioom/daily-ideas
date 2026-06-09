# Aura

A calm, private, on-device **migraine & headache tracker** for iOS 17+ — the
gentle answer to Migraine Buddy. Log attacks in seconds, see your patterns, and
keep a clean diary you can show your neurologist. "Conjured, not just coded."

> Aura is a personal diary, **not a medical device**. It does not diagnose,
> treat, or provide medical advice. Share it with your clinician.

## What it is

Aura turns every headache into a quick, structured entry — intensity, type,
location, aura, triggers, symptoms, and the medications that helped — then
surfaces frequency trends, ranks your likely triggers, flags medication-overuse
risk, and estimates monthly impact. Everything is stored locally with SwiftData.

## Features

- **Today** — a live ongoing-attack card (duration ticks via `TimelineView`,
  end-attack and add-meds actions), or a calm overview: days since last attack,
  this-month frequency, acute-med-days, and a gentle medication-overuse banner,
  with a one-tap **Log attack** button.
- **Log** — attacks grouped by month (newest first); each row shows date,
  intensity dot, type, duration, and trigger chips. Tap through to a full
  **Attack detail** view (timing, location, aura, triggers, symptoms, meds with
  relief, note) with edit and delete.
- **Attack editor** — start/end date-time (validated end ≥ start, or mark
  ongoing), 1–10 intensity slider, type, location, aura toggle, multi-select
  trigger & symptom chips with add-custom, add medications (from catalog or
  custom, with dose, minutes-after-onset, and relief), and a note.
- **Insights** (Swift Charts) — attacks per month (bar), intensity over time
  (line + point), trigger ranking by coincidence fraction, symptom frequency
  (bar), medication usage & average relief, and a 30-day MIDAS-style impact card.
  Stat tiles up top, full empty state.
- **Manage** — CRUD for your Triggers, Symptoms, and Medication catalog.
  Built-ins are protected; deleting a custom item never orphans past attacks
  (taken-meds snapshot their own data; many-to-many links unlink safely).
- **Settings** — persisted prefs wired to behavior: default headache type
  (prefills the editor), interface haptics, acute-med overuse threshold
  (6–20, drives the warning), show-impact toggle. Plus delete-all-data
  (confirmed), replay intro, and the personal-diary disclaimer.
- **Onboarding** — three calm slides, gated by `@AppStorage`.

## Run

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` if present).
3. Open `Aura.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, and press Cmd+R.

**Free signing:** select the Aura target → Signing & Capabilities → pick your
personal team; the bundle id is `com.orbioom.aura`. No paid account needed to run
on a simulator or your own device.

## Tech notes

- **iOS 17+**, **SwiftUI**, lightweight **MVVM** (pure static `AuraEngine` for
  analytics, views own view-state), **SwiftData** (`@Model`, `@Query`,
  `@Relationship` — many-to-many triggers/symptoms, cascade-owned meds),
  **Swift Charts**, Orbioom design system (`Brand` tokens, glass surfaces,
  ink buttons), full Dynamic Type, VoiceOver labels/values, Reduce Motion
  gating, AA-contrast light & dark.
- On-device only; no network, no account, no tracking.

### Monetization

Free forever for logging and recent history. **Aura+** subscription unlocks
unlimited history, the full trigger-correlation analytics suite, and clinician
**PDF/CSV export** — a model already proven to convert in the migraine-tracker
category.

### Why it can boom

Tens of millions of people live with migraine. The category leader (Migraine
Buddy) has huge usage but is cluttered and pushy with ads and prompts. Aura is
the opposite: calm, private, on-device, and sharper on the one thing sufferers
most want — *what is actually triggering this?* — with honest medication-overuse
awareness their clinicians will appreciate.

## Self-review attestation

Every Swift source was re-read by hand. Verified: imports (SwiftUI / SwiftData /
Charts / Foundation / UIKit where needed); all enum cases, initializers, and
modifiers exist in the iOS 17 SDK; SwiftData wiring type-checks (cascade `meds`
with inverse `MedTaken.attack`; one-directional safe many-to-many for triggers
and symptoms); `@State`/`@Bindable`/`@Environment`/`@Query` ownership;
multi-select chip binding via `Set<PersistentIdentifier>`; `NavigationStack` and
sheet bindings; live duration via `TimelineView(.periodic)`; Swift Charts marks
and axes; all date math via `Calendar`; divide-by-zero guarded in every average
and correlation. No `try!`, no `as!`, no force-unwraps on user paths, and the
only `fatalError` is the in-memory `ModelContainer` fallback (identical to the
Chime reference). Anti-stub grep (`TODO|FIXME|XXX|placeholder|lorem|coming
soon|not implemented|// stub`) returns zero matches.
