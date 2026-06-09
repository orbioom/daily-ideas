# Sprout — kids chores & allowance

**One line:** A private family chore chart with built-in allowance — no debit card, no bank login, no ads.
**Problem & audience:** Parents want kids to do chores and learn about money, but the popular apps (Greenlight, Homey, S'moresUp, BusyKid) gate everything behind a monthly subscription and a kids' debit card, with dated interfaces and constant bank-link errors. Sprout does the actual job — a clear board kids check off and an allowance ledger you control — beautifully and entirely on-device.

## Full feature list
- **Today** — a per-child board of the chores scheduled for today with one-tap check-off, a completion percentage, and (when approval is required) a parent **approval queue** to approve or reject.
- **Kids** — cards with avatar, points, weekly completions and current balance; add children (8 colors, 10 icons, optional weekly allowance).
- **Kid detail** — balance, total points, this-week earnings, a 14-day points chart, full **money history** (chore rewards + bonuses/allowance/payouts/spending), a "Money" sheet (add bonus, cash out, record spend, adjust), and a one-tap "Pay allowance now".
- **Chores** — catalog grouped by child; create chores with an icon, assignment, schedule (every day / certain weekdays / one time), money reward and points; activate/deactivate; full edit & delete.
- **Allowance engine** — optional weekly allowance auto-credited on launch for any whole weeks elapsed.
- **Settings** — currency symbol, auto-approve vs parent approval, auto-pay weekly allowance, haptics, load sample family, reset onboarding.
- Onboarding (persisted) with a sample-family path; empty/loading/success states; light & dark; Dynamic Type; VoiceOver; Reduce Motion.

## Run it
1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Sprout.xcodeproj` in Xcode 15+, pick an iOS 17+ simulator, Cmd+R.

**Free signing:** no paid Apple Developer account needed — personal team, simulator or your own device.

## Tech notes
iOS 17+, SwiftUI 5, MVVM with a pure `ChoreEngine` (today scheduling via weekday bitmask, completion state, allowance auto-credit, weekly stats, daily points). **SwiftData** models `Kid → Chore / Completion / LedgerEntry` (cascade). Each child's balance is derived (approved-chore rewards + signed ledger), so it can't drift. Swift Charts for points. Orbioom design language.
- **Monetization:** freemium — free for one child and core chores; Family Pro (one-time or low subscription) unlocks unlimited kids, reward redemption/wishlist, recurring bonuses, and shared family sync.
- **Why it can boom:** a proven, evergreen parenting category where every incumbent forces a paid debit-card subscription and a clunky UI; a private, no-card, genuinely pleasant chore + allowance app is a wide-open lane.

## Self-review
Hand-checked every file: imports resolve; SwiftUI/SwiftData/Charts APIs iOS-17-valid; weekday bitmask scheduling and approval/allowance flows reviewed; `Picker` with optional `Kid` selection and tags type-checks; sheets/`@Query`/`@Bindable` correct; no force-unwrap/`try!`/`fatalError` on user paths. Anti-stub grep clean. `project.yml` valid YAML naming the `Sprout` sources and `Info.plist`.
