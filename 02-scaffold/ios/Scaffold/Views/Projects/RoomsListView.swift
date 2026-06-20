import SwiftUI
import SwiftData

struct RoomsListView: View {
    @Environment(\.modelContext) private var context
    @Query private var properties: [Property]
    @State private var showAddRoom = false
    @State private var showAddProperty = false

    private var property: Property? { properties.first }

    var body: some View {
        NavigationStack {
            Group {
                if let property {
                    mainContent(property)
                } else {
                    noPropertyState
                }
            }
            .navigationTitle("Rooms")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if property != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showAddRoom = true }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .accessibilityLabel("Add room")
                    }
                }
            }
            .sheet(isPresented: $showAddRoom) {
                if let property { AddRoomView(property: property) }
            }
            .sheet(isPresented: $showAddProperty) {
                AddPropertyView()
            }
            .navigationDestination(for: Room.self) { room in
                RoomDetailView(room: room)
            }
        }
    }

    private func mainContent(_ property: Property) -> some View {
        Group {
            if property.rooms.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(property.rooms.sorted(by: { $0.name < $1.name })) { room in
                        NavigationLink(value: room) {
                            RoomRowView(room: room)
                        }
                    }
                    .onDelete { idx in deleteRooms(from: property, at: idx) }
                }
                .listStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "door.left.hand.open")
                .font(.system(size: 56))
                .foregroundColor(ScaffoldTheme.secondaryLabel)
                .accessibilityHidden(true)
            Text("No Rooms Yet")
                .font(.title2.bold())
                .foregroundColor(ScaffoldTheme.label)
            Text("Add rooms to organize your projects by area.")
                .font(.body)
                .foregroundColor(ScaffoldTheme.secondaryLabel)
                .multilineTextAlignment(.center)
            Button("Add First Room") { showAddRoom = true }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Add first room")
        }
        .padding()
    }

    private var noPropertyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "house")
                .font(.system(size: 56))
                .foregroundColor(ScaffoldTheme.secondaryLabel)
                .accessibilityHidden(true)
            Text("No Property Set Up")
                .font(.title2.bold())
                .foregroundColor(ScaffoldTheme.label)
            Button("Set Up Property") { showAddProperty = true }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Set up property")
        }
        .padding()
    }

    private func deleteRooms(from property: Property, at offsets: IndexSet) {
        let sorted = property.rooms.sorted(by: { $0.name < $1.name })
        for i in offsets {
            context.delete(sorted[i])
        }
        try? context.save()
    }
}

struct RoomRowView: View {
    let room: Room

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(ScaffoldTheme.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: room.type.icon)
                    .foregroundColor(ScaffoldTheme.accent)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(ScaffoldTheme.label)
                Text("\(room.projects.count) project\(room.projects.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(ScaffoldTheme.secondaryLabel)
            }
            Spacer()
            if room.activeProjectCount > 0 {
                Text("\(room.activeProjectCount) active")
                    .font(.caption.weight(.medium))
                    .foregroundColor(ScaffoldTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(ScaffoldTheme.accent.opacity(0.12)))
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(room.name), \(room.type.rawValue), \(room.projects.count) projects")
    }
}
