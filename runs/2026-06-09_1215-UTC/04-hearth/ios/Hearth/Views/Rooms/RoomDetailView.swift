import SwiftUI
import SwiftData

struct RoomDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var room: Room

    @AppStorage("hearth.soonWindowDays") private var soonWindowDays = 3
    @AppStorage("hearth.showEstimatedTime") private var showEstimatedTime = true

    @State private var editingTask: CleaningTask?
    @State private var showingAdd = false

    private var freshness: Double { HearthEngine.roomFreshness(room) }
    private var ringTint: Color {
        if freshness >= 0.75 { return Brand.live }
        if freshness >= 0.5 { return Brand.warn }
        return Brand.danger
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if room.sortedTasks.isEmpty {
                    EmptyStateView(icon: "checklist",
                                   title: "No tasks yet",
                                   message: "Add cleaning chores with how often they should be done.")
                        .glassCard()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(room.sortedTasks) { task in
                            TaskRow(task: task,
                                    soonWindowDays: soonWindowDays,
                                    showTime: showEstimatedTime,
                                    onDone: { markDone(task) },
                                    onEdit: { editingTask = task },
                                    onToggleActive: { toggleActive(task) },
                                    onDelete: { delete(task) })
                        }
                    }
                    .glassCard()
                }
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add task")
            }
        }
        .sheet(isPresented: $showingAdd) {
            TaskEditView(room: room,
                         task: nil,
                         nextSortIndex: (room.tasks.map { $0.sortIndex }.max() ?? -1) + 1)
        }
        .sheet(item: $editingTask) { task in
            TaskEditView(room: room, task: task, nextSortIndex: task.sortIndex)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            ZStack {
                ProgressRing(progress: freshness, lineWidth: 8, tint: ringTint)
                    .frame(width: 72, height: 72)
                Image(systemName: room.symbol)
                    .font(.system(size: 26))
                    .foregroundStyle(Palette.color(room.colorIndex))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Format.percent(freshness)) fresh")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Brand.text)
                Text("\(room.activeTasks.count) active \(room.activeTasks.count == 1 ? "task" : "tasks")")
                    .font(Brand.mono(12))
                    .foregroundStyle(Brand.text3)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(room.name) freshness")
        .accessibilityValue("\(Format.percent(freshness)) fresh")
    }

    // MARK: - Actions

    private func markDone(_ task: CleaningTask) {
        withAnimation(Brand.ease(0.35)) {
            TaskActions.markDone(task, context: context)
        }
    }

    private func toggleActive(_ task: CleaningTask) {
        Haptics.selection()
        withAnimation(Brand.ease(0.3)) {
            task.isActive.toggle()
            try? context.save()
        }
    }

    private func delete(_ task: CleaningTask) {
        Haptics.warning()
        withAnimation(Brand.ease(0.3)) {
            context.delete(task)
            try? context.save()
        }
    }
}

/// A task row inside a room: status dot, name, cadence/next-due, freshness bar,
/// a one-tap Done, and a context menu for edit/pause/delete.
private struct TaskRow: View {
    @Bindable var task: CleaningTask
    let soonWindowDays: Int
    let showTime: Bool
    let onDone: () -> Void
    let onEdit: () -> Void
    let onToggleActive: () -> Void
    let onDelete: () -> Void

    private var status: HearthEngine.DueStatus {
        HearthEngine.status(for: task, soonWindowDays: soonWindowDays)
    }
    private var freshness: Double { HearthEngine.freshness(for: task) }
    private var daysFromNow: Int {
        HearthEngine.daysBetween(.now, HearthEngine.nextDue(for: task))
    }

    private var subtitle: String {
        var parts = [Format.cadence(days: task.frequencyDays)]
        parts.append(task.lastDone == nil ? "Due today" : Format.duePhrase(daysFromNow: daysFromNow))
        if showTime { parts.append(Format.duration(minutes: task.estMinutes)) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                StatusDot(color: task.isActive ? status.color : Brand.text3)
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(task.isActive ? Brand.text : Brand.text3)
                        .strikethrough(!task.isActive, color: Brand.text3)
                    Text(task.isActive ? subtitle : "Paused")
                        .font(Brand.mono(12))
                        .foregroundStyle(Brand.text3)
                }
                Spacer()
                if task.isActive {
                    Button(action: onDone) {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(status.color.gradient, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Mark \(task.name) done")
                }
            }
            if task.isActive {
                FreshnessBar(value: freshness, tint: status.color)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
            Button { onToggleActive() } label: {
                Label(task.isActive ? "Pause" : "Resume",
                      systemImage: task.isActive ? "pause.circle" : "play.circle")
            }
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(task.name)
        .accessibilityValue(task.isActive
                            ? "\(status.label), \(Format.percent(freshness)) fresh, \(subtitle)"
                            : "Paused")
        .accessibilityHint(task.isActive ? "Use the button to mark done, or long press for more options" : "Long press for more options")
    }
}
