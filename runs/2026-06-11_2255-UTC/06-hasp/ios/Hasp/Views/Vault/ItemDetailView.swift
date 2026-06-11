import SwiftUI

struct ItemDetailView: View {
    @Bindable var store: VaultStore
    let itemID: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var revealed = false
    @State private var copiedField: String?
    @State private var editing = false
    @State private var confirmDelete = false

    private var item: VaultItem? {
        store.vault.items.first { $0.id == itemID }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let item {
                    content(item)
                } else {
                    EmptyStateView(
                        icon: "trash",
                        title: "Item deleted",
                        message: "This item no longer exists in the vault."
                    )
                }
            }
            .background(Theme.bgPrimary)
            .navigationTitle(item?.title ?? "Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if item != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                editing = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                confirmDelete = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Item actions")
                    }
                }
            }
            .sheet(isPresented: $editing) {
                if let item {
                    ItemEditorView(store: store, existing: item)
                }
            }
            .alert("Delete this item?", isPresented: $confirmDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let item { store.delete(item) }
                    dismiss()
                }
            } message: {
                Text("This can't be undone — Hasp keeps no copies.")
            }
        }
    }

    private func content(_ item: VaultItem) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                header(item)

                VStack(spacing: 0) {
                    if !item.username.isEmpty {
                        fieldRow(label: item.usernameLabel, value: item.username, fieldKey: "username", monospaced: false)
                        Divider()
                    }
                    secretRow(item)
                    if !item.detail.isEmpty {
                        Divider()
                        fieldRow(label: item.detailLabel, value: item.detail, fieldKey: "detail", monospaced: false)
                    }
                }
                .haspCard()

                if !item.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Text(item.notes)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .haspCard()
                }

                Text("Created \(item.createdAt.formatted(date: .abbreviated, time: .omitted)) · updated \(item.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(16)
        }
    }

    private func header(_ item: VaultItem) -> some View {
        VStack(spacing: 8) {
            Image(systemName: item.kind.icon)
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: 54, height: 54)
                .background(Theme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)
            Text(item.kind.label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func secretRow(_ item: VaultItem) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.secretLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text(revealed ? item.secret : String(repeating: "•", count: min(14, max(6, item.secret.count))))
                    .font(.body.monospaced())
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(revealed ? nil : 1)
                    .textSelection(.enabled)
                    .accessibilityLabel(revealed ? "Secret revealed" : "Secret hidden")
            }
            Spacer()
            Button {
                revealed.toggle()
                Haptics.tap()
            } label: {
                Image(systemName: revealed ? "eye.slash" : "eye")
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityLabel(revealed ? "Hide secret" : "Reveal secret")
            copyButton(value: item.secret, fieldKey: "secret")
        }
        .padding(.vertical, 8)
    }

    private func fieldRow(label: String, value: String, fieldKey: String, monospaced: Bool) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text(value)
                    .font(monospaced ? .body.monospaced() : .body)
                    .foregroundStyle(Theme.textPrimary)
                    .textSelection(.enabled)
            }
            Spacer()
            copyButton(value: value, fieldKey: fieldKey)
        }
        .padding(.vertical, 8)
    }

    private func copyButton(value: String, fieldKey: String) -> some View {
        Button {
            UIPasteboard.general.string = value
            copiedField = fieldKey
            Haptics.success()
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                if copiedField == fieldKey { copiedField = nil }
            }
        } label: {
            Image(systemName: copiedField == fieldKey ? "checkmark" : "doc.on.doc")
                .foregroundStyle(copiedField == fieldKey ? Theme.ok : Theme.accent)
        }
        .accessibilityLabel(copiedField == fieldKey ? "Copied" : "Copy")
    }
}
