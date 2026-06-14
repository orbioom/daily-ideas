# Latest run — 2026-06-14_0012-UTC

**Folder:** `runs/2026-06-14_0012-UTC/`
**Shipped:** 6 production-ready native iOS apps (slots 01–06), all built to the Definition of Done.
171 Swift files total. Each ships a XcodeGen `project.yml` (no hand-written `.xcodeproj`), a real
distinctive 1024² on-brand icon (silver motif over the Orbioom mist→ink ground), light + dark first
class, onboarding gated by a persisted flag, a Settings screen with ≥3 functional persisted prefs,
empty/loading/error/success states, SwiftData persistence, Dynamic Type + VoiceOver + Reduce Motion +
opt-out haptics, and an honest one-time Pro unlock surface (StoreKit not wired in this build; gated by
`@AppStorage("isPro")`). Each app was built by a dedicated agent then audited by the studio lead
(no Xcode in the sandbox): anti-stub grep clean, no force-unwrap/`try!`(beyond the in-memory
`ModelContainer` fallback)/`fatalError` on user paths, no duplicate types, every `Theme.` token
defined-vs-used, observation wiring (`@Observable`+`@State`/`@Environment` vs `ObservableObject`+
`@StateObject`/`@EnvironmentObject`) verified consistent per app, project.yml/Info.plist/asset JSON
parsed, brace/paren/bracket balance verified, and one real Swift Charts tuple-keypath issue in Lexeme
found and fixed (converted chart series to `Identifiable` structs).

## The 6 apps

- **Aster** — *built* — `01-aster` — Mind-mapping app: a `MindMap` cascades a `MapNode` tree; a pure
  `LayoutEngine` computes deterministic radial + horizontal-tree positions and connectors (skipping
  collapsed subtrees); a pannable/zoomable Canvas editor, a synced indented Outline editor, a Node
  detail screen, 5 starter Templates, and Markdown outline export. — *Monetization: free up to 3 maps
  + 2 themes; one-time Aster Pro ($6.99) for unlimited maps, all themes, export.* — *Boom: mind-mapping
  is a proven paid category (MindNode revenue) but the leaders are subscriptions (MindNode) or dated
  (SimpleMind) — a calm, native, one-time mind map is the wished-for tool amid subscription fatigue.*
- **Peregrine** — *built* — `02-peregrine` — World-geography learning game: a 129-country dataset
  (flag emoji derived from ISO codes), a pure `QuizEngine` with 5 modes (flag→country, country↔capital,
  flag→continent, bigger-population), region-aware distractors, mastery-weighted **adaptive** selection,
  and a date-seeded daily challenge; Atlas browse + country detail; Swift Charts progress + achievements.
  — *Monetization: free 3 continents + daily + 3 quizzes/day; one-time Peregrine Pro ($4.99) for all
  continents, unlimited, all modes.* — *Boom: geography quiz apps are a perennial ed-game hit (Seterra,
  Sporcle) but the field is fragmented and ad-stuffed — one clean, adaptive, ad-free trainer wins.*
- **Cusp** — *built* — `03-cusp` — Event countdown (days-until & days-since): a `CountdownEngine` with
  Feb-29- and month-end-safe recurrence, live `TimelineView` spans, and Today/Upcoming/Past grouping;
  gradient event cards, a detail screen with a progress ring + `ImageRenderer` share card, a month
  calendar, and quick-add occasion templates. — *Monetization: free up to 5 events + 3 themes (never
  paywall the first countdown); one-time Cusp Pro ($3.99) for unlimited events, all gradients, calendar
  + share cards.* — *Boom: countdowns are universal and shareable; incumbents are "30 ads to make one
  event" and paywall their widgets — a calm, ad-free, one-time countdown is exactly the 1-star fix.*
- **Abacus** — *built* — `04-abacus` — Mortgage & loan calculator: a pure `LoanMath` engine
  (payment, amortization with extra + one-time payments, interest & months saved vs baseline,
  affordability inverse, refinance break-even), balance-over-time + principal/interest Swift Charts,
  and saved scenarios with side-by-side compare + CSV export. — *Monetization: free calculator + 1
  scenario + amortization; one-time Abacus Pro ($4.99) for unlimited scenarios, compare, refinance,
  export.* — *Boom: high-intent homeowners search these constantly; incumbents are ugly/ad-laden, and
  "here's how much interest your extra payment saves" is a motivating, sticky hook.*
- **Lexeme** — *built* — `05-lexeme` — English vocabulary builder (SAT/GRE/word-lovers): a 185-word
  curated bank, a `LexemeEngine` with deterministic word-of-the-day, spaced repetition
  ([0,1,3,7,16,40]-day intervals) and 4 quiz modes (definition↔word, synonym, fill-in-the-blank) with
  same-POS distractors; Today, Study, Lexicon + word detail, and a Progress dashboard. — *Monetization:
  free everyday bank + 20 reviews/day; one-time Lexeme Pro ($5.99) for the full SAT & GRE banks,
  unlimited reviews, all modes.* — *Boom: test-prep audiences pay; Magoosh is free-but-bland and the
  rest are ad/subscription — a beautiful, fun, ad-free word-power app fills the taste gap.*
- **Sapper** — *built* — `06-sapper` — Minesweeper: a pure `MineEngine` (first-click-safe generation,
  iterative flood-fill, chording) plus a logical `Solver` (single-point + subset/1-2-1) that drives
  **no-guess** board generation, a SplitMix64-seeded daily challenge, resume-on-relaunch, a zoom/pan
  board, and win-rate/time Swift Charts. — *Monetization: free fully (no ads ever); one-time Sapper Pro
  ($2.99) for themes, no-guess mode, custom boards, export.* — *Boom: a nostalgic classic whose top
  apps are ad-stuffed/subscription; the reviews literally beg for "ad-free + no-guess" — that's Sapper.*

## Top recommendation

**Cusp** has the highest ceiling: countdowns are universal and inherently shareable (every share card
markets the app), the incumbents are notorious for ad-spam and paywalled widgets, and the lock-screen/
widget era rewards exactly this. **Peregrine** is the strongest "proven-but-fragmented-market" play (a
clean adaptive geography trainer in a field of ad-stuffed quiz apps), and **Sapper** is the safest
virality bet (nostalgia + the precise "ad-free, no-guess" fix the 1-star reviews demand). **Abacus**
and **Lexeme** are the most defensible high-intent utilities (homeowners; test-prep) where willingness
to pay is already proven and the incumbents are bland.

## Research signals worth following next run

- **Subscription-fatigue, one-time native versions of proven paid tools** (Aster): the productivity
  long tail — outliners, kanban, whiteboards, diagramming, flowcharts — all proven, mostly subscription.
- **Adaptive ed-games** (Peregrine): the rest of the learn-by-quiz stable — anatomy, music theory,
  chemistry/periodic table, art history, coding-concepts, capitals-of-US-states — proven and ad-stuffed.
- **Shareable lifestyle utilities** (Cusp): the widget-era long tail — habit/streak widgets, "this day
  in…" memories, age/time-lived counters, salary-earned-today tickers — viral and screenshot-friendly.
- **High-intent finance calculators, no bank login** (Abacus): rent-vs-buy, lease-vs-buy, refinance,
  paycheck/take-home, compound-interest visualizers — high search volume, ad-laden incumbents.
- **Ad-free classic games done right** (Sapper): solitaire variants we haven't built, 2048/merge,
  nonogram packs, kakuro, mahjong solitaire — nostalgia + "no ads, no subscription" is the whole pitch.
