import SwiftUI

struct LockView: View {
    @Bindable var store: VaultStore
    @State private var passcode = ""
    @State private var unlocking = false
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Theme.bgPrimary.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Hasp is locked")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)

                SecureField("Master passcode", text: $passcode)
                    .textContentType(.password)
                    .focused($focused)
                    .submitLabel(.go)
                    .onSubmit(unlock)
                    .padding(14)
                    .background(Theme.bgElevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 32)
                    .accessibilityLabel("Master passcode")

                if let error = store.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Theme.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                if store.failedAttempts >= 3 {
                    Text("\(store.failedAttempts) failed attempts. There is no recovery passcode — only the right one opens the vault.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Button {
                    unlock()
                } label: {
                    Group {
                        if unlocking {
                            HStack(spacing: 10) {
                                ProgressView().tint(.white)
                                Text("Unlocking…")
                            }
                        } else {
                            Text("Unlock")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(unlocking || passcode.isEmpty)
                .padding(.horizontal, 32)

                if store.biometricsEnabled {
                    Button {
                        Task { _ = await store.unlockWithBiometrics() }
                    } label: {
                        Label("Unlock with Face ID", systemImage: "faceid")
                            .font(.subheadline.weight(.semibold))
                    }
                    .accessibilityHint("Uses Face ID or Touch ID instead of the passcode")
                }
                Spacer()
                Text("Vault file: AES-256-GCM · key never leaves this device")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
                    .padding(.bottom, 12)
            }
        }
        .onAppear {
            focused = true
            if store.biometricsEnabled {
                Task { _ = await store.unlockWithBiometrics() }
            }
        }
    }

    private func unlock() {
        guard !passcode.isEmpty else { return }
        unlocking = true
        Task { @MainActor in
            await Task.yield()
            let ok = store.unlock(passcode: passcode)
            unlocking = false
            if ok {
                passcode = ""
                Haptics.success()
            } else {
                Haptics.error()
            }
        }
    }
}
