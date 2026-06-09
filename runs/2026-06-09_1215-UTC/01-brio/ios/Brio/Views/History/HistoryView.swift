import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    private var summary: StatsEngine.Summary { StatsEngine.summary(sessions) }

    /// Sessions grouped by calendar day, newest day first.
    private var grouped: [(day: Date, items: [WorkoutSession])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: sessions) { cal.startOfDay(for: $0.date) }
        return dict.keys.sorted(by: >).map { ($0, dict[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "calendar",
                                       title: "No sessions yet",
                                       message: "Finish a workout and it'll show up here, grouped by day.")
                            .glassCard()
                            .padding(20)
                    }
                } else {
                    List {
                        Section {
                            streakHeader
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
                                .listRowBackground(Color.clear)
                        }
                        ForEach(grouped, id: \.day) { group in
                            Section {
                                ForEach(group.items) { session in
                                    NavigationLink {
                                        SessionDetailView(session: session)
                                    } label: {
                                        SessionRow(session: session)
                                    }
                                    .listRowBackground(Color.clear)
                                }
                                .onDelete { offsets in
                                    delete(offsets, in: group.items)
                                }
                            } header: {
                                Text(headerLabel(group.day))
                                    .foregroundStyle(Brand.text2)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("History")
        }
    }

    private var streakHeader: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(summary.currentStreak)", label: "Day streak", tint: Brand.magic)
            StatTile(value: "\(summary.sessionsThisWeek)", label: "This week")
            StatTile(value: Format.duration(summary.totalMinutes * 60), label: "Total time")
        }
    }

    private func headerLabel(_ day: Date) -> String {
        Format.relativeDay(day)
    }

    private func delete(_ offsets: IndexSet, in items: [WorkoutSession]) {
        for index in offsets {
            guard items.indices.contains(index) else { continue }
            context.delete(items[index])
        }
        try? context.save()
        Haptics.warning()
    }
}

struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.workoutCategory.symbol)
                .font(.body)
                .foregroundStyle(session.workoutCategory.tint)
                .frame(width: 40, height: 40)
                .background(session.workoutCategory.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.workoutName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Text("\(Format.duration(session.actualSeconds)) · \(session.workoutCategory.label)")
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if !session.completed {
                    TagChip(text: "Ended early", tint: Brand.warn)
                } else if session.feeling > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...session.feeling, id: \.self) { _ in
                            Circle().fill(Brand.live).frame(width: 5, height: 5)
                        }
                    }
                    .accessibilityHidden(true)
                }
                Text(session.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(Brand.text3)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.workoutName), \(Format.duration(session.actualSeconds)), \(session.completed ? "completed" : "ended early")")
    }
}
