import SwiftUI

struct ItemEditorView: View {
    @Bindable var store: VaultStore
    let existing: VaultItem?

    @Environment(\.dismiss) private var dismiss
    @State private var draft = VaultItem()
    @State private var validationMessage: String?
    @State private var showSecret = false

    /// True when the item isn't in the vault yet (brand new or prefilled
    /// from the generator).
    private var isNew: Bool {
        guard let existing else { return true }
        return !store.vault.items.contains { $0.id == existing.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $draft.kind) {
                        ForEach(ItemKind.allCases) { kind in
                            Label(kind.label, systemImage: kind.icon).tag(kind)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(existing != nil)
                }

                Section("Details") {
                    TextField("Title (e.g. \(draft.kind == .card ? "Visa ••• 4821" : "GitHub"))", text: $draft.title)
                        .accessibilityLabel("Title")
                    if draft.kind != .note {
                        TextField(draft.usernameLabel, text: $draft.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityLabel(draft.usernameLabel)
                    }
                    HStack {
                        Group {
                            if showSecret || draft.kind == .note {
                                TextField(draft.secretLabel, text: $draft.secret, axis: draft.kind == .note ? .vertical : .horizontal)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField(draft.secretLabel, text: $draft.secret)
                            }
                        }
                        .accessibilityLabel(draft.secretLabel)
                        if draft.kind != .note {
                            Button {
                                showSecret.toggle()
                            } label: {
                                Image(systemName: showSecret ? "eye.slash" : "eye")
                                    .foregroundStyle(Theme.accent)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(showSecret ? "Hide" : "Show")
                        }
                    }
                    if draft.kind == .login {
                        Button {
                            draft.secret = PasswordGenerator.generate(.init())
                            showSecret = true
                            Haptics.tap()
                        } label: {
                            Label("Generate a strong password", systemImage: "dice")
                                .font(.subheadline)
                        }
                    }
                    if draft.kind != .note {
                        TextField(draft.detailLabel, text: $draft.detail)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityLabel(draft.detailLabel)
                    }
                }

                if draft.kind == .login, !draft.secret.isEmpty {
                    Section("Strength") {
                        let bits = PasswordGenerator.entropyBits(for: draft.secret)
                        let strength = PasswordGenerator.strengthLabel(bits: bits)
                        HStack {
                            ProgressView(value: strength.fraction)
                                .tint(strength.fraction >= 0.75 ? Theme.ok : (strength.fraction >= 0.5 ? .yellow : Theme.danger))
                            Text("\(strength.label) · ~\(Int(bits)) bits")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Password strength \(strength.label)")
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section {
                    Toggle("Favorite", isOn: $draft.isFavorite)
                }
            }
            .navigationTitle(existing == nil ? "New item" : "Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Can't save yet", isPresented: Binding(
                get: { validationMessage != nil },
                set: { if !$0 { validationMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage ?? "")
            }
            .onAppear {
                if let existing { draft = existing }
            }
        }
    }

    private func save() {
        let title = draft.title.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else {
            validationMessage = "Give the item a title."
            return
        }
        guard !draft.secret.isEmpty else {
            validationMessage = "The \(draft.secretLabel.lowercased()) can't be empty — it's the thing being protected."
            return
        }
        draft.title = title
        store.upsert(draft)
        if store.lastError == nil {
            Haptics.success()
            dismiss()
        } else {
            validationMessage = store.lastError
        }
    }
}
