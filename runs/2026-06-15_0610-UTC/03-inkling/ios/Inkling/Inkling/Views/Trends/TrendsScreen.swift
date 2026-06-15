import SwiftUI
import SwiftData

/// Pick a tracker → see a 30/90-day trend chart, its rolling stats, and a calendar of logged days.
/// Tapping a day opens a Day Detail of every value logged that day, with inline edit.
struct TrendsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Tracker.sortOrder) private var trackers: [Tracker]

    @State private var selectedID: UUID?
    @State private var range: TimeRange = .days30
    @State private var detailDay: Date?
    @State private var didInit = false

    private var visibleTrackers: [Tracker] {
        trackers.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var selected: Tracker? {
        if let selectedID { return trackers.first { $0.id == selectedID } }
        return visibleTrackers.first(where: \.isActive) ?? visibleTrackers.first
    }

    var body: some View {
        NavigationStack {
            Group {
                if visibleTrackers.isEmpty {
                    EmptyStateView(symbol: "chart.xyaxis.line",
                                   title: "No trackers yet",
                                   message: "Create a tracker and log a few days to see trends here.")
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Trends")
            .sheet(item: dayBinding) { day in
                DayDetailView(day: day.date, trackers: trackers)
            }
        }
        .onAppear {
            if !didInit {
                range = settings.defaultRange
                if selectedID == nil { selectedID = selected?.id }
                didInit = true
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                trackerPicker

                if let tracker = selected {
                    let points = pointsFor(tracker)
                    TrendChartCard(tracker: tracker, points: points, range: range)
                    rangePicker
                    statsRow(for: tracker, points: points)
                    LoggedCalendarCard(tracker: tracker) { day in
                        Haptics.select(settings.hapticsEnabled)
                        detailDay = day
                    }
                }
            }
            .padding(16)
        }
    }

    private var trackerPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(visibleTrackers) { tracker in
                    let isSel = tracker.id == selected?.id
                    Button {
                        Haptics.select(settings.hapticsEnabled)
                        selectedID = tracker.id
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tracker.symbolName)
                                .font(.system(size: 12, weight: .semibold))
                                .accessibilityHidden(true)
                            Text(tracker.name).font(Theme.rounded(14, .semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .foregroundStyle(isSel ? .white : Theme.ink)
                        .background(
                            Capsule().fill(isSel ? tracker.color : Theme.surface)
                        )
                        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: isSel ? 0 : 1))
                    }
                    .accessibilityLabel(tracker.name)
                    .accessibilityValue(isSel ? "Selected" : "")
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            Text("30 days").tag(TimeRange.days30)
            Text("90 days").tag(TimeRange.days90)
            Text("All").tag(TimeRange.all)
        }
        .pickerStyle(.segmented)
    }

    private func statsRow(for tracker: Tracker, points: [TrendPoint]) -> some View {
        let summary = StatsEngine.summary(points: points.map { ($0.date, $0.value) })
        return CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: summary.trend.symbol)
                        .foregroundStyle(tracker.color)
                        .accessibilityHidden(true)
                    Text(summary.trend.label)
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(summary.streak)-day streak")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                HStack(spacing: 10) {
                    StatTile(value: display(summary.average7, tracker), caption: "7-day avg")
                    StatTile(value: display(summary.average30, tracker), caption: "30-day avg")
                    StatTile(value: display(summary.current, tracker), caption: "Latest", color: tracker.color)
                }
                HStack(spacing: 10) {
                    StatTile(value: display(summary.minValue, tracker), caption: "Min")
                    StatTile(value: display(summary.maxValue, tracker), caption: "Max")
                    StatTile(value: "\(summary.count)", caption: "Logged days")
                }
            }
        }
    }

    private func display(_ value: Double?, _ tracker: Tracker) -> String {
        guard let value else { return "—" }
        return tracker.displayValue(value, scale10: settings.useScale10)
    }

    // MARK: Data

    private func pointsFor(_ tracker: Tracker) -> [TrendPoint] {
        let cutoff: Date? = range.days.flatMap {
            DayMath.calendar.date(byAdding: .day, value: -($0 - 1), to: DayMath.startOfDay(Date()))
        }
        return tracker.sortedEntries.compactMap { entry in
            if let cutoff, entry.date < cutoff { return nil }
            return TrendPoint(date: DayMath.startOfDay(entry.date), value: entry.value)
        }
    }

    private var dayBinding: Binding<DayWrapper?> {
        Binding(
            get: { detailDay.map(DayWrapper.init) },
            set: { detailDay = $0?.date }
        )
    }
}

/// A single trend data point.
struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

/// Identifiable wrapper so a `Date` can drive `.sheet(item:)`.
struct DayWrapper: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSince1970 }
}
