import SwiftData
import SwiftUI

/// Create, rename, and delete folders (a Pro feature). Deleting a folder
/// nullifies its notebooks' folder reference (notebooks are kept).
struct FolderManagerSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \Folder.createdAt) private var folders: [Folder]

    @State private var newName = ""
    @State private var newColorHex: UInt = 0x4C63D8

    var body: some View {
        NavigationStack {
            Form {
                Section("New Folder") {
                    TextField("Folder name", text: $newName)
                        .accessibilityLabel("Folder name")
                    ColorPaletteView(selectedHex: $newColorHex, isPro: true)
                    Button {
                        addFolder()
                    } label: {
                        Label("Add Folder", systemImage: "plus")
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Section("Folders") {
                    if folders.isEmpty {
                        Text("No folders yet.")
                            .foregroundStyle(Theme.inkSoft)
                    } else {
                        ForEach(folders) { folder in
                            HStack {
                                Circle()
                                    .fill(Color(hexString: folder.colorHex))
                                    .frame(width: 14, height: 14)
                                Text(folder.name).foregroundStyle(Theme.ink)
                                Spacer()
                                Text("\(folder.notebooks.count)")
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(folder.name), \(folder.notebooks.count) notebooks")
                        }
                        .onDelete(perform: deleteFolders)
                    }
                }
            }
            .navigationTitle("Folders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func addFolder() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let folder = Folder(name: trimmed, colorHex: newColorHex.rgbHexString)
        context.insert(folder)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        newName = ""
    }

    private func deleteFolders(at offsets: IndexSet) {
        for index in offsets where index < folders.count {
            context.delete(folders[index])
        }
        try? context.save()
        Haptics.warning(settings.hapticsEnabled)
    }
}
