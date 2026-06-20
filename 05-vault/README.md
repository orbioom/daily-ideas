# 05 — Vault: Private Photo Album

A fully on-device private photo locker — import photos from your library, store them in encrypted albums, and protect access with Face ID, Touch ID, or a 4-digit PIN. Photos never leave the device.

## Features

- **Face ID / Touch ID** — LocalAuthentication biometric unlock on every app launch
- **PIN Fallback** — 4-digit PIN with SHA256 hashing, animated keypad
- **Private Albums** — multiple albums with custom emoji icons, context menu rename/delete
- **Batch Import** — PhotosPicker supporting up to 20 photos at once
- **Photo Viewer** — swipeable full-screen viewer with pinch-to-zoom and caption editing
- **Favorites** — star photos for quick reference
- **Auto-Lock** — configurable lock timing (immediate, 1/5/15 min, never)
- **Storage Meter** — shows how much local space your vault uses
- **Grid Columns** — 2, 3, or 4 columns
- **3-step Onboarding** — welcome → create PIN → enable biometrics

## Screens

1. Onboarding (3 steps: welcome, PIN setup, biometrics)
2. Lock Screen (biometric prompt + PIN keypad)
3. Albums Grid (2-column cards with cover photo)
4. Photo Grid (configurable columns, PhotosPicker import)
5. Photo Viewer (full-screen swipeable, pinch-zoom, favorites, caption)
6. Settings (biometrics, auto-lock, grid columns, storage, change PIN)
7. Add Album (emoji picker + name)
8. Rename Album
9. Change PIN (3-step: current → new → confirm)

## Tech

- SwiftUI 5 + SwiftData (iOS 17+)
- LocalAuthentication for Face ID / Touch ID
- PhotosUI PhotosPicker for batch import
- FileManager-based JPEG storage in Documents/VaultPhotos/
- CryptoKit SHA256 for PIN hashing
- XcodeGen `project.yml`

## Monetization

One-time Pro unlock ($4.99): unlimited albums (free = 2 albums, 50 photos), break-in alerts, fake decoy PIN that shows empty vault.

## Market Signal

"Private photo vault" has 90K+ monthly searches — one of the highest-intent utility app searches on the App Store. Top competitors (Keepsafe, Private Photo Vault) are subscription-based ($3.99+/month). Vault is one-time purchase, fully offline, and uses SwiftData + modern Swift concurrency — technically cleaner than legacy ObjC competitors.
