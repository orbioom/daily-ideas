import SwiftUI
import SwiftData
import Charts

private struct DayCompletion: Identifiable {
    let id: String   // dayKey
    let date: Date
    let completed: Int
}

struct TrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var logs: [PrayerLog]
    @AppStorage("cityID") private var cityID = Gazetteer.defaultCityID

    @State private var selectedDayOffset = 0

    private var timeZone: TimeZone {
        (Gazetteer.city(id: cityID) ?? Gazetteer.cities[0]).timeZone
    }

    private var selectedDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedDayOffset, to: .now) ?? .now
    }

    private var selectedDayKey: String {
        DayKey.make(for: selectedDate, timeZone: timeZone)
    }

    private func log(for prayer: Prayer, dayKey: String) -> PrayerLog? {
        logs.first { $0.dayKey == dayKey && $0.prayerRaw == prayer.rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    streakHeader
                    daySelector
                    checklist
                    historyChart
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Prayer Tracker")
        }
    }

    // MARK: - Streak

    /// Days (ending today, allowing today to be incomplete) where all 5 prayers were logged.
    private var streak: Int {
        var streak = 0
        var offset = 0
        let calendar = Calendar.current
        while offset > -3650 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: .now) else { break }
            let key = DayKey.make(for: day, timeZone: timeZone)
            let done = Prayer.obligatory.filter { log(for: $0, dayKey: key) != nil }.count
            if done == 5 {
                streak += 1
            } else if offset == 0 {
                // Today may still be in progress; don't break the streak for it.
            } else {
                break
            }
            offset -= 1
        }
        return streak
    }

    private var streakHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(streak) day\(streak == 1 ? "" : "s")")
                    .font(.title2.weight(.semibold))
                    .fontDesign(.serif)
                Text("all five prayers logged")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 34))
                .foregroundStyle(streak > 0 ? MihrabTheme.gold : Color(.systemGray3))
                .accessibilityHidden(true)
        }
        .mihrabPanel()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Day selector (last 7 days strip)

    private var daySelector: some View {
        HStack(spacing: 8) {
            ForEach((-6...0).reversed(), id: \.self) { offset in
                let day = Calendar.current.date(byAdding: .day, value: offset, to: .now) ?? .now
                let key = DayKey.make(for: day, timeZone: timeZone)
                let done = Prayer.obligatory.filter { log(for: $0, dayKey: key) != nil }.count
                Button {
                    Haptics.tap()
                    selectedDayOffset = offset
                } label: {
                    VStack(spacing: 4) {
                        Text(day, format: .dateTime.weekday(.narrow))
                            .font(.caption2.weight(.semibold))
                        Text(day, format: .dateTime.day())
                            .font(.callout.weight(.semibold))
                        Circle()
                            .fill(done == 5 ? MihrabTheme.gold : (done > 0 ? MihrabTheme.gold.opacity(0.35) : Color(.systemGray5)))
                            .frame(width: 7, height: 7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(offset == selectedDayOffset ? MihrabTheme.gold.opacity(0.18) : Color(.secondarySystemGroupedBackground))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide).day().month())), \(done) of 5 prayers logged")
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: - Checklist

    private var checklist: some View {
        let key = selectedDayKey
        return VStack(spacing: 0) {
            HStack {
                Text(selectedDate, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.headline)
                Spacer()
                if selectedDayOffset != 0 {
                    Button("Today") {
                        Haptics.tap()
                        selectedDayOffset = 0
                    }
                    .font(.caption.weight(.semibold))
                }
            }
            .padding(.bottom, 8)

            ForEach(Prayer.obligatory) { prayer in
                let existing = log(for: prayer, dayKey: key)
                Button {
                    cycle(prayer: prayer, dayKey: key)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: statusIcon(existing))
                            .font(.title3)
                            .foregroundStyle(statusColor(existing))
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(prayer.displayName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(existing.map { $0.status.displayName } ?? "Not logged")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(prayer.arabicName)
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(prayer.displayName): \(existing.map { $0.status.displayName } ?? "not logged")")
                .accessibilityHint("Tap to cycle between prayed, prayed late, and not logged")
                if prayer != .isha {
                    Divider().padding(.leading, 44)
                }
            }
        }
        .mihrabPanel()
    }

    private func statusIcon(_ log: PrayerLog?) -> String {
        guard let log else { return "circle" }
        return log.status == .prayed ? "checkmark.circle.fill" : "clock.badge.checkmark.fill"
    }

    private func statusColor(_ log: PrayerLog?) -> Color {
        guard let log else { return Color(.systemGray3) }
        return log.status == .prayed ? MihrabTheme.gold : .orange
    }

    /// none → prayed → late → none
    private func cycle(prayer: Prayer, dayKey: String) {
        Haptics.tap()
        if let existing = log(for: prayer, dayKey: dayKey) {
            switch existing.status {
            case .prayed:
                existing.statusRaw = PrayerStatus.late.rawValue
            case .late:
                modelContext.delete(existing)
            }
        } else {
            let othersDone = Prayer.obligatory.filter { $0 != prayer && log(for: $0, dayKey: dayKey) != nil }.count
            modelContext.insert(PrayerLog(dayKey: dayKey, prayer: prayer, status: .prayed))
            if othersDone == 4 { Haptics.success() } // that was the fifth — full day
        }
    }

    // MARK: - 30-day chart

    private var completions: [DayCompletion] {
        let calendar = Calendar.current
        var result: [DayCompletion] = []
        for offset in stride(from: -29, through: 0, by: 1) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: .now) else { continue }
            let key = DayKey.make(for: day, timeZone: timeZone)
            let done = Prayer.obligatory.filter { log(for: $0, dayKey: key) != nil }.count
            result.append(DayCompletion(id: key, date: calendar.startOfDay(for: day), completed: done))
        }
        return result
    }

    private var historyChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 30 Days")
                .font(.headline)
            if logs.isEmpty {
                Text("Log prayers above and your consistency will chart here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                Chart(completions) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Prayers", day.completed)
                    )
                    .foregroundStyle(day.completed == 5 ? MihrabTheme.gold : MihrabTheme.gold.opacity(0.45))
                    .cornerRadius(2)
                }
                .chartYScale(domain: 0...5)
                .frame(height: 160)
                .accessibilityLabel("Bar chart of prayers logged per day over the last 30 days")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mihrabPanel()
    }
}
