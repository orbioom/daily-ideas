# Coast — financial independence planner

**What it is.** Coast turns the FIRE movement's core math into a calm, personal picture: your FI number (the 4% rule), the years until work becomes optional, and the milestone most apps ignore — **Coast FI**, the point where you can stop investing entirely and still retire on time. For the huge, money-motivated FIRE/r/financialindependence audience, done on-device with zero bank logins.

## Full feature list

- **Plan dashboard** — your FI number with an animated filling-wave progress indicator; % there, years-to-FI, and the age work becomes optional; a dedicated **Coast FI** card (amount needed, distance to it, years to reach it, "you're coasting" state when achieved); savings-rate / real-return / withdrawal-rate lever tiles; today's safe passive monthly income and what % of spending it covers.
- **Assumptions editor** — age, annual spending, currently invested, annual contribution (validated number fields) + real-return and withdrawal-rate sliders, with the FI number recalculating live.
- **Projection** — dual-path Swift Chart (keep-contributing area+line vs. coast-only dashed line) against the FI rule line with compact-currency axes; plain-English explainer of your FI age; year-by-year value table.
- **Progress** — log net-worth snapshots; least-squares **real-pace** monthly growth and an FI date projected from your actual history (not just assumptions); net-worth line chart vs. FI line; history list with delete; optional sync of latest figure into the plan.
- **Milestones** — auto-generated ladder ($10k → Coast FI → ¼ → ½ → Lean FI ¾ → FI) with live progress bars + reached states, plus custom goals (house deposit, sabbatical) with add/swipe-delete.
- **Settings** — currency (5, all formatting respects it), traditional-retirement-age slider (drives Coast FI), haptics, appearance, sample-journey loader (16 months of climbing history + custom milestones), reset-all with confirmation, "planning tool not advice" disclosure.
- Onboarding (3 pages, persisted), empty states, inline validation, Dynamic Type, accessibility labels, Reduce Motion (wave animation disabled), dark + light first-class.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Coast.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

*Free signing:* Xcode → Signing & Capabilities → personal team.

## Tech notes

- iOS 17+, SwiftUI 5, MVVM: pure `FIEngine` (compound years-to-target with intra-year interpolation, Coast FI via discounting, savings rate, projection series, least-squares pace, history-based FI date, milestone ladder — no UI imports), SwiftData `Profile` + `NetWorthEntry` + `Milestone`; custom `Shape` wave + `Shape` animatableData.
- Design language: calm ocean horizon — teal sea, sun-gold, coral FI line; rounded display type; animated water-level progress.
- **Monetization:** FIRE audience reliably pays for planning tools (e.g. ProjectionLab, Empower's audience); Coast Pro one-time ~$14.99 unlocks multi-scenario plans + CSV export; free core covers one full plan. No predatory subscription, unlike the category's web tools.
- **Why it can boom:** "Coast FI" is a beloved, shareable concept with no great native iOS home; the FIRE community is large, evangelical, and money-motivated, and a beautiful private calculator (no Plaid bank-linking anxiety) is exactly what they recommend to each other.

## Self-review

Re-read every Swift file: imports verified; iOS 17 APIs only (Swift Charts AreaMark/LineMark series/RuleMark/AxisMarks, Shape animatableData, NavigationStack, confirmationDialog, @Bindable); single-profile bootstrapped in `.task`; all money parsing guarded (bounded, comma-tolerant, no force-unwraps/`try!`); division guarded (withdrawalRate>0, denom checks in regression); projection horizon bounded to avoid runaway loops; milestone delete maps row index → custom model safely. Anti-stub grep clean. project.yml names the real `Coast` folder and Info.plist.
