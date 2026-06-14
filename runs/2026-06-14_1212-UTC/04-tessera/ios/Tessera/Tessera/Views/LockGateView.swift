import SwiftUI

/// Gates its content behind biometric/passcode auth when `requireBiometrics` is on.
/// Locks on launch and whenever the app returns from background. When the setting
/// is off, content shows immediately.
struct LockGateView<Content: View>: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase

    /// nil = not yet decided; true = unlocked; false = locked.
    @State private var unlocked: Bool? = nil
    @State private var authInProgress = false
    @State private var lastFailed = false

    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            // Always build content so SwiftData/state stays alive, but cover it
            // when locked.
            content()
                .allowsHitTesting(isOpen)
                .accessibilityHidden(!isOpen)

            if !isOpen {
                lockedOverlay
                    .transition(.opacity)
            }
        }
        .onAppear { evaluateInitial() }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhase(phase)
        }
        .onChange(of: settings.requireBiometrics) { _, requires in
            // Turning the lock off should immediately reveal the app.
            if !requires { unlocked = true } else { unlocked = false; attempt() }
        }
    }

    private var isOpen: Bool {
        if !settings.requireBiometrics { return true }
        return unlocked == true
    }

    private var lockedOverlay: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Tessera is locked")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                Text(lastFailed
                     ? "Authentication didn't succeed. Tap Unlock to try again."
                     : "Use \(BiometricAuth.biometryName()) to view your codes.")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                Spacer()
                Button {
                    attempt()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "faceid")
                        Text("Unlock")
                    }
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.accent))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .disabled(authInProgress)
                .accessibilityLabel("Unlock with \(BiometricAuth.biometryName())")
            }
        }
    }

    // MARK: - Logic

    private func evaluateInitial() {
        guard settings.requireBiometrics else { unlocked = true; return }
        if unlocked == nil {
            unlocked = false
            attempt()
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        guard settings.requireBiometrics else { return }
        switch phase {
        case .background:
            // Re-lock when leaving the app.
            unlocked = false
        case .active:
            if unlocked != true && !authInProgress {
                attempt()
            }
        default:
            break
        }
    }

    private func attempt() {
        guard settings.requireBiometrics else { unlocked = true; return }
        guard !authInProgress else { return }
        authInProgress = true
        BiometricAuth.authenticate(reason: "Unlock Tessera to view your codes") { success in
            authInProgress = false
            lastFailed = !success
            withAnimation(.easeInOut(duration: 0.25)) {
                unlocked = success
            }
        }
    }
}
