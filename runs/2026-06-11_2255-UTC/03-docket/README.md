# Docket — private document scanner with on-device OCR

**What it is.** A scanner for everyone who hates what scanner apps became. CamScanner's review pages are a museum of dark patterns (paywall pop-ups for paying users, cloud uploads without consent, a 2019 malware incident); Scanner Pro pushes subscriptions. Docket does the proven job — scan → searchable archive → clean PDF — with zero cloud, zero account, zero nags.

## Features

- **Scan** — VisionKit document camera (edge detection, perspective correction, multi-page) with graceful fallback when unsupported (e.g. Simulator) plus **Import from Photos** (PhotosPicker, up to 20 pages) so every device can ingest documents.
- **On-device OCR** — every page is read by the Vision framework (`VNRecognizeTextRequest`, accurate + language correction) in the background, with a live "Reading text · page x of y" status pill; recognized text powers search and per-page text view.
- **Library** — documents sorted by recency, thumbnail rows with page count/folder/favorite, full-text search across titles **and recognized page text**, swipe to delete (removes JPEGs from disk too), empty + no-results states.
- **Document detail** — page grid with OCR badges, context-menu page reorder (move up/down) and delete, rename, favorite, move-to-folder, append pages from Photos, delete with confirmation; **Prepare PDF → Share PDF** flow (PDFKit assembly with loading state, error alert if pages can't load, temp file named after the document for ShareLink).
- **Page detail** — segmented Image / Text panes; pan-zoomable scan image; selectable monospaced OCR text with copy-all (success feedback).
- **Folders** — CRUD with auto-picked icons, rename/delete swipes (delete nullifies, never destroys documents), per-folder contents screen.
- **Settings** — JPEG quality (Compact/Balanced/Best), PDF naming, haptics; privacy statement. Onboarding (persisted flag), Dynamic Type, light/dark, accessibility labels throughout.

## Run

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or `./gen.sh` at the repo root).
3. Open `Docket.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R. (Camera scanning needs a real device; use Import from Photos in the Simulator.)

## Tech notes

- iOS 17+, SwiftUI 5; SwiftData (`Folder` →nullify→ `ScanDocument` →cascade→ `ScanPage`), JPEGs in `Documents/Pages` via `ImageStore` (long-edge cap 2200 px, atomic writes), `@MainActor @Observable ScanIngestor` pipeline, Vision OCR off the main thread via checked continuation, PDFKit export.
- Design language: "paper & ink ledger" — archival blue on ivory/slate, tight grids.
- **Monetization:** one-time Pro (folders + unlimited docs) — the anti-subscription scanner; office workers, freelancers and parents pay for receipts/contracts/records.
- **Why it can boom:** scanning is a top-utility proven market and the leaders are actively hated (dark patterns, privacy scandals); "private, fair scanner" is a marketing message that writes itself.

## Self-review

Re-read every Swift file: VisionKit delegate signatures, Vision request API, PDFKit `PDFPage(image:)`/`dataRepresentation()`, PhotosPicker transferable loading, SwiftData relationship delete rules (folder deletion preserves documents), file deletion paired with model deletion, no force-unwraps/`try!` on user paths, anti-stub grep clean.
