# Brief — Invoice Maker for Freelancers

Beautiful, native iOS invoice generator and client manager for freelancers and self-employed professionals.

## The Problem
Invoice Simple charges $100+/year. Zoho Invoice is complex and cloud-only. FreshBooks is overkill. Freelancers need a simple, beautiful, offline-capable iOS tool — without a subscription.

## Why Brief Can Win
- **59M+ freelancers** in the US alone, all needing invoicing
- **Pricing frustration** with incumbent subscription models ($100/yr vs $4.99 one-time)
- **Native iOS** — faster, prettier, and offline-capable vs web apps
- **No artificial limits** — unlimited clients and invoices on the free tier
- **PDF export** built-in via iOS share sheet

## Monetization
**One-time $4.99 Pro unlock** (no subscription, ever):
- Custom invoice templates
- Tax presets
- Client CSV import/export

## Features
- Client management with financial summaries
- Invoice creation with line items, tax, and discounts
- PDF generation via UIGraphicsPDFRenderer
- Payment status tracking (Draft → Sent → Paid)
- Overdue detection (visual, non-destructive)
- SwiftData persistence — all data stays on device
- iOS 17+, SwiftUI 5

## Tech Stack
- **iOS 17+**, **SwiftUI 5**, **SwiftData**
- **UIGraphicsPDFRenderer** for professional PDF generation
- **Decimal arithmetic** throughout (no floating point money bugs)
- No backend, no accounts, no cloud dependency

## Building
1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. `cd ios && xcodegen generate`
3. Open `Brief.xcodeproj` in Xcode 15+
4. Build and run on iOS 17+ simulator or device

## App Structure
- `BriefApp.swift` — App entry point, SwiftData model container
- `Models/` — SwiftData models (Client, Invoice, LineItem, BriefSettings)
- `Views/` — All SwiftUI views organized by feature
- `Utilities/` — PDF renderer, currency formatting, invoice number generation
- `Theme/` — App-wide colors and styling
