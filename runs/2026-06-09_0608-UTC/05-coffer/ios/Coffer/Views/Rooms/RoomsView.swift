import SwiftUI
import SwiftData

struct RoomsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Room.sortIndex, order: .forward) private var rooms: [Room]
    @Query private var allItems: [Item]
    @AppStorage("coffer.currencyCode") private var currencyCode = "USD"

    @State private var showingEditor = false

    private var unassignedItems: [Item] { allItems.filter { $0.room == nil } }

    var body: some View {
        Group {
            if rooms.isEmpty && unassignedItems.isEmpty {
                ScrollView {
                    EmptyStateView(icon: "square.split.bottomrightquarter",
                                   title: "No rooms yet",
                                   message: "Add a room to start organizing your inventory by location.")
                        .padding(.top, 40)
                }
                .scrollContentBackground(.hidden)
            } else {
                List {
                    ForEach(rooms) { room in
                        NavigationLink {
                            RoomDetailView(room: room)
                        } label: {
                            roomRow(room: room,
                                    count: room.items.count,
                                    value: InventoryEngine.totalValue(room.items),
                                    icon: room.iconName)
                        }
                        .listRowBackground(Color.clear)
                    }

                    if !unassignedItems.isEmpty {
                        NavigationLink {
                            UnassignedItemsView()
                        } label: {
                            roomRow(room: nil,
                                    count: unassignedItems.count,
                                    value: InventoryEngine.totalValue(unassignedItems),
                                    icon: "tray.fill")
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Brand.pageBackground)
        .navigationTitle("Rooms")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add room")
            }
        }
        .sheet(isPresented: $showingEditor) {
            RoomEditorView(room: nil)
        }
    }

    private func roomRow(room: Room?, count: Int, value: Double, icon: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Brand.mist3.opacity(0.7))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Brand.info)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(room?.name ?? "Unassigned")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.text)
                Text("\(count) item\(count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            Spacer()
            Text(Format.currency(value, code: currencyCode))
                .font(Brand.mono(14, weight: .medium))
                .foregroundStyle(Brand.text2)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .glassCard(padding: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(room?.name ?? "Unassigned"), \(count) items, \(Format.currency(value, code: currencyCode))")
    }
}
