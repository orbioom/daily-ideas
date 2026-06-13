import SwiftUI
import SwiftData

struct YearView: View {
    @Query(sort: \DayEntry.day, order: .reverse) private var entries: [DayEntry]
    @State private var year = Calendar.current.component(.year, from: .now)
    @State private var target: EditorTarget?

    private let cal = Calendar.current

    private var yearEntries: [Date: DayEntry] { MosaicStats.entriesInYear(entries, year: year) }
    private var yearList: [DayEntry] { Array(yearEntries.values) }
    private var years: [Int] { MosaicStats.availableYears(entries) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if entries.isEmpty {
                    EmptyState(icon: "square.grid.3x3",
                               title: "Your year is empty",
                               message: "Capture a few days and watch your year fill in with color, one tile at a time.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            yearHeader
                            legend
                            grid
                            distribution
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Year in Pixels")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $target) { t in EntryEditor(day: t.day, existing: t.entry) }
        }
    }

    private var yearHeader: some View {
        HStack {
            Menu {
                ForEach(years, id: \.self) { y in
                    Button("\(String(y))") { year = y }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(String(year)).font(Theme.rounded(26)).foregroundStyle(Theme.ink)
                    Image(systemName: "chevron.down").font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            Spacer()
            Text("\(yearList.count) days").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.accent)
        }
    }

    private var legend: some View {
        HStack(spacing: 12) {
            ForEach(Theme.moods) { mood in
                HStack(spacing: 4) {
                    Circle().fill(mood.color).frame(width: 10, height: 10)
                    Text(mood.name).font(.system(size: 11)).foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityHidden(true)
    }

    private var grid: some View {
        VStack(spacing: 6) {
            ForEach(1...12, id: \.self) { month in
                monthRow(month)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
    }

    private func monthRow(_ month: Int) -> some View {
        let comps = DateComponents(year: year, month: month, day: 1)
        let monthStart = cal.date(from: comps) ?? .now
        let dayCount = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let today = cal.startOfDay(for: .now)
        return HStack(spacing: 3) {
            Text(monthStart.formatted(.dateTime.month(.narrow)))
                .font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.inkFaint)
                .frame(width: 16, alignment: .leading)
            GeometryReader { geo in
                let tile = (geo.size.width - CGFloat(30) * 3) / 31
                HStack(spacing: 3) {
                    ForEach(1...31, id: \.self) { d in
                        if d <= dayCount {
                            let date = cal.date(from: DateComponents(year: year, month: month, day: d)) ?? monthStart
                            let entry = yearEntries[cal.startOfDay(for: date)]
                            let future = date > today
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(entry.map { Theme.moodColor($0.moodIndex) } ?? Theme.emptyTile)
                                .frame(width: tile, height: tile)
                                .opacity(future ? 0.3 : 1)
                                .onTapGesture { if !future { target = EditorTarget(day: date, entry: entry) } }
                        } else {
                            Color.clear.frame(width: tile, height: tile)
                        }
                    }
                }
            }
            .frame(height: 9)
        }
        .accessibilityElement()
        .accessibilityLabel("\(monthStart.formatted(.dateTime.month(.wide))), \(yearList.filter { cal.component(.month, from: $0.day) == month }.count) days kept")
    }

    private var distribution: some View {
        let counts = MosaicStats.moodCounts(yearList)
        let maxCount = max(1, counts.map { $0.count }.max() ?? 1)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Mood mix").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink)
            ForEach(counts, id: \.mood.id) { item in
                HStack(spacing: 10) {
                    Text(item.mood.name).font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
                        .frame(width: 52, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surfaceAlt)
                            Capsule().fill(item.mood.color)
                                .frame(width: max(6, geo.size.width * CGFloat(item.count) / CGFloat(maxCount)))
                        }
                    }
                    .frame(height: 14)
                    Text("\(item.count)").font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.inkSoft).frame(width: 30, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
    }
}
