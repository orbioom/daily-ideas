import SwiftData
import SwiftUI

/// Create a new notebook: title, cover color, default template, and an
/// optional folder. Honors free-tier limits via the paywall.
struct CreateNotebookSheet: View {
    /// Pre-selected folder when launched from a filtered library.
    let initialFolder: Folder?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro: Bool = false

    @Query(sort: \Folder.createdAt) private var folders: [Folder]

    @State private var title = ""
    @State private var colorHex: UInt = 0x4C63D8
    @State private var template: PaperTemplate = .ruled
    @State private var selectedFolder: Folder?
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g. Daily Journal", text: $title)
                        .font(Theme.rounded(17))
                        .accessibilityLabel("Notebook title")
                }

                Section("Cover Color") {
                    ColorPaletteView(
                        selectedHex: $colorHex,
                        isPro: isPro,
                        onLockedTap: { paywallReason = .lockedColor }
                    )
                }

                Section("Default Paper") {
                    ForEach(PaperTemplate.allCases) { t in
                        let locked = t.requiresPro && !isPro
                        Button {
                            if locked { paywallReason = .lockedTemplate(t) }
                            else { template = t }
                        } label: {
                            HStack {
                                Image(systemName: t.systemImage)
                                    .foregroundStyle(Theme.accent).frame(width: 28)
                                Text(t.title).foregroundStyle(Theme.ink)
                                Spacer()
                                if locked {
                                    Image(systemName: "lock.fill").foregroundStyle(Theme.inkFaint)
                                } else if template == t {
                                    Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                                }
                            }
                        }
                    }
                }

                if Pro.foldersUnlocked(isPro: isPro) && !folders.isEmpty {
                    Section("Folder") {
                        Picker("Folder", selection: $selectedFolder) {
                            Text("None").tag(Optional<Folder>.none)
                            ForEach(folders) { folder in
                                Text(folder.name).tag(Optional(folder))
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Notebook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") { create() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                template = settings.defaultTemplate
                if settings.defaultTemplate.requiresPro && !isPro {
                    template = .ruled
                }
                selectedFolder = initialFolder
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private func create() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let notebook = Notebook(
            title: trimmed,
            coverColorHex: colorHex.rgbHexString,
            defaultTemplate: template,
            folder: Pro.foldersUnlocked(isPro: isPro) ? selectedFolder : nil
        )
        context.insert(notebook)
        // Start with one empty page so the notebook is immediately usable.
        let firstPage = Page(orderIndex: 0, template: template, notebook: notebook)
        context.insert(firstPage)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
