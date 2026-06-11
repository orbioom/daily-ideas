import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @Bindable var store: VaultStore
    @AppStorage("autoLockMinutes") private var autoLockMinutes = 5
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @State private var showChangePasscode = false
    @State private var oldPasscode = ""
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var changePasscodeMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Security") {
                    Picker("Auto-lock after", selection: $autoLockMinutes) {
                        Text("Never").tag(0)
                        Text("1 minute").tag(1)
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                    }

                    Toggle("Face ID / Touch ID", isOn: $store.biometricsEnabled)
                        .disabled(!isBiometricsAvailable)
                }

                Section("Behavior") {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }

                Section {
                    Button("Change Master Passcode") {
                        showChangePasscode = true
                    }
                    .foregroundStyle(Theme.accent)
                } footer: {
                    Text("Your passcode cannot be recovered. Choose one you'll remember.")
                }

                Section("Privacy") {
                    Text("Hasp keeps all your data on this device. Nothing leaves your iPhone — not even an encrypted copy. Your vault is sealed with AES-256-GCM and never synced, shared, or backed up anywhere.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showChangePasscode) {
                changePasscodeSheet
            }
        }
    }

    private var changePasscodeSheet: some View {
        NavigationStack {
            Form {
                Section("Current Passcode") {
                    SecureField("Master passcode", text: $oldPasscode)
                        .textContentType(.password)
                        .accessibilityLabel("Current passcode")
                }

                Section("New Passcode") {
                    SecureField("New master passcode", text: $newPasscode)
                        .textContentType(.password)
                        .accessibilityLabel("New passcode")
                    SecureField("Confirm new passcode", text: $confirmPasscode)
                        .textContentType(.password)
                        .accessibilityLabel("Confirm new passcode")
                }

                if let message = changePasscodeMessage {
                    Section {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(message.contains("successfully") ? Theme.ok : Theme.danger)
                    }
                }
            }
            .navigationTitle("Change Passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetForm()
                        showChangePasscode = false
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveNewPasscode()
                    }
                    .disabled(newPasscode.isEmpty || confirmPasscode.isEmpty || oldPasscode.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveNewPasscode() {
        guard !newPasscode.isEmpty else {
            changePasscodeMessage = "Enter a new passcode."
            return
        }
        guard newPasscode == confirmPasscode else {
            changePasscodeMessage = "New passcodes don't match."
            return
        }
        guard newPasscode.count >= 4 else {
            changePasscodeMessage = "Passcode must be at least 4 characters."
            return
        }

        if store.changePasscode(current: oldPasscode, new: newPasscode) {
            changePasscodeMessage = "Passcode changed successfully."
            Haptics.success()
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                resetForm()
                showChangePasscode = false
            }
        } else {
            changePasscodeMessage = store.lastError ?? "Failed to change passcode."
            Haptics.error()
        }
    }

    private func resetForm() {
        oldPasscode = ""
        newPasscode = ""
        confirmPasscode = ""
        changePasscodeMessage = nil
    }

    private var isBiometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
