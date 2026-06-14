import SwiftUI
import SwiftData

/// The Timeline / Home screen: gradient cards with live counts, pinned section,
/// segmented filter, sort, and an empty state. Tap a card to open its detail.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("isPro") private var isPro = false
    @Query private var events: [CountdownEvent]

    @State private var filter: Filter = .upcoming
    @State private var sort: SortOption = .soonest
    @State private var showingEditor = false
    @State private var paywall: PaywallReason?
    @State private var editingEvent: CountdownEvent?

    enum Filter: String, CaseIterable, Identifiable {
        case upcoming = "Upcoming"
        case past = "Past"
        case all = "All"
        var id: String { rawValue }
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case soonest = "Soonest"
        case title = "Title"
        case recentlyAdded = "Recently added"
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .soonest: return "clock"
            case .title: return "textformat"
            case .recentlyAdded: return "sparkles"
            }
        }
    }

    private var engine: CountdownEngine { settings.engine }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: tickInterval)) { context in
                content(now: context.date)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Cusp")
            .toolbar { toolbar }
            .navigationDestination(for: CountdownEvent.self) { event in
                EventDetailView(event: event)
            }
            .sheet(isPresented: $showingEditor) {
                EventEditorView(mode: .create(defaults: defaults()))
            }
            .sheet(item: $editingEvent) { event in
                EventEditorView(mode: .edit(event))
            }
            .sheet(item: $paywall) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    /// Tick every second only when any visible event shows a live time ticker.
    private var tickInterval: TimeInterval {
        settings.showSecondsOnCards ? 1 : 60
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let visible = filtered(events, now: now)
        let pinned = visible.filter { $0.pinned }
        let unpinned = visible.filter { !$0.pinned }

        if events.isEmpty {
            EmptyStateView(
                symbol: "hourglass",
                title: "No countdowns yet",
                message: "Add your first event and watch the days tick by.",
                actionTitle: "Add an event",
                action: { startCreate() }
            )
        } else if visible.isEmpty {
            EmptyStateView(
                symbol: filter == .past ? "clock.arrow.circlepath" : "calendar.badge.plus",
                title: filter == .past ? "Nothing in the past" : "Nothing upcoming",
                message: filter == .past
                    ? "Events you've passed will collect here."
                    : "Add an event or switch the filter to see your other moments."
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    summaryStrip(now: now)

                    if !pinned.isEmpty {
                        SectionHeader(title: "Pinned", count: pinned.count, symbol: "pin.fill")
                            .padding(.horizontal, 16)
                            .padding(.top, 2)
                        ForEach(sorted(pinned, now: now)) { event in
                            cardLink(event, now: now)
                        }
                    }

                    if !unpinned.isEmpty {
                        SectionHeader(title: pinned.isEmpty ? filter.rawValue : "More",
                                      count: unpinned.count)
                            .padding(.horizontal, 16)
                            .padding(.top, pinned.isEmpty ? 0 : 6)
                        ForEach(sorted(unpinned, now: now)) { event in
                            cardLink(event, now: now)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }

    private func cardLink(_ event: CountdownEvent, now: Date) -> some View {
        NavigationLink(value: event) {
            EventCard(event: event, now: now, engine: engine,
                      showSeconds: settings.showSecondsOnCards)
                .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                togglePin(event)
            } label: {
                Label(event.pinned ? "Unpin" : "Pin", systemImage: event.pinned ? "pin.slash" : "pin")
            }
            Button {
                editingEvent = event
            } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) {
                delete(event)
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func summaryStrip(now: Date) -> some View {
        let c = engine.counts(events, now: now)
        return HStack(spacing: 10) {
            summaryPill(value: c.upcoming, label: "Upcoming", symbol: "arrow.forward")
            summaryPill(value: c.today, label: "Today", symbol: "sparkles", accent: true)
            summaryPill(value: c.past, label: "Past", symbol: "clock.arrow.circlepath")
        }
        .padding(.horizontal, 16)
    }

    private func summaryPill(value: Int, label: String, symbol: String, accent: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(accent ? Theme.accent : Theme.ink)
            Text(label)
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                }
                Divider()
                Picker("Sort", selection: $sort) {
                    ForEach(SortOption.allCases) {
                        Label($0.rawValue, systemImage: $0.symbol).tag($0)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            .accessibilityLabel("Filter and sort")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                startCreate()
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add event")
        }
        ToolbarItem(placement: .principal) {
            if !events.isEmpty {
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)
            }
        }
    }

    // MARK: - Data helpers

    private func filtered(_ events: [CountdownEvent], now: Date) -> [CountdownEvent] {
        switch filter {
        case .all: return events
        case .upcoming:
            return events.filter { engine.group(for: $0, now: now) != .past }
        case .past:
            return events.filter { engine.group(for: $0, now: now) == .past }
        }
    }

    private func sorted(_ list: [CountdownEvent], now: Date) -> [CountdownEvent] {
        switch sort {
        case .soonest:
            return engine.sortedForHome(list, now: now)
        case .title:
            return list.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .recentlyAdded:
            return list.sorted { $0.createdAt > $1.createdAt }
        }
    }

    private func defaults() -> EventEditorView.Defaults {
        EventEditorView.Defaults(kind: settings.defaultKind, themeTag: settings.defaultThemeTag)
    }

    private func startCreate() {
        if Pro.canCreate(currentCount: events.count, isPro: isPro) {
            Haptics.tap(enabled: settings.hapticsEnabled)
            showingEditor = true
        } else {
            Haptics.warning(enabled: settings.hapticsEnabled)
            paywall = .eventLimit
        }
    }

    private func togglePin(_ event: CountdownEvent) {
        Haptics.tap(enabled: settings.hapticsEnabled)
        event.pinned.toggle()
        try? context.save()
    }

    private func delete(_ event: CountdownEvent) {
        Haptics.warning(enabled: settings.hapticsEnabled)
        context.delete(event)
        try? context.save()
    }
}
