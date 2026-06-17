import SwiftUI
import SwiftData
import Charts

struct SiteDetailView: View {
    let site: MeasurementSite

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @Query private var entries: [MeasurementEntry]

    @State private var showAddEntry = false
    @State private var editingEntry: MeasurementEntry?
    @State private var showGoalEditor = false
    @State private var toast: String?

    init(site: MeasurementSite) {
        self.site = site
        let key = site.key
        _entries = Query(
            filter: #Predicate<MeasurementEntry> { $0.siteKey == key },
            sort: \MeasurementEntry.date
        )
    }

    /// Entries visible to the user, respecting the free 90-day history cap.
    private var visibleEntries: [MeasurementEntry] {
        let sorted = entries.sorted { $0.date < $1.date }
        guard !proStore.isPro else { return sorted }
        let cutoff = Calendar.current.date(byAdding: .day, value: -ProGate.freeHistoryDays, to: Date()) ?? .distantPast
        return sorted.filter { $0.date >= cutoff }
    }

    private var stats: SiteStats { SiteStats.compute(entries: visibleEntries) }
    private var kind: UnitKind { site.unitKind }
    private var unit: String { Units.unitLabel(kind: kind, system: settings.unitSystem) }

    private var historyTrimmed: Bool {
        !proStore.isPro && visibleEntries.count < entries.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if visibleEntries.isEmpty {
                    EmptyStateView(
                        icon: SiteCatalog.symbol(for: site.key),
                        title: "No entries for \(site.name)",
                        message: "Add your first \(site.name.lowercased()) measurement to start a trend.",
                        actionTitle: "Add entry",
                        action: { showAddEntry = true }
                    )
                    .padding(.top, 40)
                } else {
                    chartCard
                    statsCard
                    goalCard
                    historySection
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(site.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.impact(.light, enabled: settings.hapticsEnabled)
                    showAddEntry = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add entry")
            }
        }
        .sheet(isPresented: $showAddEntry) {
            EntryEditorView(site: site, entry: nil) { toast = "Entry added" }
        }
        .sheet(item: $editingEntry) { entry in
            EntryEditorView(site: site, entry: entry) { toast = "Entry updated" }
        }
        .sheet(isPresented: $showGoalEditor) {
            GoalEditorView(site: site) { toast = "Goal saved" }
        }
        .toast(message: $toast)
    }

    // MARK: Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trend")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)

            let points = visibleEntries.map {
                ChartPoint(date: $0.date,
                           value: Units.displayValue(canonical: $0.valueCanonical, kind: kind, system: settings.unitSystem))
            }

            Chart {
                ForEach(points) { p in
                    AreaMark(x: .value("Date", p.date), y: .value(site.name, p.value))
                        .foregroundStyle(
                            LinearGradient(colors: [Theme.accent.opacity(0.25), Theme.accent.opacity(0.02)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("Date", p.date), y: .value(site.name, p.value))
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                }
                if let goal = site.goalValue {
                    let g = Units.displayValue(canonical: goal, kind: kind, system: settings.unitSystem)
                    RuleMark(y: .value("Goal", g))
                        .foregroundStyle(Theme.warn.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Goal")
                                .font(Theme.rounded(10, .semibold))
                                .foregroundStyle(Theme.warn)
                        }
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 200)
            .accessibilityLabel("\(site.name) trend over time")
            .accessibilityValue(trendAccessibilitySummary)

            if historyTrimmed {
                Text("Showing the last \(ProGate.freeHistoryDays) days. Unlock Pro to chart your full history.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(16)
        .cardSurface()
    }

    private var trendAccessibilitySummary: String {
        guard let current = stats.current, let minV = stats.min, let maxV = stats.max else {
            return "No data"
        }
        let c = Units.formatted(canonical: current, kind: kind, system: settings.unitSystem)
        let lo = Units.formatted(canonical: minV, kind: kind, system: settings.unitSystem)
        let hi = Units.formatted(canonical: maxV, kind: kind, system: settings.unitSystem)
        return "Current \(c) \(unit), ranging from \(lo) to \(hi) \(unit) across \(stats.count) entries"
    }

    // MARK: Stats

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCell("Current", stats.current)
                statCell("Average", stats.average)
                statCell("Lowest", stats.min)
                statCell("Highest", stats.max)
            }
            Divider().overlay(Theme.hairline)
            HStack {
                Text("Weekly rate")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(weeklyRateText)
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(rateIntent.color())
            }
            HStack {
                Text("Total change")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(totalChangeText)
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.ink)
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func statCell(_ label: String, _ canonical: Double?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkSoft)
            Text(canonical.map { "\(Units.formatted(canonical: $0, kind: kind, system: settings.unitSystem)) \(unit)" } ?? "—")
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(canonical.map { "\(Units.formatted(canonical: $0, kind: kind, system: settings.unitSystem)) \(unit)" } ?? "no data")
    }

    private var weeklyRateText: String {
        guard let rate = stats.weeklyRate else { return "Need 2+ entries" }
        let d = Units.displayValue(canonical: rate, kind: kind, system: settings.unitSystem)
        let sign = d > 0 ? "+" : ""
        return "\(sign)\(Units.number(d, digits: 2)) \(unit)/wk"
    }

    private var rateIntent: ChangeIntent {
        guard let rate = stats.weeklyRate, abs(rate) > 0.0001 else { return .neutral }
        return rate < 0 ? .good : .bad
    }

    private var totalChangeText: String {
        guard let total = stats.totalChange else { return "—" }
        let d = Units.displayValue(canonical: total, kind: kind, system: settings.unitSystem)
        let sign = d > 0 ? "+" : ""
        return "\(sign)\(Units.number(d, digits: 1)) \(unit)"
    }

    // MARK: Goal

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Goal")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button(site.goalValue == nil ? "Set goal" : "Edit") {
                    Haptics.selection(enabled: settings.hapticsEnabled)
                    showGoalEditor = true
                }
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.accentDeep)
            }
            if let goal = site.goalValue,
               let first = visibleEntries.first?.valueCanonical,
               let current = stats.current {
                let frac = GoalProgress.fraction(start: first, current: current, goal: goal)
                let goalText = Units.formatted(canonical: goal, kind: kind, system: settings.unitSystem)
                let curText = Units.formatted(canonical: current, kind: kind, system: settings.unitSystem)
                GoalProgressBar(title: "Progress", progress: frac, detail: "\(curText) → \(goalText) \(unit)")
            } else {
                Text("No goal set. Add one to track your progress with a filling bar.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
            VStack(spacing: 0) {
                ForEach(visibleEntries.reversed()) { entry in
                    historyRow(entry)
                    if entry.id != visibleEntries.first?.id {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .cardSurface()
        }
    }

    private func historyRow(_ entry: MeasurementEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Units.formatted(canonical: entry.valueCanonical, kind: kind, system: settings.unitSystem) + " " + unit)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(DateFmt.medium(entry.date))
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Button {
                Haptics.selection(enabled: settings.hapticsEnabled)
                editingEntry = entry
            } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(Theme.accentDeep)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit entry from \(DateFmt.medium(entry.date))")
            Button(role: .destructive) {
                delete(entry)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Theme.bad)
            }
            .buttonStyle(.plain)
            .padding(.leading, 6)
            .accessibilityLabel("Delete entry from \(DateFmt.medium(entry.date))")
        }
        .padding(.vertical, 10)
    }

    private func delete(_ entry: MeasurementEntry) {
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
        modelContext.delete(entry)
        try? modelContext.save()
        toast = "Entry deleted"
    }
}

struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
