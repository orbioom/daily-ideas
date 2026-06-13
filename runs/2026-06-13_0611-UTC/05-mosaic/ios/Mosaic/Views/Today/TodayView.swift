import SwiftUI
import SwiftData

struct EditorTarget: Identifiable {
    let day: Date
    let entry: DayEntry?
    var id: Date { day }
}

struct TodayView: View {
    @Query(sort: \DayEntry.day, order: .reverse) private var entries: [DayEntry]
    @State private var target: EditorTarget?

    private var today: Date { Calendar.current.startOfDay(for: .now) }
    private var todayEntry: DayEntry? {
        entries.first { Calendar.current.isDate($0.day, inSameDayAs: today) }
    }
    private var memories: [DayEntry] { MosaicStats.memories(entries) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    todayCard
                    statsRow
                    monthStrip
                    if !memories.isEmpty { memoriesSection }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(today.formatted(.dateTime.weekday(.wide).month().day()))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $target) { t in EntryEditor(day: t.day, existing: t.entry) }
        }
    }

    private var todayCard: some View {
        Group {
            if let entry = todayEntry {
                Button { target = EditorTarget(day: today, entry: entry) } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        if entry.hasPhoto {
                            PhotoThumb(fileName: entry.photoFileName, cornerRadius: 0)
                                .frame(height: 220).clipped()
                        } else {
                            Theme.moodColor(entry.moodIndex).opacity(0.5).frame(height: 120)
                                .overlay(Image(systemName: "sun.max.fill").font(.system(size: 34))
                                    .foregroundStyle(.white.opacity(0.9)))
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                moodBadge(entry.moodIndex)
                                Spacer()
                                Label("Edit", systemImage: "pencil").font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.accent)
                            }
                            if !entry.caption.isEmpty {
                                Text(entry.caption).font(.system(size: 15)).foregroundStyle(Theme.ink)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(16)
                    }
                    .background(RoundedRectangle(cornerRadius: 22).fill(Theme.surface))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
                .buttonStyle(.plain)
            } else {
                Button { target = EditorTarget(day: today, entry: nil) } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.circle.fill").font(.system(size: 50)).foregroundStyle(Theme.accent)
                        Text("Capture today").font(Theme.rounded(22)).foregroundStyle(Theme.ink)
                        Text("Add a photo and how the day felt — it only takes a moment.")
                            .font(.system(size: 14)).foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center).padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 36)
                    .background(RoundedRectangle(cornerRadius: 22).fill(Theme.surface))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func moodBadge(_ index: Int) -> some View {
        HStack(spacing: 6) {
            Circle().fill(Theme.moodColor(index)).frame(width: 12, height: 12)
            Text(Theme.mood(index)?.name ?? "").font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(MosaicStats.currentStreak(entries))", label: "Day streak")
            StatTile(value: "\(entries.count)", label: "Days kept")
            StatTile(value: String(format: "%.1f", MosaicStats.averageMood(entries)),
                     label: "Avg mood", color: Theme.moodColor(Int(MosaicStats.averageMood(entries).rounded())))
        }
    }

    private var monthStrip: some View {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: today)
        let monthStart = cal.date(from: comps) ?? today
        let range = cal.range(of: .day, in: .month, for: monthStart) ?? (1..<29)
        let byDay = Dictionary(uniqueKeysWithValues: entries.map { (cal.startOfDay(for: $0.day), $0) })
        let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)

        return VStack(alignment: .leading, spacing: 8) {
            Text(today.formatted(.dateTime.month(.wide))).font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(range, id: \.self) { d in
                    let date = cal.date(byAdding: .day, value: d - 1, to: monthStart) ?? monthStart
                    let entry = byDay[cal.startOfDay(for: date)]
                    let future = date > today
                    Button {
                        if !future { target = EditorTarget(day: date, entry: entry) }
                    } label: {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(entry.map { Theme.moodColor($0.moodIndex) } ?? Theme.emptyTile)
                            .aspectRatio(1, contentMode: .fit)
                            .opacity(future ? 0.35 : 1)
                            .overlay {
                                if cal.isDate(date, inSameDayAs: today) {
                                    RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.accent, lineWidth: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(future)
                    .accessibilityLabel("\(date.formatted(.dateTime.month().day())), \(entry.map { Theme.mood($0.moodIndex)?.name ?? "" } ?? "no entry")")
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface))
    }

    private var memoriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("On this day", systemImage: "clock.arrow.circlepath")
                .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.inkFaint)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(memories) { entry in
                        Button { target = EditorTarget(day: entry.day, entry: entry) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                if entry.hasPhoto {
                                    PhotoThumb(fileName: entry.photoFileName).frame(width: 150, height: 110)
                                } else {
                                    RoundedRectangle(cornerRadius: 14).fill(Theme.moodColor(entry.moodIndex).opacity(0.5))
                                        .frame(width: 150, height: 110)
                                }
                                Text(entry.day, format: .dateTime.month().day().year())
                                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.inkSoft)
                                if !entry.caption.isEmpty {
                                    Text(entry.caption).font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
                                        .lineLimit(2).frame(width: 150, alignment: .leading)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
