import SwiftUI
import SwiftData

struct FoldersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    @Query private var notes: [Note]
    @State private var path = NavigationPath()
    @State private var showAdd = false
    @State private var editingFolder: Folder?

    private func count(_ folder: Folder) -> Int {
        notes.filter { $0.folder?.persistentModelID == folder.persistentModelID && !$0.isArchived }.count
    }
    private var unfiled: Int { notes.filter { $0.folder == nil && !$0.isArchived }.count }
    private var archived: Int { notes.filter { $0.isArchived }.count }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if folders.isEmpty {
                    EmptyState(icon: "folder.badge.plus",
                               title: "No folders yet",
                               message: "Folders keep your notes organized by project, theme, or mood.",
                               actionTitle: "New folder") { showAdd = true }
                } else {
                    List {
                        Section {
                            ForEach(folders) { folder in
                                NavigationLink(value: FolderRoute.folder(folder)) {
                                    folderRow(symbol: folder.symbol, color: folder.colorIndex,
                                              name: folder.name, count: count(folder))
                                }
                                .listRowBackground(Theme.surface)
                                .swipeActions {
                                    Button(role: .destructive) { context.delete(folder) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button { editingFolder = folder } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }.tint(Theme.accent)
                                }
                            }
                        }
                        Section {
                            NavigationLink(value: FolderRoute.unfiled) {
                                folderRow(symbol: "tray", color: 0, name: "Unfiled", count: unfiled)
                            }.listRowBackground(Theme.surface)
                            NavigationLink(value: FolderRoute.archived) {
                                folderRow(symbol: "archivebox", color: 0, name: "Archived", count: archived)
                            }.listRowBackground(Theme.surface)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Folders")
            .navigationDestination(for: FolderRoute.self) { route in
                FilteredNotesView(route: route, path: $path)
            }
            .navigationDestination(for: Note.self) { note in
                NoteDetailView(note: note, path: $path)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "folder.badge.plus") }
                        .accessibilityLabel("New folder")
                }
            }
            .sheet(isPresented: $showAdd) { FolderEditSheet(folder: nil) }
            .sheet(item: $editingFolder) { FolderEditSheet(folder: $0) }
        }
    }

    private func folderRow(symbol: String, color: Int, name: String, count: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(color == 0 ? Theme.inkSoft : Theme.tagColor(color))
                .frame(width: 26)
            Text(name).font(.system(size: 16)).foregroundStyle(Theme.ink)
            Spacer()
            Text("\(count)").font(.system(size: 15)).foregroundStyle(Theme.inkFaint).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(count) notes")
    }
}

enum FolderRoute: Hashable {
    case folder(Folder)
    case unfiled
    case archived
}

struct FilteredNotesView: View {
    let route: FolderRoute
    @Binding var path: NavigationPath
    @Query private var notes: [Note]

    private var title: String {
        switch route {
        case .folder(let f): return f.name
        case .unfiled: return "Unfiled"
        case .archived: return "Archived"
        }
    }

    private var matching: [Note] {
        switch route {
        case .folder(let f):
            return notes.filter { $0.folder?.persistentModelID == f.persistentModelID && !$0.isArchived }
                .sorted { $0.updatedAt > $1.updatedAt }
        case .unfiled:
            return notes.filter { $0.folder == nil && !$0.isArchived }.sorted { $0.updatedAt > $1.updatedAt }
        case .archived:
            return notes.filter { $0.isArchived }.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if matching.isEmpty {
                EmptyState(icon: "tray", title: "Nothing here",
                           message: "This folder has no notes yet.")
            } else {
                List {
                    ForEach(matching) { note in
                        NavigationLink(value: note) { NoteRow(note: note) }
                            .listRowBackground(Theme.bg)
                            .listRowSeparatorTint(Theme.hairline)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct FolderEditSheet: View {
    let folder: Folder?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]

    @State private var name = ""
    @State private var symbol = "folder"
    @State private var colorIndex = 0

    private let symbols = ["folder", "tray", "lightbulb", "book.closed", "briefcase",
                           "heart", "star", "leaf", "flame", "graduationcap",
                           "airplane", "house", "cart", "pencil", "music.note"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Folder name", text: $name)
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                        ForEach(symbols, id: \.self) { s in
                            Button { symbol = s; Haptics.tap() } label: {
                                Image(systemName: s)
                                    .font(.system(size: 18))
                                    .frame(width: 42, height: 42)
                                    .background(Circle().fill(symbol == s ? Theme.accentSoft : Theme.surfaceAlt))
                                    .foregroundStyle(symbol == s ? Theme.accent : Theme.inkSoft)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section("Color") {
                    HStack(spacing: 14) {
                        ForEach(Theme.tagColors.indices, id: \.self) { i in
                            Button { colorIndex = i; Haptics.tap() } label: {
                                ColorDot(index: i, size: 26)
                                    .overlay {
                                        if colorIndex == i {
                                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(i == 0 ? Theme.ink : .white)
                                        }
                                    }
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(folder == nil ? "New folder" : "Edit folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let folder {
                    name = folder.name; symbol = folder.symbol; colorIndex = folder.colorIndex
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let folder {
            folder.name = trimmed; folder.symbol = symbol; folder.colorIndex = colorIndex
        } else {
            let f = Folder(name: trimmed, symbol: symbol, colorIndex: colorIndex,
                           sortOrder: (folders.map(\.sortOrder).max() ?? -1) + 1)
            context.insert(f)
        }
        Haptics.success()
        dismiss()
    }
}
