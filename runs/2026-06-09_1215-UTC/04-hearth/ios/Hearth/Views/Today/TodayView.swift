import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Room.sortIndex) private var rooms: [Room]

    @AppStorage("hearth.soonWindowDays") private var soonWindowDays = 3
    @AppStorage("hearth.includeSoonInToday") private var includeSoon = false
    @AppStorage("hearth.showEstimatedTime") private var showEstimatedTime = true

    private var cleanliness: Double { HearthEngine.homeCleanliness(rooms) }

    private var items: [HearthEngine.DueItem] {
        HearthEngine.todaysTasks(rooms,
                                 soonWindowDays: soonWindowDays,
                                 includeSoon: includeSoon)
    }

    private var grouped: [(status: HearthEngine.DueStatus, items: [HearthEngine.DueItem])] {
        let order: [HearthEngine.DueStatus] = [.overdue, .today, .soon]
        return order.compactMap { status in
            let matching = items.filter { $0.status == status }
            return matching.isEmpty ? nil : (status, matching)
        }
    }

    private var totalMinutes: Int {
        items.reduce(0) { $0 + $1.task.estMinutes }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    gauge

                    if rooms.isEmpty {
                        EmptyStateView(icon: "house",
                                       title: "No rooms yet",
                                       message: "Add rooms and chores in the Rooms tab to start tracking your home.")
                            .glassCard()
                    } else if items.isEmpty {
                        EmptyStateView(icon: "sparkles",
                                       title: "All fresh — nothing due",
                                       message: "Every room is on top of its rotation. Enjoy the calm.")
                            .glassCard()
                    } else {
                        ForEach(grouped, id: \.status) { group in
                            section(for: group.status, items: group.items)
                        }
                    }
                }
                .padding(20)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Today")
        }
    }

    // MARK: - Gauge

    private var gauge: some View {
        let tint = gaugeTint(cleanliness)
        return VStack(spacing: 14) {
            ZStack {
                ProgressRing(progress: cleanliness, lineWidth: 16, tint: tint)
                    .frame(width: 168, height: 168)
                VStack(spacing: 2) {
                    Text(Format.percent(cleanliness))
                        .font(Brand.mono(40, weight: .semibold))
                        .foregroundStyle(Brand.text)
                    Text("clean")
                        .font(Brand.mono(12, weight: .medium))
                        .tracking(1.2)
                        .foregroundStyle(Brand.text3)
                }
            }
            Text(gaugeCaption)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Whole-home cleanliness")
        .accessibilityValue("\(Format.percent(cleanliness)). \(gaugeCaption)")
    }

    private var gaugeCaption: String {
        if rooms.isEmpty { return "Add rooms to see your home's freshness." }
        let count = items.filter { $0.status == .overdue || $0.status == .today }.count
        if count == 0 { return "Nothing due — your home is fresh." }
        let timePart = showEstimatedTime ? " · about \(Format.duration(minutes: totalMinutes))" : ""
        return "\(count) \(count == 1 ? "chore" : "chores") need attention\(timePart)."
    }

    private func gaugeTint(_ value: Double) -> Color {
        if value >= 0.75 { return Brand.live }
        if value >= 0.5 { return Brand.warn }
        return Brand.danger
    }

    // MARK: - Sections

    private func section(for status: HearthEngine.DueStatus, items: [HearthEngine.DueItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusPill(status: status)
                Spacer()
                Text("\(items.count)")
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text3)
            }
            ForEach(items) { item in
                TodayTaskRow(task: item.task,
                             status: item.status,
                             showTime: showEstimatedTime) {
                    markDone(item.task)
                }
            }
        }
        .glassCard()
    }

    private func markDone(_ task: CleaningTask) {
        withAnimation(Brand.ease(0.35)) {
            TaskActions.markDone(task, context: context)
        }
    }
}

/// A single due-task row on Today with a one-tap Done button.
private struct TodayTaskRow: View {
    let task: CleaningTask
    let status: HearthEngine.DueStatus
    let showTime: Bool
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(task.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                HStack(spacing: 6) {
                    Text(task.roomName.isEmpty ? "Home" : task.roomName)
                    if showTime {
                        Text("·")
                        Text(Format.duration(minutes: task.estMinutes))
                    }
                }
                .font(Brand.mono(12))
                .foregroundStyle(Brand.text3)
            }
            Spacer()
            Button(action: onDone) {
                Image(systemName: "checkmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(status.color.gradient, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(task.name) done")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.name), \(task.roomName.isEmpty ? "Home" : task.roomName), \(status.label)")
        .accessibilityHint("Double tap the button to mark done")
    }
}
