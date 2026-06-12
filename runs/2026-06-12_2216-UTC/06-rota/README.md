# Rota — Shift-Work Calendar & Earnings

**What it is:** A rotating-shift calendar for the enormous workforce whose week isn't Monday–Friday — nurses, paramedics, factory crews, transit drivers, retail and hospitality staff. Define your rotation once (4-on-4-off, 2D-2N-4-off, anything) and every month fills itself in; tap any day to swap/override; put rates on shift types and Rota projects paid hours and earnings. The category is proven (Supershift: "world's most downloaded shift calendar", 4.8★) but subscription-gated and weak on pay — Rota is one-time, on-device, and counts your money.

## Full feature list

- **Shift types** — name, 1–3-letter color badge (7-color palette with auto-pick of unused colors), start/end times via time pickers, **overnight wrap support** (19:00→07:00 = next day), unpaid-break deduction, hourly rate, rest-day flag; live paid-hours and per-shift-pay footer; full CRUD.
- **Rotation patterns** — ordered day cycles of any length anchored to a start date, modulo engine that's correct for dates *before* the anchor too; multiple rotations with one active (swipe to activate — handy when rosters change); slot add/replace (menu), drag-reorder, swipe-delete with reindex.
- **Three one-tap presets** — 4 on/4 off, 2 days/2 nights/4 off, 5 on/2 off — created with sensible hours, anchored to today.
- **Today tab** — today's shift (or Day Off / no-rotation guidance), override note display, live countdown to the next shift (60-day lookahead, TimelineView), next-7-days strip with badges, and a 7-day shifts/hours/pay summary.
- **Calendar tab** — month grid (Monday or Sunday start, per Settings), color badges per day, today highlight, amber dots on overridden days, month navigation with "back to today".
- **Day sheet** — see what's scheduled, change *just that day* to any shift type or force a day off, attach a note ("swap with Dana"), restore the rotation; the cycle underneath never breaks.
- **Earnings tab** — any month: shifts/paid-hours/estimated-pay tiles, pay-by-week Swift Charts bar chart, by-shift-type breakdown with hours and money; graceful "add rates to see pay" state when rates are zero.
- **Settings** — 24-hour clock, week start day, currency symbol (9 options), haptics, data counts.
- **Onboarding** (3 pages, persisted), empty states (no rotation, no types, no working shifts), full Dynamic Type, VoiceOver day-cell labels ("Tuesday 14 May: Night, manually changed"), light + dark.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Rota.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

*Free signing:* personal team in Signing & Capabilities; suffix the bundle id if needed.

## Tech notes

- iOS 17+, SwiftUI 5. SwiftData: `ShiftType`, `RotationPattern` →cascade→ `PatternSlot` (ordered via `orderIndex`), `ShiftOverride` keyed by local day string; pure `RotaEngine` (day resolution = override ?? pattern[(days − anchor) mod n], Euclidean mod; period summaries; next-shift search).
- Design language: "depot control board" — slate panels, signal amber `#F2A93B`, chunky color-coded badges, monospaced digits for times and money.
- **Monetization:** free for one rotation + current month; one-time **Rota Pro** (multiple rotations, earnings history, future: calendar export & widgets) — shift workers already pay Supershift's subscription for less.
- **Why it can boom:** shift workers are tens of millions of people with a recurring, painful job-to-be-done and proven app demand; the market leader's own positioning (subscriptions, weak earnings features) leaves "one-time, counts your pay, private" wide open — and nurses recommend tools to entire wards.

## Self-review

Re-read every Swift file: Euclidean modulo for pre-anchor dates (`((days % n) + n) % n`); overnight span math (`span += 24*60` when end ≤ start); all loops bounded (`safety` caps, 60-day next-shift window); key-path time bindings total; deletes guarded by index checks; only stored-property sorts in `@Query`; Charts use `Identifiable` structs; no force-unwraps/`try!` on user paths; iOS 17 APIs only. Anti-stub grep clean. `project.yml` names the real `Rota` folder and `Info.plist`.
