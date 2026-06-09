import SwiftUI
import SwiftData

struct RoomDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var room: Room

    @AppStorage("coffer.currencyCode") private var currencyCode = "USD"
    @AppStorage("coffer.warrantyWindowDays") private var warrantyWindowDays = 30

    @State private var showingEditRoom = false
    @State private var showingAddItem = false

    private var sortedItems: [Item] {
        room.items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    StatTile(value: "\(room.items.count)", label: "Items")
                    StatTile(value: Format.compactCurrency(InventoryEngine.totalValue(room.items), code: currencyCode),
                             label: "Value")
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                if !room.notes.isEmpty {
                    Text(room.notes)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .listRowBackground(Color.clear)
                }
            }

            if sortedItems.isEmpty {
                Section {
                    EmptyStateView(icon: "shippingbox",
                                   title: "No items in this room",
                                   message: "Add items here and they'll show up in your inventory and charts.")
                        .listRowBackground(Color.clear)
                }
            } else {
                Section("Items") {
                    ForEach(sortedItems) { item in
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
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddItem = true
                    } label: { Label("Add item", systemImage: "plus") }
                    Button {
                        showingEditRoom = true
                    } label: { Label("Edit room", systemImage: "pencil") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Room actions")
            }
        }
        .sheet(isPresented: $showingEditRoom) {
            RoomEditorView(room: room)
        }
        .sheet(isPresented: $showingAddItem) {
            ItemEditorView(item: nil, defaultRoom: room)
        }
    }
}

/// A simple list of all items not assigned to any room.
struct UnassignedItemsView: View {
    @Query private var allItems: [Item]
    @AppStorage("coffer.currencyCode") private var currencyCode = "USD"
    @AppStorage("coffer.warrantyWindowDays") private var warrantyWindowDays = 30

    private var items: [Item] {
        allItems.filter { $0.room == nil }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            if items.isEmpty {
                EmptyStateView(icon: "tray",
                               title: "Nothing unassigned",
                               message: "Every item is assigned to a room.")
                    .listRowBackground(Color.clear)
            } else {
                ForEach(items) { item in
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
        .background(Brand.pageBackground)
        .navigationTitle("Unassigned")
        .navigationBarTitleDisplayMode(.inline)
    }
}
