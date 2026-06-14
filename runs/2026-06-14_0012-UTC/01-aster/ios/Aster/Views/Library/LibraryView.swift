import SwiftUI
import SwiftData

/// The home screen: all maps with search, sort, create, rename, delete.
struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @AppStorage("defaultMapTheme") private var defaultMapTheme = MapTheme.mist.rawValue

    @Query private var maps: [MindMap]

    @State private var search = ""
    @State private var sort: SortMode = .recent
    @State private var renameTarget: MindMap?
    @State private var renameText = ""
    @State private var pendingDelete: MindMap?
    @State private var showPaywall = false
    @State private var newMapID: UUID?
    @State private var path: [UUID] = []

    @AppStorage("confirmDelete") private var confirmDelete = true

    enum SortMode: String, CaseIterable, Identifiable {
        case recent, name
        var id: String { rawValue }
        var label: String { self == .recent ? "Recent" : "Name" }
    }

    private var filtered: [MindMap] {
        let trimmed = search.trimmingCharacters(in: .whitespaces)
        let base = trimmed.isEmpty
            ? maps
            : maps.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
        switch sort {
        case .recent: return base.sorted { $0.updatedAt > $1.updatedAt }
        case .name:   return base.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Maps")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { sortMenu }
                ToolbarItem(placement: .topBarTrailing) { addButton }
            }
            .searchable(text: $search, prompt: "Search maps")
            .navigationDestination(for: UUID.self) { id in
                if let map = maps.first(where: { $0.id == id }) {
                    MapWorkspaceView(map: map)
                } else {
                    missingMap
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Rename Map", isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } })) {
                TextField("Title", text: $renameText)
                Button("Cancel", role: .cancel) { renameTarget = nil }
                Button("Save") { commitRename() }
            }
            .confirmationDialog(
                "Delete this map? This cannot be undone.",
                isPresented: Binding(get: { pendingDelete != nil },
                                     set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { confirmDeleteNow() }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    // MARK: - Content states

    @ViewBuilder
    private var content: some View {
        if maps.isEmpty {
            EmptyStateView(
                symbol: "circle.hexagongrid",
                title: "No maps yet",
                message: "Create your first mind map and start branching your ideas outward.",
                actionTitle: "New Map",
                action: createMap
            )
        } else if filtered.isEmpty {
            EmptyStateView(
                symbol: "magnifyingglass",
                title: "No matches",
                message: "No maps match \u{201C}\(search)\u{201D}. Try a different search."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if !isPro {
                        freeTierBanner
                    }
                    ForEach(filtered) { map in
                        Button {
                            Haptics.tap()
                            path.append(map.id)
                        } label: {
                            MapRow(map: map)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button { startRename(map) } label: { Label("Rename", systemImage: "pencil") }
                            Button(role: .destructive) { requestDelete(map) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private var freeTierBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(maps.count) of \(ProLimits.freeMapLimit) free maps used")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Unlock Aster Pro for unlimited maps")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
            }
            .padding(14)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var missingMap: some View {
        EmptyStateView(symbol: "questionmark.folder",
                       title: "Map unavailable",
                       message: "This map could not be found. It may have been deleted.")
    }

    // MARK: - Toolbar

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $sort) {
                ForEach(SortMode.allCases) { Text($0.label).tag($0) }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    private var addButton: some View {
        Button {
            createMap()
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel("New map")
    }

    // MARK: - Actions

    private func createMap() {
        guard ProLimits.canCreateMap(currentCount: maps.count, isPro: isPro) else {
            Haptics.warning()
            showPaywall = true
            return
        }
        let theme = MapTheme.from(defaultMapTheme)
        let map = MindMap(title: "Untitled Map", theme: theme)
        context.insert(map)
        let root = map.ensureRoot(context: context)
        root.text = "Central Idea"
        Haptics.success()
        path.append(map.id)
    }

    private func startRename(_ map: MindMap) {
        renameText = map.title
        renameTarget = map
    }

    private func commitRename() {
        guard let target = renameTarget else { return }
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        target.title = trimmed.isEmpty ? "Untitled Map" : trimmed
        target.touch()
        renameTarget = nil
        Haptics.tap()
    }

    private func requestDelete(_ map: MindMap) {
        if confirmDelete {
            pendingDelete = map
        } else {
            delete(map)
        }
    }

    private func confirmDeleteNow() {
        if let map = pendingDelete { delete(map) }
        pendingDelete = nil
    }

    private func delete(_ map: MindMap) {
        context.delete(map)
        Haptics.warning()
    }
}

// MARK: - Row

private struct MapRow: View {
    let map: MindMap

    private var updatedText: String {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .abbreviated
        return fmt.localizedString(for: map.updatedAt, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(map.theme.swatch)
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.9))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(map.title.isEmpty ? "Untitled Map" : map.title)
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label("\(map.nodeCount)", systemImage: "circle.hexagongrid")
                        .labelStyle(.titleAndIcon)
                    Text("\u{00B7}")
                    Text(map.theme.name)
                    Text("\u{00B7}")
                    Text(updatedText)
                }
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(map.title), \(map.nodeCount) nodes, \(map.theme.name) theme, updated \(updatedText)")
    }
}
