# Romp — tilt-to-play party charades

**What it is.** The forehead party game (proven by Heads Up!, a decade-long top-paid "sensation" per the NYT) rebuilt the way friends wish it worked: zero ads, no video-recording upsell, instant rounds, custom decks that make it personal, and buttons that always work alongside tilt — so it's playable in the Simulator, by players who can't tilt, and at chaotic parties.

## Features

- **8 built-in decks, ~355 cards** — Animal Kingdom, Act It Out (classic charades), Movie Night, Icons & Characters, Snack Attack, Game On, On the Job, Throwback — each a candy-colored gradient card with emoji, blurb and your best-score trophy badge.
- **The round** — 3-2-1 get-ready screen with hold-to-forehead instructions; giant auto-scaling word; countdown timer + progress bar (deterministic end-date timing); **CoreMotion tilt scoring** (screen-to-floor = correct, screen-to-ceiling = pass, must return to vertical to re-arm) with graceful fallback to on-screen Got it / Pass buttons when motion is unavailable or disabled; green/amber full-screen flash + distinct haptics per outcome; passed words recycle so the round never runs dry; end-round early.
- **Recap & scores** — time's-up screen with big score, guessed/passed word lists, explicit save (success state); Scores tab with rounds/best/total tiles, best-score-by-deck horizontal bar chart (Swift Charts), recent rounds with delete.
- **Custom decks** — full CRUD, emoji icon picker, rapid card entry (submit-to-add with refocus, case-insensitive de-dupe), swipe to delete cards, 5-card minimum enforced with inline messaging.
- **Settings** — default round length (30/60/90/120 s), tilt toggle, haptics, how-to-play.
- Onboarding (persisted flag); empty states; landscape + portrait; Reduce Motion respected (flash + countdown); accessibility labels/hints on every control; light & dark.

## Run

1. `brew install xcodegen` (one-time). 2. In `ios/`, `xcodegen generate` (or `./gen.sh`). 3. Open `Romp.xcodeproj` in Xcode 15+, iOS 17+ simulator, Cmd+R. (Tilt needs a device; buttons work everywhere.)

## Tech notes

- iOS 17+, SwiftUI 5; `@Observable GameEngine` (phase machine: getReady → playing ⇄ flash → finished; wall-clock end date; CMMotionManager gravity-z arm/fire/re-arm), SwiftData (`GameResult` with `[String]` word lists, `CustomDeck`), `@AppStorage` prefs.
- Design language: "confetti arcade" — coral on cream (plum in dark), chunky rounded type, candy deck cards.
- **Monetization:** deck packs as IAP (the exact model Heads Up! proved) + one-time unlock for unlimited custom decks.
- **Why it can boom:** party games are inherently viral (every round demos the app to a room of potential installers); the proven leader is paid, ad-laden and stale.

## Self-review

Re-read every Swift file: CoreMotion API (`isDeviceMotionAvailable`, `startDeviceMotionUpdates(to:)`, gravity sign convention verified — face-down z>0, face-up z<0), phase-machine transitions guard double-fires, Task cancellation on dismiss, SwiftData wiring, no force-unwraps on user paths, anti-stub grep clean.
