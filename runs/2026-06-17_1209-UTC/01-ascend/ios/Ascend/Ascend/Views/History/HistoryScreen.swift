import SwiftUI
import SwiftData

/// History — completed sessions grouped by week, newest first.
struct HistoryScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(filter: #Predicate<WorkoutSession> { $0.isComplete },
           sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    private var grouped: [(label: String, sessions: [WorkoutSession])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: sessions) { session -> Date in
            cal.dateInterval(of: .weekOfYear, for: session.date)?.start ?? session.date
        }
        return groups
            .sorted { $0.key > $1.key }
            .map { (weekLabel(for: $0.key), $0.value.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if sessions.isEmpty {
                    EmptyStateView(symbol: "clock.arrow.circlepath",
                                   title: "No sessions yet",
                                   message: "Finish a workout in the Today tab and it'll show up here with all your sets.")
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                            ForEach(grouped, id: \.label) { group in
                                Section {
                                    ForEach(group.sessions) { session in
                                        NavigationLink {
                                            SessionDetailView(session: session)
                                        } label: {
                                            SessionRow(session: session)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } header: {
                                    Text(group.label.uppercased())
                                        .font(Theme.rounded(13, .bold))
                                        .foregroundStyle(Theme.inkSoft)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 6)
                                        .background(Theme.bg)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private func weekLabel(for weekStart: Date) -> String {
        let cal = Calendar.current
        if cal.isDate(weekStart, equalTo: Date(), toGranularity: .weekOfYear) {
            return "This week"
        }
        if let lastWeek = cal.date(byAdding: .weekOfYear, value: -1, to: Date()),
           cal.isDate(weekStart, equalTo: lastWeek, toGranularity: .weekOfYear) {
            return "Last week"
        }
        return "Week of " + weekStart.formatted(date: .abbreviated, time: .omitted)
    }
}

/// Compact session summary row.
private struct SessionRow: View {
    let session: WorkoutSession
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Card {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.dayName)
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                    HStack(spacing: 10) {
                        statText("\(session.completedSetCount) sets")
                        statText(durationText)
                        statText(settings.weight(session.totalVolumeKg) + " vol")
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func statText(_ s: String) -> some View {
        Text(s)
            .font(Theme.rounded(12, .medium))
            .foregroundStyle(Theme.steel)
    }

    private var durationText: String {
        let m = session.durationSeconds / 60
        return "\(m) min"
    }
}
