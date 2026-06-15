import SwiftData
import SwiftUI

/// The Library: a grid of notebook covers with search, sort, folder filters,
/// and full notebook CRUD.
struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro: Bool = false

    @Query private var notebooks: [Notebook]
    @Query(sort: \Folder.createdAt) private var folders: [Folder]

    @State private var search = ""
    @State private var sort: NotebookSort = .recent
    @State private var selectedFolder: Folder?
    @State private var showCreate = false
    @State private var showManageFolders = false
    @State private var paywallReason: PaywallReason?

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 190), spacing: 22)]

    private var displayed: [Notebook] {
        LibraryEngine.process(notebooks, search: search, folder: selectedFolder, sort: sort)
    }

    var body: some View {
        Group {
            if notebooks.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Library")
        .toolbar { toolbarItems }
        .searchable(text: $search, prompt: "Search notebooks")
        .sheet(isPresented: $showCreate) {
            CreateNotebookSheet(initialFolder: selectedFolder)
        }
        .sheet(isPresented: $showManageFolders) {
            FolderManagerSheet()
        }
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        .navigationDestination(for: Notebook.self) { notebook in
            NotebookDetailView(notebook: notebook)
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if Pro.foldersUnlocked(isPro: isPro) && !folders.isEmpty {
                    folderChips
                }

                if displayed.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No matches",
                        message: "No notebooks match your search or filter."
                    )
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    LazyVGrid(columns: columns, spacing: 26) {
                        ForEach(displayed) { notebook in
                            NavigationLink(value: notebook) {
                                BookCover(
                                    title: notebook.title,
                                    colorHex: notebook.coverColorHex,
                                    pageCount: notebook.pageCount,
                                    isFavorite: notebook.isFavorite,
                                    template: notebook.defaultTemplate
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    toggleFavorite(notebook)
                                } label: {
                                    Label(
                                        notebook.isFavorite ? "Unfavorite" : "Favorite",
                                        systemImage: notebook.isFavorite ? "star.slash" : "star"
                                    )
                                }
                                Button(role: .destructive) {
                                    delete(notebook)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
            .padding(.top, 8)
        }
    }

    private var folderChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                chip(title: "All", color: Theme.inkSoft, isSelected: selectedFolder == nil) {
                    selectedFolder = nil
                }
                ForEach(folders) { folder in
                    chip(
                        title: folder.name,
                        color: Color(hexString: folder.colorHex),
                        isSelected: selectedFolder?.id == folder.id
                    ) {
                        selectedFolder = (selectedFolder?.id == folder.id) ? nil : folder
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chip(title: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 9, height: 9)
                Text(title).font(Theme.rounded(14, .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected ? Theme.accentSoft : Theme.surfaceAlt,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? Theme.accent : Theme.inkSoft)
        }
        .accessibilityLabel("Filter: \(title)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "books.vertical",
            title: "Your library is empty",
            message: "Create your first notebook and start writing with pen, highlighter, or fountain pen.",
            actionTitle: "New Notebook",
            action: { attemptCreate() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Sort", selection: $sort) {
                    ForEach(NotebookSort.allCases) { option in
                        Label(option.title, systemImage: option.systemImage).tag(option)
                    }
                }
                if Pro.foldersUnlocked(isPro: isPro) {
                    Button {
                        showManageFolders = true
                    } label: {
                        Label("Manage Folders", systemImage: "folder")
                    }
                } else {
                    Button {
                        paywallReason = .folders
                    } label: {
                        Label("Folders (Pro)", systemImage: "folder.badge.plus")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Sort and folders")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                attemptCreate()
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("New notebook")
        }
    }

    // MARK: - Actions

    private func attemptCreate() {
        if Pro.canCreateNotebook(currentCount: notebooks.count, isPro: isPro) {
            showCreate = true
        } else {
            paywallReason = .notebookLimit
        }
    }

    private func toggleFavorite(_ notebook: Notebook) {
        notebook.isFavorite.toggle()
        notebook.updatedAt = .now
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }

    private func delete(_ notebook: Notebook) {
        context.delete(notebook)
        try? context.save()
        Haptics.warning(settings.hapticsEnabled)
    }
}
