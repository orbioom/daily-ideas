import SwiftUI
import SwiftData

struct RoomsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Room.sortIndex) private var rooms: [Room]

    @AppStorage("hearth.soonWindowDays") private var soonWindowDays = 3

    @State private var editingRoom: Room?
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if rooms.isEmpty {
                    EmptyStateView(icon: "square.grid.2x2",
                                   title: "No rooms yet",
                                   message: "Add your first room to start building a calm cleaning rotation.")
                        .glassCard()
                        .padding(20)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(rooms) { room in
                            NavigationLink {
                                RoomDetailView(room: room)
                            } label: {
                                RoomCard(room: room, soonWindowDays: soonWindowDays)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    editingRoom = room
                                } label: {
                                    Label("Edit room", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    delete(room)
                                } label: {
                                    Label("Delete room", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Rooms")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add room")
                }
            }
            .sheet(isPresented: $showingAdd) {
                RoomEditView(room: nil, nextSortIndex: (rooms.map { $0.sortIndex }.max() ?? -1) + 1)
            }
            .sheet(item: $editingRoom) { room in
                RoomEditView(room: room, nextSortIndex: room.sortIndex)
            }
        }
    }

    private func delete(_ room: Room) {
        Haptics.warning()
        withAnimation(Brand.ease(0.3)) {
            context.delete(room)   // cascades to tasks; CompletionLog history is kept
            try? context.save()
        }
    }
}

/// A room summary card: symbol, name, freshness ring, and a "N due" badge.
private struct RoomCard: View {
    let room: Room
    let soonWindowDays: Int

    private var freshness: Double { HearthEngine.roomFreshness(room) }
    private var dueCount: Int { HearthEngine.dueCount(for: room, soonWindowDays: soonWindowDays) }
    private var accent: Color { Palette.color(room.colorIndex) }

    private var ringTint: Color {
        if freshness >= 0.75 { return Brand.live }
        if freshness >= 0.5 { return Brand.warn }
        return Brand.danger
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                ProgressRing(progress: freshness, lineWidth: 6, tint: ringTint)
                    .frame(width: 52, height: 52)
                Image(systemName: room.symbol)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(accent)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                HStack(spacing: 6) {
                    Text("\(Format.percent(freshness)) fresh")
                    Text("·")
                    Text("\(room.activeTasks.count) \(room.activeTasks.count == 1 ? "task" : "tasks")")
                }
                .font(Brand.mono(12))
                .foregroundStyle(Brand.text3)
            }
            Spacer()
            if dueCount > 0 {
                Text("\(dueCount) due")
                    .font(Brand.mono(12, weight: .medium))
                    .foregroundStyle(Brand.danger)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Brand.danger.opacity(0.12), in: Capsule())
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(room.name)
        .accessibilityValue("\(Format.percent(freshness)) fresh, \(dueCount) due")
    }
}
