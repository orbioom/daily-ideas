import SwiftUI
import SwiftData

struct ClosetView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ClothingItem.createdAt, order: .reverse) private var allItems: [ClothingItem]
    @AppStorage("defaultCurrency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var filter: ItemCategory?
    @State private var search = ""
    @State private var showSettings = false
    @State private var editing: ClothingItem?

    private var items: [ClothingItem] {
        var base = allItems.filter { !$0.archived }
        if let f = filter { base = base.filter { $0.category == f } }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            base = base.filter {
                $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q) || $0.colorName.lowercased().contains(q)
            }
        }
        return base
    }

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if allItems.filter({ !$0.archived }).isEmpty {
                    EmptyStateView(
                        icon: "square.grid.2x2",
                        title: "Your closet is empty",
                        message: "Tap + to add your first piece. Give it a color, brand, and what you paid to track cost-per-wear."
                    )
                } else {
                    VStack(spacing: 0) {
                        categoryFilter
                        if items.isEmpty {
                            EmptyStateView(icon: "magnifyingglass", title: "No matches",
                                           message: "Nothing here matches your filter or search.")
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(items) { item in
                                        NavigationLink(value: item) { itemCell(item) }
                                            .buttonStyle(.plain)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Closet")
            .navigationDestination(for: ClothingItem.self) { ItemDetailView(item: $0) }
            .searchable(text: $search, prompt: "Search pieces")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        let item = ClothingItem(name: "")
                        context.insert(item); editing = item
                    } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add piece")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $editing) { ItemEditorView(item: $0, isNew: true) }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", symbol: "square.grid.2x2", on: filter == nil) { filter = nil }
                ForEach(ItemCategory.allCases) { c in
                    chip(c.label, symbol: c.symbol, on: filter == c) { filter = c }
                }
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
    }

    private func chip(_ title: String, symbol: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            withAnimation(Brand.ease(0.2)) { action() }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.caption2)
                Text(title).font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(on ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.12)))
            .foregroundStyle(on ? Color.accentColor : Brand.text2)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func itemCell(_ item: ClothingItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ItemSwatch(colorHex: item.colorHex, symbol: item.category.symbol, size: 104)
            Text(item.name.isEmpty ? "Untitled" : item.name)
                .font(.caption.weight(.medium)).foregroundStyle(Brand.text)
                .lineLimit(1)
            Text("\(item.wearCount) wear\(item.wearCount == 1 ? "" : "s")")
                .font(Brand.mono(10)).foregroundStyle(Brand.text3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.category.label), \(item.wearCount) wears")
    }
}
