import SwiftUI
import SwiftData

/// Manage folders (create / rename / delete with reassignment), and reorder
/// accounts within a folder or the unfiled set.
struct FoldersScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Folder.sortIndex) private var folders: [Folder]
    @Query(sort: \Account.sortIndex) private var accounts: [Account]

    @State private var showNewFolder = false
    @State private var newFolderName = ""
    @State private var renaming: Folder?
    @State private var renameText = ""
    @State private var deletingFolder: Folder?
    @State private var showPaywall = false

    private var unfiled: [Account] {
        accounts.filter { $0.folder == nil }.sorted { $0.sortIndex < $1.sortIndex }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Folders")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !accounts.isEmpty || !folders.isEmpty {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if isPro || folders.isEmpty {
                            newFolderName = ""
                            showNewFolder = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "folder.badge.plus")
                            .accessibilityLabel("New folder")
                    }
                }
            }
            .alert("New folder", isPresented: $showNewFolder) {
                TextField("Name", text: $newFolderName)
                Button("Create", action: createFolder)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Group related accounts together.")
            }
            .alert("Rename folder", isPresented: Binding(
                get: { renaming != nil },
                set: { if !$0 { renaming = nil } })) {
                TextField("Name", text: $renameText)
                Button("Save", action: commitRename)
                Button("Cancel", role: .cancel) { renaming = nil }
            }
            .confirmationDialog(
                "Delete \(deletingFolder?.name ?? "folder")?",
                isPresented: Binding(get: { deletingFolder != nil },
                                     set: { if !$0 { deletingFolder = nil } }),
                titleVisibility: .visible) {
                Button("Delete folder, keep accounts", role: .destructive) {
                    deleteFolder(reassignToNone: true)
                }
                Button("Cancel", role: .cancel) { deletingFolder = nil }
            } message: {
                Text("Accounts inside will move to Unfiled. Your codes are not deleted.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .folders)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if accounts.isEmpty && folders.isEmpty {
            EmptyStateView(symbol: "folder.badge.questionmark",
                           title: "No folders yet",
                           message: "Add some accounts first, then create folders like Work or Personal to keep them tidy.")
        } else {
            List {
                ForEach(folders) { folder in
                    folderSection(folder)
                }
                unfiledSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private func folderSection(_ folder: Folder) -> some View {
        Section {
            let items = folder.accounts.sorted { $0.sortIndex < $1.sortIndex }
            if items.isEmpty {
                Text("No accounts in this folder")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkFaint)
                    .listRowBackground(Theme.surface)
            } else {
                ForEach(items) { account in
                    accountRow(account)
                        .listRowBackground(Theme.surface)
                }
                .onMove { from, to in
                    move(in: items, from: from, to: to)
                }
            }
        } header: {
            HStack {
                Label(folder.name, systemImage: "folder.fill")
                    .foregroundStyle(Theme.accent)
                Spacer()
                Text("\(folder.accounts.count)")
                    .foregroundStyle(Theme.inkFaint)
                Menu {
                    Button {
                        renameText = folder.name
                        renaming = folder
                    } label: { Label("Rename", systemImage: "pencil") }
                    Button(role: .destructive) {
                        deletingFolder = folder
                    } label: { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("Folder options for \(folder.name)")
                }
            }
        }
    }

    private var unfiledSection: some View {
        Section {
            if unfiled.isEmpty {
                Text("Everything is filed")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkFaint)
                    .listRowBackground(Theme.surface)
            } else {
                ForEach(unfiled) { account in
                    accountRow(account)
                        .listRowBackground(Theme.surface)
                }
                .onMove { from, to in
                    move(in: unfiled, from: from, to: to)
                }
            }
        } header: {
            Label("Unfiled", systemImage: "tray")
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private func accountRow(_ account: Account) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Theme.accountColor(hue: account.colorHue).opacity(0.22))
                Text(account.monogram)
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.accountColor(hue: account.colorHue))
            }
            .frame(width: 36, height: 36)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayTitle)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                if !account.displaySubtitle.isEmpty {
                    Text(account.displaySubtitle)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer()
            Menu {
                Picker("Move to", selection: Binding(
                    get: { account.folder?.id },
                    set: { newID in moveAccount(account, toFolderID: newID) })) {
                    Text("Unfiled").tag(UUID?.none)
                    ForEach(folders) { f in
                        Text(f.name).tag(UUID?.some(f.id))
                    }
                }
            } label: {
                Image(systemName: "folder.badge.gear")
                    .foregroundStyle(Theme.inkSoft)
                    .accessibilityLabel("Move \(account.displayTitle)")
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Mutations

    private func createFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let nextIndex = (folders.map { $0.sortIndex }.max() ?? -1) + 1
        let folder = Folder(name: name, sortIndex: nextIndex)
        context.insert(folder)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
    }

    private func commitRename() {
        guard let folder = renaming else { return }
        let name = renameText.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty { folder.name = name }
        try? context.save()
        renaming = nil
        Haptics.tap(settings.hapticsEnabled)
    }

    private func deleteFolder(reassignToNone: Bool) {
        guard let folder = deletingFolder else { return }
        if reassignToNone {
            for account in folder.accounts { account.folder = nil }
        }
        context.delete(folder)
        try? context.save()
        deletingFolder = nil
        Haptics.warning(settings.hapticsEnabled)
    }

    private func moveAccount(_ account: Account, toFolderID id: UUID?) {
        let target = folders.first { $0.id == id }
        account.folder = target
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }

    /// Reorder within a list, rewriting sortIndex to the new order.
    private func move(in items: [Account], from: IndexSet, to: Int) {
        var reordered = items
        reordered.move(fromOffsets: from, toOffset: to)
        for (index, account) in reordered.enumerated() {
            account.sortIndex = index
        }
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }
}
