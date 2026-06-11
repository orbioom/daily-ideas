import SwiftUI

/// First run: explain the model, then create the master passcode.
struct OnboardingView: View {
    @Bindable var store: VaultStore
    @State private var step = 0
    @State private var passcode = ""
    @State private var confirm = ""
    @State private var creating = false
    @State private var validationMessage: String?
    @FocusState private var focused: Bool

    private let intro: [(icon: String, title: String, message: String)] = [
        ("lock.shield", "A vault, not a service",
         "Hasp keeps your passwords in one encrypted file on this phone. No cloud, no account, no subscription, no company that can be breached."),
        ("key.horizontal", "One passcode rules it",
         "Everything is sealed with AES-256, with the key stretched from your master passcode. We can't recover it — that's the point. Choose something you'll remember."),
    ]

    var body: some View {
        ZStack {
            Theme.bgPrimary.ignoresSafeArea()
            if step < intro.count {
                introView
            } else {
                createView
            }
        }
    }

    private var introView: some View {
        VStack(spacing: 0) {
            TabView(selection: $step) {
                ForEach(Array(intro.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 22) {
                        Image(systemName: item.icon)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text(item.title)
                            .font(.largeTitle.weight(.bold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.textPrimary)
                        Text(item.message)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 32)
                    }
                    .tag(index)
                    .padding(.bottom, 60)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                withAnimation { step += 1 }
            } label: {
                Text(step < intro.count - 1 ? "Continue" : "Create my passcode")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private var createView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "key.horizontal.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Set your master passcode")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text("At least 8 characters. This is the only key to your vault — it cannot be reset or recovered.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                SecureField("Master passcode", text: $passcode)
                    .textContentType(.newPassword)
                    .focused($focused)
                    .padding(14)
                    .background(Theme.bgElevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("Master passcode")
                SecureField("Repeat passcode", text: $confirm)
                    .textContentType(.newPassword)
                    .padding(14)
                    .background(Theme.bgElevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("Repeat master passcode")
            }
            .padding(.horizontal, 24)

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(Theme.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            let bits = PasswordGenerator.entropyBits(for: passcode)
            if !passcode.isEmpty {
                let strength = PasswordGenerator.strengthLabel(bits: bits)
                VStack(spacing: 4) {
                    ProgressView(value: strength.fraction)
                        .tint(strength.fraction >= 0.75 ? Theme.ok : (strength.fraction >= 0.5 ? .yellow : Theme.danger))
                        .padding(.horizontal, 40)
                    Text(strength.label)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Passcode strength: \(strength.label)")
            }

            Spacer()

            Button {
                create()
            } label: {
                Group {
                    if creating {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("Sealing the vault…")
                        }
                    } else {
                        Text("Create vault")
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(creating)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .onAppear { focused = true }
    }

    private func create() {
        guard passcode.count >= 8 else {
            validationMessage = "Use at least 8 characters."
            Haptics.error()
            return
        }
        guard passcode == confirm else {
            validationMessage = "The two entries don't match."
            Haptics.error()
            return
        }
        validationMessage = nil
        creating = true
        // Key derivation is deliberately slow (600k PBKDF2 rounds); hop off
        // the next runloop tick so the spinner appears.
        Task { @MainActor in
            await Task.yield()
            store.createVault(passcode: passcode)
            creating = false
            if let err = store.lastError {
                validationMessage = err
                Haptics.error()
            } else {
                Haptics.success()
            }
        }
    }
}
