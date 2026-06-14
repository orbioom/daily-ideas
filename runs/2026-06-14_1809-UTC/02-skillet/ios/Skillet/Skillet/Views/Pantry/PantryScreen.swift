import SwiftUI
import SwiftData

/// Your ingredients, grouped by aisle. Toggle stock, add, search, delete.
struct PantryScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \PantryItem.name) private var items: [PantryItem]

    @State private var searchText = ""
    @State private var showAdd = false
    @State private var inStockOnly = false

    private var filtered: [PantryItem] {
        var list = items
        if inStockOnly { list = list.filter { $0.inStock } }
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.name.lowercased().contains(q) || $0.aisle.rawValue.lowercased().contains(q)
            }
        }
        return list
    }

    private var grouped: [(aisle: Aisle, items: [PantryItem])] {
        Aisle.allCases.compactMap { aisle in
            let rows = filtered.filter { $0.aisle == aisle }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return rows.isEmpty ? nil : (aisle, rows)
        }
    }

    private var inStockCount: Int { items.filter { $0.inStock }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Pantry")
            .searchable(text: $searchText, prompt: "Search ingredients")
            .toolbar { toolbar }
            .sheet(isPresented: $showAdd) {
                AddPantryItemView()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if items.isEmpty {
            EmptyStateView(symbol: "refrigerator",
                           title: "Your pantry is empty",
                           message: "Add what you have on hand, or quick-stock the kitchen basics to get matching.",
                           actionTitle: "Stock the basics") { stockBasics() }
        } else if filtered.isEmpty {
            EmptyStateView(symbol: "magnifyingglass",
                           title: "No matches",
                           message: "Nothing fits that search or filter.",
                           actionTitle: "Clear") { searchText = ""; inStockOnly = false }
        } else {
            list
        }
    }

    private var list: some View {
        List {
            Section {
                HStack {
                    Label("\(inStockCount) in stock", systemImage: "checkmark.seal")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.good)
                    Spacer()
                    Button { stockBasics() } label: {
                        Label("Stock basics", systemImage: "plus.circle")
                            .font(Theme.rounded(13, .semibold))
                    }
                    .buttonStyle(.borderless)
                }
                .listRowBackground(Theme.surfaceAlt)
            }

            ForEach(grouped, id: \.aisle) { group in
                Section {
                    ForEach(group.items) { item in
                        row(item)
                    }
                    .onDelete { offsets in delete(group.items, at: offsets) }
                } header: {
                    Label(group.aisle.rawValue, systemImage: group.aisle.symbol)
                        .foregroundStyle(group.aisle.hue)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func row(_ item: PantryItem) -> some View {
        Button {
            item.inStock.toggle()
            Haptics.tap(settings.hapticsEnabled)
            try? context.save()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.inStock ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.inStock ? Theme.good : Theme.inkFaint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(Theme.rounded(16, .medium))
                        .foregroundStyle(item.inStock ? Theme.ink : Theme.inkSoft)
                    if !item.note.isEmpty {
                        Text(item.note)
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
                Spacer()
                Text(item.inStock ? "In stock" : "Out")
                    .font(Theme.rounded(11, .semibold))
                    .foregroundStyle(item.inStock ? Theme.good : Theme.inkFaint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Theme.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.name)
        .accessibilityValue(item.inStock ? "in stock" : "out of stock")
        .accessibilityHint("Double tap to toggle stock")
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { inStockOnly.toggle() } label: {
                Image(systemName: inStockOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
            }
            .accessibilityLabel(inStockOnly ? "Showing in-stock only" : "Show all items")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showAdd = true } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add ingredient")
        }
    }

    private func delete(_ source: [PantryItem], at offsets: IndexSet) {
        for index in offsets where source.indices.contains(index) {
            context.delete(source[index])
        }
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }

    private func stockBasics() {
        let existing = Set(items.map { $0.normalizedName })
        var added = 0
        for basic in SeedData.basicsSpecs() {
            let key = IngredientNormalizer.normalize(basic.name)
            if existing.contains(key) {
                // If present but out of stock, restock it.
                if let match = items.first(where: { $0.normalizedName == key }), !match.inStock {
                    match.inStock = true
                    added += 1
                }
            } else {
                context.insert(PantryItem(name: basic.name, aisle: basic.aisle, inStock: true))
                added += 1
            }
        }
        if added > 0 {
            try? context.save()
            Haptics.success(settings.hapticsEnabled)
        }
    }
}
