# Latest run — 2026-06-14 18:09 UTC

**Folder:** `runs/2026-06-14_1809-UTC/` · 6 production-ready native iOS apps (slots 01–06), all built (none deferred to spec).

Each app: SwiftUI 5 + SwiftData, MVVM, iOS 17+, one-time/freemium monetization (StoreKit not wired — demo unlock + Restore), first-run onboarding, ≥4 feature screens + Settings, light/dark, Dynamic Type + VoiceOver, seeded sample data (50+ where a collection is implied), real 1024² app icon. Shipped as XcodeGen `project.yml` (run `./gen.sh`, never a hand-written `.xcodeproj`).

## The six apps

- **Lancet** — built — `01-lancet` — Glucose & diabetes manager with a classic meal-slot logbook and free eA1C/GMI/Time-in-Range insights. — Monetization: logging free; Insights charts + CSV export are a one-time $4.99 Pro. — Why it can boom: glucose tracking is a proven high-retention health category; the leader (mySugr) is widely disliked for paywalling reports — Lancet ships the beloved logbook + free analytics, on-device, once-and-done.
- **Skillet** — built — `02-skillet` — "Cook with what you have" pantry→recipe matcher: shows what you can make now and what you're one ingredient away from. — Monetization: browsing/matching free; >5 custom recipes + shopping export are a one-time $3.99 Pro. — Why it can boom: SuperCook proved demand for the job; incumbents are ad-cluttered and dated — Skillet does it offline, beautifully, with a smart shopping-unlock list.
- **Allot** — built — `03-allot` — Zero-based / envelope budgeting (the YNAB method) with no bank login, fully on-device. — Monetization: free 1 budget/2 accounts/10 categories; Reports + CSV + higher limits are a one-time $6.99 Pro. — Why it can boom: the envelope method has a proven, high-willingness-to-pay audience that loudly resents YNAB's $109/yr subscription and forced sync — Allot is the method, native, private, one-time.
- **Clef** — built — `04-clef` — Sight-reading / staff note-reading trainer across treble, bass, alto, grand staff with adaptive, mastery-weighted drills. — Monetization: free treble/naturals/≤20; other clefs, accidentals, timed mode, full ranges, export are a one-time $4.99 Pro. — Why it can boom: note-reading trainers are a proven evergreen music-ed niche with steady paid downloads; the incumbents are dated and ad-driven — Clef is the tasteful, multi-clef, adaptive version.
- **Daybreak** — built — `05-daybreak` — Routine builder + guided runner: chain habits into a morning/evening/focus routine and *run it* with a calm, relaunch-safe wall-clock player. — Monetization: free up to 2 routines; unlimited routines + all templates + export are a one-time $5.99 Pro. — Why it can boom: guided routines are a proven top-grossing wellness mechanic (Fabulous, Routinery) resented for aggressive subscriptions — Daybreak nails build→press-play→keep-streak with taste and a one-time price.
- **Cobble** — built — `06-cobble` — Block puzzle (8×8 drop, clear rows/cols, combos) with a deterministic engine, resume-on-relaunch, and a seeded daily challenge — no ads, ever. — Monetization: full game free; premium themes, unlimited Undo (free capped 3/game), daily archive are a one-time $2.99 Pro. — Why it can boom: block-drop puzzles are a download/revenue mega-genre whose one universal complaint is forced ads — Cobble removes exactly that for the price of a coffee.

## Top recommendation

**Allot (zero-based budgeting).** It targets the clearest proven willingness-to-pay in the set — YNAB has trained a devoted audience to pay ~$109/yr for precisely this method — against an incumbent whose price and forced bank-sync are its most-complained-about traits. A native, private, one-time-purchase envelope budget with correct Ready-to-Assign math is the version that audience keeps asking for, and it has the strongest "boom + monetize" combination. Runners-up: **Cobble** (largest raw audience / ride-the-trend) and **Lancet** (high-retention health category with a hated incumbent).

## Research signals worth following next run
- **Read-it-later** is wide open after Pocket's shutdown (Instapaper aging) — a private, offline reader-mode + highlights app; needs a share-extension + article parsing.
- **Smart alarm / sleep + wake** (Sleep Cycle, Alarmy) is huge but iOS background-alarm reliability is the design constraint — solvable with notification + in-app wake flow.
- **Chronic-symptom/flare tracker** (Bearable) — broad correlation-engine health category; differentiate from our Aura (migraine) and Tide (mood) by spanning arbitrary symptoms + factors.
- **Dividend-income / portfolio-income tracker** — proven niche (paid "Dividend Tracker" apps); needs mockable price data.
- **Kids' phonics / early-reading game** — large parent-paid education market; build as an adaptive mini-game suite.
- **Screen-time / focus-lock** (Opal, one sec) — strong monetization but gated by FamilyControls/DeviceActivity entitlements; viable as a foreground focus-session app.
