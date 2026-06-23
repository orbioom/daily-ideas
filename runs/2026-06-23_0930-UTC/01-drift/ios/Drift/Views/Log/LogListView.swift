import SwiftUI
import SwiftData

/// Browsable history of logged nights with swipe-to-delete and tap-to-edit.
struct LogListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SleepLog.night, order: .reverse) private var logs: [SleepLog]
    @Query private var settingsList: [SleepSettings]

    @State private var showCreate = false
    @State private var editing: SleepLog?
    @State private var pendingDelete: SleepLog?

    private var use24h: Bool { settingsList.first?.use24HourClock ?? false }

    var body: some View {
        NavigationStack {
            ZStack {
                DriftBackground()
                if logs.isEmpty {
                    EmptyStateView(
                        symbol: "bed.double",
                        title: "No nights logged",
                        message: "Tap the plus button to record your first night. Drift only needs your bedtime and wake time.",
                        actionTitle: "Log a night",
                        action: { showCreate = true }
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Sleep Log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a night")
                }
            }
            .sheet(isPresented: $showCreate) {
                LogEditorView(mode: .create)
            }
            .sheet(item: $editing) { log in
                LogEditorView(mode: .edit(log))
            }
            .alert("Delete this night?", isPresented: deleteBinding, presenting: pendingDelete) { log in
                Button("Delete", role: .destructive) { delete(log) }
                Button("Cancel", role: .cancel) {}
            } message: { log in
                Text("\(Format.relativeNight(log.night)) · \(Format.duration(log.durationHours)) will be removed.")
            }
        }
    }

    private var list: some View {
        List {
            ForEach(logs) { log in
                Button {
                    editing = log
                } label: {
                    LogRow(log: log, use24h: use24h)
                }
                .listRowBackground(Theme.card)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        pendingDelete = log
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var deleteBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }

    private func delete(_ log: SleepLog) {
        context.delete(log)
        try? context.save()
        pendingDelete = nil
    }
}

private struct LogRow: View {
    let log: SleepLog
    let use24h: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(Format.dayShort(log.night))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
                Text(qualityEmoji)
                    .font(.title3)
            }
            .frame(width: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(Format.relativeNight(log.night))
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: "moon.fill").font(.caption2).foregroundStyle(Theme.night)
                    Text(Format.clock(log.bedTime, use24h: use24h))
                    Image(systemName: "arrow.right").font(.caption2)
                    Image(systemName: "sunrise.fill").font(.caption2).foregroundStyle(Theme.dawn)
                    Text(Format.clock(log.wakeTime, use24h: use24h))
                }
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                if !log.tags.isEmpty {
                    Text(log.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(.caption2)
                        .foregroundStyle(Theme.dusk)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.duration(log.durationHours))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(log.awakenings) wake-ups")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Format.relativeNight(log.night)), \(Format.duration(log.durationHours)) in bed, quality \(log.quality) of 5, \(log.awakenings) wake-ups")
        .accessibilityHint("Opens the editor")
    }

    private var qualityEmoji: String {
        switch log.quality {
        case 5: return "😴"
        case 4: return "🙂"
        case 3: return "😐"
        case 2: return "😕"
        default: return "😣"
        }
    }
}
