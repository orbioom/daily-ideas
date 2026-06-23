import SwiftUI
import SwiftData

/// A chronological, filterable log of every event with full edit/delete.
struct LogTimelineView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.volumeUnit) private var volumeUnitRaw = VolumeUnit.oz.rawValue
    @AppStorage(PrefKey.hapticsEnabled) private var haptics = true
    @AppStorage(PrefKey.confirmDelete) private var confirmDelete = true

    @Bindable var baby: Baby

    @State private var filter: FilterOption = .all
    @State private var editing: EditTarget?
    @State private var pendingDelete: TimelineItem?

    private var unit: VolumeUnit { VolumeUnit(rawValue: volumeUnitRaw) ?? .oz }

    enum FilterOption: String, CaseIterable, Identifiable {
        case all, feed, sleep, diaper, growth
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var source: TimelineItem.Source? {
            switch self {
            case .all: return nil
            case .feed: return .feed
            case .sleep: return .sleep
            case .diaper: return .diaper
            case .growth: return .growth
            }
        }
    }

    private var items: [TimelineItem] {
        let all = SprigEngine.timeline(for: baby)
        guard let src = filter.source else { return all }
        return all.filter { $0.source == src }
    }

    /// Groups items into day sections for the sectioned list.
    private var grouped: [(day: Date, items: [TimelineItem])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: items) { cal.startOfDay(for: $0.date) }
        return dict.keys.sorted(by: >).map { ($0, dict[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ambientGradient(scheme).ignoresSafeArea()
                content
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Filter", selection: $filter) {
                            ForEach(FilterOption.allCases) { Text($0.label).tag($0) }
                        }
                    } label: {
                        Image(systemName: filter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                    .accessibilityLabel("Filter events")
                }
            }
            .sheet(item: $editing) { target in editor(for: target) }
            .confirmationDialog("Delete this entry?",
                                isPresented: Binding(get: { pendingDelete != nil },
                                                     set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let item = pendingDelete { performDelete(item) }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if items.isEmpty {
            EmptyStateView(
                systemImage: filter == .all ? "tray" : filter.source?.systemImage ?? "tray",
                title: filter == .all ? "No events yet" : "No \(filter.label.lowercased()) events",
                message: filter == .all
                    ? "Log a feed, sleep, diaper or measurement and it'll appear here."
                    : "Try a different filter or add a new entry from the Today screen."
            )
        } else {
            List {
                ForEach(grouped, id: \.day) { section in
                    Section {
                        ForEach(section.items) { item in
                            row(for: item)
                                .listRowBackground(Theme.card(scheme))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        requestDelete(item)
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { openEditor(item) }
                        }
                    } header: {
                        Text(sectionTitle(section.day))
                            .foregroundStyle(Theme.secondaryText(scheme))
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    private func sectionTitle(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInYesterday(day) { return "Yesterday" }
        return Fmt.day(day)
    }

    // MARK: Row rendering

    @ViewBuilder
    private func row(for item: TimelineItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(item.source.tint.opacity(0.18)).frame(width: 38, height: 38)
                Image(systemName: item.source.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(item.source.tint)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title(for: item))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText(scheme))
                Text(subtitle(for: item))
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText(scheme))
            }
            Spacer()
            Text(Fmt.time(item.date))
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.secondaryText(scheme))
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title(for: item)), \(subtitle(for: item)), \(Fmt.time(item.date))")
        .accessibilityHint("Double tap to edit")
    }

    private func title(for item: TimelineItem) -> String {
        switch item.source {
        case .feed:
            guard let f = feed(item) else { return "Feed" }
            if f.kind.isBreast { return "Breast feed · \(f.kind.label)" }
            return "Bottle"
        case .sleep:
            return "Sleep"
        case .diaper:
            return "Diaper · \(diaper(item)?.kind.label ?? "")"
        case .growth:
            return "Measurement"
        }
    }

    private func subtitle(for item: TimelineItem) -> String {
        switch item.source {
        case .feed:
            guard let f = feed(item) else { return "" }
            if f.kind.isBreast { return Fmt.duration(Double(f.durationSeconds)) }
            return "\(Fmt.num(unit.display(fromML: f.volumeML))) \(unit.label)"
        case .sleep:
            guard let s = sleep(item) else { return "" }
            return s.isOngoing ? "In progress" : Fmt.duration(s.duration())
        case .diaper:
            return diaper(item)?.note.isEmpty == false ? (diaper(item)?.note ?? "") : "Changed"
        case .growth:
            guard let g = growth(item) else { return "" }
            var parts: [String] = []
            if g.hasWeight { parts.append("\(Fmt.num(g.weightGrams / 1000, decimals: 2)) kg") }
            if g.hasLength { parts.append("\(Fmt.num(g.lengthCM)) cm") }
            return parts.joined(separator: " · ")
        }
    }

    // MARK: Lookups

    private func feed(_ i: TimelineItem) -> FeedLog? { baby.feeds.first { $0.id == i.id } }
    private func sleep(_ i: TimelineItem) -> SleepLog? { baby.sleeps.first { $0.id == i.id } }
    private func diaper(_ i: TimelineItem) -> DiaperLog? { baby.diapers.first { $0.id == i.id } }
    private func growth(_ i: TimelineItem) -> GrowthEntry? { baby.growth.first { $0.id == i.id } }

    // MARK: Editing

    private func openEditor(_ item: TimelineItem) {
        switch item.source {
        case .feed: if let f = feed(item) { editing = .feed(f) }
        case .sleep: if let s = sleep(item) { editing = .sleep(s) }
        case .diaper: if let d = diaper(item) { editing = .diaper(d) }
        case .growth: if let g = growth(item) { editing = .growth(g) }
        }
    }

    @ViewBuilder
    private func editor(for target: EditTarget) -> some View {
        switch target {
        case .feed(let f): FeedEditorView(baby: baby, existing: f)
        case .sleep(let s): SleepEditorView(baby: baby, existing: s)
        case .diaper(let d): DiaperEditorView(baby: baby, existing: d)
        case .growth(let g): GrowthEditorView(baby: baby, existing: g)
        }
    }

    // MARK: Delete

    private func requestDelete(_ item: TimelineItem) {
        if confirmDelete { pendingDelete = item } else { performDelete(item) }
    }

    private func performDelete(_ item: TimelineItem) {
        switch item.source {
        case .feed: if let f = feed(item) { context.delete(f) }
        case .sleep: if let s = sleep(item) { context.delete(s) }
        case .diaper: if let d = diaper(item) { context.delete(d) }
        case .growth: if let g = growth(item) { context.delete(g) }
        }
        try? context.save()
        Haptics.warning(haptics)
    }
}

/// Identifies which entry an editor sheet is editing.
private enum EditTarget: Identifiable {
    case feed(FeedLog)
    case sleep(SleepLog)
    case diaper(DiaperLog)
    case growth(GrowthEntry)

    var id: UUID {
        switch self {
        case .feed(let f): return f.id
        case .sleep(let s): return s.id
        case .diaper(let d): return d.id
        case .growth(let g): return g.id
        }
    }
}
