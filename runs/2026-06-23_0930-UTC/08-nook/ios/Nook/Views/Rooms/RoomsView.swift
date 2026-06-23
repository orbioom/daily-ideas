import SwiftUI
import SwiftData

struct RoomsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Room.name) private var rooms: [Room]
    @Query private var settingsRows: [AppSettings]

    @State private var showingEditor = false
    @State private var selectedRoom: Room?

    private var settings: AppSettings { settingsRows.first ?? AppSettings() }

    private func dueCount(_ room: Room) -> Int {
        room.tasks.filter {
            let s = ScheduleEngine.status(for: $0, dueSoonWindow: settings.dueSoonWindowDays)
            return s == .overdue || s == .dueToday
        }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if rooms.isEmpty {
                    EmptyStateView(systemImage: "square.split.bottomrightquarter",
                                   title: "No rooms yet",
                                   message: "Add the rooms and areas of your home to organise maintenance by location.",
                                   actionTitle: "Add a room") { showingEditor = true }
                } else {
                    list
                }
            }
            .navigationTitle("Rooms")
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingEditor = true } label: { Label("Add room", systemImage: "plus") }
                }
            }
            .navigationDestination(item: $selectedRoom) { RoomDetailView(room: $0) }
            .sheet(isPresented: $showingEditor) { RoomEditorView(room: nil) }
        }
    }

    private var list: some View {
        List {
            ForEach(rooms) { room in
                Button { selectedRoom = room } label: { roomRow(room) }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.card)
                    .swipeActions {
                        Button(role: .destructive) {
                            context.delete(room)
                            try? context.save()
                            Haptics.warning(enabled: settings.hapticsEnabled)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
    }

    private func roomRow(_ room: Room) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accent.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: room.kind.systemImage)
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(room.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Text("\(room.tasks.count) tasks · \(room.appliances.count) equipment")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if dueCount(room) > 0 {
                Text("\(dueCount(room)) due")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.overdue)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Theme.overdue.opacity(0.14))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(room.name)
        .accessibilityValue("\(room.tasks.count) tasks, \(room.appliances.count) equipment, \(dueCount(room)) due")
    }
}

#Preview {
    RoomsView()
        .previewModelContainer()
}
