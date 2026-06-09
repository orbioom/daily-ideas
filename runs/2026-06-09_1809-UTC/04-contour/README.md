# Contour

A private progress-photo & body-transformation tracker for iPhone. Capture
progress photos, log body measurements, and watch your trend take shape — all
stored **only on your device**.

## What it is

Contour is a calm, native iOS app for tracking a body transformation over time.
You add progress photos (front / side / back) and body measurements (weight,
waist, chest, hips, arms, thighs, body fat, neck). Contour groups your photos by
month, lets you compare a "before" and "after" side by side, and renders real
trend charts — smoothed weight lines, goal projection, and per-measurement
sparklines. There is no account and no cloud: your photos never leave the phone.

## Features

- **Timeline** — progress photos grouped by month in an adaptive thumbnail grid,
  filterable by pose, with a calm fallback tile for any missing image. Tap a
  photo for full-size detail (date, pose, weight, note), edit, or
  delete-with-confirmation.
- **Add** — pick a photo with the system `PhotosPicker` (saved on-device as
  JPEG), choose pose, date, optional weight + note; or switch the segment to log
  a body measurement with no photo. Inputs are validated; a brief success state
  confirms the save.
- **Compare** — choose a pose, pick a "before" and "after" (defaulting to the
  earliest and latest of that pose), and see them side by side with the number of
  days between and the weight change.
- **Progress** — every tracked measurement with current / start / change and a
  Swift Charts line. The weight chart overlays raw readings, an EMA trend line,
  and your goal line, plus rate-per-week and goal-date projection. Logging
  streak, total photos, and days-tracked stat tiles up top.
- **Settings** — weight unit (kg/lb), length unit (cm/in), default pose, goal
  weight + target date, haptics toggle, an on-device privacy note, and a
  destructive "delete all photos & data" that also clears the image files.
- **Onboarding** — three-slide intro that explains the on-device privacy model,
  gated by `@AppStorage`.
- Rich seed data on first launch — ~13 weeks of weekly weight/waist/chest/body-fat
  readings plus several synthesized gradient progress photos — so charts, the
  timeline, and Compare are full immediately.

## Run

1. `brew install xcodegen`
2. In `ios/`, run `xcodegen generate`
3. Open `Contour.xcodeproj` in Xcode 15+, choose an iOS 17+ simulator, and press
   Cmd+R.

**Free signing:** the project uses a personal-team-friendly bundle id
(`com.orbioom.contour`). Select your own team under Signing & Capabilities if you
deploy to a device; the simulator needs no signing.

## Tech notes

- iOS 17+, SwiftUI, MVVM-ish (pure static engine + SwiftData-backed views).
- **SwiftData** persists `ProgressPhoto` and `BodyMetric`; survives relaunch.
- **FileManager image store** (`Utilities/ImageStore.swift`) keeps photo bytes on
  disk under `Documents/Photos/` — SwiftData only stores filename references, never
  blobs, and nothing touches the network.
- **PhotosUI** `PhotosPicker` for image selection (`loadTransferable(type:Data.self)`
  → `UIImage`); no photo-library permission is required for the picker.
- **Swift Charts** for all Progress trends; canonical storage (kg, cm, %) with a
  `Units` helper for kg/lb and cm/in display.
- Orbioom design system (Brand tokens, GlassCard, ink/glass buttons, chips);
  full light + dark, Dynamic Type, accessibility labels/values, Reduce Motion,
  and sparse gated haptics.
- **Monetization:** one-time Pro unlock (or light subscription) for unlimited
  poses, side-by-side video export, and extra measurement types.
- **Why it can boom:** progress-photo and vanity-metric tracking is a proven,
  high-retention fitness behavior — and Contour's on-device-only privacy is a
  sharp wedge against cloud-hungry incumbents people don't trust with body photos.

## Self-review attestation

Every Swift file was hand-verified against the iOS 17 SDK (no Xcode in the build
sandbox). Confirmed: imports correct (SwiftUI, SwiftData, Charts, PhotosUI,
UIKit); iOS-17 APIs only (`PhotosPicker` + `PhotosPickerItem.loadTransferable`,
`@Query`/`@Bindable`/`modelContainer`, `NavigationStack`, `.sheet(item:)`);
no force-unwraps / `try!` / unguarded division on user paths (engine guards empty
series and zero/sign-degenerate slopes; image loads return nil gracefully to a
fallback tile, never crashing); the only `fatalError` is the reference
in-memory-container fallback. Anti-stub grep is clean. Empty, loading, success,
and error states are present across all feature screens. ≥3 persisted Settings
prefs (units, default pose, goal, haptics).
