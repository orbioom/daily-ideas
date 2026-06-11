# Hired — native job-application tracker

**What it is.** Hired is the job-search command center that lives on your phone instead of a $13-a-week browser tab: every application with its stage, interviews, contacts, and follow-ups, plus a real funnel that shows which step of your search is leaking. For active job seekers — a market Teal and Huntr have proven will pay, then annoyed with web-first paywalls.

## Full feature list

- **Pipeline** — all applications with stage chips, company monogram, excitement flame, last-activity age; filters (Active / Wishlist / Offers / Closed / All); search by company or role; swipe-to-delete; add/edit via full editor (company, role, location, work mode, salary text, posting link, excitement 1–5, stage, applied date, notes) with validation.
- **Application detail** — header card with role/location/mode/salary/link; one-tap **Move** through 9 stages (wishlist → applied → screening → interview → offer → accepted, plus rejected/ghosted/withdrawn), every move recorded as a dated StageEvent; follow-up checklist with overdue highlighting; interviews (5 types, scheduled time, notes, pending/passed/failed outcome menu); contacts (name/title/email with text selection); full stage history timeline; delete with confirmation.
- **Up next** — pending interviews from today forward, follow-ups due within a week (tap-to-complete), and a "Going quiet" section: active applications with no movement past a configurable threshold, sorted oldest-silence first.
- **Insights** — sent / response-rate / median-days-to-first-reply tiles; applied→screening→interview→offer funnel with per-step conversion percentages and bar lengths; applications-per-week chart (8 weeks); excitement-spread chart with a targeting nudge.
- **Settings** — quiet-threshold stepper (5–30 days), haptics toggle, appearance picker, 12-application sample pipeline (all stages exercised, interviews + follow-ups included), delete-all with confirmation.
- Onboarding (3 pages, persisted), empty states on all tabs + filtered-empty state, validation errors surfaced inline, Dynamic Type, accessibility labels/hints, Reduce Motion respected, dark + light first-class.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Hired.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

*Free signing:* Xcode → target → Signing & Capabilities → Automatically manage signing → personal team.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM: pure `FunnelEngine` (funnel/conversions/response-rate/median-reply/stale detection, no UI imports), SwiftData `Application` cascading `StageEvent`/`Interview`/`JobContact`/`FollowUp`.
- Design language: editorial broadsheet — ivory paper, serif display type, one electric blue, stage-colored chips; full dark palette.
- **Monetization:** job seekers in pain pay fast — free up to 15 active applications, one-time "Hired Pro" (~$14.99) for unlimited + insights. Teal proves $9–13/week tolerance; we undercut with lifetime pricing.
- **Why it can boom:** Teal/Huntr validated demand but are web-first, subscription-heavy, and surprise users with mid-application paywalls; nobody owns "fast, native, offline job tracker" on the App Store, and every layoff cycle mints a new cohort of searchers.

## Self-review

Re-read every Swift file: imports (SwiftUI/SwiftData/Charts) verified; all APIs iOS 17 (NavigationStack, navigationDestination(for:), searchable, confirmationDialog, presentationDetents, Swift Charts); @Model relationships have explicit cascade inverses; navigation values use Hashable @Model instances; no force-unwraps/`try!` on user paths (URL(string:) guarded, optional chaining on application links); filtered-list onDelete indexes into the same filtered array it renders. Anti-stub grep clean. project.yml names the real `Hired` folder and Info.plist.
