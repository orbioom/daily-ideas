import SwiftUI
import SwiftData

struct FoldersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Folder.name) private var folders: [Folder]

    @State private var addingFolder = false
    @State private var folderName = ""
    @State private var renamingFolder: Folder?

    private let iconChoices = ["folder", "doc.text", "creditcard", "house", "briefcase", "heart.text.square", "car", "graduationcap", "airplane", "pawprint"]

    var body: some View {
        NavigationStack {
            Group {
                if folders.isEmpty {
                    EmptyStateView(
                        icon: "folder.badge.plus",
                        title: "No folders yet",
                        message: "Folders keep receipts, contracts, medical records and IDs apart. Documents outside a folder still live in the Library."
                    )
                } else {
                    List {
                        ForEach(folders) { folder in
                            NavigationLink(value: folder) {
                                HStack(spacing: 12) {
                                    Image(systemName: folder.icon)
                                        .foregroundStyle(Theme.accent)
                                        .frame(width: 28)
                                        .accessibilityHidden(true)
                                    Text(folder.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text("\(folder.documents.count)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                            .listRowBackground(Theme.bgElevated)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    context.delete(folder)   // documents are nullified, not deleted
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    folderName = folder.name
                                    renamingFolder = folder
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(Theme.accent)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Folders")
            .navigationDestination(for: Folder.self) { folder in
                FolderContentsView(folder: folder)
            }
            .navigationDestination(for: ScanDocument.self) { document in
                DocumentDetailView(document: document)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        folderName = ""
                        addingFolder = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    .accessibilityLabel("New folder")
                }
            }
            .alert("New folder", isPresented: $addingFolder) {
                TextField("Name", text: $folderName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    let trimmed = folderName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    let icon = iconChoices[abs(trimmed.hashValue) % iconChoices.count]
                    context.insert(Folder(name: trimmed, icon: icon))
                    Haptics.success()
                }
            }
            .alert("Rename folder", isPresented: Binding(
                get: { renamingFolder != nil },
                set: { if !$0 { renamingFolder = nil } }
            )) {
                TextField("Name", text: $folderName)
                Button("Cancel", role: .cancel) { renamingFolder = nil }
                Button("Save") {
                    let trimmed = folderName.trimmingCharacters(in: .whitespaces)
                    if let folder = renamingFolder, !trimmed.isEmpty {
                        folder.name = trimmed
                    }
                    renamingFolder = nil
                }
            }
        }
    }
}

struct FolderContentsView: View {
    let folder: Folder

    private var documents: [ScanDocument] {
        folder.documents.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        Group {
            if documents.isEmpty {
                EmptyStateView(
                    icon: folder.icon,
                    title: "Empty folder",
                    message: "Move documents here from a document's ••• menu in the Library."
                )
            } else {
                List(documents) { document in
                    NavigationLink(value: document) {
                        DocumentRowView(document: document)
                    }
                    .listRowBackground(Theme.bgElevated)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Theme.bgPrimary)
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
