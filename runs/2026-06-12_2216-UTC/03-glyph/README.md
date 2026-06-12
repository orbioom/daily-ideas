# Glyph — QR Studio Without the Subscription Scam

**What it is:** A complete QR toolkit — create styled codes (links, Wi-Fi, contact cards, email, SMS, phone), scan with the camera or from photos, keep a library and history — all generated and read **on-device**. Built against a category whose top apps charge $9.99/*week* for QR codes that "expire" on someone else's server. Audience: everyone who ever printed a menu, shared Wi-Fi, or put a link on a poster.

## Full feature list

- **7 payload types with real encoders** — URL (auto-`https://`), free text, Wi-Fi (`WIFI:` with WPA/WEP/open, hidden-network flag, correct `\;,:"`escaping), vCard 3.0 contact (N/FN/ORG/TEL/EMAIL/URL with field escaping), `mailto:` with subject/body (URLComponents percent-encoding), `SMSTO:`, `tel:`.
- **Live styled preview** — six module colors × six background colors, four error-correction levels (L/M/Q/H) with plain-language guidance, nearest-neighbor crisp rendering, automatic **low-contrast scannability warning** (luminance check).
- **Per-type validation** with calm inline errors; empty drafts show a neutral hint instead of a nag.
- **Share as crisp PNG** (ShareLink, ~1024 px) — codes never expire because there is no server.
- **Library** — saved codes stay *editable* (the draft is stored, not just the string), pin favorites, search, swipe to delete, full-screen detail with payload preview and share.
- **Camera scanning** — AVFoundation with QR-only metadata output, duplicate debounce, full permission flow (not-determined → request, denied → instructions + photo fallback), session stopped when off-screen.
- **Photo scanning** — Vision `VNDetectBarcodesRequest`, works in the simulator and fully offline; clear unreadable/no-code error alerts.
- **Scan results** classified into the same taxonomy with type-aware actions: copy, open link, compose email, call, message.
- **Scan history** (optional — a Settings toggle disables storage entirely), tap-to-copy with inline "Copied" confirmation, swipe-delete, clear-all with confirmation.
- **Settings** — default correction level, keep-history toggle, haptics toggle, live library/scan counts.
- **Onboarding** (3 pages, persisted), empty states on every list, loading states for rendering and photo scanning, Dynamic Type, VoiceOver labels/hints throughout, light + dark.

## Run steps

1. `brew install xcodegen` (one-time).
2. In `ios/`, run `xcodegen generate` (or run `./gen.sh` at the repo root).
3. Open `Glyph.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, Cmd+R. (Camera scanning needs a device; photo scanning works in the simulator.)

*Free signing:* personal team in Signing & Capabilities; suffix the bundle id if needed.

## Tech notes

- iOS 17+, SwiftUI 5. One `PayloadDraft` struct keeps form/validation/encoding in lockstep; CoreImage `CIQRCodeGenerator` + `CIFalseColor` for tinted rendering; Vision for photo decode; AVFoundation for live scan.
- SwiftData (`SavedCode` with JSON-embedded editable draft, `ScanRecord`); `@AppStorage` for the three preferences.
- Design language: "precision instrument" — near-black panels, signal-mint `#53E0A6`, monospaced payloads, capsule chips.
- **Monetization:** free core (create + scan); one-time **Glyph Pro** for the library beyond 5 saved codes, extra palettes, and SVG-quality export — undercutting $9.99/week incumbents with a single honest purchase.
- **Why it can boom:** the QR category has enormous organic search traffic and is dominated by subscription-scam apps with expiring codes; "your codes are yours forever, $4.99 once" is a story reviewers and Reddit love to spread.

## Self-review

Re-read every Swift file: CoreImage filter names/params checked (`qrCodeGenerator`, `CIFalseColor` inputColor0/1); AVFoundation session built off-main with weak self, delegate on main queue, `.qr` availability guarded; Vision continuation resumes exactly once on every path; PhotosPicker `loadTransferable(type: Data.self)`; all optionals guarded; no `try!`/force-unwraps on user paths; `@Query` sorts on stored properties; iOS 17 APIs only. Anti-stub grep clean. `Info.plist` includes `NSCameraUsageDescription`; `project.yml` valid.
