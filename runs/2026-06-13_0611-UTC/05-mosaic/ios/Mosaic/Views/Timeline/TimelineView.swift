import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \DayEntry.day, order: .reverse) private var entries: [DayEntry]

    private var grouped: [(String, [DayEntry])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: entries) { entry -> Date in
            cal.date(from: cal.dateComponents([.year, .month], from: entry.day)) ?? entry.day
        }
        return groups.keys.sorted(by: >).map { key in
            (key.formatted(.dateTime.month(.wide).year()), groups[key]!.sorted { $0.day > $1.day })
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if entries.isEmpty {
                    EmptyState(icon: "rectangle.stack",
                               title: "No moments yet",
                               message: "Days you capture appear here as a scrollable journal. Start with today.")
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14, pinnedViews: [.sectionHeaders]) {
                            ForEach(grouped, id: \.0) { month, days in
                                Section {
                                    ForEach(days) { entry in
                                        NavigationLink(value: entry) { TimelineRow(entry: entry) }
                                            .buttonStyle(.plain)
                                    }
                                } header: {
                                    Text(month).font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.ink)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 6).padding(.horizontal, 4).background(Theme.bg)
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                    }
                }
            }
            .navigationTitle("Timeline")
            .navigationDestination(for: DayEntry.self) { DayDetailView(entry: $0) }
        }
    }
}

struct TimelineRow: View {
    let entry: DayEntry
    var body: some View {
        HStack(spacing: 12) {
            if entry.hasPhoto {
                PhotoThumb(fileName: entry.photoFileName).frame(width: 64, height: 64)
            } else {
                RoundedRectangle(cornerRadius: 14).fill(Theme.moodColor(entry.moodIndex).opacity(0.45))
                    .frame(width: 64, height: 64)
                    .overlay(Circle().fill(Theme.moodColor(entry.moodIndex)).frame(width: 18, height: 18))
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.day, format: .dateTime.weekday(.abbreviated).day())
                        .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.ink)
                    Circle().fill(Theme.moodColor(entry.moodIndex)).frame(width: 9, height: 9)
                    Text(Theme.mood(entry.moodIndex)?.name ?? "").font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                }
                if entry.caption.isEmpty {
                    Text("No note").font(.system(size: 13)).italic().foregroundStyle(Theme.inkFaint)
                } else {
                    Text(entry.caption).font(.system(size: 14)).foregroundStyle(Theme.inkSoft).lineLimit(2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.day.formatted(.dateTime.weekday().month().day())), \(Theme.mood(entry.moodIndex)?.name ?? ""). \(entry.caption)")
    }
}

struct DayDetailView: View {
    @Bindable var entry: DayEntry
    @State private var editing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if entry.hasPhoto {
                    PhotoThumb(fileName: entry.photoFileName, cornerRadius: 20)
                        .frame(height: 300).frame(maxWidth: .infinity)
                } else {
                    RoundedRectangle(cornerRadius: 20).fill(Theme.moodColor(entry.moodIndex).opacity(0.4))
                        .frame(height: 180)
                        .overlay(Image(systemName: "sun.max.fill").font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.9)))
                }
                HStack(spacing: 8) {
                    Circle().fill(Theme.moodColor(entry.moodIndex)).frame(width: 16, height: 16)
                    Text(Theme.mood(entry.moodIndex)?.name ?? "").font(Theme.rounded(18))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
                if !entry.caption.isEmpty {
                    Text(entry.caption).font(.system(size: 17)).foregroundStyle(Theme.ink)
                        .lineSpacing(4).fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No note for this day.").font(.system(size: 15)).italic().foregroundStyle(Theme.inkFaint)
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(entry.day.formatted(.dateTime.month().day().year()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Edit") { editing = true } } }
        .sheet(isPresented: $editing) { EntryEditor(day: entry.day, existing: entry) }
    }
}
