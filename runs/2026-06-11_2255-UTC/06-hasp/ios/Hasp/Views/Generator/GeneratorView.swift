import SwiftUI

struct GeneratorView: View {
    @Bindable var store: VaultStore
    @State private var options = PasswordGenerator.Options()
    @State private var password = ""
    @State private var copied = false
    @State private var savingToItem = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    passwordCard
                    optionsCard
                }
                .padding(16)
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Generator")
            .onAppear {
                if password.isEmpty { regenerate() }
            }
            .sheet(isPresented: $savingToItem) {
                ItemEditorView(store: store, existing: prefilledLogin)
            }
        }
    }

    /// A fresh login item carrying the generated password into the editor.
    private var prefilledLogin: VaultItem {
        var draft = VaultItem()
        draft.kind = .login
        draft.secret = password
        return draft
    }

    private var passwordCard: some View {
        let bits = PasswordGenerator.entropyBits(for: password)
        let strength = PasswordGenerator.strengthLabel(bits: bits)
        return VStack(spacing: 14) {
            Text(password.isEmpty ? "Enable at least one character set" : password)
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .foregroundStyle(password.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 70)
                .accessibilityLabel(password.isEmpty ? "No password generated" : "Generated password")

            if !password.isEmpty {
                HStack(spacing: 8) {
                    ProgressView(value: strength.fraction)
                        .tint(strength.fraction >= 0.75 ? Theme.ok : (strength.fraction >= 0.5 ? .yellow : Theme.danger))
                    Text("\(strength.label) · ~\(Int(bits)) bits")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize()
                }
                .accessibilityElement(children: .combine)
            }

            HStack(spacing: 12) {
                Button {
                    regenerate()
                } label: {
                    Label("New", systemImage: "dice")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                Button {
                    guard !password.isEmpty else { return }
                    UIPasteboard.general.string = password
                    copied = true
                    Haptics.success()
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2))
                        copied = false
                    }
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white)
                }
                .disabled(password.isEmpty)
            }
            Button {
                guard !password.isEmpty else { return }
                savingToItem = true
            } label: {
                Label("Save as a new login", systemImage: "plus.rectangle.on.rectangle")
                    .font(.subheadline.weight(.semibold))
            }
            .disabled(password.isEmpty)
            .accessibilityHint("Opens a new vault item pre-filled with this password")
        }
        .haspCard()
    }

    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Length")
                    Spacer()
                    Text("\(options.length)")
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                }
                .font(.subheadline)
                Slider(value: Binding(
                    get: { Double(options.length) },
                    set: { options.length = Int($0); regenerate() }
                ), in: 8...64, step: 1)
                    .accessibilityLabel("Password length")
                    .accessibilityValue("\(options.length) characters")
            }
            Toggle("Lowercase (abc)", isOn: bind(\.lowercase))
            Toggle("Uppercase (ABC)", isOn: bind(\.uppercase))
            Toggle("Digits (123)", isOn: bind(\.digits))
            Toggle("Symbols (#$%)", isOn: bind(\.symbols))
            Toggle("Skip look-alikes (l, 1, O, 0)", isOn: bind(\.excludeAmbiguous))
        }
        .haspCard()
    }

    private func bind(_ keyPath: WritableKeyPath<PasswordGenerator.Options, Bool>) -> Binding<Bool> {
        Binding(
            get: { options[keyPath: keyPath] },
            set: { options[keyPath: keyPath] = $0; regenerate() }
        )
    }

    private func regenerate() {
        password = PasswordGenerator.generate(options)
        if !password.isEmpty { Haptics.tap() }
    }
}
