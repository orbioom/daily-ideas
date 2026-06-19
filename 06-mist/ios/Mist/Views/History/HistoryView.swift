import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \TherapySession.date, order: .reverse) private var sessions: [TherapySession]
    @State private var filterType: TherapyType? = nil
    @AppStorage("mistUseFahrenheit") private var useFahrenheit = false
    @Environment(\.modelContext) private var modelContext

    private var filtered: [TherapySession] {
        if let t = filterType { return sessions.filter { $0.type == t } }
        return sessions
    }

    private var stats: SessionStats { SessionStats(sessions: Array(sessions)) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.18, blue: 0.22), Color(red: 0.02, green: 0.08, blue: 0.12)],
                          startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            if sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        Text("History")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 20)
                            .padding(.horizontal, 20)

                        weeklyChart
                        filterBar
                        sessionList
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Minutes")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 20)

            let data = stats.weeklyMinutes(weeks: 6)
            Chart(data, id: \.week) { d in
                BarMark(
                    x: .value("Week", d.week),
                    y: .value("Min", d.minutes)
                )
                .foregroundStyle(Color(red: 0.2, green: 0.85, blue: 0.85).gradient)
                .cornerRadius(4)
            }
            .chartYAxis { AxisMarks(stroke: StrokeStyle(lineWidth: 0)) }
            .chartXAxis {
                AxisMarks(values: .automatic) {
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.4))
                        .font(.system(size: 10))
                }
            }
            .frame(height: 120)
            .padding(.horizontal, 20)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip(label: "All", selected: filterType == nil) { filterType = nil }
                ForEach(TherapyType.allCases) { t in
                    filterChip(label: t.rawValue, selected: filterType == t) { filterType = t }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func filterChip(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(selected ? .white : .white.opacity(0.55))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selected ? Color(red: 0.15, green: 0.7, blue: 0.7) : Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    private var sessionList: some View {
        LazyVStack(spacing: 10) {
            ForEach(filtered) { s in
                sessionCard(s)
            }
        }
        .padding(.horizontal, 20)
    }

    private func sessionCard(_ s: TherapySession) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(s.type.isHot ? Color.orange.opacity(0.2) : Color.cyan.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: s.type.symbol)
                    .foregroundStyle(s.type.isHot ? .orange : .cyan)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(s.type.rawValue)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Text("\(s.durationSeconds / 60) min")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                    Text("·")
                        .foregroundStyle(.white.opacity(0.3))
                    Text(tempStr(s.temperatureCelsius))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                    if s.rounds > 1 {
                        Text("· \(s.rounds) rounds")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(s.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= s.rating ? "star.fill" : "star")
                            .font(.system(size: 9))
                            .foregroundStyle(i <= s.rating ? .yellow : .white.opacity(0.2))
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { modelContext.delete(s) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 52))
                .foregroundStyle(Color(red: 0.2, green: 0.85, blue: 0.85).opacity(0.6))
            Text("No history yet")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text("Your completed sessions will appear here.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(40)
    }

    private func tempStr(_ c: Double) -> String {
        if useFahrenheit { return String(format: "%.0f°F", c * 9/5 + 32) }
        return String(format: "%.0f°C", c)
    }
}
