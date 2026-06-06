import SwiftUI
import SwiftData

/// The inventory: every item grouped by the location it lives in, with search and a
/// category filter, expiry/low badges, and a focal "Add Item" action.
struct InventoryView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \Item.name) private var items: [Item]
    @Query(sort: \Location.sortIndex) private var locations: [Location]
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var search = ""
    @State private var filterCategoryID: UUID?
    @State private var showingEditor = false
    @State private var editingItem: Item?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingItem = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Brand.text)
                    .accessibilityLabel("Add item")
                }
            }
            .searchable(text: $search, prompt: "Search items")
            .sheet(isPresented: $showingEditor) {
                ItemEditorView(item: editingItem)
            }
        }
    }

    // MARK: - Filtering & grouping

    private var filtered: [Item] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return items.filter { item in
            let matchesSearch = query.isEmpty
                || item.name.lowercased().contains(query)
                || (item.category?.name.lowercased().contains(query) ?? false)
            let matchesCategory = filterCategoryID == nil
                || item.category?.id == filterCategoryID
            return matchesSearch && matchesCategory
        }
    }

    /// Groups filtered items by location, preserving location sort order, with an
    /// "Unassigned" bucket last for items whose location was removed.
    private var grouped: [(location: Location?, items: [Item])] {
        var result: [(Location?, [Item])] = []
        for location in locations {
            let bucket = filtered.filter { $0.location?.id == location.id }
                .sorted { $0.name < $1.name }
            if !bucket.isEmpty { result.append((location, bucket)) }
        }
        let orphans = filtered.filter { $0.location == nil }.sorted { $0.name < $1.name }
        if !orphans.isEmpty { result.append((nil, orphans)) }
        return result
    }

    @ViewBuilder
    private var content: some View {
        if items.isEmpty {
            EmptyStateView(
                icon: "cabinet",
                title: "Stock your first item",
                message: "Add what you have and where it lives. Larder will keep an eye on dates and low stock for you.",
                actionTitle: "Add an item") {
                    editingItem = nil
                    showingEditor = true
                }
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    if !categories.isEmpty {
                        categoryFilterBar
                    }
                    if grouped.isEmpty {
                        noMatchesState
                    } else {
                        ForEach(Array(grouped.enumerated()), id: \.offset) { _, group in
                            locationSection(group.location, items: group.items)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 28)
            }
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    filterCategoryID = nil
                } label: {
                    CategoryChip(name: "All", colorHue: 9, symbol: "square.grid.2x2",
                                 selected: filterCategoryID == nil)
                }
                .buttonStyle(.plain)
                ForEach(categories) { category in
                    Button {
                        filterCategoryID = (filterCategoryID == category.id) ? nil : category.id
                    } label: {
                        CategoryChip(name: category.name, colorHue: category.colorHue,
                                     symbol: category.symbol,
                                     selected: filterCategoryID == category.id)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var noMatchesState: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "Nothing matches",
            message: "Try a different search or clear the category filter.",
            actionTitle: filterCategoryID == nil ? nil : "Clear filter") {
                filterCategoryID = nil
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
    }

    private func locationSection(_ location: Location?, items: [Item]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                LocationGlyph(symbol: location?.symbol ?? "tray", size: 28)
                SectionLabel(text: location?.name ?? "Unassigned")
                Spacer()
                Text("\(items.count)")
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text3)
            }
            VStack(spacing: 10) {
                ForEach(items) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        InventoryRow(item: item, windowDays: settings.expirySoonWindowDays)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// One inventory line: name, quantity, category, expiry + low badges.
struct InventoryRow: View {
    let item: Item
    let windowDays: Int

    private var bucket: ExpiryLogic.Bucket {
        ExpiryLogic.bucket(for: item.expiryDate, windowDays: windowDays)
    }
    private var days: Int? {
        ExpiryLogic.daysUntil(item.expiryDate)
    }

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Brand.text)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(item.quantityLabel)
                            .font(Brand.mono(13, weight: .medium))
                            .foregroundStyle(Brand.text2)
                        if let category = item.category {
                            HStack(spacing: 4) {
                                Image(systemName: category.symbol)
                                    .font(.system(size: 10))
                                Text(category.name)
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(Brand.categoryColor(category.colorHue))
                        }
                    }
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 6) {
                    if bucket != .none {
                        ExpiryBadge(bucket: bucket, daysUntil: days, showPhrase: true)
                    }
                    if item.isLowStock {
                        LowStockBadge()
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [item.name, item.quantityLabel]
        if let category = item.category { parts.append(category.name) }
        if bucket != .none {
            parts.append(ExpiryLogic.relativePhrase(forDaysUntil: days))
        }
        if item.isLowStock { parts.append("Low stock") }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    InventoryView()
        .environment(SettingsStore())
        .modelContainer(PreviewData.container)
}
