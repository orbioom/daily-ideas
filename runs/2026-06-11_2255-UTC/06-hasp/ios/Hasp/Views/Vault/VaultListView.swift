import SwiftUI

struct VaultListView: View {
    @Bindable var store: VaultStore
    @State private var searchText = ""
    @State private var filter: Filter = .all
    @State private var editingItem: VaultItem?
    @State private var creating = false
    @State private var viewingItem: VaultItem?

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case favorites = "Favorites"
        case logins = "Logins"
        case cards = "Cards"
        case notes = "Notes"
        var id: String { rawValue }
    }

    private var filtered: [VaultItem] {
        var items = store.vault.items
        switch filter {
        case .all: break
        case .favorites: items = items.filter(\.isFavorite)
        case .logins: items = items.filter { $0.kind == .login }
        case .cards: items = items.filter { $0.kind == .card }
        case .notes: items = items.filter { $0.kind == .note }
        }
        if !searchText.isEmpty {
            items = items.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.username.localizedCaseInsensitiveContains(searchText) ||
                $0.detail.localizedCaseInsensitiveContains(searchText)
            }
        }
        return items.sorted {
            ($0.isFavorite ? 0 : 1, $0.title.lowercased()) < ($1.isFavorite ? 0 : 1, $1.title.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.vault.items.isEmpty {
                    EmptyStateView(
                        icon: "lock.shield",
                        title: "Your vault is empty",
                        message: "Add your first login, card or secure note. Everything is sealed with AES-256 the moment it's saved.",
                        actionTitle: "Add an item"
                    ) { creating = true }
                } else if filtered.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No matches",
                        message: "Nothing in \(filter.rawValue.lowercased()) matches\(searchText.isEmpty ? " this filter." : " “\(searchText)”.")"
                    )
                } else {
                    List {
                        ForEach(filtered) { item in
                            Button {
                                viewingItem = item
                            } label: {
                                ItemRowView(item: item)
                            }
                            .listRowBackground(Theme.bgElevated)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    store.toggleFavorite(item)
                                    Haptics.tap()
                                } label: {
                                    Label(item.isFavorite ? "Unstar" : "Star",
                                          systemImage: item.isFavorite ? "star.slash" : "star")
                                }
                                .tint(.yellow)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    editingItem = item
                                } label: {
                                    Label("Edit", systemImage: "pencil")
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
            .navigationTitle("Hasp")
            .searchable(text: $searchText, prompt: "Search titles, usernames, sites")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.lock()
                        Haptics.tap()
                    } label: {
                        Image(systemName: "lock.fill")
                    }
                    .accessibilityLabel("Lock the vault now")
                }
                ToolbarItem(placement: .principal) {
                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Filter items")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add item")
                }
            }
            .sheet(item: $viewingItem) { item in
                ItemDetailView(store: store, itemID: item.id)
            }
            .sheet(item: $editingItem) { item in
                ItemEditorView(store: store, existing: item)
            }
            .sheet(isPresented: $creating) {
                ItemEditorView(store: store, existing: nil)
            }
        }
    }
}

struct ItemRowView: View {
    let item: VaultItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.kind.icon)
                .font(.subheadline)
                .foregroundStyle(Theme.accent)
                .frame(width: 34, height: 34)
                .background(Theme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                if !item.username.isEmpty {
                    Text(item.username)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                } else if item.kind == .note {
                    Text("Secure note")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            if item.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Favorite")
            }
        }
        .padding(.vertical, 2)
    }
}
