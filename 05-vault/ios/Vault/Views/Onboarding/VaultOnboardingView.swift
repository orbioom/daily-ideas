import SwiftUI
import SwiftData
import LocalAuthentication

struct VaultOnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsQ: [VaultSettings]
    @State private var step = 0
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var pinError = ""
    @State private var useBiometrics = true
    @State private var biometricsAvailable = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i == step ? VaultTheme.gold : Color.white.opacity(0.25))
                            .frame(width: i == step ? 24 : 8, height: 8)
                            .animation(.spring(), value: step)
                    }
                }
                .padding(.top, 60)
                .accessibilityLabel("Step \(step+1) of 3")

                Spacer()

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: pinStep
                    default: biometricsStep
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .animation(.spring(response: 0.4), value: step)

                Spacer()

                Button(action: advance) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(step == 0 ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(step == 0 ? VaultTheme.gold : VaultTheme.accent))
                }
                .disabled(step == 1 && (pin.count < 4 || confirmPin.count < 4))
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .accessibilityLabel(buttonTitle)
            }
        }
        .onAppear {
            let ctx = LAContext()
            var err: NSError?
            biometricsAvailable = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
        }
    }

    private var buttonTitle: String {
        switch step {
        case 0: return "Set Up Vault"
        case 1: return pinError.isEmpty ? "Confirm PIN" : "Try Again"
        default: return "Enter Vault"
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(VaultTheme.gold)
                .accessibilityHidden(true)
            Text("Your Private Vault")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            Text("Store photos privately on your device.\nProtected by Face ID, Touch ID, or PIN.\nNothing ever leaves your phone.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private var pinStep: some View {
        VStack(spacing: 24) {
            Text(confirmPin.isEmpty ? "Create a PIN" : "Confirm your PIN")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            if !pinError.isEmpty {
                Text(pinError).font(.caption).foregroundColor(.red)
                    .accessibilityLabel(pinError)
            }

            let activePin = confirmPin.isEmpty ? pin : confirmPin
            HStack(spacing: 16) {
                ForEach(0..<4) { i in
                    Circle()
                        .fill(i < activePin.count ? VaultTheme.gold : Color.white.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
            .accessibilityLabel("PIN: \(activePin.count) of 4 digits")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(["1","2","3","4","5","6","7","8","9","","0","⌫"], id: \.self) { key in
                    if key.isEmpty {
                        Color.clear.frame(height: 60)
                    } else {
                        Button(action: { handlePINKey(key) }) {
                            Text(key)
                                .font(.title.weight(.medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                        .accessibilityLabel(key == "⌫" ? "Delete" : key)
                    }
                }
            }
            .padding(.horizontal, 48)
        }
    }

    private var biometricsStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "faceid")
                .font(.system(size: 80))
                .foregroundColor(VaultTheme.accent)
                .accessibilityHidden(true)
            Text("Quick Unlock")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Text("Use Face ID or Touch ID to unlock Vault instantly — no PIN typing needed.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if biometricsAvailable {
                Toggle("Enable Biometric Unlock", isOn: $useBiometrics)
                    .labelsHidden()
                    .accessibilityLabel("Enable biometric unlock")
                    .tint(VaultTheme.accent)
            }
        }
    }

    private func handlePINKey(_ key: String) {
        pinError = ""
        if confirmPin.isEmpty {
            if key == "⌫" { if !pin.isEmpty { pin.removeLast() } }
            else if pin.count < 4 { pin.append(key) }
        } else {
            if key == "⌫" { if !confirmPin.isEmpty { confirmPin.removeLast() } }
            else if confirmPin.count < 4 { confirmPin.append(key) }
        }
    }

    private func advance() {
        switch step {
        case 0: step = 1
        case 1:
            if confirmPin.isEmpty {
                guard pin.count == 4 else { return }
                confirmPin = ""
                // show confirm
                let savedPin = pin; pin = ""
                pin = ""
                confirmPin = ""
                // Re-enter flow: set pin = savedPin to compare on next press
                pin = savedPin
                // Trick: we use confirmPin field now — reset and let user re-enter
                pin = savedPin
            } else {
                if pin == confirmPin {
                    step = 2
                } else {
                    pinError = "PINs don't match. Try again."
                    pin = ""; confirmPin = ""
                }
            }
        default:
            complete()
        }
    }

    private func complete() {
        let s = settingsQ.first ?? { let ns = VaultSettings(); context.insert(ns); return ns }()
        s.pinHash = pin.vaultPINHash()
        s.useBiometrics = useBiometrics && biometricsAvailable
        s.onboardingComplete = true
        try? context.save()

        // Create a default album
        let defaultAlbum = VaultAlbum(name: "My Photos", emoji: "📷")
        defaultAlbum.sortOrder = 0
        context.insert(defaultAlbum)
        try? context.save()
    }
}
