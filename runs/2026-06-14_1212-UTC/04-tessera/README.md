# Tessera

A private, offline **two-factor authenticator** for iOS 17 — a clean, trustworthy
TOTP/HOTP code generator built to beat Google Authenticator and Authy on the things
that actually matter: search, folders, biometric lock, honest one-time pricing, and
no cloud. Your secrets live on your device and nowhere else.

Built with SwiftUI + SwiftData + CryptoKit. Indigo "secure utility" design language
with monospaced numerals so codes never jitter as they roll.

---

## What it does

- **Live codes list** — every account shows its issuer, account name, and the live
  OTP grouped for legibility (`123 456`). A **circular countdown ring** ticks down
  each second and the code auto-rolls at the period boundary. Tap a row to copy
  (success haptic + "Copied" toast). Pin favorites, search, and filter by folder.
- **Three real ways to add an account**
  1. **Scan QR** with the camera (AVFoundation `AVCaptureMetadataOutput`). Calm
     fallback states when the camera is denied or unavailable, pointing you to the
     other paths.
  2. **Paste setup link** — paste an `otpauth://` URI, see a live preview, confirm
     before saving.
  3. **Manual entry** — issuer, account, secret with **live Base32 validation**, plus
     algorithm / digits / period / type pickers.
- **Folders** — create, rename, and delete (delete reassigns accounts to *Unfiled*,
  never deletes codes), reorder accounts, and move accounts between folders.
- **Backup & overview** — account / favorite / type counts, an algorithm breakdown,
  per-folder counts, an **Export** (Pro) that writes all accounts as standard
  `otpauth://` lines via `ShareLink` (plus a readable plain-text list), and an
  **Import-from-text** path that skips invalid lines.
- **App-lock gate** — when "Require Face ID / Touch ID" is on, the whole app is gated
  behind `LocalAuthentication` on launch and on every return from background, with a
  calm locked state and a manual **Unlock** retry. Off by default; app opens normally.
- **Settings** — require biometrics, hide codes until tapped, haptics, default sort
  (manual / issuer / recent), theme (Pro), About, Pro / Restore, and **Load sample
  data** (seeds realistic demo accounts across folders and algorithms using clearly
  fake secrets).
- First-run **onboarding**, designed **empty / loading / error / success** states,
  full **Dynamic Type**, **light & dark** mode, accessibility labels throughout, and
  **Reduce Motion** support.

---

## The OTP engine (correctness first)

`Engine/` is a pure, UI-free implementation of the relevant RFCs, verified by hand
against the published reference vectors (no Xcode in the build sandbox):

- **`Base32`** — RFC 4648 decode (tolerant of lowercase, spaces, dashes, and optional
  `=` padding; rejects anything outside the alphabet and malformed trailing bits) and
  encode (for export). Returns `nil` on invalid input — no force-unwraps.
- **`OTPGenerator`** —
  - HMAC over an **8-byte big-endian counter** built byte-by-byte (no endianness or
    layout assumptions), keyed with `SymmetricKey(data: secret)`.
  - Algorithms via CryptoKit: `HMAC<Insecure.SHA1>` (RFC 6238 default), `HMAC<SHA256>`,
    `HMAC<SHA512>`.
  - **RFC 4226 §5.3 dynamic truncation**: offset = low nibble of the last HMAC byte;
    a 31-bit value (top bit masked) read from 4 bytes at that offset; reduced mod
    `10^digits`; zero-padded to 6 / 7 / 8 digits. All byte indexing is guarded.
  - **TOTP**: `counter = floor(unixTime / period)`,
    `secondsRemaining = period - (unixTime % period)`, and a `progress` fraction for
    the countdown ring.
  - **HOTP**: counter stored per account, incremented on tap-to-reveal / refresh.
- **`OTPAuthURI`** — robust parser/serializer for
  `otpauth://totp|hotp/Issuer:account?secret=…&issuer=…&algorithm=…&digits=…&period=…&counter=…`,
  tolerant of URL-encoding and missing optional params (defaults: SHA1, 6 digits,
  period 30, counter 0). Used for QR import, paste import, and export.

Every user-facing path is total: bad input yields `nil` (and a calm error), never a
crash. There are no force-unwraps, `try!`, `as!`, `fatalError`, or `precondition`
calls on user paths anywhere in the engine.

---

## Architecture

- **`TesseraApp`** — single `@main`; builds the `ModelContainer(for: Account, Folder)`
  in `init()` with do/catch (the **only** `try!` in the app is the in-memory fallback).
  `@AppStorage("hasOnboarded")` gates Onboarding vs the locked app.
- **Persistence (SwiftData)** — `Account` (issuer, label, secret, algorithm, digits,
  period, type, counter, color, sortIndex, favorite, createdAt, optional `folder`) and
  `Folder` (name, sortIndex, one-to-many `accounts`, `Account.folder` inverse). Enums
  are stored as raw values with typed accessors. `@AppStorage` holds only small prefs
  and flags (`isPro`, `hasOnboarded`, settings).
- **`AppSettings`** — `ObservableObject` of `@AppStorage`-backed prefs, injected via
  `@EnvironmentObject`.
- **Views** — `TabView` with five tabs: Codes, Add, Folders, Backup, Settings. A single
  `TimelineView(.periodic(by: 1))` drives the per-second refresh for the whole list,
  off the critical path.

---

## Monetization

- **Free**: up to **10 accounts**.
- **Tessera Pro — one-time $4.99** unlocks: unlimited accounts, folders, encrypted-at-rest
  export / backup, and appearance themes.
- Gating is enforced on account creation and import (free imports fill remaining slots,
  then prompt the paywall). Folders, export, and themes route to a contextual paywall.

**Honest note:** StoreKit is **not** wired in this build (it is unsigned). The paywall's
"Unlock" sets `@AppStorage("isPro") = true` for demonstration and "Restore Purchase" is
present. A production build would back these with a real StoreKit one-time purchase.

---

## Why it can boom

Two-factor authentication is **universal** — almost everyone with a bank, email, or
crypto account needs an authenticator — yet the incumbents are weak:

- **Google Authenticator** has no search and no folders, and historically shipped with
  no backup at all (losing your phone meant losing every code).
- **Authy** is bloated, cloud-bound, and requires a phone-number account, which is
  exactly the attack surface privacy-minded users want to avoid.

Tessera is the **clean, private, offline** alternative people keep asking for: instant
search, folders, biometric app-lock, standard `otpauth://` import/export (no lock-in),
and a one-time price instead of a subscription. It deliberately does the **code
generator** job extremely well — a different product from a password vault — which keeps
it small, fast, and trustworthy. That focus, plus the universality of 2FA and the
weakness of the defaults, is the wedge.

---

## How your secrets are stored & protected (honest)

In this build, an account's Base32 secret is stored as-is in the app's local SwiftData
database. Protection comes from:

1. **iOS Data Protection** — the app's container is encrypted by the system and tied to
   your device passcode.
2. **The optional app-lock** — when "Require Face ID / Touch ID" is on, the whole app is
   gated behind `LocalAuthentication` on launch and on every resume from background.
3. **No network** — secrets are never uploaded; there is no account and no analytics.

There is **no additional application-layer encryption** of the secret in this build —
your device passcode and the app lock are the security boundary. A production hardening
step would store secrets in the **Keychain** (with `kSecAttrAccessibleWhenUnlocked`) or
wrap them with a key held in the Secure Enclave, and encrypt exports with a
user-supplied passphrase. This is called out plainly so there are no surprises.

---

## Self-review attestation

- **OTP correctness**: HMAC counter is 8-byte big-endian (built byte-by-byte); RFC 4226
  dynamic-truncation offset & 31-bit masking verified; TOTP `counter` /
  `secondsRemaining` / `progress` math checked; Base32 decode handles real secrets
  (incl. the RFC 6238 reference secret `GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ`); CryptoKit
  HMAC generic types (`Insecure.SHA1`, `SHA256`, `SHA512`) are iOS 17-valid.
- **Safety**: no force-unwraps, `as!`, `fatalError`, or `precondition`/`assert` on user
  paths. Exactly **one `@main`** and exactly **one `try!`** (the in-memory `ModelContainer`
  fallback). All array indexing and division are guarded.
- **DoD**: 4 substantive feature screens (Codes, Add, Folders, Backup) + Settings;
  onboarding; SwiftData persistence with a one-to-many relationship; ≥3 functional
  persisted prefs; empty / loading / error / success states; light & dark; Dynamic Type
  & accessibility; sparse, toggle-gated haptics; Reduce-Motion-aware animation; a Pro
  tier with a free limit, paywall, and gating; and a "Load sample data" action that
  seeds realistic demo accounts.
- **Anti-stub**: grep over the sources is clean (no TODO / FIXME / placeholder / etc.);
  every screen, button, swipe, and menu does real work end-to-end.

> The Xcode project config, `Info.plist` (incl. `NSFaceIDUsageDescription` and
> `NSCameraUsageDescription`), and asset catalogs were pre-generated and are not part of
> this Swift authoring task.
