import SwiftData
import SwiftUI

/// Edit a notebook's title, cover color, and default template for new pages.
struct NotebookSettingsSheet: View {
    @Bindable var notebook: Notebook

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro: Bool = false

    @State private var draftTitle: String = ""
    @State private var selectedColorHex: UInt = 0x4C63D8
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Notebook title", text: $draftTitle)
                        .font(Theme.rounded(17))
                        .accessibilityLabel("Notebook title")
                }

                Section("Cover Color") {
                    ColorPaletteView(
                        selectedHex: $selectedColorHex,
                        isPro: isPro,
                        onLockedTap: { paywallReason = .lockedColor }
                    )
                }

                Section {
                    ForEach(PaperTemplate.allCases) { template in
                        let locked = template.requiresPro && !isPro
                        Button {
                            if locked {
                                paywallReason = .lockedTemplate(template)
                            } else {
                                notebook.defaultTemplate = template
                            }
                        } label: {
                            HStack {
                                Image(systemName: template.systemImage)
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 28)
                                Text(template.title).foregroundStyle(Theme.ink)
                                Spacer()
                                if locked {
                                    Image(systemName: "lock.fill").foregroundStyle(Theme.inkFaint)
                                } else if notebook.defaultTemplate == template {
                                    Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Default Paper For New Pages")
                }
            }
            .navigationTitle("Notebook Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(draftTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                draftTitle = notebook.title
                selectedColorHex = parseHex(notebook.coverColorHex)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private func parseHex(_ s: String) -> UInt {
        let scrubbed = s.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        return UInt(scrubbed, radix: 16) ?? 0x4C63D8
    }

    private func save() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        notebook.title = trimmed
        notebook.coverColorHex = selectedColorHex.rgbHexString
        notebook.updatedAt = .now
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
