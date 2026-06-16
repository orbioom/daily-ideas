import SwiftUI
import SwiftData

struct PipelineView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @Query(sort: [SortDescriptor(\Application.dateAdded, order: .reverse)])
    private var applications: [Application]

    @State private var searchText = ""
    @State private var filter: AppStatus? = nil
    @State private var showingForm = false
    @State private var showingPaywall = false
    @State private var toast: ToastData?

    private var engine: PipelineEngine {
        PipelineEngine(applications: applications, weeklyGoal: settings.weeklyGoal, staleAfterDays: settings.staleAfterDays)
    }

    private var activeApplications: [Application] {
        applications.filter { !$0.isArchived }
    }

    private var filtered: [Application] {
        let base = activeApplications.filter { app in
            filter == nil || app.status == filter
        }
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return base }
        return base.filter {
            $0.company.lowercased().contains(query) ||
            $0.role.lowercased().contains(query) ||
            $0.location.lowercased().contains(query)
        }
    }

    /// Grouped by status, in pipeline order, with only non-empty groups.
    private var grouped: [(status: AppStatus, items: [Application])] {
        AppStatus.pipelineOrder.compactMap { status in
            let items = filtered.filter { $0.status == status }
                .sorted { lhs, rhs in
                    if lhs.priority.sortRank != rhs.priority.sortRank {
                        return lhs.priority.sortRank < rhs.priority.sortRank
                    }
                    return lhs.dateAdded > rhs.dateAdded
                }
            return items.isEmpty ? nil : (status, items)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Pipeline")
            .navigationDestination(for: Application.self) { app in
                ApplicationDetailView(application: app)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        attemptAdd()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                    }
                    .accessibilityLabel("Add application")
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search company or role")
            .sheet(isPresented: $showingForm) {
                ApplicationFormView { _ in
                    toast = ToastData(message: "Application added", symbol: "checkmark.circle.fill")
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(reason: "You've reached the free limit of \(ProStore.freeApplicationCap) active applications.")
            }
            .toast($toast)
        }
    }

    @ViewBuilder
    private var content: some View {
        if activeApplications.isEmpty {
            EmptyStateView(
                symbol: "tray.full",
                title: "Start your pipeline",
                message: "Add the first role you're chasing. Pursuit keeps every application, interview and contact in one private place.",
                actionTitle: "Add application",
                action: attemptAdd
            )
        } else {
            List {
                Section {
                    FunnelSummaryCard(engine: engine)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    filterChips
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if filtered.isEmpty {
                    EmptyStateView(
                        symbol: "magnifyingglass",
                        title: "No matches",
                        message: "No applications match your search or filter. Try clearing them."
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(grouped, id: \.status) { group in
                        statusSection(group.status, items: group.items)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", count: activeApplications.count, isOn: filter == nil, color: Theme.accent) {
                    filter = nil
                }
                ForEach(AppStatus.pipelineOrder) { status in
                    let count = activeApplications.filter { $0.status == status }.count
                    if count > 0 {
                        chip(title: status.label, count: count, isOn: filter == status, color: status.color) {
                            filter = (filter == status) ? nil : status
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func chip(title: String, count: Int, isOn: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { action() }
            Haptics.selection(enabled: settings.hapticsEnabled)
        } label: {
            HStack(spacing: 6) {
                Text(title).font(Theme.rounded(14, .semibold))
                Text("\(count)")
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(isOn ? color : Theme.inkSoft)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background((isOn ? Color.white : color.opacity(0.15)), in: Capsule())
            }
            .foregroundStyle(isOn ? .white : Theme.ink)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(isOn ? color : Theme.surface, in: Capsule())
            .overlay(Capsule().stroke(isOn ? Color.clear : Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) filter, \(count) items")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    @ViewBuilder
    private func statusSection(_ status: AppStatus, items: [Application]) -> some View {
        Section {
            ForEach(items) { app in
                NavigationLink(value: app) {
                    ApplicationRow(application: app)
                }
                .listRowBackground(Theme.surface)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if let next = app.status.next {
                        Button {
                            advance(app, to: next)
                        } label: {
                            Label("To \(next.label)", systemImage: "arrow.right")
                        }
                        .tint(next.color)
                    }
                    if !app.status.isTerminal {
                        Button {
                            advance(app, to: .withdrawn)
                        } label: {
                            Label("Withdraw", systemImage: "arrow.uturn.backward")
                        }
                        .tint(Theme.inkSoft)
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        archive(app)
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(Theme.bad)
                }
            }
        } header: {
            HStack(spacing: 8) {
                Image(systemName: status.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(status.color)
                Text(status.label)
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.inkSoft)
                Text("\(items.count)")
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .textCase(nil)
        }
    }

    // MARK: - Actions

    private func attemptAdd() {
        let activeCount = activeApplications.count
        if !pro.isPro && activeCount >= ProStore.freeApplicationCap {
            showingPaywall = true
            Haptics.notify(.warning, enabled: settings.hapticsEnabled)
        } else {
            showingForm = true
        }
    }

    private func advance(_ app: Application, to status: AppStatus) {
        guard app.status != status else { return }
        app.status = status
        if status.isSubmitted && app.appliedDate == nil {
            app.appliedDate = Date()
        }
        let ev = ActivityEvent(kind: .statusChanged, detail: "Moved to \(status.label)", status: status)
        ev.application = app
        context.insert(ev)
        app.events.append(ev)
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        toast = ToastData(message: "Moved to \(status.label)", symbol: status.symbol, tint: status.color)
    }

    private func archive(_ app: Application) {
        app.isArchived = true
        try? context.save()
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
        toast = ToastData(message: "Archived \(app.company)", symbol: "archivebox.fill", tint: Theme.inkSoft)
    }
}
