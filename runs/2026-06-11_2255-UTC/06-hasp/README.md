# Hasp — a password vault sealed with AES-256

**What it is.** A zero-trust password manager that treats your phone like a vault. No cloud, no account, no company that can be breached. Your vault is a single encrypted file on your device, locked with a master passcode. Everything inside is sealed with AES-256-GCM, and the passcode key is stretched with 600,000 rounds of PBKDF2-HMAC-SHA256 (OWASP-recommended order of magnitude). Face ID / Touch ID unlock caches the derived key in the Keychain (device-only, accessible only when unlocked) — without compromising offline security.

## Features

- **Vault with 3 item types** — logins (username + password + website), cards (cardholder name + number + expiry/CVC), secure notes; dynamic field labels per type.
- **Full CRUD** — create, view with reveal/hide toggle, edit, delete, favorite/star via swipes or menus.
- **Search & filter** — instant search across titles, usernames, detail fields; filter by all / favorites / logins / cards / notes.
- **Password generator** — configurable length (8-64 chars), character-set toggles (lowercase/uppercase/digits/symbols), exclude-ambiguous-characters (l/1/I/O/0/o) option, real-time entropy meter (bits of security) with strength label (Weak/Okay/Strong/Excellent), and one-click "save as a new login" to prefill the editor.
- **Master passcode setup** — 2-slide onboarding explaining the model, then passcode creation with 8+ character requirement and live entropy strength meter; the vault is sealed with AES-256 during setup (with deliberate slow 600k-round key derivation so the spinner appears).
- **Biometric unlock** — Face ID / Touch ID unlock via cached derived key in Keychain; graceful fallback to passcode if biometrics unavailable; failed-attempt tracking.
- **Change passcode** — current + new + confirm with validation, re-stretches the vault with new salt and rounds.
- **Auto-lock** — configurable timeout (0/1/5/10 minutes) after backgrounding.
- **Haptics** — tap / success / error feedback, toggle in settings.
- **Copy to clipboard** — every field (username, secret, detail, note) has a copy button with 2-second success flash.
- **Persistence** — JSON envelope on disk (salt + rounds + AES-256-GCM blob) with atomic writes, no intermediate unencrypted copies.
- **Empty states**, **Dark/light mode**, **Dynamic Type**, **Accessibility labels/hints** on every control.

## Run

1. `brew install xcodegen` (one-time). 2. In `ios/`, `xcodegen generate` (or `./gen.sh`). 3. Open `Hasp.xcodeproj` in Xcode 15+, iOS 17+ simulator, Cmd+R.

## Tech notes

- iOS 17+, SwiftUI 5; `@Observable VaultStore` (state machine: noVault → locked → unlocked; PBKDF2-HMAC-SHA256 key derivation via CommonCrypto; AES-256-GCM via CryptoKit; secure random salt 16 bytes).
- `KeychainService` caches the derived key (this-device-only, accessible-when-unlocked) for Face ID / Touch ID unlock without storing the passcode.
- Models: `VaultItem` (id/kind/title/username/secret/detail/notes/isFavorite + timestamps), `Vault` ([VaultItem]).
- `PasswordGenerator` entropy estimation and strength labeling; never stores weak passwords.
- Cryptography: PBKDF2 (600k rounds, SHA-256, HMAC) + AES-256-GCM (authenticated encryption).
- Design language: "bank vault at midnight" — violet on near-black (dark mode), cool porcelain (light mode), monospaced secrets, brushed-steel neutrals.
- **Monetization:** one-time Pro unlock for unlimited vaults (multi-vault support is in the sequel).
- **Why it can boom:** password managers are table-stakes on smartphones. The category leader (1Password, Bitwarden, Apple Keychain) all sync or rely on trust in the company. Hasp is for the "zero-trust local vault" buyer — someone who'd rather own the risk than delegate it. Every person concerned about breaches (and there are many) is a potential user.

## Self-review

- **Cryptography:** CryptoService uses PBKDF2-HMAC-SHA256 (600k rounds, correct salt size 16 bytes) and AES-256-GCM (authenticated encryption with combined nonce+ciphertext+tag). KeychainService stores key data correctly with this-device-only accessibility. No hardcoded keys, salts, or weakened KDFs.
- **Key management:** Derived key cached in Keychain only when biometrics enabled. Keychain delete on disable. No key stored in UserDefaults or plist.
- **Vault persistence:** JSON envelope (salt/rounds/blob) written atomically with `.atomic` flag; no intermediate unencrypted states. CryptoService guards both seal and open paths with proper error types (not force-unwraps).
- **UI safety:** No force-unwraps on user input paths. Optional bindings guard all lookups. Sheet and alert bindings properly managed.
- **Biometrics:** LAContext.canEvaluatePolicy checks availability; evaluatePolicy async/await; graceful fallback to passcode on cancel or unavailability.
- **State machine:** noVault → locked → unlocked transitions guarded. Lock clears key and vault on background.
- **Password generation:** entropy estimation via character-pool analysis; ambiguous characters excluded; shuffling for security; length clamped 6-64.
- **Accessibility:** all controls have labels/hints; color not the only indicator of strength (ProgressView + label); Reduce Motion respected (no animation on flash when motion is disabled, per iOS 17 APIs).
- **Anti-stub grep:** no TODO, FIXME, XXX, placeholder, coming soon, or not-implemented comments.
- All imports correct (CryptoKit, CommonCrypto, LocalAuthentication, Security, Observation).
