# Vitae — Resume Builder Without the Trial Trap

**What it is:** A native iPhone resume builder: structured editor (experience, education, skill groups), three typeset templates with live preview, and real multi-page PDF export — for job seekers burned by web builders whose "$2.95 trial" auto-converts to **$29.95/month** with cancellation horror stories filling Trustpilot. One honest purchase; your document, your device.

## Full feature list

- **Multi-resume management** — create blank (uses your default template), duplicate (deep copy including all items), swipe-delete, completeness meter and relative-edited timestamps per resume; "Start from Example" seeds a fully-written sample resume so the format teaches itself.
- **Structured editor** — identity, contact (typed keyboards: email/phone/URL), multi-line profile summary, and three reorderable CRUD sections: Experience (role/company/period + one-bullet-per-line details), Education (degree/institution/period/note), Skill groups (name + comma-separated skills). Drag-reorder via EditButton, swipe-delete, stable `orderIndex` persistence.
- **Three typeset templates** — Classic (centered serif, ruled sections), Banner (full-width accent header), Compact (dense one-pager) — all rendered by one `ResumeDocumentView` so the preview *is* the export. Documents render ink-on-paper in both app color schemes.
- **Live preview** — pinch-free dual-axis scroll, instant template switching (segmented), six accent colors, paper shadow.
- **Real multi-page PDF export** — SwiftUI → `ImageRenderer` (3× scale) → `UIGraphicsPDFRenderer` pagination at true US Letter (612×792) or A4 (595×842) point sizes; file named from your name; share sheet; export spinner + calm error alerts (render/write failures).
- **Resume Guide tab** — 9 substantive, opinionated tips (structure / bullets / polish) including ATS-vocabulary advice.
- **Settings** — paper size (Letter/A4), default template for new resumes, haptics; counts and a no-subscription statement.
- **Onboarding** (3 pages, persisted), empty state with two actions, loading state for export, error states, full Dynamic Type in the app chrome (documents are fixed-point by design, like any typeset artifact), VoiceOver labels (completeness announced as percent), light + dark.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Vitae.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R.

*Free signing:* personal team in Signing & Capabilities; suffix the bundle id if needed.

## Tech notes

- iOS 17+, SwiftUI 5, SwiftData with cascade relationships (`Resume` → `ExperienceItem`/`EducationItem`/`SkillGroup`, inverse + delete rules), `@Bindable` editors writing straight to models.
- PDF pipeline: `ImageRenderer.uiImage` on the main actor, sliced into pages by drawing at negative offsets inside `UIGraphicsPDFRenderer` — no third-party PDF code.
- Design language: "stationer's desk" — ivory/navy chrome, confident blue `#2F6BD8`, the document always presented as a physical sheet with shadow.
- **Monetization:** free for one resume; one-time **Vitae Pro** (unlimited resumes, all templates/accents) at $6.99 — positioned directly against the $29.95/mo trial-trap incumbents.
- **Why it can boom:** resume builders are a perennial, high-intent, high-search category where the dominant players' own reviews are billing complaints; "the resume app that doesn't subscribe you" is an instantly understandable wedge, and job seekers share tools that saved them money.

## Self-review

Re-read every Swift file: SwiftData relationships declared with `@Relationship(deleteRule: .cascade, inverse:)` on the parent and plain optional back-refs on children (the supported pattern); deep-copy duplicate inserts children explicitly; `onMove`/`onDelete` operate on the sorted arrays then rewrite `orderIndex`; `ImageRenderer` used only on `@MainActor`; pagination math guards `pageCount >= 1`; sheet/alert bindings are total; no force-unwraps/`try!` on user paths; iOS 17 APIs only; `Identifiable` chart-free screens. Anti-stub grep clean. `project.yml` names the real `Vitae` folder and `Info.plist`.
