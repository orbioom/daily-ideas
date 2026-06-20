import SwiftUI
import LocalAuthentication

struct LockScreenView: View {
    @Query private var settingsQ: [VaultSettings]
    let onUnlock: () -> Void

    @State private var pin = ""
    @State private var showPIN = false
    @State private var error = ""
    @State private var shake = false

    private var settings: VaultSettings? { settingsQ.first }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64))
                        .foregroundColor(VaultTheme.gold)
                        .accessibilityHidden(true)
                    Text("Vault")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    Text("Your private photos are locked")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }

                if showPIN {
                    pinEntry
                }

                Spacer()

                VStack(spacing: 12) {
                    if settings?.useBiometrics == true {
                        Button(action: authenticateWithBiometrics) {
                            Label("Use Face ID / Touch ID", systemImage: "faceid")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(VaultTheme.accent))
                        }
                        .accessibilityLabel("Unlock with Face ID or Touch ID")
                        .padding(.horizontal, 32)
                    }

                    Button(action: { showPIN.toggle(); pin = ""; error = "" }) {
                        Text(showPIN ? "Hide PIN" : "Use PIN Instead")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .accessibilityLabel(showPIN ? "Hide PIN entry" : "Enter PIN instead")
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            if settings?.useBiometrics == true { authenticateWithBiometrics() }
        }
    }

    private var pinEntry: some View {
        VStack(spacing: 20) {
            // PIN dots
            HStack(spacing: 16) {
                ForEach(0..<4) { i in
                    Circle()
                        .fill(i < pin.count ? VaultTheme.gold : Color.white.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
            .offset(x: shake ? -10 : 0)
            .animation(shake ? .default.repeatCount(4, autoreverses: true).speed(4) : .default, value: shake)
            .accessibilityLabel("PIN entry: \(pin.count) of 4 digits entered")

            if !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .accessibilityLabel(error)
            }

            // Keypad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(["1","2","3","4","5","6","7","8","9","","0","⌫"], id: \.self) { key in
                    if key.isEmpty {
                        Color.clear.frame(height: 64)
                    } else {
                        Button(action: { handleKey(key) }) {
                            Text(key)
                                .font(.title.weight(.medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 64)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                        .accessibilityLabel(key == "⌫" ? "Delete" : key)
                    }
                }
            }
            .padding(.horizontal, 48)
        }
    }

    private func handleKey(_ key: String) {
        if key == "⌫" {
            if !pin.isEmpty { pin.removeLast() }
        } else if pin.count < 4 {
            pin.append(key)
            if pin.count == 4 { verifyPIN() }
        }
    }

    private func verifyPIN() {
        guard let settings else { return }
        if pin.vaultPINHash() == settings.pinHash {
            onUnlock()
        } else {
            error = "Incorrect PIN"
            shake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false; pin = "" }
        }
    }

    private func authenticateWithBiometrics() {
        let ctx = LAContext()
        var authError: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            showPIN = true
            return
        }
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock Vault to access your private photos") { success, _ in
            DispatchQueue.main.async {
                if success { onUnlock() } else { showPIN = true }
            }
        }
    }
}
