import SwiftUI
import SwiftData

struct ItemsView: View {
    @Query(sort: \Item.createdAt, order: .reverse) private var allItems: [Item]
    @AppStorage("coffer.currencyCode") private var currencyCode = "USD"
    @AppStorage("coffer.warrantyWindowDays") private var warrantyWindowDays = 30

    @State private var query = ""
    @State private var categoryFilter: InventoryCategory? = nil
    @State private var showingAddItem = false

    private var filtered: [Item] {
        var result = InventoryEngine.search(allItems, query: query)
        if let categoryFilter {
            result = result.filter { $0.category == categoryFilter }
        }
        return result
    }

    var body: some View {
        Group {
            if allItems.isEmpty {
                ScrollView {
                    EmptyStateView(icon: "shippingbox",
                                   title: "No items yet",
                                   message: "Tap + to add your first item — a TV, a ring, a bike. Coffer tracks its value and warranty.")
                        .padding(.top, 40)
                }
                .scrollContentBackground(.hidden)
            } else {
                List {
                    if filtered.isEmpty {
                        EmptyStateView(icon: "magnifyingglass",
                                       title: "No matches",
                                       message: "Try a different search or clear the category filter.")
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(filtered) { item in
                            NavigationLink {
                                ItemDetailView(item: item)
                            } label: {
                                ItemRow(item: item,
                                        status: InventoryEngine.warrantyStatus(for: item, window: warrantyWindowDays).status,
                                        currencyCode: currencyCode)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .searchable(text: $query, prompt: "Name, brand, model, serial")
            }
        }
        .background(Brand.pageBackground)
        .navigationTitle("Items")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        categoryFilter = nil
                        Haptics.selection()
                    } label: {
                        Label("All categories", systemImage: categoryFilter == nil ? "checkmark" : "square.grid.2x2")
                    }
                    Divider()
                    ForEach(InventoryCategory.allCases) { category in
                        Button {
                            categoryFilter = category
                            Haptics.selection()
                        } label: {
                            Label(category.label,
                                  systemImage: categoryFilter == category ? "checkmark" : category.symbol)
                        }
                    }
                } label: {
                    Image(systemName: categoryFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
                .accessibilityLabel("Filter by category")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add item")
            }
        }
        .sheet(isPresented: $showingAddItem) {
            ItemEditorView(item: nil, defaultRoom: nil)
        }
    }
}
