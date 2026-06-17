import SwiftUI
import SwiftData

/// Past sessions grouped by week.
struct LogScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SwimSession.date, order: .reverse) private var sessions: [SwimSession]
    @AppStorage(PrefKey.unitsRaw) private var unitsRaw = DistanceUnit.meters.rawValue
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitsRaw) ?? .meters }
    private var fmt: UnitFormatter { UnitFormatter(unit: unit) }

    /// Sessions grouped into (weekStart, [sessions]) buckets, newest first.
    private var grouped: [(week: Date, sessions: [SwimSession])] {
        let cal = Calendar.current
        var buckets: [Date: [SwimSession]] = [:]
        for session in sessions {
            let start = StatsEngine.weekStart(for: session.date, calendar: cal)
            buckets[start, default: []].append(session)
        }
        return buckets
            .map { (week: $0.key, sessions: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.week > $1.week }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Log")
        }
    }

    @ViewBuilder
    private var content: some View {
        if sessions.isEmpty {
            EmptyStateView(symbol: "calendar",
                           title: "No swims logged",
                           message: "Finish a swim on the Swim tab and it will appear here, grouped by week.")
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18, pinnedViews: []) {
                    ForEach(grouped, id: \.week) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            weekHeader(group.week, sessions: group.sessions)
                            ForEach(group.sessions) { session in
                                NavigationLink {
                                    SessionDetailView(session: session)
                                } label: {
                                    SessionRow(session: session, unit: unit)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(session)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
    }

    private func weekHeader(_ week: Date, sessions: [SwimSession]) -> some View {
        let total = sessions.reduce(0) { $0 + $1.totalDistanceMeters }
        return HStack {
            Text(weekLabel(week))
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("\(fmt.distance(total)) · \(sessions.count) swim\(sessions.count == 1 ? "" : "s")")
                .font(.footnote)
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private func weekLabel(_ week: Date) -> String {
        let cal = Calendar.current
        if cal.isDate(week, equalTo: StatsEngine.weekStart(for: .now, calendar: cal), toGranularity: .day) {
            return "This week"
        }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let end = cal.date(byAdding: .day, value: 6, to: week) ?? week
        return "\(f.string(from: week)) – \(f.string(from: end))"
    }

    private func delete(_ session: SwimSession) {
        Haptics.warning(hapticsEnabled)
        context.delete(session)
        try? context.save()
    }
}

/// A row summarizing one session in the log.
struct SessionRow: View {
    let session: SwimSession
    let unit: DistanceUnit

    private var fmt: UnitFormatter { UnitFormatter(unit: unit) }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(session.date, format: .dateTime.day())
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(Theme.accent)
                Text(session.date, format: .dateTime.month(.abbreviated))
                    .font(.caption2)
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(width: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutName ?? "Free swim")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    Pill(text: fmt.distance(session.totalDistanceMeters), color: Theme.accent)
                    Pill(text: UnitFormatter.clock(Double(session.durationSeconds)), color: Theme.accentDeep, systemImage: "clock")
                    if let rpe = session.rpe {
                        Pill(text: "RPE \(rpe)", color: Theme.warn)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(session.workoutName ?? "Free swim"), \(fmt.distance(session.totalDistanceMeters)), on \(session.date.formatted(date: .abbreviated, time: .omitted))")
    }
}
