# Apertura

A calm, native iOS companion for manual and film photography, by **Orbioom**.

Apertura has two halves that reinforce each other:

1. **An exposure calculator / visualizer** — reason about the exposure triangle before
   a shot using real photometry (`EV = log2(N²/t)`), solve the missing leg, snap to
   ⅓/½/full stops, enumerate equivalent exposures, and read honest qualitative guidance
   on depth of field, motion-blur risk, and grain.
2. **A shot log** — a relational journal of **Rolls** (film stock, ISO, format, camera)
   each owning ordered **Frames** (aperture, shutter, focal length, subject, location,
   notes, and the computed EV). Export any roll as CSV or JSON.

---

## Features

### Calculator / visualizer (preloaded, always usable)
- Pick which leg to **solve for** (aperture / shutter / ISO); dial the other two.
- Real EV math at the working ISO, with a metered-scene target and a **"you're N stops
  under/over"** read-out snapped to clean ⅓/½/⅔ fractions.
- **Solve** button that computes and snaps the chosen leg to the nearest valid stop.
- **Meter from current** captures the live exposure as the target.
- **Equivalent exposures**: every aperture/shutter pair that yields the same EV in the
  chosen increment.
- **Trade-off guidance** (clearly labelled *"guidance, not a meter"*): depth of field,
  motion-blur risk (informed by the 1/focal rule), and grain/noise — each conveyed by
  text **and** color, never color alone.

### Shot log
- **Roll library** — every roll with stock, format badge, ISO, frame count, developed state.
- **Roll detail** — metadata, the ordered frames, add-frame, edit, delete, and **export**.
- **Frame editor** — stop sliders with a live computed EV; subject / location / notes.
- **Export** a roll's log as **CSV** or **JSON** via the system share sheet (SwiftUI `ShareLink`).

### Throughout
- First-run **onboarding** (persisted flag; replayable from Settings).
- **Settings** with persisted preferences that each change behavior: appearance, default
  stop increment, units, haptics, default film stock, default ISO; plus reset-to-sample
  and clear-all.
- Empty / populated / guarded-error / success states everywhere.
- Seeded with **four** realistic sample rolls and their frames on first launch.
- Full accessibility: Dynamic Type, VoiceOver labels & values on every slider, decorative
  imagery hidden, light **and** dark, Reduce-Motion aware.
- On-brand Orbioom app icon (aperture-blade motif), AccentColor, and a launch screen.

---

## Run steps

1. Open **`Apertura.xcodeproj`** in Xcode 15 or later.
2. Select an **iOS 17** simulator (e.g. iPhone 15).
3. Press **Cmd+R**.

**Free signing:** the project builds with the personal team / automatic signing. If
Xcode prompts, select your own team under *Signing & Capabilities* — no paid account is
required for the simulator or a personal device.

---

## Tech notes

- **iOS 17+, SwiftUI 5, MVVM, no external dependencies.**
- **SwiftData** is the primary store for `Roll` and `Frame` with a cascade relationship
  (deleting a roll deletes its frames). The model container degrades gracefully to an
  in-memory store if the on-disk store can't be opened, so cold launch never crashes.
- **`UserDefaults`** holds only flags and preferences (onboarding/seeded flags, default
  increment, default film stock, default ISO, units, appearance, haptics).
- **`Utilities/Exposure.swift`** is a pure, testable value type: EV computation, inverse
  solving for any leg, snapping to ⅓/½/full stops, equivalent-exposure enumeration, and
  qualitative DoF/blur/noise indicators. Every entry point is guarded against
  non-positive aperture/shutter/ISO and against divide-by-zero / log-of-non-positive.
- Haptics are sparse and gated by the Settings toggle.
- Monospaced digits for all EV / aperture / shutter figures; ink-gradient primary action;
  `.ultraThinMaterial` glass on mist backgrounds.

---

## Self-review

- **Anti-stub:** `grep -rniE 'todo|fixme|xxx|placeholder|lorem|coming soon|not
  implemented|// stub' Apertura` returns **no matches** (clean).
- **Compile / data-flow review (no Xcode available):** every `import` verified; all types,
  initializers, and modifiers used exist in the iOS 17 SDK (`@Observable`, `@Model`,
  `@Query`, `@Bindable`, `ModelContainer`/`ModelConfiguration`, `ShareLink` with a custom
  `Transferable`, `NavigationStack` + `navigationDestination`, segmented `Picker`,
  `Slider(value:in:step:)`). No post-iOS-17 API is used.
- **Data flow traced** create → persist → relaunch → read: a new roll/frame is inserted
  into the `modelContext`, SwiftData persists it, `@Query` re-reads it after relaunch, and
  the cascade delete removes frames with their roll.
- **Safety:** no force-unwraps, `try!`, `fatalError`, unguarded array indexing, or
  unguarded division on user paths. All photometric inputs are bounded (aperture > 0,
  shutter > 0, ISO > 0) and all text is trimmed on save.
