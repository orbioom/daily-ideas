# Latest run — 2026-06-18_0725-UTC

Folder: `runs/2026-06-18_0725-UTC/` — **6 production-ready native iOS apps** (slots 01–06), each shipped as a XcodeGen `project.yml` + Swift sources + real 1024 AppIcon + README. Generate with `./gen.sh` (or `xcodegen generate` in each `ios/`), open in Xcode 15+, run on an iOS 17 simulator.

All six were checked against the 279-entry `SHIPPED.md` registry and are genuinely new concepts in large, proven markets (the registry already covers habit/sleep/finance/most casual games/most health trackers, so this run targets the remaining white space).

## The 6 apps

- **Pangram** — built — `01-pangram` — Spelling-Bee-style word game: find words from 7 honeycomb letters (must use the center), pangrams, 10-rank ladder, deterministic daily + unlimited practice, streak + Stats. — *Monetization:* one-time Pro (unlimited practice, full daily archive, hints page, themes). — *Why it can boom:* NYT Spelling Bee is wildly popular but locked behind the NYT Games subscription and offline-hostile; ours is free, offline, unlimited, ad-free.
- **Crest** — built — `02-crest` — TriPeaks solitaire with 3 layouts, combo scoring, undo/hint, wall-clock timer, daily/numbered/random deals, resume-on-relaunch, streak + Stats. — *Monetization:* one-time Pro (Pyramid/Diamond layouts, daily archive, felt themes, export). — *Why it can boom:* solitaire is evergreen top-grossing but the incumbents are ad-saturated and naggy; ours is a clean ad-free one-time buy.
- **Glimpse** — built — `03-glimpse` — Photo-a-day moment journal (photo + caption + mood + tags), streak, Timeline/Calendar-heatmap/Memories ("on this day")/Stats, montage export, daily reminder. — *Monetization:* one-time Pro (multiple moments/day, multiple journals, montage export, themes). — *Why it can boom:* 1 Second Everyday is video-only + subscription and Day One is subscription; ours is a simple, private, one-time photo-a-day journal with Memories.
- **Fetch** — built — `04-fetch` — Dog training & tricks coach: 40 step-by-step tricks + 5 programs, multi-dog progress, training-day streak, full-screen session player with a synthesized clicker, Stats. — *Monetization:* one-time Pro (unlimited dogs, all programs, advanced stats, custom tricks). — *Why it can boom:* dog ownership is huge and Dogo/GoodPup charge up to ~$40/mo (some with human trainers); ours is a one-time self-serve trick library.
- **Assay** — built — `05-assay` — Private bloodwork/lab-results tracker: 36-marker catalog with sex-specific reference + optimal ranges, status/trend engines, history charts with band shading, doctor CSV/text report. — *Monetization:* one-time Pro (unlimited markers/history, report export, custom markers, trend insights). — *Why it can boom:* Function Health ($499/yr) made self-tracked bloodwork go viral in 2024–25 and people have nowhere good to log results; ours is private, on-device, one-time, works with any lab.
- **Crisp** — built — `06-crisp` — Air-fryer cooking guide + multi-timer: 68-food catalog (fresh/frozen, shake/flip, internal temps), portion scaling, oven→air-fryer + unit conversion, doneness temps, relaunch-safe concurrent timers with notifications. — *Monetization:* one-time Pro (unlimited timers + custom foods, doneness pro). — *Why it can boom:* air fryers are in most kitchens and the App Store options are ad/IAP-junk reference lists; ours is an accurate guide plus a real multi-timer.

## Top recommendation

**Pangram.** Of the six it has the widest, most proven appetite (a daily word game people already play obsessively), the cleanest viral loop (shareable daily score + streak), and the strongest "incumbent is mediocre/paywalled" wedge (NYT Spelling Bee behind a subscription, no good free/offline version). It's also pure on-device logic with no data dependencies, so it ships clean. **Crest** is the safe runner-up (evergreen solitaire demand). **Assay** is the highest-ceiling sleeper, riding the longevity/biohacking wave.

## Research signals worth following next run

The registry is now ~285 deep and most obvious large markets are taken. Confirmed still-open, proven-demand gaps observed while scoping this run:
- **Spelling Bee / anagram word finder** — now taken (Pangram); a *crossword* (clue-based) remains open but needs a sizeable clue bank.
- **TriPeaks/Pyramid solitaire** — now taken (Crest); remaining solitaire families: *Golf*, *Yukon*, *Forty Thieves*.
- **Air-fryer / cooking-times** — now taken (Crisp); adjacent open: *sous-vide time/temp guide* (explicitly not done yet), *Instant-Pot pressure-cook guide*.
- **Lab/bloodwork** — now taken (Assay); adjacent open: *supplement-stack / longevity-protocol tracker*.
- Still genuinely open big-ish markets seen but not built: **adult coloring / mandala** (art-authoring is the hard part), **brain-training mini-games suite** (Elevate/Peak — large build), **manga/webtoon reading tracker**, **award-travel miles & points balance tracker**, **fitness progress-photo / body-transformation** (distinct from the body-measurement tracker already shipped).
