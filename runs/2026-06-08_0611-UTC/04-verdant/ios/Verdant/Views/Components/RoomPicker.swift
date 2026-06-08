import SwiftUI
import SwiftData

struct RoomPicker: View {
    @Binding var selectedRoom: Room?
    @Query(sort: \Room.order) private var rooms: [Room]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddRoom = false
    @State private var newRoomName = ""
    @State private var newRoomSymbol = "door.left.hand.open"

    private let roomSymbols = [
        "door.left.hand.open", "sofa.fill", "bed.double.fill",
        "fork.knife", "wind", "shower.fill", "desktopcomputer",
        "books.vertical.fill", "tray.fill"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    RoomChip(
                        name: "None",
                        symbol: "xmark",
                        isSelected: selectedRoom == nil
                    ) {
                        Haptics.selection()
                        selectedRoom = nil
                    }

                    ForEach(rooms) { room in
                        RoomChip(
                            name: room.name,
                            symbol: room.symbol,
                            isSelected: selectedRoom?.id == room.id
                        ) {
                            Haptics.selection()
                            selectedRoom = room
                        }
                    }

                    Button {
                        showAddRoom = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.caption.weight(.bold))
                            Text("New Room")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Brand.live)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Brand.live.opacity(0.1), in: Capsule())
                        .overlay(Capsule().strokeBorder(Brand.live.opacity(0.3), lineWidth: 1))
                    }
                    .accessibilityLabel("Add new room")
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
        .sheet(isPresented: $showAddRoom) {
            addRoomSheet
        }
    }

    private var addRoomSheet: some View {
        NavigationStack {
            Form {
                Section("Room Name") {
                    TextField("e.g. Living Room", text: $newRoomName)
                        .autocorrectionDisabled()
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(roomSymbols, id: \.self) { sym in
                            Button {
                                newRoomSymbol = sym
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(newRoomSymbol == sym ? Brand.live.opacity(0.18) : Color.clear)
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(newRoomSymbol == sym ? Brand.live : Brand.hairline, lineWidth: 1.5)
                                    Image(systemName: sym)
                                        .font(.system(size: 22))
                                        .foregroundStyle(newRoomSymbol == sym ? Brand.live : Brand.text2)
                                }
                                .frame(height: 50)
                            }
                            .accessibilityLabel(sym)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newRoomName = ""
                        showAddRoom = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = newRoomName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        let room = Room(name: trimmed, symbol: newRoomSymbol, order: rooms.count)
                        modelContext.insert(room)
                        selectedRoom = room
                        newRoomName = ""
                        showAddRoom = false
                        Haptics.success()
                    }
                    .disabled(newRoomName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct RoomChip: View {
    let name: String
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.caption2.weight(.semibold))
                    .accessibilityHidden(true)
                Text(name)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : Brand.text2)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Brand.live : Brand.live.opacity(0.0), in: Capsule())
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Brand.hairline, lineWidth: 0.5))
        }
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
