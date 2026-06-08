import SwiftUI
import SwiftData

struct RoomsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Room.order) private var rooms: [Room]
    @Query(sort: \Plant.order) private var plants: [Plant]
    @AppStorage("verdant.seasonal") private var seasonalAdjust = true

    @State private var showAddRoom = false
    @State private var editingRoom: Room? = nil
    @State private var roomToDelete: Room? = nil
    @State private var showDeleteAlert = false
    @State private var selectedRoom: Room? = nil

    private func plantsInRoom(_ room: Room) -> [Plant] {
        plants.filter { $0.room?.id == room.id && !$0.archived }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if rooms.isEmpty {
                    EmptyStateView(
                        icon: "house",
                        title: "No rooms yet",
                        message: "Add rooms to organise your plants by location."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(rooms) { room in
                                RoomCard(
                                    room: room,
                                    plants: plantsInRoom(room),
                                    seasonalAdjust: seasonalAdjust,
                                    now: Date(),
                                    onEdit: { editingRoom = room },
                                    onDelete: {
                                        roomToDelete = room
                                        showDeleteAlert = true
                                    }
                                )
                                .onTapGesture {
                                    selectedRoom = room
                                    Haptics.tap()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Rooms")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddRoom = true
                        Haptics.tap()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add new room")
                }
            }
            .sheet(isPresented: $showAddRoom) {
                RoomEditView()
            }
            .sheet(item: $editingRoom) { room in
                RoomEditView(editingRoom: room)
            }
            .navigationDestination(item: $selectedRoom) { room in
                RoomPlantListView(room: room, seasonalAdjust: seasonalAdjust)
            }
            .alert("Delete \"\(roomToDelete?.name ?? "")\"?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let room = roomToDelete {
                        // Nullify plants' room reference
                        let affected = plants.filter { $0.room?.id == room.id }
                        for plant in affected { plant.room = nil }
                        modelContext.delete(room)
                        roomToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) { roomToDelete = nil }
            } message: {
                Text("Plants in this room will be moved to unassigned.")
            }
        }
    }
}

private struct RoomCard: View {
    let room: Room
    let plants: [Plant]
    let seasonalAdjust: Bool
    let now: Date
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var overdueCount: Int {
        plants.filter {
            if case .overdue = CareEngine.status(plant: $0, seasonalAdjust: seasonalAdjust, now: now) {
                return true
            }
            return false
        }.count
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Brand.live.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: room.symbol)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Brand.live)
                        }
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(room.name)
                                .font(.headline)
                                .foregroundStyle(Brand.text)
                            Text("\(plants.count) \(plants.count == 1 ? "plant" : "plants")")
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }
                    }

                    Spacer()

                    if overdueCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .accessibilityHidden(true)
                            Text("\(overdueCount) overdue")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Brand.danger)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Brand.danger.opacity(0.1), in: Capsule())
                    }

                    Menu {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit Room", systemImage: "pencil")
                        }
                        Divider()
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete Room", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.callout)
                            .foregroundStyle(Brand.text2)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Room options")
                }

                if !plants.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(plants.prefix(6)) { plant in
                                PlantPeek(plant: plant, seasonalAdjust: seasonalAdjust, now: now)
                            }
                            if plants.count > 6 {
                                Text("+\(plants.count - 6)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Brand.text3)
                                    .frame(width: 36, height: 36)
                                    .background(Brand.hairline.opacity(0.5), in: Circle())
                            }
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(room.name), \(plants.count) plants")
    }
}

private struct PlantPeek: View {
    let plant: Plant
    let seasonalAdjust: Bool
    let now: Date

    private var statusColor: Color {
        switch CareEngine.status(plant: plant, seasonalAdjust: seasonalAdjust, now: now) {
        case .overdue:  return Brand.danger
        case .dueToday: return Brand.warn
        case .dueSoon:  return Brand.warn
        case .ok:       return Brand.live
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: plant.colorHex).opacity(0.16))
                    .frame(width: 40, height: 40)
                Image(systemName: plant.symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: plant.colorHex))
            }
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .offset(x: 2, y: -2)
        }
        .accessibilityLabel("\(plant.nickname): \(statusColor == Brand.danger ? "overdue" : "ok")")
    }
}

struct RoomEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Room.order) private var rooms: [Room]

    var editingRoom: Room? = nil

    @State private var name = ""
    @State private var symbol = "door.left.hand.open"

    private let symbolOptions = [
        "door.left.hand.open", "sofa.fill", "bed.double.fill",
        "fork.knife", "wind", "shower.fill", "desktopcomputer",
        "books.vertical.fill", "tray.fill", "sun.max.fill",
        "moon.fill", "leaf.fill"
    ]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Room Name") {
                    TextField("e.g. Living Room", text: $name)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Room name")
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(symbolOptions, id: \.self) { sym in
                            Button {
                                symbol = sym
                                Haptics.selection()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(symbol == sym ? Brand.live.opacity(0.18) : Color.clear)
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(symbol == sym ? Brand.live : Brand.hairline, lineWidth: 1.5)
                                    Image(systemName: sym)
                                        .font(.system(size: 24))
                                        .foregroundStyle(symbol == sym ? Brand.live : Brand.text2)
                                }
                                .frame(height: 56)
                            }
                            .accessibilityLabel(sym)
                            .accessibilityAddTraits(symbol == sym ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(editingRoom == nil ? "New Room" : "Edit Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let r = editingRoom {
                    name = r.name
                    symbol = r.symbol
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let r = editingRoom {
            r.name = trimmed
            r.symbol = symbol
        } else {
            let room = Room(name: trimmed, symbol: symbol, order: rooms.count)
            modelContext.insert(room)
        }
        Haptics.success()
        dismiss()
    }
}

struct RoomPlantListView: View {
    let room: Room
    let seasonalAdjust: Bool
    @Query(sort: \Plant.order) private var allPlants: [Plant]

    private var now: Date { Date() }

    private var roomPlants: [Plant] {
        allPlants.filter { $0.room?.id == room.id && !$0.archived }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground

            if roomPlants.isEmpty {
                EmptyStateView(
                    icon: "leaf",
                    title: "No plants in \(room.name)",
                    message: "Assign plants to this room from the Plants tab."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(roomPlants) { plant in
                            NavigationLink(destination: PlantDetailView(plant: plant)) {
                                plantRow(plant)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private func plantRow(_ plant: Plant) -> some View {
        let status = CareEngine.status(plant: plant, seasonalAdjust: seasonalAdjust, now: now)
        let isUrgent = status.isUrgent

        return GlassCard(padding: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: plant.colorHex).opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: plant.symbol)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(hex: plant.colorHex))
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(plant.nickname)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.text)
                    Text(plant.species.isEmpty ? "Unknown species" : plant.species)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Spacer()

                StatusDotLabel(status: status)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plant.nickname)\(plant.species.isEmpty ? "" : ", \(plant.species)"): \(isUrgent ? "needs care" : "care up to date")")
    }
}
