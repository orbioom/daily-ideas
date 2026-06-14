import SwiftUI
import SwiftData

/// All readings grouped by day with filter and full CRUD (add / edit / swipe-delete).
struct HistoryScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Reading.date, order: .reverse) private var readings: [Reading]

    @State private var filter: ContextFilter = .all
    @State private var showAdd = false
    @State private var editingReading: Reading?

    private enum ContextFilter: Hashable, Identifiable {
        case all
        case context(ReadingContext)
        var id: String {
            switch self {
            case .all: return "all"
            case .context(let c): return c.rawValue
            }
        }
        var label: String {
            switch self {
            case .all: return "All"
            case .context(let c): return c.label
            }
        }
    }

    private var filtered: [Reading] {
        switch filter {
        case .all: return readings
        case .context(let c): return readings.filter { $0.context == c }
        }
    }

    /// Grouped by start-of-day, newest day first; stable section ids.
    private var sections: [(day: Date, items: [Reading])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.date) }
        return groups
            .map { (day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if readings.isEmpty {
                    EmptyStateView(symbol: "list.bullet.rectangle",
                                   title: "No history yet",
                                   message: "Every reading you log shows up here, grouped by day.",
                                   actionTitle: "Log reading") { showAdd = true }
                } else {
                    content
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { filterMenu }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus").accessibilityLabel("Log reading")
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddReadingSheet() }
            .sheet(item: $editingReading) { r in AddReadingSheet(editing: r) }
        }
    }

    private var content: some View {
        List {
            ForEach(sections, id: \.day) { section in
                Section {
                    ForEach(section.items) { r in
                        Button { editingReading = r } label: {
                            ReadingRow(reading: r)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.surface)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { delete(r) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    sectionHeader(section.day, count: section.items.count)
                }
            }
            if filtered.isEmpty {
                Section {
                    Text("No readings match this filter.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .listRowBackground(Theme.surface)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
    }

    private func sectionHeader(_ day: Date, count: Int) -> some View {
        let dayReadings = sections.first { Calendar.current.isDate($0.day, inSameDayAs: day) }?.items ?? []
        let avg = GlucoseEngine.averageMgdl(dayReadings)
        return HStack {
            Text(dayLabel(day))
                .font(Theme.rounded(13, .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            if avg > 0 {
                Text("avg \(settings.formatValue(avg))")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(settings.band(for: avg).color)
            }
        }
        .textCase(nil)
    }

    private var filterMenu: some View {
        Menu {
            Picker("Filter", selection: $filter) {
                Text("All").tag(ContextFilter.all)
                ForEach(ReadingContext.allCases) { c in
                    Label(c.label, systemImage: c.symbol).tag(ContextFilter.context(c))
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text(filter.label).font(Theme.rounded(14, .medium))
            }
            .accessibilityLabel("Filter by context, currently \(filter.label)")
        }
    }

    private func dayLabel(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func delete(_ reading: Reading) {
        context.delete(reading)
        try? context.save()
        Haptics.warning(settings.hapticsEnabled)
    }
}
